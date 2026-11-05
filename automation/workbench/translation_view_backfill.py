"""
Vedic Heritage Platform — Translation View Backfill & Independent Review Engine
Addresses the 752 legacy translation records lacking discrete Literal and Tatparya views.
Enforces that AI suggestions remain strictly DRAFT with traceable commentary citations,
and enables reviewers to approve translation views independently.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.padachheda import PadachhedaEngine
from automation.ai_sanskrit_engine.source_research import SourceResearchEngine
from database.connection import get_db_session
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    Text,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)

logger = logging.getLogger("vedam.automation.workbench.translation_view_backfill")


class TranslationViewBackfillEngine:
    """Manages prioritized backfilling of Literal and Traditional Tatparya views."""

    @classmethod
    def get_legacy_translation_records(cls, session: Session) -> List[Translation]:
        """Identifies all active translation records missing separate literal/tatparya views."""
        all_canonical_texts = (
            session.query(Text)
            .filter(Text.content_id.like("VEDA-TXT-%"), ~Text.content_id.in_(["VEDA-TXT-00009", "VEDA-TXT-00099"]))
            .all()
        )
        canonical_verse_ids = [v.id for t in all_canonical_texts for v in t.verses]

        all_translations = (
            session.query(Translation)
            .filter(Translation.verse_id.in_(canonical_verse_ids))
            .all()
        )

        legacy_records = [
            tr for tr in all_translations
            if not (isinstance(tr.word_by_word_json, dict) and tr.word_by_word_json.get("literal_translation"))
        ]
        return legacy_records

    @classmethod
    def generate_draft_view_candidates(
        cls,
        session: Session,
        translation_id: int,
    ) -> Dict[str, Any]:
        """Generates draft Literal and Tatparya view candidates for a legacy translation."""
        translation = session.query(Translation).filter_by(id=translation_id).first()
        if not translation:
            raise ValueError(f"Translation ID {translation_id} not found.")

        verse = translation.verse
        text = verse.text
        is_vedic = bool(verse.vedic_accents_present or "suktam" in text.primary_category.slug or "mantra" in text.primary_category.slug)
        is_awadhi = bool(text.original_language == "awa")

        # 1. Padachheda & Literal Draft Candidate
        verse_raw = verse.devanagari_text or ""
        padachheda_data = PadachhedaEngine.analyze_padachheda(
            verse_raw, language="awa" if is_awadhi else "sa", is_vedic=is_vedic
        )
        literal_candidate_text = f"Literal word-by-word syntax rendering of verse {verse.verse_number} in {translation.target_language.upper()}."

        # 2. Traditional Commentary Reference
        citation_key = "SAYANA_RIGVEDA" if is_vedic else ("GITA_PRESS_MANAS" if is_awadhi else "SHANKARA_STOTRA_BHASHYA")
        citation = SourceResearchEngine.get_verified_citation(
            source_key=citation_key, page_or_verse_ref=f"Verse {verse.verse_number}"
        )
        tatparya_candidate_text = (
            f"Traditional doctrinal exposition according to {citation['author_commentator']} "
            f"({citation['edition']})."
        )

        return {
            "translation_id": translation.id,
            "verse_id": verse.verse_id,
            "target_language": translation.target_language,
            "literal_view_draft": {
                "view_type": TranslationType.LITERAL.value,
                "text": literal_candidate_text,
                "source_reference": "Padachheda & Syntactical Word Analysis (Draft Suggestion)",
                "padas": padachheda_data["primary_padas"][:6],
                "review_status": ReviewStatus.DRAFT.value,
            },
            "tatparya_view_draft": {
                "view_type": TranslationType.TATPARYA.value,
                "text": tatparya_candidate_text,
                "source_reference": f"{citation['source_title']} ({citation['author_commentator']})",
                "review_status": ReviewStatus.DRAFT.value,
            },
            "disclaimer": "AI-assisted draft candidate; requires human scholar verification before activation.",
        }

    @classmethod
    def approve_view_independently(
        cls,
        session: Session,
        view_id: str,
        reviewer_id: int,
        scholarly_commentary: str,
    ) -> TranslationView:
        """
        Allows a verified human scholar to approve a single translation view (e.g. LITERAL)
        independently, leaving other views (e.g. TATPARYA) under DRAFT or in-review status.
        """
        view = session.query(TranslationView).filter_by(view_id=view_id).first()
        if not view:
            raise ValueError(f"TranslationView '{view_id}' not found.")

        reviewer = session.query(ReviewerProfile).filter_by(id=reviewer_id).first()
        if not reviewer or not reviewer.is_credentials_verified:
            raise ValueError(f"Reviewer ID {reviewer_id} credentials are unverified.")

        view.review_status = ReviewStatus.APPROVED
        view.reviewer = f"{reviewer.full_name} ({reviewer.academic_qualifications or reviewer.sanskrit_proficiency})"
        view.reviewed_at = datetime.now(timezone.utc)
        view.approval_notes = scholarly_commentary

        # Record in action log
        action_id = f"ACT-VIEW-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
        log = ReviewActionLog(
            action_id=action_id,
            translation_id=view.translation_id,
            translation_view_id=view.id,
            verse_id=view.verse_id,
            reviewer_id=reviewer.id,
            action_type=ReviewActionType.APPROVE,
            previous_status="DRAFT",
            new_status="APPROVED",
            previous_text=view.view_text,
            proposed_text=view.view_text,
            scholarly_commentary=scholarly_commentary,
            is_human_review=bool(getattr(reviewer, "is_human_verified", False)),
            created_at=datetime.now(timezone.utc),
        )
        session.add(log)
        session.flush()
        logger.info("Independently approved TranslationView %s (%s) by %s", view_id, view.view_type.value, reviewer.full_name)
        return view
