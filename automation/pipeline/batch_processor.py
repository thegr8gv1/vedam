"""
Vedic Heritage Platform — Controlled Batch Ingestion Engine
Orchestrates safe, resilient batch processing of sacred texts with configurable batch
sizes, dry-run simulation, source permission gates, duplicate checks, atomic checkpoints,
error queues, and automated QA reporting.
"""

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
import json
import logging
import os
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from automation.classifiers.text_classifier import TextClassifier
from automation.duplicate_detection.engine import DuplicateDetectionEngine
from automation.identity.generator import ContentIdentityGenerator
from automation.parsers.metadata_extractor import LiturgicalMetadataExtractor
from automation.parsers.verse_splitter import VerseSplitter
from automation.pipeline.checkpoint import JobCheckpoint
from automation.pipeline.logger import PipelineLogger
from automation.rights.jurisdiction import IPLayerType, Jurisdiction, RightsReleaseStatus
from automation.validators.completeness_checker import CompletenessChecker
from automation.validators.qa_engine import (
    ContentQualityAssuranceEngine,
    QualityAuditReport,
    QualityLifecycleStatus,
)
from database.connection import get_db_session
from database.models import (
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    ReviewStatus,
    RightsGrant,
    Source,
    SourceEdition,
    Text,
    TextVersion,
    Verse,
    VerseType,
    VersionType,
)

logger = logging.getLogger("vedam.automation.batch_processor")


@dataclass
class RawBatchItem:
    raw_text: str
    source_code: str
    source_url: str
    proposed_title: str
    proposed_category_slug: str
    deity_slug: str
    composer_or_rishi: Optional[str] = None
    scripture_ref: Optional[str] = None
    language: str = "sa"
    script: str = "Devanagari"
    publication_year: Optional[int] = None
    is_public_domain: bool = True
    context_metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BatchConfig:
    batch_size: int = 5
    dry_run: bool = False
    enforce_rights_check: bool = True
    auto_checkpoint: bool = True
    checkpoint_dir: str = "logs/checkpoints"
    job_name: str = "batch_ingestion"


@dataclass
class BatchExecutionReport:
    job_name: str
    timestamp: str
    dry_run: bool
    total_submitted: int
    processed_count: int
    success_count: int
    failed_count: int
    duplicate_count: int
    error_queue: List[Dict[str, Any]] = field(default_factory=list)
    quality_reports: List[Dict[str, Any]] = field(default_factory=list)
    ingested_content_ids: List[str] = field(default_factory=list)


