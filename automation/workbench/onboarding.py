"""
Vedic Heritage Platform — Real Reviewer Onboarding & Credential Governance Framework
Enforces strict competency criteria for Vedic, Classical Sanskrit, Awadhi, and regional translators.
Provides auditable administrative verification workflows and strictly segregates demonstration accounts.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.workbench.auth import AuthService, hash_password, PermissionGuard, PermissionDeniedError
from database.models import (
    ReviewerProfile,
    ReviewerRole,
    ReviewerVerificationStatus,
)
from database.schemas import (
    ReviewerProfileAdminRead,
    ReviewerProfileCreate,
    ReviewerProfilePublicRead,
)

logger = logging.getLogger("vedam.automation.workbench.onboarding")


class OnboardingGovernanceError(Exception):
    """Raised when onboarding or credential verification rules are violated."""
    pass


class ReviewerOnboardingService:
    """Manages reviewer applications, credential verification, and status transitions."""

    ROLE_COMPETENCY_REQUIREMENTS = {
        ReviewerRole.VEDIC_RECENSION: {
            "minimum_degree": "Veda Veda-Bhashya / Acharya or MA/PhD in Vedic Studies",
            "required_competencies": [
                "Oral recitation with certified Swara accents (Udatta, Anudatta, Svarita)",
                "Rigvedic/Yajurvedic/Atharvavedic Shakha recension awareness",
                "Familiarity with Sayana, Bhatta Bhaskara, or Skandasvamin bhashyas",
            ],
            "verification_evidence": "Adhyayana certification, published Vedic editions, or university credentials",
        },
        ReviewerRole.SANSKRIT_TEXTUAL: {
            "minimum_degree": "Acharya / MA in Sanskrit Textual Criticism or Philology",
            "required_competencies": [
                "Critical manuscript collation & variant apparatus analysis",
                "Metrical scansion (Vedic & Classical Chandas)",
                "Orthographic consistency and sandhi normalization",
            ],
            "verification_evidence": "Peer-reviewed critical editions, academic publication record",
        },
        ReviewerRole.SANSKRIT_GRAMMAR: {
            "minimum_degree": "Acharya / PhD in Vyakarana (Paninian Grammar)",
            "required_competencies": [
                "Ashtadhyayi sutra citations and Mahabhashya/Kashika reference mastery",
                "Padachheda and Samasa dissection capability",
                "Subanta/Tinganta morphological analysis",
            ],
            "verification_evidence": "Traditional Vyakarana examination certificate or university degree",
        },
        ReviewerRole.AWADHI_SPECIALIST: {
            "minimum_degree": "MA/PhD in Early Modern Hindi / Awadhi Bhakti Literature",
            "required_competencies": [
                "Awadhi vernacular morphology, phonology, and archaic lexemes",
                "Tulsidas Ramcharitmanas and Hanuman Chalisa manuscript traditions",
                "Chaupai (16 matras) and Doha (13+11 matras) prosody expertise",
            ],
            "verification_evidence": "Published translations or commentaries in Awadhi literature",
        },
        ReviewerRole.HINDI_TRANSLATOR: {
            "minimum_degree": "MA in Hindi or accredited professional literary translator",
            "required_competencies": ["Native proficiency", "Vedic devotional idioms", "Rigorous syntactic accuracy"],
            "verification_evidence": "Published translations from Sanskrit to Hindi",
        },
        ReviewerRole.TELUGU_TRANSLATOR: {
            "minimum_degree": "MA in Telugu or accredited Telugu scholar",
            "required_competencies": ["Native proficiency", "Telugu classical poetics", "Sanskrit loanword integration"],
            "verification_evidence": "Published translations or Sahitya Akademi recognized work",
        },
        ReviewerRole.TAMIL_TRANSLATOR: {
            "minimum_degree": "MA in Tamil or accredited Tamil scholar",
            "required_competencies": ["Native proficiency", "Grantha subscript phonetics", "Manipravalam awareness"],
            "verification_evidence": "Published Tamil religious or philosophical translations",
        },
        ReviewerRole.KANNADA_TRANSLATOR: {
            "minimum_degree": "MA in Kannada or accredited Kannada scholar",
            "required_competencies": ["Native proficiency", "Halegannada/Hosagannada balance", "Bhakti literature nuance"],
            "verification_evidence": "Published translations or institutional credential",
        },
        ReviewerRole.MARATHI_TRANSLATOR: {
            "minimum_degree": "MA in Marathi or accredited Marathi scholar",
            "required_competencies": ["Native proficiency", "Varkari & Abhanga devotional nuance", "Sanskrit translation"],
            "verification_evidence": "Published Marathi translations or scholarly work",
        },
        ReviewerRole.BENGALI_TRANSLATOR: {
            "minimum_degree": "MA in Bengali or accredited Bengali scholar",
            "required_competencies": ["Native proficiency", "Gaudiya Vaishnava exegesis", "Sanskrit-Bengali syntax"],
            "verification_evidence": "Published Bengali translations or university degree",
        },
        ReviewerRole.GUJARATI_TRANSLATOR: {
            "minimum_degree": "MA in Gujarati or accredited Gujarati scholar",
            "required_competencies": ["Native proficiency", "Gujarati devotional terminology", "Syntactic fidelity"],
            "verification_evidence": "Published Gujarati translations or institutional credential",
        },
        ReviewerRole.MALAYALAM_TRANSLATOR: {
            "minimum_degree": "MA in Malayalam or accredited Malayalam scholar",
            "required_competencies": ["Native proficiency", "Manipravalam and Sanskrit prosodic compatibility"],
            "verification_evidence": "Published Malayalam translations or university credential",
        },
        ReviewerRole.ODIA_TRANSLATOR: {
            "minimum_degree": "MA in Odia or accredited Odia scholar",
            "required_competencies": ["Native proficiency", "Jagannatha Sampradaya devotional vocabulary"],
            "verification_evidence": "Published Odia translations or institutional credential",
        },
        ReviewerRole.TRADITIONAL_COMMENTARY: {
            "minimum_degree": "Traditional Sampradaya initiation / Acharya title",
            "required_competencies": [
                "Bhashya citation accuracy (Advaita, Vishishtadvaita, Dvaita)",
                "Siddhanta doctrinal fidelity without bias",
                "Distinguishing literal bhashya from secondary modern glosses",
            ],
            "verification_evidence": "Traditional Matha/Ashrama certification or recognized Acharya title",
        },
        ReviewerRole.EDITORIAL_BOARD: {
            "minimum_degree": "Senior Acharya / Professor / Editorial Director with 10+ years experience",
            "required_competencies": [
                "Multi-tradition dispute resolution and consensus drafting",
                "Holistic oversight of text, translation, and commentary integrity",
                "Final release approval authority",
            ],
            "verification_evidence": "Formal appointment by Vedam Editorial Council",
        },
    }

    @classmethod
    def register_applicant(
        cls,
        session: Session,
        application_data: ReviewerProfileCreate,
        raw_password: str,
    ) -> ReviewerProfile:
        """
        Registers an external scholarly applicant. The account starts strictly in
        'PENDING_VERIFICATION' status with credentials unverified.
        """
        existing = session.query(ReviewerProfile).filter_by(reviewer_id=application_data.reviewer_id).first()
        if existing:
            raise OnboardingGovernanceError(f"Reviewer with ID '{application_data.reviewer_id}' already exists.")

        pwd_hash = hash_password(raw_password)

        profile = ReviewerProfile(
            reviewer_id=application_data.reviewer_id,
            full_name=application_data.full_name.strip(),
            email=application_data.email.strip() if application_data.email else None,
            primary_role=application_data.primary_role,
            secondary_roles=application_data.secondary_roles or [],
            areas_of_expertise=application_data.areas_of_expertise or [],
            language_proficiency=application_data.language_proficiency or {},
            sanskrit_proficiency=application_data.sanskrit_proficiency,
            vedic_specialization=application_data.vedic_specialization,
            academic_qualifications=application_data.academic_qualifications,
            institutional_affiliation=application_data.institutional_affiliation,
            password_hash=pwd_hash,
            is_demonstration=False,
            is_credentials_verified=False,
            verification_status="PENDING_VERIFICATION",
            verified_by_admin=None,
            verification_notes=None,
            verification_method=None,
            verification_date=None,
            permissions=application_data.permissions or ["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        session.add(profile)
        session.flush()

        AuthService.log_event(
            session,
            event_type="REVIEWER_APPLICANT_REGISTERED",
            reviewer_id=profile.id,
            details=f"New applicant registered: {profile.reviewer_id} ({profile.primary_role.value})",
        )
        logger.info("Registered applicant %s in PENDING_VERIFICATION status", profile.reviewer_id)
        return profile

    @classmethod
    def create_demonstration_profile(
        cls,
        session: Session,
        reviewer_id: str,
        full_name: str,
        role: ReviewerRole,
        raw_password: str,
        qualifications: str = "Demo Simulation Account",
    ) -> ReviewerProfile:
        """
        Creates a demonstration profile for sandbox tests.
        Strictly flagged with is_demonstration=True and verification_status='DEMO'.
        Demonstration accounts CANNOT issue production approvals.
        """
        existing = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if existing:
            return existing

        profile = ReviewerProfile(
            reviewer_id=reviewer_id,
            full_name=full_name,
            email=f"{reviewer_id.lower()}@demo.local",
            primary_role=role,
            secondary_roles=[],
            areas_of_expertise=["Demonstration & Automated Test Scenarios"],
            language_proficiency={"sa": "Native", "en": "Fluent"},
            sanskrit_proficiency="Vidwan (Demo)",
            academic_qualifications=qualifications,
            institutional_affiliation="Vedam Test Harness (Non-Production)",
            password_hash=hash_password(raw_password),
            is_demonstration=True,
            is_credentials_verified=False,
            verification_status="DEMO",
            verified_by_admin="test_harness",
            verification_notes="Simulated account for regression testing only. Not a production endorsement.",
            verification_method="SIMULATION_FIXTURE",
            verification_date=datetime.now(timezone.utc),
            permissions=["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        session.add(profile)
        session.flush()
        logger.info("Created demonstration profile %s (is_demonstration=True)", reviewer_id)
        return profile

    @classmethod
    def verify_credentials(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        verification_method: str,
        verification_notes: str,
        approve: bool = True,
    ) -> ReviewerProfile:
        """
        Administratively reviews and approves/rejects an applicant's scholarly credentials.
        Requires administrative or editorial board permissions.
        """
        # Guard: Check that admin has permission
        PermissionGuard.require_permission(admin_reviewer, "CAN_VERIFY_CREDENTIALS")

        applicant = session.query(ReviewerProfile).filter_by(reviewer_id=applicant_reviewer_id).first()
        if not applicant:
            raise OnboardingGovernanceError(f"Applicant '{applicant_reviewer_id}' not found.")

        if applicant.is_demonstration:
            raise OnboardingGovernanceError(f"Cannot verify demonstration account '{applicant_reviewer_id}'.")

        if approve:
            applicant.is_credentials_verified = True
            applicant.verification_status = "VERIFIED"
            applicant.verified_by_admin = admin_reviewer.reviewer_id
            applicant.verification_method = verification_method
            applicant.verification_notes = verification_notes
            applicant.verification_date = datetime.now(timezone.utc)
            # Grant approval permission once verified
            perms = list(applicant.permissions or [])
            if "APPROVE_TRANSLATION" not in perms:
                perms.append("APPROVE_TRANSLATION")
            applicant.permissions = perms
            event_type = "CREDENTIALS_VERIFIED"
            logger.info("Admin %s verified credentials for %s", admin_reviewer.reviewer_id, applicant.reviewer_id)
        else:
            applicant.is_credentials_verified = False
            applicant.verification_status = "REJECTED"
            applicant.verified_by_admin = admin_reviewer.reviewer_id
            applicant.verification_notes = verification_notes
            applicant.verification_date = datetime.now(timezone.utc)
            event_type = "CREDENTIALS_REJECTED"
            logger.info("Admin %s rejected credentials for %s", admin_reviewer.reviewer_id, applicant.reviewer_id)

        applicant.updated_at = datetime.now(timezone.utc)
        session.flush()

        AuthService.log_event(
            session,
            event_type=event_type,
            reviewer_id=applicant.id,
            details=f"Admin: {admin_reviewer.reviewer_id} | Method: {verification_method} | Notes: {verification_notes}",
        )
        return applicant

    @classmethod
    def deactivate_reviewer(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        reviewer_id: str,
        reason: str,
    ) -> ReviewerProfile:
        """
        Deactivates a reviewer and immediately revokes all of their active sessions.
        """
        PermissionGuard.require_permission(admin_reviewer, "CAN_DEACTIVATE_REVIEWER")

        profile = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not profile:
            raise OnboardingGovernanceError(f"Reviewer '{reviewer_id}' not found.")

        profile.is_active = False
        profile.verification_status = "DEACTIVATED"
        profile.updated_at = datetime.now(timezone.utc)

        # Immediately revoke all active sessions
        revoked_count = AuthService.revoke_all_sessions(
            session,
            reviewer_id=profile.id,
            reason=f"Account deactivated by {admin_reviewer.reviewer_id}: {reason}",
        )

        session.flush()
        logger.info("Deactivated reviewer %s (revoked %d active sessions)", reviewer_id, revoked_count)
        return profile

    @classmethod
    def get_reviewer_census(cls, session: Session) -> Dict[str, Any]:
        """Returns census breakdown distinguishing demo, verified production, pending, and deactivated."""
        all_profiles = session.query(ReviewerProfile).all()

        total = len(all_profiles)
        demos = [p for p in all_profiles if p.is_demonstration]
        verified_prod = [p for p in all_profiles if not p.is_demonstration and p.verification_status == "VERIFIED" and p.is_active]
        pending = [p for p in all_profiles if not p.is_demonstration and p.verification_status == "PENDING_VERIFICATION" and p.is_active]
        rejected = [p for p in all_profiles if p.verification_status == "REJECTED"]
        deactivated = [p for p in all_profiles if not p.is_active or p.verification_status == "DEACTIVATED"]

        return {
            "total_profiles": total,
            "demonstration_accounts": len(demos),
            "verified_production_reviewers": len(verified_prod),
            "pending_verification": len(pending),
            "rejected_applicants": len(rejected),
            "deactivated_profiles": len(deactivated),
            "role_distribution": {
                role.value: len([p for p in all_profiles if p.primary_role == role])
                for role in ReviewerRole
            },
        }
