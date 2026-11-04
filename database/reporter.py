"""
Vedic Heritage Platform — Database Reporting & Integrity Analytics Engine
Generates detailed status reports on registered compositions, source editions,
verses, verification statuses, metadata completeness, and rights clearances.
"""

from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
from typing import Any, Dict, List, Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from database.connection import get_db_session
from database.models import (
    Category,
    ContentRights,
    Contributor,
    Deity,
    DuplicateCandidate,
    MediaAsset,
    ReleaseStatus,
    ReviewStatus,
    RightsGrant,
    Source,
    SourceEdition,
    Text,
    TextVersion,
    Translation,
    Transliteration,
    Verse,
)


@dataclass
class DatabaseSummary:
    timestamp: str
    total_compositions: int
    total_source_editions: int
    total_verses: int
    total_translations: int
    total_transliterations: int
    total_contributors: int
    total_media_assets: int
    approved_for_publication: int
    texts_awaiting_verification: int
    texts_with_incomplete_metadata: int
    texts_without_confirmed_rights: int
    duplicate_candidates_count: int
    languages_breakdown: Dict[str, int]
    translation_languages_breakdown: Dict[str, int]
    deities_breakdown: Dict[str, int]
    categories_breakdown: Dict[str, int]
    audit_details: Dict[str, Any]


