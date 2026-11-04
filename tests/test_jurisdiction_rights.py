"""
Unit Tests for Jurisdiction-Aware Copyright Engine
"""

from datetime import datetime, timedelta, timezone
import pytest

from automation.rights.jurisdiction import (
    IPLayerType,
    Jurisdiction,
    JurisdictionRightsEngine,
    RightsReleaseStatus,
)


def test_ancient_composition_clearance():
    # Ancient composition (c. 8th century CE, Adi Shankara)
    status, reason = JurisdictionRightsEngine.evaluate_layer_rights(
        layer=IPLayerType.COMPOSITION,
        composition_year_ce=800,
        author_death_year=820,
        edition_publication_year=None,
        jurisdiction=Jurisdiction.GLOBAL,
        commercial_reuse_authorized=True,
        license_type="PUBLIC_DOMAIN",
    )
    assert status == RightsReleaseStatus.GREEN
    assert "universal public domain" in reason.lower()


def test_modern_edition_us_pre_1930():
    # Edition published in 1912 (Pre-1930 rule in US)
    status, reason = JurisdictionRightsEngine.evaluate_layer_rights(
        layer=IPLayerType.EDITION,
        composition_year_ce=800,
        author_death_year=820,
        edition_publication_year=1912,
        jurisdiction=Jurisdiction.US,
        commercial_reuse_authorized=True,
        license_type="PUBLIC_DOMAIN",
        is_legally_approved=True,
        legal_reviewer="Adv. S. Sharma",
    )
    assert status == RightsReleaseStatus.GREEN
    assert "public domain in us" in reason.lower()


def test_modern_edition_requires_human_legal_approval():
    # Pre-1930 edition without human legal sign-off cannot be automatically marked GREEN
    status, reason = JurisdictionRightsEngine.evaluate_layer_rights(
        layer=IPLayerType.EDITION,
        composition_year_ce=800,
        author_death_year=820,
        edition_publication_year=1912,
        jurisdiction=Jurisdiction.GLOBAL,
        commercial_reuse_authorized=True,
        license_type="PUBLIC_DOMAIN",
        is_legally_approved=False,  # Unapproved by legal reviewer
    )
    assert status == RightsReleaseStatus.AMBER
    assert "requires legal" in reason.lower()


def test_expired_written_contract():
    past_date = datetime.now(timezone.utc) - timedelta(days=5)
    status, reason = JurisdictionRightsEngine.evaluate_layer_rights(
        layer=IPLayerType.TRANSLATION,
        composition_year_ce=1980,
        author_death_year=None,
        edition_publication_year=1985,
        jurisdiction=Jurisdiction.GLOBAL,
        commercial_reuse_authorized=True,
        license_type="PROPRIETARY_PARTNER_AGREEMENT",
        has_written_contract=True,
        contract_expiry=past_date,
    )
    assert status == RightsReleaseStatus.RED
    assert "expired" in reason.lower()