class BatchIngestionEngine:
    """Production-grade batch orchestrator enforcing zero-corruption ingestion."""

    def __init__(self, config: Optional[BatchConfig] = None, session: Optional[Session] = None):
        self.config = config or BatchConfig()
        self.session = session
        self.checkpoint = JobCheckpoint(
            job_id=self.config.job_name,
            source_code="BATCH",
            checkpoint_dir=self.config.checkpoint_dir,
        )

    def process_batch(self, items: List[RawBatchItem]) -> BatchExecutionReport:
        """Processes a bounded batch of raw text items with checkpoints and QA gates."""
        if self.session is not None:
            return self._execute_batch_in_session(items, self.session)
        with get_db_session() as session:
            return self._execute_batch_in_session(items, session)

    def _execute_batch_in_session(self, items: List[RawBatchItem], session: Session) -> BatchExecutionReport:
        now_str = datetime.now(timezone.utc).isoformat()
        report = BatchExecutionReport(
            job_name=self.config.job_name,
            timestamp=now_str,
            dry_run=self.config.dry_run,
            total_submitted=len(items),
            processed_count=0,
            success_count=0,
            failed_count=0,
            duplicate_count=0,
        )

        # Slice to configured batch size to prevent uncontrolled ingestion runs
        batch_slice = items[: self.config.batch_size]

        for item in batch_slice:
            report.processed_count += 1
            try:
                result = self._process_single_item(item, session)
                if result["status"] == "SUCCESS":
                    report.success_count += 1
                    report.ingested_content_ids.append(result["content_id"])
                    report.quality_reports.append(result["quality_report"])
                    if self.config.auto_checkpoint:
                        self.checkpoint.mark_completed(item.proposed_title)
                elif result["status"] == "DUPLICATE":
                    report.duplicate_count += 1
                    report.quality_reports.append(result["quality_report"])
            except Exception as e:
                report.failed_count += 1
                if self.config.auto_checkpoint:
                    self.checkpoint.mark_failed(item.proposed_title, str(e))
                error_entry = {
                    "proposed_title": item.proposed_title,
                    "source_code": item.source_code,
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                }
                report.error_queue.append(error_entry)
                logger.error(f"Failed to process item '{item.proposed_title}': {e}", exc_info=True)

        if not self.config.dry_run:
            session.commit()

        return report

    def _process_single_item(self, item: RawBatchItem, session: Session) -> Dict[str, Any]:
        """Processes and validates an individual item."""
        # 1. Source Permission Gate
        if self.config.enforce_rights_check:
            self._verify_source_permission(item, session)

        # 2. Liturgical Metadata Extraction & Classification
        liturgical_meta = LiturgicalMetadataExtractor.extract_metadata(item.raw_text)
        detected_lang = TextClassifier.detect_language(item.raw_text)

        # 3. Content Identity & Content Hash
        content_hash = ContentIdentityGenerator.compute_content_hash(item.raw_text)
        max_id = session.query(Text.id).order_by(Text.id.desc()).first()
        next_seq = (max_id[0] + 1) if max_id else 1
        content_id = ContentIdentityGenerator.generate_text_id(next_seq)

        # 4. Duplicate Check
        existing_texts = session.query(Text).all()
        for ext in existing_texts:
            if ext.content_hash == content_hash:
                return {
                    "status": "DUPLICATE",
                    "content_id": ext.content_id,
                    "quality_report": {"message": f"Exact duplicate of existing record {ext.content_id}"},
                }

        # 5. Verse Segmentation
        raw_verses = VerseSplitter.split_into_verses(item.raw_text)
        if not raw_verses:
            raw_verses = [{"verse_number": 1, "text": item.raw_text, "type": "VERSE"}]

        # 6. Database Entities Construction
        cat = session.query(Category).filter_by(slug=item.proposed_category_slug).first()
        if not cat:
            cat = Category(slug=item.proposed_category_slug, name=item.proposed_category_slug.title())
            session.add(cat)
            session.flush()

        deity = session.query(Deity).filter_by(slug=item.deity_slug).first()
        if not deity:
            deity = Deity(slug=item.deity_slug, name=item.deity_slug.title())
            session.add(deity)
            session.flush()

        text_record = Text(
            content_id=content_id,
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title=item.proposed_title,
            devanagari_title=item.context_metadata.get("devanagari_title", item.proposed_title),
            deity_id=deity.id,
            primary_category_id=cat.id,
            original_language=detected_lang or item.language,
            original_script=item.script,
            composer=item.composer_or_rishi or liturgical_meta.get("composer"),
            rishi=liturgical_meta.get("rishi"),
            chandas=liturgical_meta.get("chandas"),
            devata=liturgical_meta.get("devata"),
            source_scripture=item.scripture_ref or item.context_metadata.get("source_scripture"),
            verse_count=len(raw_verses),
            content_hash=content_hash,
            raw_source_script=item.script,
            raw_source_text=item.raw_text,
            canonical_scholarly_text=item.raw_text,
        )

        # Add Source Edition
        src = session.query(Source).filter_by(source_code=item.source_code).first()
        edition = SourceEdition(
            text=text_record,
            source=src,
            edition_title=item.context_metadata.get("edition_title", f"Edition from {item.source_code}"),
            publication_year=item.publication_year,
            archive_url=item.source_url,
            is_primary_critical_edition=True,
        )
        text_record.source_editions.append(edition)

        # Add Rights Grant (Initial status AMBER; requires manual human legal approval)
        rg = RightsGrant(
            text=text_record,
            ip_layer=IPLayerType.COMPOSITION,
            jurisdiction=Jurisdiction.GLOBAL,
            license_type="PUBLIC_DOMAIN" if item.is_public_domain else "UNDER_REVIEW",
            status=RightsReleaseStatus.AMBER,  # Strict Rule: Cannot jump to GREEN automatically
            is_legally_approved=False,
            notes=f"Ingested from {item.source_code}. Awaiting formal legal sign-off.",
        )
        text_record.rights_grants.append(rg)

        # Add Verses
        for v_dict in raw_verses:
            v_text = v_dict.get("devanagari_text") or v_dict.get("text", "")
            raw_v_type = v_dict.get("verse_type") or v_dict.get("type")
            if isinstance(raw_v_type, VerseType):
                v_type_enum = raw_v_type
            elif raw_v_type == "PHALASRUTI":
                v_type_enum = VerseType.PHALASRUTI
            elif raw_v_type == "DOHA":
                v_type_enum = VerseType.DOHA
            elif raw_v_type == "CHAUPAI":
                v_type_enum = VerseType.CHAUPAI
            else:
                v_type_enum = VerseType.VERSE

            v_obj = Verse(
                text=text_record,
                verse_id=f"{content_id}-V{v_dict['verse_number']:03d}",
                verse_number=v_dict["verse_number"],
                verse_type=v_type_enum,
                devanagari_text=v_text,
                raw_source_text=v_text,
            )
            text_record.verses.append(v_obj)

        if not self.config.dry_run:
            session.add(text_record)
            session.add(edition)
            session.add(rg)
            session.flush()

        # Run automated QA check
        qa_report = ContentQualityAssuranceEngine.audit_text(text_record)

        return {
            "status": "SUCCESS",
            "content_id": content_id,
            "quality_report": asdict(qa_report),
        }

    @staticmethod
    def _verify_source_permission(item: RawBatchItem, session: Session) -> None:
        """Enforces that an ingestion item comes from an authorized source."""
        src = session.query(Source).filter_by(source_code=item.source_code).first()
        if not src:
            raise PermissionError(f"Source code '{item.source_code}' is not registered in Master Source Registry.")
        
        # Check forbidden sources
        if item.source_code in ["SRC-002", "SRC-004"]:
            raise PermissionError(f"Automated ingestion from commercial source {item.source_code} is strictly forbidden.")

    @staticmethod
    def approve_for_publication(content_id: str, legal_reviewer: str, session: Optional[Session] = None) -> bool:
        """
        Transitions an audited text's rights grant to GREEN after human legal review.
        """
        if session is not None:
            return BatchIngestionEngine._do_approval(content_id, legal_reviewer, session)
        with get_db_session() as sess:
            return BatchIngestionEngine._do_approval(content_id, legal_reviewer, sess)

    @staticmethod
    def _do_approval(content_id: str, legal_reviewer: str, session: Session) -> bool:
        text = session.query(Text).filter_by(content_id=content_id).first()
        if not text:
            raise ValueError(f"Text not found: {content_id}")

        for grant in text.rights_grants:
            grant.status = RightsReleaseStatus.GREEN
            grant.is_legally_approved = True
            grant.legal_reviewer = legal_reviewer
            grant.commercial_reuse_authorized = True

        if text.rights:
            text.rights.release_status = ReleaseStatus.GREEN
            text.rights.review_date = datetime.now(timezone.utc)

        session.commit()
        logger.info(f"Text {content_id} approved for publication by legal reviewer {legal_reviewer}")
        return True
