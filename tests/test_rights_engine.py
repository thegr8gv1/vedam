"""
Unit Tests for Content Rights and Provenance Engine
"""

from datetime import datetime, timedelta, timezone
import pytest

from automation.rights.engine import RightsComplianceError, RightsProvenanceEngine
from database.models import ContentRights, ReleaseStatus


@pytest.fixture
def green_rights():
    """A fully compliant public-domain rights record."""
    return ContentRights(
        original_composition_attribution="Adi Shankaracharya",
        primary_source="Nirnaya Sagar Press (1912)",
        specific_edition="Nirnaya Sagar Stotra Ratnavali",
        edition_publication_date="1912",
        license_type="PUBLIC_DOMAIN",
        commercial_reuse_permitted=True,
        translation_permitted=True,
        derivative_work_permitted=True,
        distribution_permitted=True,
        attribution_required=True,
        attribution_text="Source: Nirnaya Sagar Press (1912)",
        release_status=ReleaseStatus.GREEN,
        supporting_evidence="Author died >1200 years ago; edition published in 1912 (>110 years ago).",
    )


@pytest.fixture
def amber_rights():
    """An under-review partner agreement missing supporting evidence."""
    return ContentRights(
        original_composition_attribution="Traditional",
        primary_source="Community Collection",
        license_type="PROPRIETARY_PARTNER_AGREEMENT",
        commercial_reuse_permitted=True,
        written_permission_reference=None,  # Missing reference
        supporting_evidence=None,
        release_status=ReleaseStatus.AMBER,
    )


@pytest.fixture
def red_rights():
    """A strictly copyrighted, non-commercial record."""
    return ContentRights(
        original_composition_attribution="Contemporary Commentary",
        primary_source="Commercial Website",
        license_type="ALL_RIGHTS_RESERVED",
        commercial_reuse_permitted=False,
        release_status=ReleaseStatus.RED,
    )


def test_evaluate_release_status_green(green_rights):
    status, reason = RightsProvenanceEngine.evaluate_release_status(green_rights)
    assert status == ReleaseStatus.GREEN
    assert "approved" in reason.lower()


def test_evaluate_release_status_red_forbidden(red_rights):
    status, reason = RightsProvenanceEngine.evaluate_release_status(red_rights)
    assert status == ReleaseStatus.RED
    assert "prohibits" in reason.lower() or "false" in reason.lower()


def test_evaluate_release_status_expired_permission():
    past_date = datetime.now(timezone.utc) - timedelta(days=10)
    rights = ContentRights(
        original_composition_attribution="Traditional",
        primary_source="Special Archive",
        license_type="PROPRIETARY_PARTNER_AGREEMENT",
        commercial_reuse_permitted=True,
        written_permission_reference="AGREEMENT-2020",
        supporting_evidence="Contract on file",
        permission_expiry=past_date,
    )
    status, reason = RightsProvenanceEngine.evaluate_release_status(rights)
    assert status == ReleaseStatus.RED
    assert "expired" in reason.lower()


def test_assert_export_clearance_blocks_unauthorized_commercial(red_rights, amber_rights, green_rights):
    # RED must be blocked from commercial release
    with pytest.raises(RightsComplianceError):
        RightsProvenanceEngine.assert_export_clearance(red_rights, "commercial_release")

    # AMBER must be blocked from commercial release
    with pytest.raises(RightsComplianceError):
        RightsProvenanceEngine.assert_export_clearance(amber_rights, "commercial_release")

    # GREEN must pass commercial release
    RightsProvenanceEngine.assert_export_clearance(green_rights, "commercial_release")


def test_scholarly_review_channel(amber_rights, red_rights):
    # AMBER can be exported for internal scholarly review
    RightsProvenanceEngine.assert_export_clearance(amber_rights, "scholarly_review")

    # RED is blocked even from scholarly review if commercial reuse is strictly forbidden
    with pytest.raises(RightsComplianceError):
        RightsProvenanceEngine.assert_export_clearance(red_rights, "scholarly_review")
