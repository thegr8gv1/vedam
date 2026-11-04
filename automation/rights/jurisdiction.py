"""
Vedic Heritage Platform — Jurisdiction-Aware Rights Engine
Distinguishes rights across granular intellectual property layers (underlying composition,
modern edition, transcription, translation, commentary, audio, video) and geographic
jurisdictions (India, United States, European Union, United Kingdom, Global).
"""

from datetime import datetime, timezone
import enum
from typing import Dict, List, Optional, Set, Tuple


class IPLayerType(str, enum.Enum):
    """Granular layers of intellectual property in sacred and devotional literature."""
    COMPOSITION = "COMPOSITION"          # Ancient or traditional underlying verse/hymn
    EDITION = "EDITION"                  # Critical edition, layout, typography, arrangement
    TRANSCRIPTION = "TRANSCRIPTION"      # Digital keystroke/OCR input contribution
    EDITORIAL = "EDITORIAL"              # Introductions, footnotes, liturgical guidance
    TRANSLATION = "TRANSLATION"          # Target language translation (specific to translator)
    COMMENTARY = "COMMENTARY"            # Philosophical/theological commentary (Bhashya/Tatparya)
    AUDIO = "AUDIO"                      # Performance, phonogram, chanting recording
    VIDEO = "VIDEO"                      # Motion graphics, visual artwork, video clubbing


class Jurisdiction(str, enum.Enum):
    """Geographic territory for copyright evaluation."""
    IN = "IN"          # India (Copyright Act, 1957: Life + 60 years)
    US = "US"          # United States (Pre-1929 PD; Post-1929 95 years from pub or Life + 70)
    EU = "EU"          # European Union (Life + 70 years)
    GB = "GB"          # United Kingdom (Life + 70 years)
    GLOBAL = "GLOBAL"  # Clearance verified across all primary target markets


class RightsReleaseStatus(str, enum.Enum):
    GREEN = "GREEN"  # Approved for commercial publishing in specified jurisdictions
    AMBER = "AMBER"  # Under review; additional clearance, verification, or contract needed
    RED = "RED"      # Prohibited for commercial use in specified jurisdictions


