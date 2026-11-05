"""
Vedic Heritage Platform — Conflict Resolution & Textual Dispute Engine
Preserves competing traditional interpretations, records supporting citations,
assigns disputes to secondary specialists, and logs editorial board resolutions.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from database.models import (
    DisputeStatus,
    ReviewerProfile,
    ReviewerRole,
    TextualDispute,
    Verse,
)
from database.schemas import TextualDisputeCreate

logger = logging.getLogger("vedam.automation.workbench.conflict_engine")


class ConflictResolutionError(Exception):
    """Raised when conflict resolution actions violate scholarly rules."""
    pass


class ConflictResolutionEngine:
    """Manages textual and interpretive disagreements across scholars."""

    @classmethod
    def register_dispute(
        cls,
        session: Session,
        dispute_data: TextualDisputeCreate,
    ) -> TextualDispute:
        """Records a formal textual or interpretive dispute between two scholarly viewpoints."""
        verse = session.query(Verse).filter_by(id=dispute_data.verse_id).first()
        if not verse:
            raise ConflictResolutionError(f"Verse ID {dispute_data.verse_id} not found.")

        dispute_id = f"DSP-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"

        dispute = TextualDispute(
            dispute_id=dispute_id,
            verse_id=dispute_data.verse_id,
            translation_id=dispute_data.translation_id,
            translation_view_id=dispute_data.translation_view_id,
            dispute_nature=dispute_data.dispute_nature,
            opinion_a_json=dispute_data.opinion_a_json,
            opinion_b_json=dispute_data.opinion_b_json,
            status=DisputeStatus.OPEN,
            created_at=datetime.now(timezone.utc),
        )
        session.add(dispute)
        session.flush()
        logger.info("Registered textual dispute %s on verse %s (%s)", dispute_id, verse.verse_id, dispute_data.dispute_nature)
        return dispute

    @classmethod
    def refer_to_editorial_board(
        cls,
        session: Session,
        dispute_id: str,
        referral_notes: str,
    ) -> TextualDispute:
        """Escalates an open dispute to the multi-sampradaya editorial board."""
        dispute = session.query(TextualDispute).filter_by(dispute_id=dispute_id).first()
        if not dispute:
            raise ConflictResolutionError(f"Dispute '{dispute_id}' not found.")

        dispute.status = DisputeStatus.REFERRED_TO_EDITORIAL_BOARD
        dispute.editorial_resolution_notes = f"[REFERRED TO EDITORIAL BOARD]: {referral_notes}"
        session.flush()
        logger.info("Dispute %s referred to editorial board.", dispute_id)
        return dispute

    @classmethod
    def resolve_preserve_both(
        cls,
        session: Session,
        dispute_id: str,
        resolved_by: str,
        editorial_justification: str,
    ) -> TextualDispute:
        """
        Resolves dispute by affirmatively preserving BOTH traditional readings as valid
        sampradaya variants in accordance with Vedic textual tradition.
        """
        dispute = session.query(TextualDispute).filter_by(dispute_id=dispute_id).first()
        if not dispute:
            raise ConflictResolutionError(f"Dispute '{dispute_id}' not found.")

        dispute.status = DisputeStatus.RESOLVED_PRESERVED_BOTH
        dispute.resolved_by = resolved_by
        dispute.resolved_at = datetime.now(timezone.utc)
        dispute.editorial_resolution_notes = (
            f"Preserved both traditional interpretations as canonical variants.\n"
            f"Adjudicated by Editorial Board ({resolved_by}): {editorial_justification}"
        )
        session.flush()
        logger.info("Dispute %s resolved by preserving both traditional readings.", dispute_id)
        return dispute

    @classmethod
    def list_disputes(
        cls,
        session: Session,
        status: Optional[DisputeStatus] = None,
    ) -> List[TextualDispute]:
        """Lists textual disputes."""
        query = session.query(TextualDispute)
        if status:
            query = query.filter_by(status=status)
        return query.order_by(TextualDispute.created_at.desc()).all()
