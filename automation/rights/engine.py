"""
Vedic Heritage Platform — Content Rights and Provenance Engine
Mandatory gatekeeper enforcing copyright compliance, licensing rules,
and release status state machines across the entire platform.
"""

from datetime import datetime, timezone
from typing import Optional, Tuple

from database.models import ContentRights, ReleaseStatus


class RightsComplianceError(Exception):
    """Raised when an operation attempts to distribute or publish unreleased content."""
    pass


class RightsProvenanceEngine:
    """
    Evaluates, audits, and enforces legal clearance for all sacred literature.
    
    Principles:
    - Ancient Sanskrit verses may be public domain, but modern editions/translations carry rights.
    - No content enters the commercial publishing, audio, or mobile app pipeline without GREEN status.
    - AMBER and RED content are strictly sequestered for scholarly review.
    """

    VALID_COMMERCIAL_LICENSES = {
        "PUBLIC_DOMAIN",
        "CC0",
        "CC_BY_4_0",
        "CC_BY_SA_4_0",
        "PROPRIETARY_PARTNER_AGREEMENT",
    }

    RESTRICTED_LICENSES = {
        "ALL_RIGHTS_RESERVED",
        "CC_BY_NC_4_0",
        "CC_BY_NC_SA_4_0",
        "COMMERCIAL_PROPRIETARY",
        "SCRAPED_UNAUTHORIZED",
    }

    @classmethod
    def evaluate_release_status(cls, rights: ContentRights) -> Tuple[ReleaseStatus, str]:
        """
        Evaluate a ContentRights record against legal compliance criteria.
        Returns the appropriate (ReleaseStatus, reason).
        """
        now = datetime.now(timezone.utc)

        # Check explicit restrictions
        if rights.license_type in cls.RESTRICTED_LICENSES:
            if not rights.written_permission_reference:
                return ReleaseStatus.RED, f"License {rights.license_type} prohibits commercial use without written agreement."

        if not rights.commercial_reuse_permitted:
            return ReleaseStatus.RED, "Commercial reuse permission is explicitly set to False."

        # Check written permission expiration
        if rights.permission_expiry:
            # Normalize to naive UTC if needed
            expiry = rights.permission_expiry if rights.permission_expiry.tzinfo else rights.permission_expiry.replace(tzinfo=timezone.utc)
            if expiry < now:
                return ReleaseStatus.RED, f"Written permission expired on {rights.permission_expiry}."

        # Check license validity
        if rights.license_type not in cls.VALID_COMMERCIAL_LICENSES:
            return ReleaseStatus.AMBER, f"License type '{rights.license_type}' requires legal verification."

        # Partner agreement requirements
        if rights.license_type == "PROPRIETARY_PARTNER_AGREEMENT":
            if not rights.written_permission_reference:
                return ReleaseStatus.AMBER, "Partner agreement license missing formal written_permission_reference."
            if not rights.supporting_evidence:
                return ReleaseStatus.AMBER, "Partner agreement requires attached supporting evidence or contract link."

        # Public domain provenance check
        if rights.license_type == "PUBLIC_DOMAIN":
            if not rights.specific_edition or not rights.primary_source:
                return ReleaseStatus.AMBER, "Public domain claim requires explicit primary source and edition citations."

        # If all criteria are met, status is GREEN
        return ReleaseStatus.GREEN, "Rights verified and approved for commercial release."

    @classmethod
    def assert_export_clearance(cls, rights: Optional[ContentRights], target_channel: str = "commercial_release") -> None:
        """
        Gatekeeper for exporters and publishing pipelines.
        Raises RightsComplianceError if content lacks clearance for target channel.
        """
        if rights is None:
            raise RightsComplianceError(
                f"Security Violation: Text cannot be exported to '{target_channel}' because no ContentRights record exists."
            )

        status, reason = cls.evaluate_release_status(rights)

        if target_channel in {"commercial_release", "mobile_production", "audio_distribution"}:
            if status != ReleaseStatus.GREEN:
                raise RightsComplianceError(
                    f"Publication Blocked: Content ID associated with source '{rights.primary_source}' "
                    f"has status '{status.value}' and cannot enter '{target_channel}'. Reason: {reason}"
                )
        elif target_channel == "scholarly_review":
            # Scholarly review allows GREEN and AMBER
            if status == ReleaseStatus.RED:
                raise RightsComplianceError(
                    f"Scholarly Review Blocked: Status is RED. Reason: {reason}"
                )
        else:
            if status != ReleaseStatus.GREEN:
                raise RightsComplianceError(f"Target '{target_channel}' requires GREEN status. Current: {status.value}")

    @classmethod
    def can_publish_commercially(cls, rights: Optional[ContentRights]) -> bool:
        """Convenience method returning boolean permission."""
        try:
            cls.assert_export_clearance(rights, "commercial_release")
            return True
        except RightsComplianceError:
            return False