class JurisdictionRightsEngine:
    """
    Evaluates copyright clearance across multiple legal jurisdictions and IP layers.
    
    Principles:
    - Ancient traditional compositions (pre-19th century) are universal public domain.
    - Modern editions, translations, and commentaries require separate jurisdiction audits.
    - Life + 60 (India) does NOT automatically clear a work in Life + 70 (EU/US) jurisdictions.
    - Human legal sign-off (legal_reviewer) is strictly required for GREEN status.
    """

    # Primary public domain thresholds (as of 2026)
    US_PUBLIC_DOMAIN_YEAR = 1930  # Works published before Jan 1, 1931 are generally PD in the US

    @classmethod
    def evaluate_layer_rights(
        cls,
        layer: IPLayerType,
        composition_year_ce: Optional[int],
        author_death_year: Optional[int],
        edition_publication_year: Optional[int],
        jurisdiction: Jurisdiction,
        commercial_reuse_authorized: bool,
        license_type: str,
        has_written_contract: bool = False,
        contract_expiry: Optional[datetime] = None,
        is_legally_approved: bool = False,
        legal_reviewer: Optional[str] = None,
    ) -> Tuple[RightsReleaseStatus, str]:
        """
        Evaluate release status for a specific IP layer in a specific territory.
        """
        now_year = datetime.now(timezone.utc).year
        now_dt = datetime.now(timezone.utc)

        # 1. Commercial reuse flag check
        if not commercial_reuse_authorized and not has_written_contract:
            return (
                RightsReleaseStatus.RED,
                f"Commercial reuse is explicitly unauthorized for layer {layer.value}.",
            )

        # 2. Check contract expiration
        if has_written_contract and contract_expiry:
            expiry_dt = (
                contract_expiry
                if contract_expiry.tzinfo
                else contract_expiry.replace(tzinfo=timezone.utc)
            )
            if expiry_dt < now_dt:
                return (
                    RightsReleaseStatus.RED,
                    f"Written contract expired on {contract_expiry.strftime('%Y-%m-%d')}.",
                )

        # 3. Layer: Underlying Composition
        if layer == IPLayerType.COMPOSITION:
            # Traditional ancient / medieval compositions (>100 years old) are public domain worldwide
            if composition_year_ce and composition_year_ce < 1850:
                return (
                    RightsReleaseStatus.GREEN,
                    f"Ancient composition (c. {composition_year_ce} CE) is universal public domain.",
                )
            if author_death_year and (now_year - author_death_year) > 100:
                return (
                    RightsReleaseStatus.GREEN,
                    f"Author deceased in {author_death_year} (>100 years), universal public domain.",
                )

        # 4. Layer: Modern Edition / Transcription / Translation / Commentary
        if layer in {IPLayerType.EDITION, IPLayerType.TRANSCRIPTION, IPLayerType.TRANSLATION, IPLayerType.COMMENTARY}:
            # If authorized via formal bilateral contract
            if has_written_contract and is_legally_approved and legal_reviewer:
                return (
                    RightsReleaseStatus.GREEN,
                    f"Authorized under written partner contract. Reviewed by {legal_reviewer}.",
                )

            # Check jurisdiction-specific public domain terms for historical editions
            if edition_publication_year:
                # India: 60 years post-publication / post-death
                if jurisdiction == Jurisdiction.IN:
                    if (now_year - edition_publication_year) > 60 and author_death_year and (now_year - author_death_year) > 60:
                        if is_legally_approved:
                            return (RightsReleaseStatus.GREEN, f"Public domain in India (>60 years post-death/pub).")
                        return (RightsReleaseStatus.AMBER, "Meets Indian copyright age, but requires legal sign-off.")

                # United States: Pre-1930 works are public domain
                elif jurisdiction == Jurisdiction.US:
                    if edition_publication_year < cls.US_PUBLIC_DOMAIN_YEAR:
                        if is_legally_approved:
                            return (RightsReleaseStatus.GREEN, f"Published {edition_publication_year} (<1931), public domain in US.")
                        return (RightsReleaseStatus.AMBER, "Pre-1931 publication, requires legal confirmation.")
                    else:
                        return (RightsReleaseStatus.AMBER, f"Published in {edition_publication_year}; may be protected under US 95-year rule.")

                # European Union & UK: Life + 70 years
                elif jurisdiction in {Jurisdiction.EU, Jurisdiction.GB}:
                    if author_death_year and (now_year - author_death_year) > 70:
                        if is_legally_approved:
                            return (RightsReleaseStatus.GREEN, f"Author deceased {author_death_year} (>70 years), public domain in EU/UK.")
                        return (RightsReleaseStatus.AMBER, "Meets Life+70 rule, requires legal confirmation.")
                    else:
                        return (RightsReleaseStatus.AMBER, "Does not meet Life+70 threshold in EU/UK.")

                # Global clearance requires satisfying all major jurisdictions
                elif jurisdiction == Jurisdiction.GLOBAL:
                    is_pre_1930 = edition_publication_year < cls.US_PUBLIC_DOMAIN_YEAR
                    is_life_70 = author_death_year and (now_year - author_death_year) > 70
                    if is_pre_1930 and is_life_70:
                        if is_legally_approved:
                            return (RightsReleaseStatus.GREEN, "Global clearance verified (Pre-1930 and Life+70).")
                        return (RightsReleaseStatus.AMBER, "Qualifies for global public domain, requires legal approval sign-off.")
                    return (
                        RightsReleaseStatus.AMBER,
                        f"Edition {edition_publication_year} cannot be certified GLOBAL public domain automatically.",
                    )

        # Default fallback
        if not is_legally_approved:
            return (
                RightsReleaseStatus.AMBER,
                "Requires human legal reviewer sign-off before entering production pipeline.",
            )

        return (RightsReleaseStatus.AMBER, "Pending detailed rights determination.")
