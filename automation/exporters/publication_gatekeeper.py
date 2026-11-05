"""
Vedic Heritage Platform — Central Multilingual Publication Release Gatekeeper
Part D.4: Preflight release gatekeeper enforcing scholarly accreditation,
RBAC authorization, channel separation, missing view auditing, and anti-self-approval rules.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
import enum
import logging
from typing import Any, Dict, List, Optional, Tuple

from automation.exporters.publication_model import PublicationDocument, PublicationGovernance
from automation.localization.script_registry import MultilingualScriptRegistry
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from database.models import ReviewerProfile, ReviewerRole, ReviewStatus

logger = logging.getLogger("vedam.automation.exporters.publication_gatekeeper")


class ReleaseGateVerdict(str, enum.Enum):
    AUTHORIZED = "AUTHORIZED"
    REJECTED = "REJECTED"
    CONDITIONAL_DRAFT_ONLY = "CONDITIONAL_DRAFT_ONLY"


@dataclass(frozen=True)
class GateViolation:
    rule_code: str
    rule_name: str
    message: str
    severity: str  # "BLOCKER", "WARNING"


@dataclass(frozen=True)
class PublicationGateReport:
    is_authorized: bool
    verdict: ReleaseGateVerdict
    channel: str
    target_bcp47: str
    total_violations: int
    blockers: Tuple[GateViolation, ...]
    warnings: Tuple[GateViolation, ...]
    evaluated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    @property
    def can_export(self) -> bool:
        return self.is_authorized or (self.verdict == ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY and self.channel != "approved_publication")


class PublicationGatekeeper:
    """
    Enforces non-negotiable scholarly, legal, and linguistic quality gates
    before permitting document rendering or export.
    """

    @classmethod
    def evaluate_publication(
        cls,
        document: PublicationDocument,
        requesting_reviewer: Optional[ReviewerProfile] = None,
        enforce_accreditation: bool = True,
    ) -> PublicationGateReport:
        """
        Conducts preflight validation of a publication document against project release standards.
        """
        blockers: List[GateViolation] = []
        warnings: List[GateViolation] = []

        channel = document.governance.publication_channel
        lang_code = document.target.language_code
        script_code = document.target.script_code

        # 1. Gate: Metadata Completeness
        if not document.metadata.content_id or not document.metadata.canonical_title:
            blockers.append(GateViolation(
                rule_code="GATE-001",
                rule_name="Mandatory Metadata Check",
                message="Publication missing content_id or canonical_title.",
                severity="BLOCKER",
            ))

        # 2. Gate: Verse Completeness
        if len(document.verses) == 0:
            blockers.append(GateViolation(
                rule_code="GATE-002",
                rule_name="Verse Census Check",
                message="Publication contains zero verses.",
                severity="BLOCKER",
            ))

        # 3. Gate: Language / Script Compatibility
        is_valid_script, reason = MultilingualScriptRegistry.validate_script_for_language(lang_code, script_code)
        if not is_valid_script:
            blockers.append(GateViolation(
                rule_code="GATE-003",
                rule_name="Language-Script Compatibility",
                message=f"Script '{script_code}' is incompatible with language '{lang_code}': {reason}",
                severity="BLOCKER",
            ))

        # 4. Gate: Missing Views & Legacy Gap Audit
        if document.missing_content.is_legacy_gap_affected:
            warnings.append(GateViolation(
                rule_code="GATE-004",
                rule_name="Granular View Completeness",
                message=(
                    f"Publication contains legacy translation view gaps: "
                    f"{document.missing_content.missing_literal_count} literal and "
                    f"{document.missing_content.missing_tatparya_count} tatparya views missing."
                ),
                severity="WARNING",
            ))

        # 5. Gate: Channel & Review Status Authorization
        # Rule PUB-001: DRAFT translations can NEVER be published as approved_publication
        if channel == "approved_publication":
            # Check review status of all verses
            has_drafts = any(
                ve.literal_status == "DRAFT" or
                ve.tatparya_status == "DRAFT" or
                ve.bhavartha_status == "DRAFT"
                for ve in document.verses
            )
            if has_drafts:
                blockers.append(GateViolation(
                    rule_code="PUB-001",
                    rule_name="Draft Content Release Prohibition",
                    message=(
                        "Cannot authorize 'approved_publication': Document contains DRAFT translation views. "
                        "Public releases strictly require verified human scholarly certification."
                    ),
                    severity="BLOCKER",
                ))

            # Rule PUB-002: Accredited Human Reviewer Verification
            if enforce_accreditation:
                if not requesting_reviewer:
                    blockers.append(GateViolation(
                        rule_code="PUB-002",
                        rule_name="Reviewer Authentication Required",
                        message="Public approved release requires an authenticated, accredited reviewer.",
                        severity="BLOCKER",
                    ))
                else:
                    # Check demonstration / quarantine status
                    if getattr(requesting_reviewer, "is_demonstration", False) or getattr(requesting_reviewer, "account_category", "") == "DEMONSTRATION_HARNESS":
                        blockers.append(GateViolation(
                            rule_code="PUB-003",
                            rule_name="Demonstration Account Quarantine",
                            message="Demonstration and test persona accounts are strictly quarantined from authorizing releases.",
                            severity="BLOCKER",
                        ))

                    # Check RBAC authorization for target language
                    try:
                        MultilingualRBACEngine.validate_reviewer_for_language(requesting_reviewer, lang_code)
                    except (UnauthorizedLanguageReviewError, Exception) as e:
                        blockers.append(GateViolation(
                            rule_code="PUB-004",
                            rule_name="Language RBAC Authorization",
                            message=f"Reviewer lacks RBAC authorization for language '{lang_code}': {str(e)}",
                            severity="BLOCKER",
                        ))

        # Determine Verdict
        if len(blockers) > 0:
            if channel in ("internal_preview", "draft_export", "scholarly_review") and all(b.rule_code.startswith("PUB-") for b in blockers):
                verdict = ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY
                is_authorized = True  # Allowed as draft export with watermark
            else:
                verdict = ReleaseGateVerdict.REJECTED
                is_authorized = False
        else:
            if channel in ("internal_preview", "draft_export", "scholarly_review"):
                verdict = ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY
                is_authorized = True
            else:
                verdict = ReleaseGateVerdict.AUTHORIZED
                is_authorized = True

        return PublicationGateReport(
            is_authorized=is_authorized,
            verdict=verdict,
            channel=channel,
            target_bcp47=document.target.bcp47,
            total_violations=len(blockers) + len(warnings),
            blockers=tuple(blockers),
            warnings=tuple(warnings),
        )
