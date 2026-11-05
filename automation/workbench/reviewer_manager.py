"""
Vedic Heritage Platform — Reviewer Management Architecture
Manages qualified scholar profiles, role-based specialization, verification credentials,
and administrative access controls.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from database.models import (
    ReviewerProfile,
    ReviewerRole,
)
from database.schemas import (
    ReviewerProfileAdminRead,
    ReviewerProfileCreate,
    ReviewerProfilePublicRead,
)

from automation.workbench.auth import hash_password

logger = logging.getLogger("vedam.automation.workbench.reviewer_manager")


class ReviewerGovernanceError(Exception):
    """Raised when reviewer registration or governance rules are violated."""
    pass


class ReviewerManager:
    """Manages verified scholar profiles and credential verification."""

    ROLE_CAPABILITIES = {
        ReviewerRole.SANSKRIT_TEXTUAL: {"sa_textual_critique", "variant_analysis", "meter_verification"},
        ReviewerRole.VEDIC_RECENSION: {"swara_accent_verification", "shakha_critique", "samhita_alignment"},
        ReviewerRole.HINDI_TRANSLATOR: {"hi_translation_critique", "bhakti_idiom_review"},
        ReviewerRole.TELUGU_TRANSLATOR: {"te_translation_critique", "telugu_poetic_meter"},
        ReviewerRole.TAMIL_TRANSLATOR: {"ta_translation_critique", "grantha_subscript_phonetics"},
        ReviewerRole.KANNADA_TRANSLATOR: {"kn_translation_critique", "kannada_prosody"},
        ReviewerRole.MARATHI_TRANSLATOR: {"mr_translation_critique", "abhanga_style_critique"},
        ReviewerRole.BENGALI_TRANSLATOR: {"bn_translation_critique", "gaudiya_vaishnava_exegesis"},
        ReviewerRole.GUJARATI_TRANSLATOR: {"gu_translation_critique", "gujarati_devotional_lexicon"},
        ReviewerRole.MALAYALAM_TRANSLATOR: {"ml_translation_critique", "manipravalam_knowledge"},
        ReviewerRole.ODIA_TRANSLATOR: {"or_translation_critique", "jagannatha_sampradaya_lexicon"},
        ReviewerRole.AWADHI_SPECIALIST: {"awadhi_linguistics", "chaupai_doha_prosody", "tulsidas_exegesis"},
        ReviewerRole.SANSKRIT_GRAMMAR: {"padachheda_analysis", "paninian_grammar", "sandhi_splitting", "samasa_analysis"},
        ReviewerRole.TRADITIONAL_COMMENTARY: {"bhashya_citation_verification", "sampradaya_fidelity"},
        ReviewerRole.LEGAL_COPYRIGHT: {"public_domain_clearance", "jurisdiction_rights_audit"},
        ReviewerRole.EDITORIAL_BOARD: {"dispute_adjudication", "final_canonical_signoff", "reassignment_authorization"},
    }

    @classmethod
    def register_reviewer(
        cls,
        session: Session,
        reviewer_data: ReviewerProfileCreate,
    ) -> ReviewerProfile:
        """Registers a new reviewer profile. Begins in unverified status unless administratively verified."""
        # Check uniqueness of reviewer_id
        existing = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_data.reviewer_id).first()
        if existing:
            raise ReviewerGovernanceError(f"Reviewer with ID '{reviewer_data.reviewer_id}' already exists.")

        pwd_hash = hash_password(reviewer_data.password) if getattr(reviewer_data, "password", None) else None

        profile = ReviewerProfile(
            reviewer_id=reviewer_data.reviewer_id,
            full_name=reviewer_data.full_name.strip(),
            email=reviewer_data.email.strip() if reviewer_data.email else None,
            primary_role=reviewer_data.primary_role,
            secondary_roles=reviewer_data.secondary_roles or [],
            areas_of_expertise=reviewer_data.areas_of_expertise or [],
            language_proficiency=reviewer_data.language_proficiency or {},
            sanskrit_proficiency=reviewer_data.sanskrit_proficiency,
            vedic_specialization=reviewer_data.vedic_specialization,
            academic_qualifications=reviewer_data.academic_qualifications,
            institutional_affiliation=reviewer_data.institutional_affiliation,
            password_hash=pwd_hash,
            is_demonstration=getattr(reviewer_data, "is_demonstration", False),
            is_credentials_verified=reviewer_data.is_credentials_verified,
            verification_status="VERIFIED" if reviewer_data.is_credentials_verified else ("DEMO" if getattr(reviewer_data, "is_demonstration", False) else "PENDING_VERIFICATION"),
            verification_method=reviewer_data.verification_method,
            verification_date=reviewer_data.verification_date,
            permissions=reviewer_data.permissions or ["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
            is_active=reviewer_data.is_active,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        session.add(profile)
        session.flush()
        logger.info("Registered reviewer %s (%s, %s)", profile.reviewer_id, profile.full_name, profile.primary_role)
        return profile

    @classmethod
    def verify_credentials(
        cls,
        session: Session,
        reviewer_id: str,
        verification_method: str,
        verified_by_admin: str,
    ) -> ReviewerProfile:
        """Affirmatively certifies reviewer credentials following academic/institutional validation."""
        profile = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not profile:
            raise ReviewerGovernanceError(f"Reviewer '{reviewer_id}' not found.")

        if profile.is_demonstration:
            raise ReviewerGovernanceError(f"Cannot verify demonstration account '{reviewer_id}' as production scholar.")

        profile.is_credentials_verified = True
        profile.verification_status = "VERIFIED"
        profile.verified_by_admin = verified_by_admin
        profile.verification_method = f"{verification_method} (Verified by: {verified_by_admin})"
        profile.verification_date = datetime.now(timezone.utc)
        profile.updated_at = datetime.now(timezone.utc)
        session.flush()
        logger.info("Credentials certified for reviewer %s via %s", reviewer_id, verification_method)
        return profile

    @classmethod
    def get_public_profile(cls, session: Session, reviewer_id: str) -> Optional[ReviewerProfilePublicRead]:
        """Returns sanitized public reviewer profile hiding email and internal permissions."""
        profile = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not profile:
            return None
        return ReviewerProfilePublicRead.model_validate(profile)

    @classmethod
    def get_admin_profile(cls, session: Session, reviewer_id: str) -> Optional[ReviewerProfileAdminRead]:
        """Returns full administrative reviewer profile."""
        profile = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not profile:
            return None
        return ReviewerProfileAdminRead.model_validate(profile)

    @classmethod
    def find_qualified_reviewers(
        cls,
        session: Session,
        role: Optional[ReviewerRole] = None,
        language: Optional[str] = None,
        vedic_specialization: Optional[str] = None,
        only_verified: bool = True,
    ) -> List[ReviewerProfile]:
        """Queries reviewers matching required scholarly credentials."""
        query = session.query(ReviewerProfile).filter(ReviewerProfile.is_active.is_(True))
        if only_verified:
            query = query.filter(ReviewerProfile.is_credentials_verified.is_(True))
        if role:
            query = query.filter(
                (ReviewerProfile.primary_role == role) |
                (ReviewerProfile.secondary_roles.contains([role.value]))
            )
        if vedic_specialization:
            query = query.filter(ReviewerProfile.vedic_specialization.ilike(f"%{vedic_specialization}%"))

        results = query.all()
        if language:
            results = [
                r for r in results
                if r.language_proficiency and language in r.language_proficiency
            ]
        return results
