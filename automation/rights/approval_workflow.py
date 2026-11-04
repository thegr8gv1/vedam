"""
Vedic Heritage Platform — Multidimensional Approval Workflow Engine
Enforces strict decoupling of the 6 orthogonal project governance dimensions:
1. Acquisition Status
2. Textual Verification Status
3. Rights Clearance Status
4. Translation Status
5. Editorial Approval Status
6. Publication Status

Rule: Never allow one approval dimension to automatically authorize another.
A text may be SCHOLAR_VERIFIED without being GREEN_CLEARED for commercial publication.
"""

from dataclasses import dataclass
from datetime import datetime, timezone
import enum
from typing import Any, Dict, List, Optional, Tuple


class AcquisitionStatus(str, enum.Enum):
    DISCOVERED = "DISCOVERED"
    SOURCE_IDENTIFIED = "SOURCE_IDENTIFIED"
    COLLECTED = "COLLECTED"
    VERIFIED_SOURCE = "VERIFIED_SOURCE"


class TextualVerificationStatus(str, enum.Enum):
    UNVERIFIED = "UNVERIFIED"
    PENDING_SCHOLAR = "PENDING_SCHOLAR"
    SCHOLAR_VERIFIED = "SCHOLAR_VERIFIED"
    REJECTED = "REJECTED"


class RightsClearanceStatus(str, enum.Enum):
    PENDING = "PENDING"
    AMBER_RESTRICTED = "AMBER_RESTRICTED"
    GREEN_CLEARED = "GREEN_CLEARED"
    RED_FORBIDDEN = "RED_FORBIDDEN"


class TranslationStatus(str, enum.Enum):
    NOT_STARTED = "NOT_STARTED"
    DRAFT = "DRAFT"
    SCHOLAR_REVIEWED = "SCHOLAR_REVIEWED"
    APPROVED = "APPROVED"


class EditorialApprovalStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    IN_REVIEW = "IN_REVIEW"
    APPROVED = "APPROVED"


class PublicationStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    READY_FOR_EXPORT = "READY_FOR_EXPORT"
    PUBLISHED = "PUBLISHED"
    WITHDRAWN = "WITHDRAWN"


@dataclass
class MultidimensionalApprovalState:
    acquisition_status: AcquisitionStatus
    textual_verification_status: TextualVerificationStatus
    rights_clearance_status: RightsClearanceStatus
    translation_status: TranslationStatus
    editorial_approval_status: EditorialApprovalStatus
    publication_status: PublicationStatus
    scholar_reviewer: Optional[str] = None
    legal_reviewer: Optional[str] = None
    editorial_reviewer: Optional[str] = None
    updated_at: str = ""


class ApprovalWorkflowEngine:
    """Governance validator that prevents unauthorized publication transitions."""

    @classmethod
    def can_transition_to_publication(
        cls,
        state: MultidimensionalApprovalState,
        require_approved_translation: bool = False,
    ) -> Tuple[bool, List[str]]:
        """
        Validates whether a text meets all independent prerequisites for publication.
        Returns (is_allowed, list_of_blocking_reasons).
        """
        blocking_reasons = []

        # 1. Textual verification requirement
        if state.textual_verification_status != TextualVerificationStatus.SCHOLAR_VERIFIED:
            blocking_reasons.append(
                f"Textual verification status is '{state.textual_verification_status.value}', requires 'SCHOLAR_VERIFIED'."
            )

        # 2. Rights clearance requirement
        if state.rights_clearance_status != RightsClearanceStatus.GREEN_CLEARED:
            blocking_reasons.append(
                f"Rights clearance status is '{state.rights_clearance_status.value}', requires 'GREEN_CLEARED'."
            )

        # 3. Editorial approval requirement
        if state.editorial_approval_status != EditorialApprovalStatus.APPROVED:
            blocking_reasons.append(
                f"Editorial approval status is '{state.editorial_approval_status.value}', requires 'APPROVED'."
            )

        # 4. Legal reviewer sign-off requirement
        legal_reviewer = getattr(state, "legal_reviewer", None)
        if not legal_reviewer and hasattr(state, "rights_grants") and state.rights_grants:
            legal_reviewer = next((g.legal_reviewer for g in state.rights_grants if g.legal_reviewer), None)
        if not legal_reviewer and hasattr(state, "rights") and state.rights:
            legal_reviewer = getattr(state.rights, "reviewed_by", None)

        if not legal_reviewer:
            blocking_reasons.append("Mandatory human legal reviewer sign-off is missing.")

        # 5. Optional translation approval requirement
        if require_approved_translation and state.translation_status != TranslationStatus.APPROVED:
            blocking_reasons.append(
                f"Translation status is '{state.translation_status.value}', requires 'APPROVED'."
            )

        can_publish = (len(blocking_reasons) == 0)
        return can_publish, blocking_reasons

    @classmethod
    def assert_publication_clearance(
        cls,
        state: MultidimensionalApprovalState,
        require_approved_translation: bool = False,
    ) -> None:
        """Raises PermissionError if publication prerequisites are not met."""
        allowed, reasons = cls.can_transition_to_publication(
            state, require_approved_translation=require_approved_translation
        )
        if not allowed:
            raise PermissionError(
                f"Publication blocked by governance gates: {'; '.join(reasons)}"
            )
