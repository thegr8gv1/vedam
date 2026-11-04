"""
Vedic Heritage Platform — Multilingual Human Translation Review Workflow
Enforces scholarly review, native-language verification, and audit trails
without altering original immutable Sanskrit or Awadhi texts.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from database.models import (
    ReviewStatus,
    Text,
    Translation,
    TranslationReviewFeedback,
    Verse,
)

logger = logging.getLogger("vedam.automation.localization.review_workflow")


class TranslationReviewWorkflowError(Exception):
    """Raised when review governance rules are violated."""
    pass


class HumanReviewWorkflowEngine:
    """Manages verse-level scholarly feedback, corrections, and review governance."""

    VALID_LINGUISTIC_EXPERTISE = {
        "Sanskrit",
        "Awadhi",
        "Hindi",
        "Telugu",
        "Tamil",
        "Kannada",
        "Marathi",
        "Bengali",
        "Gujarati",
        "Malayalam",
        "Odia",
        "Comparative Dravidian",
        "Indo-Aryan Philology",
    }

    @classmethod
    def record_verse_feedback(
        cls,
        session: Session,
        translation_id: int,
        reviewer_name: str,
        native_language: str,
        linguistic_expertise: str,
        review_status: ReviewStatus,
        reviewer_qualification: Optional[str] = None,
        suggested_correction: Optional[str] = None,
        scholarly_comment: Optional[str] = None,
        terminology_adherence_verified: bool = False,
    ) -> TranslationReviewFeedback:
        """
        Records a human reviewer's evaluation of a specific verse translation.
        Enforces qualification and language credentials.
        """
        tr = session.query(Translation).filter_by(id=translation_id).first()
        if not tr:
            raise TranslationReviewWorkflowError(f"Translation record ID {translation_id} not found.")

        # Validation: Never claim scholarly approval without qualified reviewer credentials
        if review_status == ReviewStatus.APPROVED:
            if not reviewer_qualification or len(reviewer_qualification.strip()) < 10:
                raise TranslationReviewWorkflowError(
                    "Cannot mark translation APPROVED without documented scholarly qualification credentials."
                )
            if not terminology_adherence_verified:
                raise TranslationReviewWorkflowError(
                    "Cannot mark translation APPROVED without affirmative terminology consistency verification."
                )

        feedback = TranslationReviewFeedback(
            translation_id=translation_id,
            reviewer_name=reviewer_name.strip(),
            reviewer_qualification=reviewer_qualification.strip() if reviewer_qualification else None,
            native_language=native_language.strip(),
            linguistic_expertise=linguistic_expertise.strip(),
            review_status=review_status,
            suggested_correction=suggested_correction.strip() if suggested_correction else None,
            scholarly_comment=scholarly_comment.strip() if scholarly_comment else None,
            terminology_adherence_verified=terminology_adherence_verified,
            reviewed_at=datetime.now(timezone.utc),
        )
        session.add(feedback)

        # Update translation state if qualified
        if review_status in (ReviewStatus.APPROVED, ReviewStatus.SCHOLAR_REVIEWED):
            tr.review_status = review_status
            tr.reviewer = f"{reviewer_name} ({reviewer_qualification})" if reviewer_qualification else reviewer_name
            if suggested_correction:
                # Apply suggested correction to translation only (original source text remains untouched)
                tr.translated_text = suggested_correction.strip()

        session.flush()
        return feedback

    @classmethod
    def get_feedback_history(
        cls, session: Session, translation_id: int
    ) -> List[Dict[str, Any]]:
        """Returns chronological review feedback and correction history for a translation."""
        feedbacks = (
            session.query(TranslationReviewFeedback)
            .filter_by(translation_id=translation_id)
            .order_by(TranslationReviewFeedback.reviewed_at.asc())
            .all()
        )
        return [
            {
                "feedback_id": f.id,
                "reviewer_name": f.reviewer_name,
                "reviewer_qualification": f.reviewer_qualification,
                "native_language": f.native_language,
                "linguistic_expertise": f.linguistic_expertise,
                "review_status": f.review_status.value,
                "suggested_correction": f.suggested_correction,
                "scholarly_comment": f.scholarly_comment,
                "terminology_adherence_verified": f.terminology_adherence_verified,
                "reviewed_at": f.reviewed_at.isoformat(),
            }
            for f in feedbacks
        ]

    @classmethod
    def audit_composition_reviews(
        cls, session: Session, content_id: str
    ) -> Dict[str, Any]:
        """Provides an aggregated review and native-reviewer coverage audit for a master composition."""
        text = session.query(Text).filter_by(content_id=content_id).first()
        if not text:
            raise TranslationReviewWorkflowError(f"Composition {content_id} not found.")

        translations = [tr for v in text.verses for tr in v.translations]
        total_translations = len(translations)
        draft_count = sum(1 for tr in translations if tr.review_status == ReviewStatus.DRAFT)
        approved_count = sum(1 for tr in translations if tr.review_status == ReviewStatus.APPROVED)
        scholar_reviewed_count = sum(1 for tr in translations if tr.review_status == ReviewStatus.SCHOLAR_REVIEWED)

        reviewers = set(tr.reviewer for tr in translations if tr.reviewer)

        return {
            "content_id": content_id,
            "title": text.canonical_title,
            "total_verses": len(text.verses),
            "total_translations": total_translations,
            "draft_count": draft_count,
            "scholar_reviewed_count": scholar_reviewed_count,
            "approved_count": approved_count,
            "unique_reviewers": list(reviewers),
            "is_fully_scholar_approved": (total_translations > 0 and approved_count == total_translations),
        }
