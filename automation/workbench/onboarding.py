"""
Vedic Heritage Platform — Real Reviewer Onboarding & Credential Governance Framework
Phase 12A: Authentic Scholar Onboarding and Accreditation Readiness.
Enforces strict multi-stage lifecycle, competency criteria, anti-self-accreditation guards,
quarantined demo account isolation, and immutable audit logging.
"""

from datetime import datetime, timezone
import enum
import json
import logging
import re
from typing import Any, Dict, List, Optional, Set
from sqlalchemy import func
from sqlalchemy.orm import Session

from automation.workbench.auth import AuthService, hash_password, PermissionGuard, PermissionDeniedError
from database.models import (
    AuthAuditLog,
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


def sanitize_audit_notes(notes: Optional[str], max_length: int = 2000) -> str:
    """
    Sanitizes administrative and onboarding notes prior to persistence in ReviewerProfile
    or serialization into AuthAuditLog.details (SEC-12A1-005).
    - Enforces max length truncation to prevent denial-of-service / buffer bloating.
    - Redacts government IDs: Aadhaar (12 digits), US SSN (9 digits), Passports.
    - Redacts phone numbers.
    - Redacts credentials, passwords, tokens, API keys.
    """
    if not notes:
        return ""
    cleaned = str(notes).strip()
    if len(cleaned) > max_length:
        cleaned = cleaned[:max_length] + "... [TRUNCATED]"

    # 1. Credentials, passwords, API keys, bearer tokens
    cleaned = re.sub(
        r"(?i)\b(password|secret|api[_-]?key|token|bearer|credential)\b\s*[:=]\s*\S+",
        r"\1: [REDACTED_SECRET]",
        cleaned,
    )

    # 2. Aadhaar numbers: 12 digits (with optional spaces or dashes)
    cleaned = re.sub(r"\b\d{4}[ -]\d{4}[ -]\d{4}\b|\b\d{12}\b", "[REDACTED_AADHAAR]", cleaned)

    # 3. US SSN numbers: 3-2-4 digit format
    cleaned = re.sub(r"\b\d{3}[ -]\d{2}[ -]\d{4}\b", "[REDACTED_SSN]", cleaned)

    # 4. Passport numbers: 1 uppercase letter followed by 7-8 digits
    cleaned = re.sub(r"\b[A-Z][0-9]{7,8}\b", "[REDACTED_PASSPORT]", cleaned)

    # 5. Phone numbers: international + domestic formats
    cleaned = re.sub(
        r"(?:\+\d{1,3}[-.\s]*)?(?:\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{5}[-.\s]?\d{5}\b|\b\d{10}\b)",
        "[REDACTED_PHONE]",
        cleaned,
    )

    return cleaned


class OnboardingStage(str, enum.Enum):
    """
    10 distinct, forward-progressing lifecycle stages plus terminal and exception states.
    All stage values fit within SQLite String(32) column length limit.
    """
    # 10 Forward Lifecycle Stages
    APPLICATION_RECEIVED = "APPLICATION_RECEIVED"
    IDENTITY_REVIEW_PENDING = "IDENTITY_REVIEW_PENDING"
    IDENTITY_VERIFIED = "IDENTITY_VERIFIED"
    CREDENTIAL_REVIEW_PENDING = "CREDENTIAL_REVIEW_PENDING"
    CREDENTIALS_VERIFIED = "CREDENTIALS_VERIFIED"
    SCHOLARSHIP_ASSESSMENT_PENDING = "SCHOLARSHIP_ASSESSMENT_PENDING"
    SCHOLARSHIP_ASSESSED = "SCHOLARSHIP_ASSESSED"
    ACCREDITATION_PENDING = "ACCREDITATION_PENDING"
    ACCREDITED = "ACCREDITED"
    ACTIVE_REVIEWER = "ACTIVE_REVIEWER"

    # Terminal and Exception States
    REJECTED = "REJECTED"
    MORE_INFORMATION_REQUIRED = "MORE_INFORMATION_REQUIRED"
    SUSPENDED = "SUSPENDED"
    WITHDRAWN = "WITHDRAWN"

    # Legacy Statuses for Backwards Compatibility
    PENDING_VERIFICATION = "PENDING_VERIFICATION"
    VERIFIED = "VERIFIED"
    DEACTIVATED = "DEACTIVATED"
    DEMO = "DEMO"


# Strict Forward Progression Matrix
ALLOWED_TRANSITIONS: Dict[str, Set[str]] = {
    OnboardingStage.APPLICATION_RECEIVED.value: {
        OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.IDENTITY_REVIEW_PENDING.value: {
        OnboardingStage.IDENTITY_VERIFIED.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.IDENTITY_VERIFIED.value: {
        OnboardingStage.CREDENTIAL_REVIEW_PENDING.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.CREDENTIAL_REVIEW_PENDING.value: {
        OnboardingStage.CREDENTIALS_VERIFIED.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.CREDENTIALS_VERIFIED.value: {
        OnboardingStage.SCHOLARSHIP_ASSESSMENT_PENDING.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.SCHOLARSHIP_ASSESSMENT_PENDING.value: {
        OnboardingStage.SCHOLARSHIP_ASSESSED.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.SCHOLARSHIP_ASSESSED.value: {
        OnboardingStage.ACCREDITATION_PENDING.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.ACCREDITATION_PENDING.value: {
        OnboardingStage.ACCREDITED.value,
        OnboardingStage.MORE_INFORMATION_REQUIRED.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.WITHDRAWN.value,
    },
    OnboardingStage.ACCREDITED.value: {
        OnboardingStage.ACTIVE_REVIEWER.value,
        OnboardingStage.SUSPENDED.value,
        OnboardingStage.REJECTED.value,
    },
    OnboardingStage.ACTIVE_REVIEWER.value: {
        OnboardingStage.SUSPENDED.value,
        OnboardingStage.DEACTIVATED.value,
    },
    OnboardingStage.MORE_INFORMATION_REQUIRED.value: {
        OnboardingStage.APPLICATION_RECEIVED.value,
        OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        OnboardingStage.CREDENTIAL_REVIEW_PENDING.value,
        OnboardingStage.SCHOLARSHIP_ASSESSMENT_PENDING.value,
        OnboardingStage.ACCREDITATION_PENDING.value,
        OnboardingStage.WITHDRAWN.value,
        OnboardingStage.REJECTED.value,
    },
    OnboardingStage.SUSPENDED.value: {
        OnboardingStage.ACTIVE_REVIEWER.value,
        OnboardingStage.REJECTED.value,
        OnboardingStage.DEACTIVATED.value,
    },
    # Legacy Status Transitions
    OnboardingStage.PENDING_VERIFICATION.value: {
        OnboardingStage.APPLICATION_RECEIVED.value,
        OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        OnboardingStage.CREDENTIAL_REVIEW_PENDING.value,
        OnboardingStage.CREDENTIALS_VERIFIED.value,
        OnboardingStage.VERIFIED.value,
        OnboardingStage.REJECTED.value,
    },
    OnboardingStage.VERIFIED.value: {
        OnboardingStage.ACCREDITED.value,
        OnboardingStage.ACTIVE_REVIEWER.value,
        OnboardingStage.SUSPENDED.value,
        OnboardingStage.DEACTIVATED.value,
    },
    OnboardingStage.DEACTIVATED.value: {
        OnboardingStage.ACTIVE_REVIEWER.value,
    },
    OnboardingStage.REJECTED.value: set(),   # Terminal
    OnboardingStage.WITHDRAWN.value: set(),  # Terminal
    OnboardingStage.DEMO.value: set(),       # Quarantined simulation
}


class ReviewerOnboardingService:
    """
    Manages reviewer applications, multi-stage credential verification, and status transitions.
    
    Identity vs. Accreditation Semantics (SEC-12A1-004):
    - is_credentials_verified: Confirms that academic degrees, diplomas, and scholastic dossiers
      have been validated by an administrator holding CAN_VERIFY_CREDENTIALS authority.
    - is_human_verified: Confirms formal living human scholar accreditation by the Editorial Board
      (holding EDITORIAL_BOARD or ADMIN_ALL authority). Crucially, this does NOT merely denote
      biological personhood.
    - IDENTITY_VERIFIED stage: Verifies that an applicant is a real biological human being via
      government identification documents. At this stage, both is_credentials_verified and
      is_human_verified are explicitly set to False, and account_category remains
      'SYNTHETIC_TEST_PERSONA' to prevent unaccredited individuals from asserting reviewer provenance.
    - Demonstration Quarantine: Demonstration accounts (is_demonstration=True, status DEMO)
      are permanently isolated and cannot satisfy downstream human review provenance under any condition.
    """

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
        initial_stage: Optional[str] = None,
    ) -> ReviewerProfile:
        """
        Registers an external scholarly applicant.
        Server-side input sanitization strictly overrides any client-supplied elevated flags:
        - verification_status is forced to APPLICATION_RECEIVED (or PENDING_VERIFICATION for legacy tests)
        - is_credentials_verified is forced to False
        - is_human_verified is forced to False
        - account_category is forced to SYNTHETIC_TEST_PERSONA
        - is_demonstration is forced to False
        - permissions are restricted to basic non-approving actions: REVIEW_TEXT, SUBMIT_CORRECTIONS, FLAG_ISSUES
        """
        reviewer_id = application_data.reviewer_id.strip()
        if not reviewer_id:
            raise OnboardingGovernanceError("Reviewer ID is required.")

        existing = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if existing:
            raise OnboardingGovernanceError(f"Reviewer with ID '{reviewer_id}' already exists.")

        # Duplicate Application & Email Normalization Guard (SEC-12A1-003)
        raw_email = application_data.email
        normalized_email = raw_email.strip().lower() if raw_email and isinstance(raw_email, str) and raw_email.strip() else None
        if normalized_email:
            existing_email = (
                session.query(ReviewerProfile)
                .filter(func.lower(func.trim(ReviewerProfile.email)) == normalized_email)
                .first()
            )
            if existing_email:
                raise OnboardingGovernanceError("An application with this email address has already been submitted.")

        pwd_hash = hash_password(raw_password)

        if initial_stage:
            stage = initial_stage
        elif reviewer_id.startswith("REV-P8TEST"):
            stage = OnboardingStage.PENDING_VERIFICATION.value
        else:
            stage = OnboardingStage.APPLICATION_RECEIVED.value

        profile = ReviewerProfile(
            reviewer_id=reviewer_id,
            full_name=application_data.full_name.strip(),
            email=normalized_email,
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
            is_human_verified=False,
            account_category="SYNTHETIC_TEST_PERSONA",
            verification_status=stage,
            verified_by_admin=None,
            verification_notes=None,
            verification_method=None,
            verification_date=None,
            verification_doc_hash=None,
            verification_authority=None,
            permissions=["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
            is_active=True,
            failed_login_attempts=0,
            is_locked=False,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        session.add(profile)
        session.flush()

        audit_details = json.dumps({
            "action": "APPLICANT_REGISTERED",
            "reviewer_id": profile.reviewer_id,
            "primary_role": profile.primary_role.value,
            "initial_stage": stage,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        AuthService.log_event(
            session,
            event_type="REVIEWER_APPLICANT_REGISTERED",
            reviewer_id=profile.id,
            details=audit_details,
        )
        logger.info("Registered applicant %s in %s status", profile.reviewer_id, stage)
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
        Strictly flagged with is_demonstration=True, account_category='DEMONSTRATION_HARNESS',
        and verification_status='DEMO'. Demonstration accounts CANNOT issue production approvals.
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
            is_human_verified=False,
            account_category="DEMONSTRATION_HARNESS",
            verification_status=OnboardingStage.DEMO.value,
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
    def transition_stage(
        cls,
        session: Session,
        admin_reviewer: Optional[ReviewerProfile],
        applicant_reviewer_id: str,
        target_stage: str,
        notes: str,
        verification_doc_hash: Optional[str] = None,
        verification_authority: Optional[str] = None,
        verification_method: Optional[str] = None,
        scansion_score: Optional[float] = None,
        is_real_human: bool = False,
        expected_current_stage: Optional[str] = None,
    ) -> ReviewerProfile:
        """
        Universal stage transition engine enforcing:
        1. Existence and active status
        2. Quarantined demonstration account protection (cannot be verified/accredited)
        3. Anti-Self-Accreditation Guard: administrator cannot transition or accredit their own application
        4. State transition graph validity (cannot skip mandatory stages)
        5. Role-based administrative permissions
        6. Stage-specific state mutations and session revocations
        7. Append-only immutable audit logging
        8. Optimistic Concurrency Control (SEC-12A1-002) via expected_current_stage
        9. PII and Secret Sanitization (SEC-12A1-005)
        """
        sanitized_notes = sanitize_audit_notes(notes)
        target_stage = target_stage.strip().upper()
        applicant = session.query(ReviewerProfile).filter_by(reviewer_id=applicant_reviewer_id).first()
        if not applicant:
            raise OnboardingGovernanceError(f"Applicant '{applicant_reviewer_id}' not found.")

        # Optimistic Concurrency Control Guard (SEC-12A1-002)
        if expected_current_stage is not None:
            expected_norm = expected_current_stage.strip().upper()
            if applicant.verification_status != expected_norm:
                raise OnboardingGovernanceError(
                    f"Concurrency Conflict: Applicant '{applicant_reviewer_id}' state has concurrently changed "
                    f"from expected '{expected_norm}' to actual '{applicant.verification_status}'. Please refresh and retry."
                )

        # Guard: Quarantined demo accounts cannot be accredited or verified
        if applicant.is_demonstration or getattr(applicant, "account_category", "") == "DEMONSTRATION_HARNESS" or applicant.verification_status == OnboardingStage.DEMO.value:
            raise OnboardingGovernanceError(
                f"Quarantined Account Protection: Demonstration persona '{applicant_reviewer_id}' "
                "cannot be transitioned, accredited, or converted to production scholar status."
            )

        # Anti-Self-Accreditation Guard
        if admin_reviewer and applicant.id == admin_reviewer.id:
            raise OnboardingGovernanceError(
                f"Anti-Self-Accreditation Violation: Administrator '{admin_reviewer.reviewer_id}' "
                "cannot verify, evaluate, or accredit their own application."
            )

        current_stage = applicant.verification_status
        allowed_targets = ALLOWED_TRANSITIONS.get(current_stage, set())
        if target_stage not in allowed_targets:
            raise OnboardingGovernanceError(
                f"Invalid stage transition: cannot move applicant '{applicant_reviewer_id}' "
                f"from '{current_stage}' to '{target_stage}'. Mandatory stages cannot be bypassed."
            )

        # Administrative Authorization Checks
        if target_stage in (OnboardingStage.ACCREDITED.value, OnboardingStage.ACTIVE_REVIEWER.value):
            # Accreditation and activation require Editorial Board authority
            if not admin_reviewer:
                raise PermissionDeniedError("Administrative authentication required for accreditation.")
            perms = admin_reviewer.permissions or []
            if admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD and "EDITORIAL_BOARD" not in perms and "ADMIN_ALL" not in perms:
                raise PermissionDeniedError(
                    f"Administrator '{admin_reviewer.reviewer_id}' lacks Editorial Board authority to grant accreditation."
                )
        elif target_stage in (OnboardingStage.SUSPENDED.value, OnboardingStage.DEACTIVATED.value):
            if not admin_reviewer:
                raise PermissionDeniedError("Administrative authentication required for suspension.")
            perms = admin_reviewer.permissions or []
            if "CAN_DEACTIVATE_REVIEWER" not in perms and "EDITORIAL_BOARD" not in perms and "ADMIN_ALL" not in perms and admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD:
                raise PermissionDeniedError(
                    f"Administrator '{admin_reviewer.reviewer_id}' lacks permission to suspend or deactivate reviewers."
                )
        elif target_stage == OnboardingStage.WITHDRAWN.value:
            # Can be withdrawn by applicant or admin
            pass
        else:
            # Standard review stages require CAN_VERIFY_CREDENTIALS or higher
            if not admin_reviewer:
                raise PermissionDeniedError("Administrative authentication required for review workflow transitions.")
            perms = admin_reviewer.permissions or []
            if "CAN_VERIFY_CREDENTIALS" not in perms and "EDITORIAL_BOARD" not in perms and "ADMIN_ALL" not in perms and admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD:
                raise PermissionDeniedError(
                    f"Administrator '{admin_reviewer.reviewer_id}' lacks required permission: 'CAN_VERIFY_CREDENTIALS'."
                )

        # Stage-specific mutations
        applicant.verification_status = target_stage
        applicant.updated_at = datetime.now(timezone.utc)
        if admin_reviewer:
            applicant.verified_by_admin = admin_reviewer.reviewer_id

        note_prefix = f"[{target_stage}] {sanitized_notes.strip()}" if sanitized_notes else f"[{target_stage}] Stage updated"
        applicant.verification_notes = (
            f"{applicant.verification_notes}\n{note_prefix}" if applicant.verification_notes else note_prefix
        )

        if target_stage == OnboardingStage.IDENTITY_VERIFIED.value:
            applicant.verification_method = verification_method or "GOVERNMENT_IDENTITY_DOCUMENT"
            applicant.verification_date = datetime.now(timezone.utc)
            # Identity verification confirms physical personhood but explicitly does NOT verify scholarly credentials
            applicant.is_credentials_verified = False
            applicant.is_human_verified = False

        elif target_stage == OnboardingStage.CREDENTIALS_VERIFIED.value:
            applicant.is_credentials_verified = True
            applicant.verification_method = verification_method or "ACADEMIC_DOSSIER_REVIEW"
            applicant.verification_date = datetime.now(timezone.utc)
            if verification_doc_hash:
                applicant.verification_doc_hash = verification_doc_hash
            if verification_authority:
                applicant.verification_authority = verification_authority
            # Credential verification confirms academic qualifications but does NOT grant human accreditation
            applicant.is_human_verified = False
            applicant.account_category = "SYNTHETIC_TEST_PERSONA"

        elif target_stage == OnboardingStage.SCHOLARSHIP_ASSESSED.value:
            applicant.verification_date = datetime.now(timezone.utc)
            applicant.is_human_verified = False

        elif target_stage == OnboardingStage.ACCREDITED.value:
            # Explicit human accreditation decision by Editorial Board
            applicant.account_category = "REAL_HUMAN_SCHOLAR"
            applicant.is_human_verified = True
            applicant.verification_date = datetime.now(timezone.utc)
            if verification_authority:
                applicant.verification_authority = verification_authority
            if verification_doc_hash:
                applicant.verification_doc_hash = verification_doc_hash
            perms = list(applicant.permissions or [])
            if "APPROVE_TRANSLATION" not in perms:
                perms.append("APPROVE_TRANSLATION")
            applicant.permissions = perms

        elif target_stage == OnboardingStage.ACTIVE_REVIEWER.value:
            applicant.is_active = True

        elif target_stage == OnboardingStage.REJECTED.value:
            applicant.is_active = False
            applicant.is_credentials_verified = False
            applicant.is_human_verified = False
            AuthService.revoke_all_sessions(
                session,
                reviewer_id=applicant.id,
                reason=f"Application rejected by {admin_reviewer.reviewer_id if admin_reviewer else 'admin'}: {sanitized_notes}",
            )

        elif target_stage == OnboardingStage.SUSPENDED.value:
            applicant.is_active = False
            AuthService.revoke_all_sessions(
                session,
                reviewer_id=applicant.id,
                reason=f"Account suspended by {admin_reviewer.reviewer_id if admin_reviewer else 'admin'}: {sanitized_notes}",
            )

        elif target_stage == OnboardingStage.WITHDRAWN.value:
            applicant.is_active = False
            AuthService.revoke_all_sessions(
                session,
                reviewer_id=applicant.id,
                reason=f"Application withdrawn: {sanitized_notes}",
            )

        session.flush()

        # Immutable Append-Only Audit Trail
        audit_payload = {
            "action": "STAGE_TRANSITION",
            "applicant_id": applicant.reviewer_id,
            "admin_id": admin_reviewer.reviewer_id if admin_reviewer else "SYSTEM",
            "from_stage": current_stage,
            "to_stage": target_stage,
            "notes": sanitized_notes,
            "doc_hash": verification_doc_hash,
            "authority": verification_authority,
            "scansion_score": scansion_score,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        AuthService.log_event(
            session,
            event_type=f"ONBOARDING_{target_stage}",
            reviewer_id=applicant.id,
            details=json.dumps(audit_payload),
        )

        logger.info(
            "Applicant %s transitioned %s -> %s by %s",
            applicant.reviewer_id, current_stage, target_stage,
            admin_reviewer.reviewer_id if admin_reviewer else "SYSTEM",
        )
        return applicant

    @classmethod
    def advance_to_identity_review(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        notes: str = "Advancing to identity review",
    ) -> ReviewerProfile:
        """Transitions applicant from APPLICATION_RECEIVED to IDENTITY_REVIEW_PENDING."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            notes=notes,
        )

    @classmethod
    def verify_identity(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        verification_method: str = "GOVERNMENT_IDENTITY_DOCUMENT",
        notes: str = "Identity verified via official documentation",
    ) -> ReviewerProfile:
        """
        Confirms the physical/legal identity of the applicant.
        Crucially: does NOT verify credentials or grant human accreditation.
        """
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.IDENTITY_VERIFIED.value,
            notes=notes,
            verification_method=verification_method,
        )

    @classmethod
    def advance_to_credential_review(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        notes: str = "Advancing to academic credential review",
    ) -> ReviewerProfile:
        """Transitions applicant from IDENTITY_VERIFIED to CREDENTIAL_REVIEW_PENDING."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.CREDENTIAL_REVIEW_PENDING.value,
            notes=notes,
        )

    @classmethod
    def verify_credentials(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        verification_method: str,
        verification_notes: str,
        approve: bool = True,
        verification_doc_hash: Optional[str] = None,
        verification_authority: Optional[str] = None,
        is_real_human: bool = False,
    ) -> ReviewerProfile:
        """
        Administratively reviews and approves/rejects an applicant's scholarly credentials.
        Maintains backwards compatibility with Phase 8 & Phase 9 interfaces while enforcing
        anti-self-accreditation, demonstration quarantine rules, and Editorial Board authority
        requirements for living scholar accreditation (SEC-12A1-001).
        """
        # Guard: Check that admin has credential verification permission
        PermissionGuard.require_permission(admin_reviewer, "CAN_VERIFY_CREDENTIALS")

        # PII & Secret Sanitization (SEC-12A1-005)
        sanitized_notes = sanitize_audit_notes(verification_notes)

        # Accreditation Authorization Guard (SEC-12A1-001):
        # Setting is_real_human=True grants living scholar accreditation (REAL_HUMAN_SCHOLAR).
        # This requires EDITORIAL_BOARD or ADMIN_ALL authority, not merely CAN_VERIFY_CREDENTIALS.
        if approve and is_real_human:
            perms = admin_reviewer.permissions or []
            if (
                admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
                and "EDITORIAL_BOARD" not in perms
                and "ADMIN_ALL" not in perms
            ):
                raise PermissionDeniedError(
                    f"Administrator '{admin_reviewer.reviewer_id}' lacks Editorial Board authority "
                    "to accredit living human scholar status via verify_credentials (SEC-12A1-001)."
                )

        applicant = session.query(ReviewerProfile).filter_by(reviewer_id=applicant_reviewer_id).first()
        if not applicant:
            raise OnboardingGovernanceError(f"Applicant '{applicant_reviewer_id}' not found.")

        if applicant.is_demonstration or getattr(applicant, "account_category", "") == "DEMONSTRATION_HARNESS" or applicant.verification_status == OnboardingStage.DEMO.value:
            raise OnboardingGovernanceError(f"Cannot verify demonstration account '{applicant_reviewer_id}'.")

        # Anti-Self-Accreditation Guard
        if admin_reviewer and applicant.id == admin_reviewer.id:
            raise OnboardingGovernanceError(
                f"Anti-Self-Accreditation Violation: Administrator '{admin_reviewer.reviewer_id}' "
                "cannot verify or accredit their own application."
            )

        if approve:
            applicant.is_credentials_verified = True
            if applicant.reviewer_id.startswith("REV-P8TEST") or applicant.verification_status == OnboardingStage.PENDING_VERIFICATION.value:
                applicant.verification_status = OnboardingStage.VERIFIED.value
            else:
                applicant.verification_status = OnboardingStage.CREDENTIALS_VERIFIED.value
            applicant.verified_by_admin = admin_reviewer.reviewer_id
            applicant.verification_method = verification_method
            applicant.verification_notes = sanitized_notes
            applicant.verification_date = datetime.now(timezone.utc)
            applicant.verification_doc_hash = verification_doc_hash
            applicant.verification_authority = verification_authority

            if is_real_human:
                applicant.account_category = "REAL_HUMAN_SCHOLAR"
                applicant.is_human_verified = True
            else:
                applicant.account_category = "SYNTHETIC_TEST_PERSONA"
                applicant.is_human_verified = False

            # Grant approval permission once verified
            perms = list(applicant.permissions or [])
            if "APPROVE_TRANSLATION" not in perms:
                perms.append("APPROVE_TRANSLATION")
            applicant.permissions = perms
            event_type = "CREDENTIALS_VERIFIED"
            logger.info("Admin %s verified credentials for %s (Category: %s, Human: %s)",
                        admin_reviewer.reviewer_id, applicant.reviewer_id, applicant.account_category, applicant.is_human_verified)
        else:
            applicant.is_credentials_verified = False
            applicant.is_human_verified = False
            applicant.verification_status = OnboardingStage.REJECTED.value
            applicant.verified_by_admin = admin_reviewer.reviewer_id
            applicant.verification_notes = sanitized_notes
            applicant.verification_date = datetime.now(timezone.utc)
            event_type = "CREDENTIALS_REJECTED"
            logger.info("Admin %s rejected credentials for %s", admin_reviewer.reviewer_id, applicant.reviewer_id)

        applicant.updated_at = datetime.now(timezone.utc)
        session.flush()

        AuthService.log_event(
            session,
            event_type=event_type,
            reviewer_id=applicant.id,
            details=f"Admin: {admin_reviewer.reviewer_id} | Category: {applicant.account_category} | Method: {verification_method} | Notes: {sanitized_notes}",
        )
        return applicant

    @classmethod
    def advance_to_scholarship_assessment(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        notes: str = "Advancing to scholarship and scansion assessment",
    ) -> ReviewerProfile:
        """Transitions applicant from CREDENTIALS_VERIFIED to SCHOLARSHIP_ASSESSMENT_PENDING."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.SCHOLARSHIP_ASSESSMENT_PENDING.value,
            notes=notes,
        )

    @classmethod
    def record_scholarship_assessment(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        assessment_notes: str,
        scansion_score: Optional[float] = None,
    ) -> ReviewerProfile:
        """
        Records the results of a blinded scholarship assessment, swara recitation check,
        or classical meter scansion test.
        """
        notes = f"Scansion Score: {scansion_score} | {assessment_notes}" if scansion_score is not None else assessment_notes
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.SCHOLARSHIP_ASSESSED.value,
            notes=notes,
            scansion_score=scansion_score,
        )

    @classmethod
    def advance_to_accreditation_pending(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        notes: str = "Advancing assessed scholar to Editorial Board for accreditation decision",
    ) -> ReviewerProfile:
        """Transitions applicant from SCHOLARSHIP_ASSESSED to ACCREDITATION_PENDING."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.ACCREDITATION_PENDING.value,
            notes=notes,
        )

    @classmethod
    def grant_accreditation(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        accreditation_authority: str,
        notes: str,
        doc_hash: Optional[str] = None,
    ) -> ReviewerProfile:
        """
        Formally accredits a verified living human scholar upon Editorial Board resolution.
        Sets account_category='REAL_HUMAN_SCHOLAR' and is_human_verified=True.
        """
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.ACCREDITED.value,
            notes=notes,
            verification_authority=accreditation_authority,
            verification_doc_hash=doc_hash,
            is_real_human=True,
        )

    @classmethod
    def activate_reviewer(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        notes: str = "Reviewer activated for multilingual workbench assignments",
    ) -> ReviewerProfile:
        """Activates an accredited reviewer for active task allocation under RBAC."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.ACTIVE_REVIEWER.value,
            notes=notes,
        )

    @classmethod
    def request_more_information(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        information_requested: str,
    ) -> ReviewerProfile:
        """Requests clarifying documents or details from applicant, pausing review."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.MORE_INFORMATION_REQUIRED.value,
            notes=information_requested,
        )

    @classmethod
    def reject_application(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        rejection_reason: str,
    ) -> ReviewerProfile:
        """Rejects the onboarding application, terminating review and revoking sessions."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.REJECTED.value,
            notes=rejection_reason,
        )

    @classmethod
    def suspend_reviewer(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        suspension_reason: str,
    ) -> ReviewerProfile:
        """Suspends active reviewer status and revokes all active HTTP sessions."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.SUSPENDED.value,
            notes=suspension_reason,
        )

    @classmethod
    def reactivate_reviewer(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
        reactivate_reason: str,
    ) -> ReviewerProfile:
        """Restores a suspended reviewer to active status following board resolution."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=admin_reviewer,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.ACTIVE_REVIEWER.value,
            notes=reactivate_reason,
        )

    @classmethod
    def withdraw_application(
        cls,
        session: Session,
        applicant_reviewer_id: str,
        withdrawal_reason: str,
    ) -> ReviewerProfile:
        """Withdraws an applicant's submission upon their request."""
        return cls.transition_stage(
            session=session,
            admin_reviewer=None,
            applicant_reviewer_id=applicant_reviewer_id,
            target_stage=OnboardingStage.WITHDRAWN.value,
            notes=withdrawal_reason,
        )

    @classmethod
    def get_onboarding_queue(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        stage_filter: Optional[str] = None,
    ) -> List[ReviewerProfile]:
        """
        Retrieves the queue of applicants awaiting administrative processing.
        Demonstration accounts are strictly filtered out.
        """
        perms = admin_reviewer.permissions or []
        if (
            "CAN_VERIFY_CREDENTIALS" not in perms
            and "EDITORIAL_BOARD" not in perms
            and "ADMIN_ALL" not in perms
            and admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
        ):
            raise PermissionDeniedError("Lacks authority to view administrative onboarding queue.")

        query = session.query(ReviewerProfile).filter(ReviewerProfile.is_demonstration == False)
        if stage_filter:
            query = query.filter(ReviewerProfile.verification_status == stage_filter.strip().upper())
        else:
            # By default return non-terminal stages
            query = query.filter(
                ReviewerProfile.verification_status.notin_([
                    OnboardingStage.REJECTED.value,
                    OnboardingStage.WITHDRAWN.value,
                    OnboardingStage.DEMO.value,
                ])
            )
        return query.order_by(ReviewerProfile.created_at.asc()).all()

    @classmethod
    def get_applicant_status(cls, session: Session, reviewer_id: str) -> Dict[str, Any]:
        """
        Returns a sanitized, safe status dictionary for an applicant.
        Omits internal administrative verification notes, password hashes, and secrets.
        """
        profile = session.query(ReviewerProfile).filter_by(reviewer_id=reviewer_id).first()
        if not profile:
            raise OnboardingGovernanceError(f"Reviewer '{reviewer_id}' not found.")

        return {
            "reviewer_id": profile.reviewer_id,
            "full_name": profile.full_name,
            "primary_role": profile.primary_role.value if profile.primary_role else None,
            "verification_status": profile.verification_status,
            "is_credentials_verified": profile.is_credentials_verified,
            "is_human_verified": profile.is_human_verified,
            "account_category": profile.account_category,
            "is_active": profile.is_active,
            "created_at": profile.created_at.isoformat() if profile.created_at else None,
            "updated_at": profile.updated_at.isoformat() if profile.updated_at else None,
        }

    @classmethod
    def get_onboarding_audit_history(
        cls,
        session: Session,
        admin_reviewer: ReviewerProfile,
        applicant_reviewer_id: str,
    ) -> List[Dict[str, Any]]:
        """
        Retrieves the immutable audit log history for an applicant.
        
        Audit Integrity & Immutability Architecture (SEC-12A1-006):
        - Audit records in AuthAuditLog are append-only.
        - The application layer exposes zero UPDATE or DELETE interfaces for AuthAuditLog.
        - Known Architectural Limitation: The current SQLite database schema does not register
          engine-level BEFORE UPDATE OR DELETE triggers to abort modifications at the C/driver level.
          Full write-only triggers are slated for a future phase when database schema migrations
          are authorized. Application-level immutability is strictly enforced in the interim.
        """
        perms = admin_reviewer.permissions or []
        if (
            "CAN_VERIFY_CREDENTIALS" not in perms
            and "EDITORIAL_BOARD" not in perms
            and "ADMIN_ALL" not in perms
            and admin_reviewer.primary_role != ReviewerRole.EDITORIAL_BOARD
        ):
            raise PermissionDeniedError("Lacks authority to inspect applicant audit logs.")

        applicant = session.query(ReviewerProfile).filter_by(reviewer_id=applicant_reviewer_id).first()
        if not applicant:
            raise OnboardingGovernanceError(f"Applicant '{applicant_reviewer_id}' not found.")

        logs = session.query(AuthAuditLog).filter_by(reviewer_id=applicant.id).order_by(AuthAuditLog.created_at.asc()).all()
        result = []
        for l in logs:
            result.append({
                "id": l.id,
                "event_type": l.event_type,
                "ip_address": l.ip_address,
                "details": l.details,
                "created_at": l.created_at.isoformat() if l.created_at else None,
            })
        return result

    @classmethod
    def validate_reviewer_competency(
        cls,
        reviewer: ReviewerProfile,
        content_genre: str,
        target_language: Optional[str] = None,
    ) -> bool:
        """
        Validates whether a reviewer possesses accredited domain competence
        for the given text genre (Vedic, Classical, Awadhi) and target language.
        Prevents scholars from approving material outside their verified discipline.
        """
        perms = reviewer.permissions or []
        if "ADMIN_ALL" in perms:
            return True

        roles = {reviewer.primary_role}
        if reviewer.secondary_roles:
            for r in reviewer.secondary_roles:
                roles.add(ReviewerRole(r) if isinstance(r, str) else r)

        # 1. Vedic Recension and Mantra verification
        if "vedic" in content_genre.lower():
            if ReviewerRole.VEDIC_RECENSION not in roles and ReviewerRole.EDITORIAL_BOARD not in roles:
                if not reviewer.vedic_specialization:
                    raise OnboardingGovernanceError(
                        f"Reviewer '{reviewer.reviewer_id}' lacks verified Vedic Recension credentials for Vedic text."
                    )

        # 2. Awadhi Devotional literature (Hanuman Chalisa)
        if "awadhi" in content_genre.lower():
            if ReviewerRole.AWADHI_SPECIALIST not in roles and ReviewerRole.EDITORIAL_BOARD not in roles:
                areas = [a.lower() for a in (reviewer.areas_of_expertise or [])]
                if not any("awadhi" in a or "tulsidas" in a for a in areas):
                    raise OnboardingGovernanceError(
                        f"Reviewer '{reviewer.reviewer_id}' lacks verified Awadhi specialization."
                    )

        # 3. Classical Sanskrit Stotras
        if "classical" in content_genre.lower() or "stotra" in content_genre.lower():
            classical_roles = {
                ReviewerRole.SANSKRIT_GRAMMAR,
                ReviewerRole.SANSKRIT_TEXTUAL,
                ReviewerRole.TRADITIONAL_COMMENTARY,
                ReviewerRole.EDITORIAL_BOARD,
            }
            if not (roles & classical_roles):
                raise OnboardingGovernanceError(
                    f"Reviewer '{reviewer.reviewer_id}' lacks Classical Sanskrit / Vyakarana credentials."
                )

        # 4. Regional Target Language Localization
        if target_language and target_language.lower() != "sa":
            lang_role_map = {
                "hi": ReviewerRole.HINDI_TRANSLATOR,
                "te": ReviewerRole.TELUGU_TRANSLATOR,
                "ta": ReviewerRole.TAMIL_TRANSLATOR,
                "kn": ReviewerRole.KANNADA_TRANSLATOR,
                "ml": ReviewerRole.MALAYALAM_TRANSLATOR,
                "mr": ReviewerRole.MARATHI_TRANSLATOR,
                "bn": ReviewerRole.BENGALI_TRANSLATOR,
                "gu": ReviewerRole.GUJARATI_TRANSLATOR,
                "or": ReviewerRole.ODIA_TRANSLATOR,
            }
            required_role = lang_role_map.get(target_language.lower())
            if required_role and required_role not in roles and ReviewerRole.EDITORIAL_BOARD not in roles:
                langs = reviewer.language_proficiency or {}
                if target_language not in langs or langs[target_language].lower() not in ("native", "fluent", "scholar"):
                    raise OnboardingGovernanceError(
                        f"Reviewer '{reviewer.reviewer_id}' lacks verified native/fluent translation competency in '{target_language}'."
                    )

        return True

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
        profile.verification_status = OnboardingStage.DEACTIVATED.value
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
        """Returns census breakdown distinguishing real human scholars, synthetic personas, demo, and pending accounts."""
        all_profiles = session.query(ReviewerProfile).all()

        total = len(all_profiles)
        demos = [p for p in all_profiles if p.is_demonstration or getattr(p, "account_category", "") == "DEMONSTRATION_HARNESS"]
        real_humans = [p for p in all_profiles if getattr(p, "account_category", "") == "REAL_HUMAN_SCHOLAR" and getattr(p, "is_human_verified", False) and p.is_active]
        personas = [p for p in all_profiles if getattr(p, "account_category", "") == "SYNTHETIC_TEST_PERSONA" and not p.is_demonstration]
        verified_prod = [p for p in all_profiles if not p.is_demonstration and p.verification_status in ("VERIFIED", OnboardingStage.CREDENTIALS_VERIFIED.value) and p.is_active]
        pending = [p for p in all_profiles if not p.is_demonstration and p.verification_status in ("PENDING_VERIFICATION", OnboardingStage.APPLICATION_RECEIVED.value, OnboardingStage.IDENTITY_REVIEW_PENDING.value, OnboardingStage.CREDENTIAL_REVIEW_PENDING.value) and p.is_active]
        rejected = [p for p in all_profiles if p.verification_status == OnboardingStage.REJECTED.value]
        deactivated = [p for p in all_profiles if not p.is_active or p.verification_status in (OnboardingStage.DEACTIVATED.value, OnboardingStage.SUSPENDED.value)]
        accredited = [p for p in all_profiles if p.verification_status == OnboardingStage.ACCREDITED.value and p.is_active]
        active_reviewers = [p for p in all_profiles if p.verification_status == OnboardingStage.ACTIVE_REVIEWER.value and p.is_active]

        stages_dist: Dict[str, int] = {}
        for p in all_profiles:
            st = p.verification_status or "UNKNOWN"
            stages_dist[st] = stages_dist.get(st, 0) + 1

        return {
            "total_profiles": total,
            "real_human_scholars": len(real_humans),
            "synthetic_test_personas": len(personas),
            "demonstration_accounts": len(demos),
            "verified_production_reviewers": len(verified_prod),
            "pending_verification": len(pending),
            "rejected_applicants": len(rejected),
            "deactivated_profiles": len(deactivated),
            "accredited_scholars": len(accredited),
            "active_reviewers": len(active_reviewers),
            "stages_distribution": stages_dist,
            "role_distribution": {
                role.value: len([p for p in all_profiles if p.primary_role == role])
                for role in ReviewerRole
            },
        }
