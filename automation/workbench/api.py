"""
Vedic Heritage Platform — Scholarly Review Workbench API & Comparison Engine
Powers the 6-Column Side-by-Side Review Interface:
Col 1: Original Sanskrit / Awadhi text
Col 2: Multi-Script Transliterations
Col 3: Literal Translation View
Col 4: Traditional Meaning / Tatparya View
Col 5: Devotional Bhavartha View
Col 6: Reviewer Actions, Corrections, and Audit History
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewAssignment,
    ReviewStatus,
    ReviewerProfile,
    Text,
    TextualDispute,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)
from database.schemas import ReviewActionLogCreate

logger = logging.getLogger("vedam.automation.workbench.api")


class WorkbenchComparisonEngine:
    """Extracts and formats data for the 6-Column Scholarly Review Interface."""

    @classmethod
    def get_verse_workbench_payload(
        cls,
        session: Session,
        verse_id: str,
        target_language: str = "te",
    ) -> Dict[str, Any]:
        """Builds complete 6-column comparative payload for a single verse."""
        # Accept either integer primary key or verse_id string identifier
        if isinstance(verse_id, int) or (isinstance(verse_id, str) and verse_id.isdigit()):
            verse = session.query(Verse).filter_by(id=int(verse_id)).first()
        else:
            verse = session.query(Verse).filter_by(verse_id=str(verse_id)).first()

        if not verse:
            raise ValueError(f"Verse '{verse_id}' not found.")

        text = verse.text

        # Column 1: Original Source Text & Liturgical Metadata
        col1_original = {
            "verse_id": verse.verse_id,
            "verse_number": verse.verse_number,
            "verse_type": verse.verse_type.value,
            "source_scripture": text.canonical_title,
            "original_language": text.original_language,
            "composer": text.composer or text.rishi or "Traditional Sage",
            "chandas_meter": verse.meter or "Traditional Liturgical Meter",
            "vedic_accents_present": verse.vedic_accents_present,
            "devanagari_text": verse.devanagari_text,
            "raw_source_text": verse.raw_source_text or verse.devanagari_text,
            "vedic_accent_annotations": verse.vedic_accent_annotations,
        }

        # Column 2: Transliterations Across Scripts
        col2_transliterations = {
            "iast": verse.iast_text,
            "scripts": {t.target_script: t.script_text for t in verse.transliterations},
        }

        # Retrieve translations and views for target language
        translation = (
            session.query(Translation)
            .filter_by(verse_id=verse.id, target_language=target_language)
            .first()
        )

        views_by_type: Dict[TranslationType, TranslationView] = {}
        if translation:
            for v in translation.views:
                views_by_type[v.view_type] = v

        # Column 3: Literal Translation View
        lit_view = views_by_type.get(TranslationType.LITERAL)
        wbw = translation.word_by_word_json if (translation and isinstance(translation.word_by_word_json, dict)) else {}
        col3_literal = {
            "view_id": lit_view.view_id if lit_view else None,
            "version": lit_view.version if lit_view else 1,
            "review_status": lit_view.review_status.value if lit_view else (translation.review_status.value if translation else "NOT_FOUND"),
            "text": lit_view.view_text if lit_view else wbw.get("literal_translation", "Literal translation view pending extraction/review."),
            "padachheda_words": wbw.get("padachheda", []),
            "source_reference": lit_view.source_reference if lit_view else "Padachheda Syntactical Analysis",
        }

        # Column 4: Traditional Meaning / Tatparya View
        tat_view = views_by_type.get(TranslationType.TATPARYA)
        col4_traditional = {
            "view_id": tat_view.view_id if tat_view else None,
            "version": tat_view.version if tat_view else 1,
            "review_status": tat_view.review_status.value if tat_view else (translation.review_status.value if translation else "NOT_FOUND"),
            "text": tat_view.view_text if tat_view else wbw.get("traditional_meaning", "Traditional sampradaya commentary view pending extraction/review."),
            "commentator_citation": wbw.get("commentator", "Traditional Sampradaya Commentary"),
            "source_reference": tat_view.source_reference if tat_view else "Classical Exegesis",
        }

        # Column 5: Devotional Bhavartha View
        bhav_view = views_by_type.get(TranslationType.BHAVARTHA)
        col5_bhavartha = {
            "view_id": bhav_view.view_id if bhav_view else None,
            "version": bhav_view.version if bhav_view else 1,
            "review_status": bhav_view.review_status.value if bhav_view else (translation.review_status.value if translation else "NOT_FOUND"),
            "text": bhav_view.view_text if bhav_view else (translation.translated_text if translation else "Translation pending."),
            "source_reference": bhav_view.source_reference if bhav_view else "Traditional Devotional Liturgy",
        }

        # Column 6: Reviewer Feedback, Audit Logs & Disputes
        recent_actions = (
            session.query(ReviewActionLog)
            .filter_by(verse_id=verse.id)
            .order_by(ReviewActionLog.created_at.desc())
            .limit(10)
            .all()
        )
        actions_list = [
            {
                "action_id": a.action_id,
                "action_type": a.action_type.value,
                "reviewer_id": a.reviewer.reviewer_id if a.reviewer else None,
                "reviewer_name": a.reviewer.full_name if a.reviewer else "Scholar",
                "is_human_review": bool(getattr(a, "is_human_review", False)),
                "previous_status": a.previous_status,
                "new_status": a.new_status,
                "scholarly_commentary": a.scholarly_commentary,
                "timestamp": a.created_at.isoformat(),
            }
            for a in recent_actions
        ]

        disputes = session.query(TextualDispute).filter_by(verse_id=verse.id).all()
        disputes_list = [
            {
                "dispute_id": d.dispute_id,
                "dispute_nature": d.dispute_nature,
                "status": d.status.value,
                "opinion_a": d.opinion_a_json,
                "opinion_b": d.opinion_b_json,
                "editorial_notes": d.editorial_resolution_notes,
            }
            for d in disputes
        ]

        col6_actions = {
            "translation_id": translation.id if translation else None,
            "target_language": target_language,
            "current_overall_status": translation.review_status.value if translation else "NOT_FOUND",
            "recent_actions": actions_list,
            "open_disputes": disputes_list,
        }

        return {
            "content_id": text.content_id,
            "canonical_title": text.canonical_title,
            "target_language": target_language,
            "column_1_original": col1_original,
            "column_2_transliterations": col2_transliterations,
            "column_3_literal": col3_literal,
            "column_4_traditional": col4_traditional,
            "column_5_bhavartha": col5_bhavartha,
            "column_6_governance": col6_actions,
        }
