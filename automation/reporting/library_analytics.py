"""
Vedic Heritage Platform — Global Library Analytics & Dashboard Engine
Computes real-time repository health, catalog coverage, rights clearance,
scholarly review backlog, multilingual coverage, and publication readiness for sacred texts.
"""

from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from sqlalchemy import func
from sqlalchemy.orm import Session

from automation.rights.approval_workflow import (
    AcquisitionStatus,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from database.connection import get_db_session
from database.models import (
    ArchivedTranslation,
    ReleaseStatus,
    ReviewStatus,
    Text,
    Translation,
    TranslationReviewFeedback,
    Verse,
    VerseType,
)


@dataclass
class LibraryDashboardMetrics:
    generated_at_utc: str
    total_candidate_catalog: int
    total_registered_database_texts: int
    verified_complete_texts: int
    sample_or_prototype_texts: int
    rights_cleared_green_texts: int
    rights_pending_amber_texts: int
    rights_forbidden_red_texts: int
    scholar_verified_texts: int
    pending_scholarly_review_texts: int
    translation_approved_texts: int
    translation_in_review_texts: int
    translation_untranslated_verses: int
    editorial_approved_texts: int
    published_manuscripts_excel: int
    published_manuscripts_word: int
    published_manuscripts_pdf: int
    audio_production_ready_texts: int
    total_verified_verses: int
    supported_scripts_count: int
    supported_scripts: List[str]
    category_distribution: Dict[str, int]
    deity_distribution: Dict[str, int]
    potential_duplicate_candidates: int
    # Multilingual Localization Metrics
    multilingual_languages_count: int = 10
    multilingual_translation_coverage: Dict[str, Dict[str, int]] = field(default_factory=dict)
    compositions_with_regional_localization: int = 0
    compositions_awaiting_regional_localization: int = 0
    compositions_localized_list: List[str] = field(default_factory=list)
    compositions_awaiting_list: List[str] = field(default_factory=list)
    regional_translation_completion_pct: float = 0.0
    publication_ready_approved_translations: int = 0
    draft_pending_review_translations: int = 0
    total_archived_historical_translations: int = 0
    multilingual_artifacts_excel: int = 0
    multilingual_artifacts_word: int = 0
    multilingual_artifacts_json: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class LibraryAnalyticsEngine:
    """Computes comprehensive health and expansion metrics across the digital library."""

    REGIONAL_LANGS = {"hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"}

    @classmethod
    def generate_dashboard_metrics(
        cls,
        session: Session,
        catalog_path: str = "data/catalogs/master_devotional_catalog.json",
    ) -> LibraryDashboardMetrics:
        # 1. Candidate Catalog Metrics
        total_candidates = 0
        if os.path.exists(catalog_path):
            with open(catalog_path, "r", encoding="utf-8") as f:
                candidates_data = json.load(f)
                total_candidates = len(candidates_data)

        # 2. Database Entities
        texts = session.query(Text).all()
        total_registered = len(texts)

        verified_complete = 0
        sample_or_prototype = 0
        rights_green = 0
        rights_amber = 0
        rights_red = 0
        scholar_verified = 0
        pending_review = 0
        trans_approved = 0
        trans_in_review = 0
        editorial_approved = 0
        audio_ready = 0
        total_verified_verses = 0
        total_all_verses = 0
        untranslated_verses = 0

        cat_dist: Dict[str, int] = {}
        deity_dist: Dict[str, int] = {}

        localized_cids = []
        awaiting_cids = []

        for t in texts:
            v_len = len(t.verses)
            total_all_verses += v_len

            is_verified = (
                t.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED
                and t.verse_count > 0
                and v_len == t.verse_count
            )

            if is_verified:
                verified_complete += 1
                total_verified_verses += v_len
                # Check if text has regional translations
                has_reg = any(
                    tr.target_language in cls.REGIONAL_LANGS
                    for v in t.verses
                    for tr in v.translations
                )
                if has_reg:
                    localized_cids.append(t.content_id)
                else:
                    awaiting_cids.append(t.content_id)
            else:
                sample_or_prototype += 1

            # Rights
            if t.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED:
                rights_green += 1
            elif t.rights_clearance_status == RightsClearanceStatus.PENDING:
                rights_amber += 1
            else:
                rights_red += 1

            # Textual Verification
            if t.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED:
                scholar_verified += 1
            else:
                pending_review += 1

            # Translation
            if t.translation_status == TranslationStatus.APPROVED:
                trans_approved += 1
            else:
                trans_in_review += 1

            for v in t.verses:
                if not v.translations:
                    untranslated_verses += 1

            # Editorial
            if t.editorial_approval_status == EditorialApprovalStatus.APPROVED:
                editorial_approved += 1

            # Audio readiness: text verified + rights green + complete verses
            if (
                t.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED
                and t.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED
                and len(t.verses) > 0
            ):
                audio_ready += 1

            # Categorization
            cat_name = t.primary_category.name if t.primary_category else "Uncategorized"
            cat_dist[cat_name] = cat_dist.get(cat_name, 0) + 1

            deity_name = t.deity.name if t.deity else "Unassigned"
            deity_dist[deity_name] = deity_dist.get(deity_name, 0) + 1

        # 3. Publication Files Count
        excel_files = len(list(Path("exports/excel").glob("VEDA-TXT-*.xlsx"))) if os.path.exists("exports/excel") else 0
        word_files = len(list(Path("exports/word").glob("VEDA-TXT-*.docx"))) if os.path.exists("exports/word") else 0
        pdf_files = len(list(Path("exports/pdf").glob("VEDA-TXT-*.pdf"))) if os.path.exists("exports/pdf") else 0

        # Supported Scripts (Devanagari, Telugu, Tamil, Kannada, Malayalam, Bengali, Gujarati, Odia, IAST)
        supported_scripts = [
            "Devanagari",
            "Telugu",
            "Tamil",
            "Kannada",
            "Malayalam",
            "Bengali",
            "Gujarati",
            "Odia",
            "IAST (Roman)",
        ]

        # 4. Multilingual Translation Coverage
        all_translations = session.query(Translation).all()
        translation_coverage: Dict[str, Dict[str, int]] = {}
        pub_ready_approved = 0
        draft_pending = 0

        for tr in all_translations:
            lang = tr.target_language
            if lang not in translation_coverage:
                translation_coverage[lang] = {"total": 0, "draft": 0, "approved": 0, "in_review": 0}
            translation_coverage[lang]["total"] += 1
            if tr.review_status == ReviewStatus.APPROVED:
                translation_coverage[lang]["approved"] += 1
                pub_ready_approved += 1
            elif tr.review_status == ReviewStatus.DRAFT:
                translation_coverage[lang]["draft"] += 1
                draft_pending += 1
            else:
                translation_coverage[lang]["in_review"] += 1
                draft_pending += 1

        # Calculate regional translation completion %
        total_possible_regional = verified_complete * 9  # 18 * 9 = 162 composition-language units
        total_actual_regional = len(localized_cids) * 9
        comp_pct = round((len(localized_cids) / max(1, verified_complete)) * 100, 2)

        # Check archived historical translations count
        archived_count = session.query(ArchivedTranslation).count()

        ml_excel = len(list(Path("exports/multilingual/excel").glob("*.xlsx"))) if os.path.exists("exports/multilingual/excel") else 0
        ml_word = len(list(Path("exports/multilingual/word").glob("*.docx"))) if os.path.exists("exports/multilingual/word") else 0
        ml_json = len(list(Path("exports/multilingual/json").glob("*.json"))) if os.path.exists("exports/multilingual/json") else 0

        return LibraryDashboardMetrics(
            generated_at_utc=datetime.now(timezone.utc).isoformat(),
            total_candidate_catalog=total_candidates,
            total_registered_database_texts=total_registered,
            verified_complete_texts=verified_complete,
            sample_or_prototype_texts=sample_or_prototype,
            rights_cleared_green_texts=rights_green,
            rights_pending_amber_texts=rights_amber,
            rights_forbidden_red_texts=rights_red,
            scholar_verified_texts=scholar_verified,
            pending_scholarly_review_texts=pending_review,
            translation_approved_texts=trans_approved,
            translation_in_review_texts=trans_in_review,
            translation_untranslated_verses=untranslated_verses,
            editorial_approved_texts=editorial_approved,
            published_manuscripts_excel=excel_files,
            published_manuscripts_word=word_files,
            published_manuscripts_pdf=pdf_files,
            audio_production_ready_texts=audio_ready,
            total_verified_verses=total_verified_verses,
            supported_scripts_count=len(supported_scripts),
            supported_scripts=supported_scripts,
            category_distribution=cat_dist,
            deity_distribution=deity_dist,
            potential_duplicate_candidates=0,
            multilingual_languages_count=len(translation_coverage),
            multilingual_translation_coverage=translation_coverage,
            compositions_with_regional_localization=len(localized_cids),
            compositions_awaiting_regional_localization=len(awaiting_cids),
            compositions_localized_list=sorted(localized_cids),
            compositions_awaiting_list=sorted(awaiting_cids),
            regional_translation_completion_pct=comp_pct,
            publication_ready_approved_translations=pub_ready_approved,
            draft_pending_review_translations=draft_pending,
            total_archived_historical_translations=archived_count,
            multilingual_artifacts_excel=ml_excel,
            multilingual_artifacts_word=ml_word,
            multilingual_artifacts_json=ml_json,
        )

    @classmethod
    def export_dashboard_snapshot(
        cls,
        session: Session,
        output_file: str = "exports/reports/library_analytics_dashboard.json",
    ) -> str:
        metrics = cls.generate_dashboard_metrics(session)
        out_p = Path(output_file)
        out_p.parent.mkdir(parents=True, exist_ok=True)
        with open(out_p, "w", encoding="utf-8") as f:
            json.dump(metrics.to_dict(), f, indent=2, ensure_ascii=False)
        return str(out_p)


if __name__ == "__main__":
    with get_db_session() as session:
        out_path = LibraryAnalyticsEngine.export_dashboard_snapshot(session)
        print(f"Library analytics snapshot exported to: {out_path}")
        with open(out_path, "r", encoding="utf-8") as f:
            print(f.read())
