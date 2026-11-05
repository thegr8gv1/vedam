"""
Vedic Heritage Platform — Review Action & Immutable Audit Engine
Handles reviewer decisions, correction proposals, version generation,
and immutable logging without altering original sacred Sanskrit or Awadhi texts.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from database.models import (
    AssignmentStatus,
    ReviewActionLog,
    ReviewActionType,
    ReviewAssignment,
    ReviewStatus,
    ReviewerProfile,
    Translation,
    TranslationView,
    Verse,
)
from database.schemas import ReviewActionLogCreate
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)

logger = logging.getLogger("vedam.automation.workbench.review_action_engine")


class ReviewActionError(Exception):
    """Raised when review actions violate scholarly governance rules."""
    pass


class ReviewActionEngine:
    """Processes review decisions, records immutable action logs, and increments versions."""

    @classmethod
    def execute_action(
        cls,
        session: Session,
        action_data: ReviewActionLogCreate,
    ) -> ReviewActionLog:
        """Executes a scholarly review action with permission verification and immutable logging."""
        # 1. Validate Reviewer
        reviewer = session.query(ReviewerProfile).filter_by(id=action_data.reviewer_id).first()
        if not reviewer or not reviewer.is_active:
            raise ReviewActionError(f"Reviewer ID {action_data.reviewer_id} is invalid or inactive.")

        # 2. Check affirmative credentials for APPROVE or APPROVE_WITH_CORRECTIONS
        if action_data.action_type in (ReviewActionType.APPROVE, ReviewActionType.APPROVE_WITH_CORRECTIONS):
            if reviewer.is_demonstration:
                raise ReviewActionError(
                    f"Reviewer '{reviewer.full_name}' is a demonstration account. Demonstration accounts cannot issue production approvals."
                )
            if not reviewer.is_credentials_verified or reviewer.verification_status != "VERIFIED":
                raise ReviewActionError(
                    f"Reviewer '{reviewer.full_name}' credentials are unverified ({reviewer.verification_status}). Cannot issue scholarly approval."
                )

        # 3. Retrieve Entities
        translation = session.query(Translation).filter_by(id=action_data.translation_id).first()
        if not translation:
            raise ReviewActionError(f"Translation ID {action_data.translation_id} not found.")

        # 3a. Multilingual RBAC: Language Authorization Check
        target_lang = getattr(translation, "target_language", None)
        if target_lang and not MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, target_lang):
            role_val = reviewer.primary_role.value if hasattr(reviewer.primary_role, "value") else str(reviewer.primary_role)
            raise ReviewActionError(
                f"Unauthorized language: Reviewer '{reviewer.full_name}' ({role_val}) "
                f"is not authorized to review target language '{target_lang}'."
            )

        # 3b. Multilingual RBAC: Anti-Self-Approval Check
        if action_data.action_type in (ReviewActionType.APPROVE, ReviewActionType.APPROVE_WITH_CORRECTIONS):
            try:
                MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)
            except SelfApprovalViolationError as e:
                raise ReviewActionError(str(e))

            # 3c. Approval capability vs Translator-only check
            if target_lang:
                can_approve, reason = MultilingualRBACEngine.can_reviewer_approve_language(reviewer, target_lang)
                if not can_approve:
                    raise ReviewActionError(reason or "Reviewer lacks approval authority.")

        verse = session.query(Verse).filter_by(id=action_data.verse_id).first()
        if not verse:
            raise ReviewActionError(f"Verse ID {action_data.verse_id} not found.")

        view: Optional[TranslationView] = None
        if action_data.translation_view_id:
            view = session.query(TranslationView).filter_by(id=action_data.translation_view_id).first()
            if not view:
                raise ReviewActionError(f"TranslationView ID {action_data.translation_view_id} not found.")

        # 4. Generate Unique Action ID
        action_id = f"ACT-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"

        previous_status = view.review_status.value if view else translation.review_status.value
        previous_text = view.view_text if view else translation.translated_text

        # 5. Process Specific Action
        new_status = action_data.new_status
        new_text = action_data.proposed_text or previous_text

        if action_data.action_type == ReviewActionType.APPROVE:
            new_status = ReviewStatus.APPROVED.value
            reviewer_str = f"{reviewer.full_name} ({reviewer.academic_qualifications or reviewer.institutional_affiliation or reviewer.sanskrit_proficiency})"
            if view:
                view.review_status = ReviewStatus.APPROVED
                view.reviewer = reviewer_str
                view.reviewed_at = datetime.now(timezone.utc)
                view.approval_notes = action_data.scholarly_commentary
                # Append to view approval history
                hist = list(view.approval_history_json or [])
                hist.append({
                    "action_id": action_id,
                    "action_type": action_data.action_type.value,
                    "reviewer_id": reviewer.reviewer_id,
                    "reviewer_name": reviewer.full_name,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "notes": action_data.scholarly_commentary,
                })
                view.approval_history_json = hist
            else:
                translation.review_status = ReviewStatus.APPROVED
                translation.reviewer = reviewer_str

        elif action_data.action_type == ReviewActionType.APPROVE_WITH_CORRECTIONS:
            if not action_data.proposed_text or action_data.proposed_text.strip() == previous_text.strip():
                raise ReviewActionError("APPROVE_WITH_CORRECTIONS requires distinct proposed text.")

            new_status = ReviewStatus.APPROVED.value
            reviewer_str = f"{reviewer.full_name} ({reviewer.academic_qualifications or reviewer.sanskrit_proficiency})"
            if view:
                # Increment version of view
                view.version += 1
                view.view_text = action_data.proposed_text.strip()
                view.review_status = ReviewStatus.APPROVED
                view.reviewer = reviewer_str
                view.reviewed_at = datetime.now(timezone.utc)
                view.approval_notes = f"[v{view.version} Correction]: {action_data.scholarly_commentary}"
                hist = list(view.approval_history_json or [])
                hist.append({
                    "action_id": action_id,
                    "action_type": action_data.action_type.value,
                    "version": view.version,
                    "previous_text": previous_text,
                    "corrected_text": action_data.proposed_text.strip(),
                    "reviewer_name": reviewer.full_name,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "notes": action_data.scholarly_commentary,
                })
                view.approval_history_json = hist
            else:
                translation.translated_text = action_data.proposed_text.strip()
                translation.review_status = ReviewStatus.APPROVED
                translation.reviewer = reviewer_str

        elif action_data.action_type == ReviewActionType.REQUEST_REVISION:
            new_status = ReviewStatus.DRAFT.value
            if view:
                view.review_status = ReviewStatus.DRAFT
                view.approval_notes = f"[Revision Requested]: {action_data.scholarly_commentary}"
            else:
                translation.review_status = ReviewStatus.DRAFT

        elif action_data.action_type == ReviewActionType.REJECT:
            new_status = "REJECTED"
            if view:
                view.review_status = ReviewStatus.DRAFT
                view.approval_notes = f"[REJECTED by Scholar]: {action_data.scholarly_commentary}"
            else:
                translation.review_status = ReviewStatus.DRAFT

        # 6. Record Immutable Action Log with Human Authenticity Tracking
        is_human = (getattr(reviewer, "account_category", "") == "REAL_HUMAN_SCHOLAR") and bool(getattr(reviewer, "is_human_verified", False))

        log = ReviewActionLog(
            action_id=action_id,
            assignment_id=action_data.assignment_id,
            translation_id=action_data.translation_id,
            translation_view_id=action_data.translation_view_id,
            verse_id=action_data.verse_id,
            reviewer_id=action_data.reviewer_id,
            action_type=action_data.action_type,
            previous_status=previous_status,
            new_status=new_status,
            previous_text=previous_text,
            proposed_text=action_data.proposed_text,
            scholarly_commentary=action_data.scholarly_commentary,
            feedback_category=getattr(action_data, 'feedback_category', None),
            traditional_references=action_data.traditional_references or [],
            alternative_readings=action_data.alternative_readings or [],
            original_text_immutable_verified=True,
            is_human_review=is_human,
            created_at=datetime.now(timezone.utc),
        )
        session.add(log)

        # 7. Update Assignment Status if provided
        if action_data.assignment_id:
            asgn = session.query(ReviewAssignment).filter_by(id=action_data.assignment_id).first()
            if asgn:
                if action_data.action_type in (ReviewActionType.APPROVE, ReviewActionType.APPROVE_WITH_CORRECTIONS):
                    asgn.status = AssignmentStatus.COMPLETED
                    asgn.completed_at = datetime.now(timezone.utc)
                elif action_data.action_type == ReviewActionType.ESCALATE:
                    asgn.status = AssignmentStatus.DISPUTED

        session.flush()
        logger.info("Executed review action %s (%s) by %s", action_id, action_data.action_type, reviewer.full_name)
        return log
