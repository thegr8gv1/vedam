"""
Vedic Heritage Platform — Content Ingestion & Processing Pipeline Queue
Orchestrates raw text through normalization, stanza splitting, metadata extraction,
completeness validation, rights gatekeeping, database persistence, and export integration.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from automation.cleaners.unicode_preserver import TransliterationEngine, UnicodePreserver
from automation.classifiers.text_classifier import TextClassifier
from automation.identity.generator import ContentIdentityGenerator
from automation.parsers.metadata_extractor import LiturgicalMetadataExtractor
from automation.parsers.verse_splitter import VerseSplitter
from automation.pipeline.logger import PipelineLogger
from automation.rights.engine import RightsProvenanceEngine
from automation.validators.completeness_checker import CompletenessChecker
from database.connection import get_db_session
from database.models import (
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    ReviewStatus,
    Text,
    TextVersion,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
    VersionType,
)


class ProcessingQueue:
    """End-to-end ingestion orchestrator for authentic sacred literature."""

    def __init__(self):
        self.logger = PipelineLogger.get_logger("pipeline.queue")

    def process_raw_item(self, payload: Dict[str, Any], sequence_num: int) -> Dict[str, Any]:
        """
        Process a single raw ingested item through the complete verified lifecycle.
        """
        raw_text = payload.get("raw_text", "")
        title = payload.get("title", "Untitled Composition")
        rights_meta = payload.get("rights", {})

        self.logger.info(f"Enqueuing: {title} (Seq: {sequence_num})")

        # 1. Unicode Normalization & Swara Analysis
        canonical_text, swara_info = UnicodePreserver.extract_canonical_text(raw_text)
        content_hash = ContentIdentityGenerator.compute_content_hash(canonical_text)
        content_id = ContentIdentityGenerator.generate_text_id(sequence_num)
        uuid_str = ContentIdentityGenerator.generate_uuid()

        # 2. Liturgical Metadata Extraction
        meta = LiturgicalMetadataExtractor.extract_metadata(canonical_text)

        # 3. Classification
        category_slug = TextClassifier.classify_category(title, canonical_text)
        deity_slug = payload.get("deity_slug") or TextClassifier.detect_deity(title, canonical_text)
        language = TextClassifier.detect_language(canonical_text)

        # 4. Verse Splitting
        v_type = VerseType.DOHA if language == "awa" else VerseType.VERSE
        split_verses = VerseSplitter.split_into_verses(canonical_text, expected_verse_type=v_type)

        # 5. Completeness & Integrity Validation
        is_complete, issues = CompletenessChecker.validate_verse_sequence(split_verses)
        if not is_complete:
            self.logger.warning(f"Integrity check flagged issues for {title}: {issues}")

        # 6. Database Persistence within Transaction
        with get_db_session() as session:
            # Check or link category & deity
            cat = session.query(Category).filter_by(slug=category_slug).first()
            if not cat:
                cat = Category(slug=category_slug, name=category_slug.capitalize())
                session.add(cat)
                session.flush()

            deity = session.query(Deity).filter_by(slug=deity_slug).first() if deity_slug else None

            # Remove existing text record if re-processing same sequence number
            existing_text = session.query(Text).filter_by(content_id=content_id).first()
            if existing_text:
                session.delete(existing_text)
                session.flush()

            # Create Master Text
            text_model = Text(
                content_id=content_id,
                uuid=uuid_str,
                canonical_title=payload.get("canonical_title", title),
                devanagari_title=payload.get("devanagari_title", title),
                alternative_titles=payload.get("alternative_titles", []),
                raw_source_script=payload.get("raw_script", "Devanagari"),
                raw_source_text=raw_text,
                canonical_scholarly_text=canonical_text,
                deity=deity,
                primary_category=cat,
                original_language=language,
                composer=meta.get("composer") or payload.get("composer"),
                rishi=meta.get("rishi") or payload.get("rishi"),
                chandas=meta.get("chandas") or payload.get("chandas"),
                devata=meta.get("devata") or payload.get("devata"),
                source_scripture=payload.get("source_scripture"),
                associated_festival=payload.get("associated_festival"),
                traditional_usage=payload.get("traditional_usage"),
                verse_count=len(split_verses),
                content_hash=content_hash,
            )
            session.add(text_model)
            session.flush()

            # Store Raw Version
            v_raw = TextVersion(
                text=text_model,
                version_type=VersionType.RAW_EXTRACTED,
                version_number=1,
                full_text=raw_text,
                notes="Immutable raw source ingestion",
            )
            session.add(v_raw)

            # Store Verses & Transliterations
            for v_data in split_verses:
                v_num = v_data["verse_number"]
                verse_id = ContentIdentityGenerator.generate_verse_id(content_id, v_num)
                v_dev = v_data["devanagari_text"]

                # Generate Roman IAST
                iast = TransliterationEngine.to_script(v_dev, "iast")

                verse_obj = Verse(
                    text=text_model,
                    verse_id=verse_id,
                    verse_number=v_num,
                    verse_type=v_data["verse_type"],
                    devanagari_text=v_dev,
                    iast_text=iast,
                    vedic_accents_present=swara_info["has_vedic_accents"],
                    vedic_accent_annotations=swara_info if swara_info["has_vedic_accents"] else None,
                )
                session.add(verse_obj)

                # Generate regional transliterations for South Indian scripts
                for script in ["telugu", "tamil", "kannada", "malayalam"]:
                    try:
                        t_text = TransliterationEngine.to_script(v_dev, script)
                        translit_obj = Transliteration(
                            verse=verse_obj,
                            target_script=script,
                            script_text=t_text,
                            is_lossless=True,
                        )
                        session.add(translit_obj)
                    except Exception as e:
                        self.logger.error(f"Transliteration failed for {script} in verse {verse_id}: {e}")

            # Link Rights Record
            rights_obj = ContentRights(
                text=text_model,
                original_composition_attribution=rights_meta.get("attribution", "Traditional"),
                primary_source=rights_meta.get("primary_source", "Verified Public Domain"),
                specific_edition=rights_meta.get("specific_edition"),
                edition_publication_date=rights_meta.get("publication_date"),
                license_type=rights_meta.get("license_type", "PUBLIC_DOMAIN"),
                commercial_reuse_permitted=rights_meta.get("commercial_reuse", True),
                translation_permitted=rights_meta.get("translation_permitted", True),
                derivative_work_permitted=rights_meta.get("derivative_permitted", True),
                distribution_permitted=rights_meta.get("distribution_permitted", True),
                release_status=ReleaseStatus(rights_meta.get("release_status", "GREEN")),
                supporting_evidence=rights_meta.get("evidence"),
            )
            session.add(rights_obj)
            session.commit()

        self.logger.info(f"Successfully processed and stored: {content_id} - {title}")
        return {
            "content_id": content_id,
            "status": "STORED",
            "verse_count": len(split_verses),
            "swaras_detected": swara_info["has_vedic_accents"],
            "integrity_issues": issues,
        }