class DatabaseReporter:
    """Analytical inspector providing real-time health and maturity metrics."""

    def __init__(self, session: Optional[Session] = None):
        self.session = session

    def generate_report(self) -> DatabaseSummary:
        """Executes full diagnostic queries across all relational entities."""
        if self.session is not None:
            return self._run_queries(self.session)
        with get_db_session() as session:
            return self._run_queries(session)

    def _run_queries(self, session: Session) -> DatabaseSummary:
        now_str = datetime.now(timezone.utc).isoformat()

        # Core Counts
        total_texts = session.query(func.count(Text.id)).scalar() or 0
        total_editions = session.query(func.count(SourceEdition.id)).scalar() or 0
        total_verses = session.query(func.count(Verse.id)).scalar() or 0
        total_translations = session.query(func.count(Translation.id)).scalar() or 0
        total_transliterations = session.query(func.count(Transliteration.id)).scalar() or 0
        total_contributors = session.query(func.count(Contributor.id)).scalar() or 0
        total_media = session.query(func.count(MediaAsset.id)).scalar() or 0
        duplicate_count = session.query(func.count(DuplicateCandidate.id)).scalar() or 0

        # Rights & Verification Metrics
        texts = session.query(Text).all()

        approved_count = 0
        awaiting_verification = 0
        incomplete_metadata = 0
        without_confirmed_rights = 0

        incomplete_details = []
        unconfirmed_rights_details = []
        awaiting_verification_details = []

        for t in texts:
            # Rights Check
            is_green = t.rights and t.rights.release_status == ReleaseStatus.GREEN
            if is_green:
                approved_count += 1
            else:
                without_confirmed_rights += 1
                unconfirmed_rights_details.append({
                    "content_id": t.content_id,
                    "title": t.canonical_title,
                    "status": t.rights.release_status.value if t.rights else "NO_RECORD"
                })

            # Incomplete Metadata Check
            # Check essential fields: composer or rishi, source scripture, category
            missing_fields = []
            if not t.composer and not t.rishi:
                missing_fields.append("composer/rishi")
            if not t.source_scripture and not t.traditional_usage:
                missing_fields.append("source_scripture/traditional_usage")
            if not t.primary_category_id:
                missing_fields.append("primary_category")
            if missing_fields:
                incomplete_metadata += 1
                incomplete_details.append({
                    "content_id": t.content_id,
                    "title": t.canonical_title,
                    "missing": missing_fields
                })

            # Verification Check: check if any audit log or scholar review is pending
            has_completed_audit = any(log.review_status == ReviewStatus.APPROVED for log in t.audit_logs)
            if not has_completed_audit:
                awaiting_verification += 1
                awaiting_verification_details.append({
                    "content_id": t.content_id,
                    "title": t.canonical_title
                })

        # Languages breakdown (original languages of compositions)
        lang_rows = (
            session.query(Text.original_language, func.count(Text.id))
            .group_by(Text.original_language)
            .all()
        )
        languages_breakdown = {lang or "unknown": count for lang, count in lang_rows}

        # Translation languages breakdown
        tr_rows = (
            session.query(Translation.target_language, func.count(Translation.id))
            .group_by(Translation.target_language)
            .all()
        )
        tr_languages_breakdown = {lang: count for lang, count in tr_rows}

        # Deity distribution
        deity_rows = (
            session.query(Deity.name, func.count(Text.id))
            .join(Text, Text.deity_id == Deity.id)
            .group_by(Deity.name)
            .all()
        )
        deities_breakdown = {d_name: count for d_name, count in deity_rows}

        # Category distribution
        cat_rows = (
            session.query(Category.name, func.count(Text.id))
            .join(Text, Text.primary_category_id == Category.id)
            .group_by(Category.name)
            .all()
        )
        categories_breakdown = {c_name: count for c_name, count in cat_rows}

        return DatabaseSummary(
            timestamp=now_str,
            total_compositions=total_texts,
            total_source_editions=total_editions,
            total_verses=total_verses,
            total_translations=total_translations,
            total_transliterations=total_transliterations,
            total_contributors=total_contributors,
            total_media_assets=total_media,
            approved_for_publication=approved_count,
            texts_awaiting_verification=awaiting_verification,
            texts_with_incomplete_metadata=incomplete_metadata,
            texts_without_confirmed_rights=without_confirmed_rights,
            duplicate_candidates_count=duplicate_count,
            languages_breakdown=languages_breakdown,
            translation_languages_breakdown=tr_languages_breakdown,
            deities_breakdown=deities_breakdown,
            categories_breakdown=categories_breakdown,
            audit_details={
                "incomplete_metadata_texts": incomplete_details,
                "unconfirmed_rights_texts": unconfirmed_rights_details,
                "awaiting_verification_texts": awaiting_verification_details,
            },
        )

    def print_formatted_summary(self) -> str:
        """Returns human-readable Markdown summary string."""
        summary = self.generate_report()
        lines = [
            f"# Vedic Heritage Platform — Database Maturity & Integrity Report",
            f"**Audit Timestamp:** `{summary.timestamp}`",
            "",
            "## 1. Inventory Summary",
            f"- **Total Registered Compositions:** {summary.total_compositions}",
            f"- **Total Source Editions Tracked:** {summary.total_source_editions}",
            f"- **Total Verses Ingested:** {summary.total_verses}",
            f"- **Total Multi-Script Transliterations:** {summary.total_transliterations}",
            f"- **Total Multilingual Translations:** {summary.total_translations}",
            f"- **Total Media Assets Cataloged:** {summary.total_media_assets}",
            f"- **Total Contributors & Scholars:** {summary.total_contributors}",
            f"- **Duplicate Candidates Flagged:** {summary.duplicate_candidates_count}",
            "",
            "## 2. Quality & Verification Gates",
            f"- **Approved for Commercial Publication (GREEN):** {summary.approved_for_publication}",
            f"- **Texts Awaiting Scholarly Verification:** {summary.texts_awaiting_verification}",
            f"- **Texts with Incomplete Liturgical Metadata:** {summary.texts_with_incomplete_metadata}",
            f"- **Texts Lacking Confirmed Rights:** {summary.texts_without_confirmed_rights}",
            "",
            "## 3. Linguistic Breakdown",
            f"- **Original Composition Languages:** {json.dumps(summary.languages_breakdown)}",
            f"- **Translation Target Languages:** {json.dumps(summary.translation_languages_breakdown)}",
            "",
            "## 4. Deity Distribution",
            json.dumps(summary.deities_breakdown, indent=2),
            "",
            "## 5. Category Distribution",
            json.dumps(summary.categories_breakdown, indent=2),
        ]
        return "\n".join(lines)
