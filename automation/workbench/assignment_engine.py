"""
Vedic Heritage Platform — Review Assignment Engine
Dispatches compositions, verses, target languages, and translation views to qualified reviewers.
Supports individual and batch assignments, priority handling, deadlines, and reassignments.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from database.models import (
    AssignmentPriority,
    AssignmentStatus,
    ReviewAssignment,
    ReviewerProfile,
    Text,
    TranslationType,
    Verse,
)
from database.schemas import ReviewAssignmentCreate

logger = logging.getLogger("vedam.automation.workbench.assignment_engine")


class AssignmentGovernanceError(Exception):
    """Raised when assignment dispatching rules are violated."""
    pass


class AssignmentEngine:
    """Manages creation, tracking, and reassignment of review tasks."""

    @classmethod
    def create_assignment(
        cls,
        session: Session,
        assignment_data: ReviewAssignmentCreate,
    ) -> ReviewAssignment:
        """Dispatches an assignment to a verified active reviewer."""
        reviewer = session.query(ReviewerProfile).filter_by(id=assignment_data.reviewer_id).first()
        if not reviewer:
            raise AssignmentGovernanceError(f"Reviewer ID {assignment_data.reviewer_id} not found.")
        if not reviewer.is_active:
            raise AssignmentGovernanceError(f"Reviewer '{reviewer.full_name}' is inactive and cannot accept assignments.")
        if not reviewer.is_credentials_verified:
            raise AssignmentGovernanceError(f"Reviewer '{reviewer.full_name}' does not have verified credentials.")

        text = session.query(Text).filter_by(id=assignment_data.text_id).first()
        if not text:
            raise AssignmentGovernanceError(f"Text ID {assignment_data.text_id} not found.")

        if assignment_data.verse_id:
            verse = session.query(Verse).filter_by(id=assignment_data.verse_id, text_id=text.id).first()
            if not verse:
                raise AssignmentGovernanceError(f"Verse ID {assignment_data.verse_id} not found in text '{text.canonical_title}'.")

        asgn_id = f"ASGN-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
        asgn = ReviewAssignment(
            assignment_id=asgn_id,
            reviewer_id=assignment_data.reviewer_id,
            text_id=assignment_data.text_id,
            verse_id=assignment_data.verse_id,
            target_language=assignment_data.target_language,
            view_type=assignment_data.view_type,
            priority=assignment_data.priority,
            status=AssignmentStatus.PENDING,
            deadline=assignment_data.deadline,
            notes=assignment_data.notes,
            assigned_by=assignment_data.assigned_by,
            assigned_at=datetime.now(timezone.utc),
        )
        session.add(asgn)
        session.flush()
        logger.info("Created assignment %s for reviewer %s (%s)", asgn.assignment_id, reviewer.full_name, text.content_id)
        return asgn

    @classmethod
    def batch_assign_composition(
        cls,
        session: Session,
        text_id: int,
        reviewer_id: int,
        target_language: str,
        view_type: Optional[TranslationType] = None,
        priority: AssignmentPriority = AssignmentPriority.NORMAL,
        deadline: Optional[datetime] = None,
        assigned_by: str = "system_admin",
    ) -> List[ReviewAssignment]:
        """Dispatches assignments for every individual verse unit in a composition."""
        text = session.query(Text).filter_by(id=text_id).first()
        if not text:
            raise AssignmentGovernanceError(f"Text ID {text_id} not found.")

        assignments = []
        for verse in text.verses:
            req = ReviewAssignmentCreate(
                reviewer_id=reviewer_id,
                text_id=text.id,
                verse_id=verse.id,
                target_language=target_language,
                view_type=view_type,
                priority=priority,
                deadline=deadline,
                notes=f"Batch assignment for verse {verse.verse_number} of {text.canonical_title}",
                assigned_by=assigned_by,
            )
            asgn = cls.create_assignment(session, req)
            assignments.append(asgn)

        logger.info("Batch dispatched %d assignments for text %s", len(assignments), text.content_id)
        return assignments

    @classmethod
    def reassign_work(
        cls,
        session: Session,
        assignment_id: str,
        new_reviewer_id: int,
        reassigned_by: str,
        reason: str,
    ) -> ReviewAssignment:
        """Reassigns an existing assignment to a different reviewer while preserving audit link."""
        asgn = session.query(ReviewAssignment).filter_by(assignment_id=assignment_id).first()
        if not asgn:
            raise AssignmentGovernanceError(f"Assignment '{assignment_id}' not found.")

        new_reviewer = session.query(ReviewerProfile).filter_by(id=new_reviewer_id).first()
        if not new_reviewer or not new_reviewer.is_active or not new_reviewer.is_credentials_verified:
            raise AssignmentGovernanceError("Replacement reviewer is not active or credentials are unverified.")

        asgn.status = AssignmentStatus.REASSIGNED
        asgn.reassigned_to_id = new_reviewer_id
        asgn.notes = f"{asgn.notes or ''}\n[REASSIGNED by {reassigned_by}]: {reason}"

        # Create new assignment for the target reviewer
        new_asgn_id = f"ASGN-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
        new_asgn = ReviewAssignment(
            assignment_id=new_asgn_id,
            reviewer_id=new_reviewer_id,
            text_id=asgn.text_id,
            verse_id=asgn.verse_id,
            target_language=asgn.target_language,
            view_type=asgn.view_type,
            priority=asgn.priority,
            status=AssignmentStatus.PENDING,
            deadline=asgn.deadline,
            notes=f"Reassigned from previous reviewer (Ref: {assignment_id}): {reason}",
            assigned_by=reassigned_by,
            assigned_at=datetime.now(timezone.utc),
        )
        session.add(new_asgn)
        session.flush()
        logger.info("Reassigned %s to reviewer %s (New Assignment: %s)", assignment_id, new_reviewer.full_name, new_asgn_id)
        return new_asgn

    @classmethod
    def list_assignments(
        cls,
        session: Session,
        reviewer_id: Optional[int] = None,
        status: Optional[AssignmentStatus] = None,
        priority: Optional[AssignmentPriority] = None,
    ) -> List[ReviewAssignment]:
        """Lists assignments filtered by reviewer, status, or priority."""
        query = session.query(ReviewAssignment)
        if reviewer_id:
            query = query.filter_by(reviewer_id=reviewer_id)
        if status:
            query = query.filter_by(status=status)
        if priority:
            query = query.filter_by(priority=priority)
        return query.order_by(ReviewAssignment.assigned_at.desc()).all()
