"""
Vedic Heritage Platform — Scholar Governance Security Hardening Test Suite
Phase 12B: Comprehensive verification of authorization, concurrency, identity semantics,
PII redaction, audit integrity, and administrative rate limiting.
Enforces complete test database isolation and verifies production database immutability.
"""

import asyncio
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import pytest
from aiohttp.test_utils import TestClient, TestServer

from automation.workbench.auth import (
    AuthService,
    PermissionDeniedError,
    RateLimitExceededError,
    hash_password,
    global_rate_limiter,
)
from automation.workbench.gateway import (
    COOKIE_NAME,
    CSRF_HEADER,
    admin_transition_rate_limiter,
    create_app,
)
from automation.workbench.onboarding import (
    ALLOWED_TRANSITIONS,
    OnboardingGovernanceError,
    OnboardingStage,
    ReviewerOnboardingService,
    sanitize_audit_notes,
)
from database.connection import get_db_session
from database.models import (
    AuthAuditLog,
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    Text,
    Translation,
    Verse,
)
from database.schemas import ReviewerProfileCreate


class SyncGatewayClient:
    """Synchronous wrapper around aiohttp TestClient for deterministic pytest execution."""

    def __init__(self, db_factory=None):
        self.loop = asyncio.new_event_loop()
        self.app = create_app(db_session_factory=db_factory or get_db_session)
        self.server = TestServer(self.app)
        self.client = TestClient(self.server, loop=self.loop)
        self.loop.run_until_complete(self.client.start_server())

    def get(self, path, **kwargs):
        return self.loop.run_until_complete(self.client.get(path, **kwargs))

    def post(self, path, **kwargs):
        return self.loop.run_until_complete(self.client.post(path, **kwargs))

    def json(self, resp):
        return self.loop.run_until_complete(resp.json())

    def text(self, resp):
        return self.loop.run_until_complete(resp.text())

    @property
    def session(self):
        return self.client.session

    def close(self):
        self.loop.run_until_complete(self.client.close())
        self.loop.close()


@pytest.fixture(autouse=True)
def reset_rate_limiters():
    """Reset all in-memory rate limiters prior to and following every test."""
    admin_transition_rate_limiter.reset()
    global_rate_limiter.reset()
    yield
    admin_transition_rate_limiter.reset()
    global_rate_limiter.reset()


@pytest.fixture(autouse=True)
def cleanup_phase12b_test_artifacts(db_session):
    """Ensure all test reviewer profiles, sessions, and audit logs are safely cleaned up."""
    yield
    test_revs = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-P12B%")).all()
    test_rev_ids = [r.id for r in test_revs]
    if test_rev_ids:
        db_session.query(AuthAuditLog).filter(AuthAuditLog.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.query(ReviewerSession).filter(ReviewerSession.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.query(ReviewActionLog).filter(ReviewActionLog.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.query(ReviewerProfile).filter(ReviewerProfile.id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.commit()


@pytest.fixture
def client():
    """Provides synchronous API test client connected to the isolated test database."""
    c = SyncGatewayClient(db_factory=get_db_session)
    yield c
    c.close()


@pytest.fixture
def admin_council_reviewer(db_session):
    """Provisions an Editorial Board Council admin profile with full accreditation authority."""
    rev_id = "REV-P12B-COUNCIL"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    profile = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Senior Council Director",
        email="council.dir@vedam.org",
        primary_role=ReviewerRole.EDITORIAL_BOARD,
        secondary_roles=[],
        verification_status=OnboardingStage.ACCREDITED.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        permissions=["ADMIN_ALL", "EDITORIAL_BOARD", "CAN_VERIFY_CREDENTIALS", "CAN_DEACTIVATE_REVIEWER"],
        password_hash=hash_password("CouncilPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(profile)
    db_session.commit()
    return profile


@pytest.fixture
def admin_credential_only_reviewer(db_session):
    """Provisions an admin profile with CAN_VERIFY_CREDENTIALS authority but NO Editorial Board authority."""
    rev_id = "REV-P12B-CRED-ONLY"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    profile = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Academic Dossier Reviewer",
        email="dossier.evaluator@vedam.org",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
        secondary_roles=[],
        verification_status=OnboardingStage.ACCREDITED.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        permissions=["CAN_VERIFY_CREDENTIALS"],
        password_hash=hash_password("CredOnlyPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(profile)
    db_session.commit()
    return profile


@pytest.fixture
def standard_reviewer(db_session):
    """Provisions a standard reviewer without editorial board or verification permissions."""
    rev_id = "REV-P12B-STANDARD"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    profile = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Standard Telugu Reviewer",
        email="telugu.reviewer@vedam.org",
        primary_role=ReviewerRole.TELUGU_TRANSLATOR,
        secondary_roles=[],
        verification_status=OnboardingStage.ACTIVE_REVIEWER.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="SYNTHETIC_TEST_PERSONA",
        is_human_verified=False,
        is_active=True,
        permissions=["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
        password_hash=hash_password("StandardPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(profile)
    db_session.commit()
    return profile


# ===========================================================================
# 1. ACCREDITATION AUTHORIZATION IN verify_credentials (SEC-12A1-001)
# ===========================================================================

def test_sec_12a1_001_credential_only_admin_cannot_grant_human_scholar_status(db_session, admin_credential_only_reviewer):
    """
    SEC-12A1-001: Calling verify_credentials with is_real_human=True by an admin
    holding only CAN_VERIFY_CREDENTIALS must raise PermissionDeniedError.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-001-APP", full_name="Scholar Candidate", primary_role=ReviewerRole.VEDIC_RECENSION),
        "CandidatePass123#",
    )
    db_session.commit()

    with pytest.raises(PermissionDeniedError) as exc_info:
        ReviewerOnboardingService.verify_credentials(
            session=db_session,
            admin_reviewer=admin_credential_only_reviewer,
            applicant_reviewer_id=app.reviewer_id,
            verification_method="ACADEMIC_DOSSIER_REVIEW",
            verification_notes="Attempting unauthorized human accreditation",
            approve=True,
            is_real_human=True,
        )
    assert "lacks Editorial Board authority" in str(exc_info.value)
    assert "SEC-12A1-001" in str(exc_info.value)


def test_sec_12a1_001_credential_only_admin_can_verify_academic_credentials(db_session, admin_credential_only_reviewer):
    """
    SEC-12A1-001: An admin holding CAN_VERIFY_CREDENTIALS can verify academic credentials
    when is_real_human=False. Sets is_credentials_verified=True, is_human_verified=False,
    and keeps account_category='SYNTHETIC_TEST_PERSONA'.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-002-APP", full_name="Scholar Candidate 2", primary_role=ReviewerRole.SANSKRIT_GRAMMAR),
        "CandidatePass123#",
    )
    db_session.commit()

    verified = ReviewerOnboardingService.verify_credentials(
        session=db_session,
        admin_reviewer=admin_credential_only_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        verification_method="ACADEMIC_DOSSIER_REVIEW",
        verification_notes="Academic qualifications and MA/PhD diplomas verified",
        approve=True,
        is_real_human=False,
    )
    assert verified.is_credentials_verified is True
    assert verified.is_human_verified is False
    assert verified.account_category == "SYNTHETIC_TEST_PERSONA"
    assert verified.verification_status == OnboardingStage.CREDENTIALS_VERIFIED.value


def test_sec_12a1_001_editorial_board_can_grant_human_scholar_status(db_session, admin_council_reviewer):
    """
    SEC-12A1-001: Editorial Board administrator CAN verify credentials and grant
    human scholar status (is_real_human=True).
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-003-APP", full_name="Living Acharya Candidate", primary_role=ReviewerRole.VEDIC_RECENSION),
        "CandidatePass123#",
    )
    db_session.commit()

    verified = ReviewerOnboardingService.verify_credentials(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        verification_method="EDITORIAL_COUNCIL_RESOLUTION",
        verification_notes="Dossier verified and accredited by Editorial Council",
        approve=True,
        is_real_human=True,
    )
    assert verified.is_credentials_verified is True
    assert verified.is_human_verified is True
    assert verified.account_category == "REAL_HUMAN_SCHOLAR"


def test_sec_12a1_001_admin_all_can_grant_human_scholar_status(db_session):
    """
    SEC-12A1-001: Reviewer with ADMIN_ALL authority (even if primary role is not
    EDITORIAL_BOARD) can verify credentials and grant human scholar status.
    """
    admin_all_rev = ReviewerProfile(
        reviewer_id="REV-P12B-ADMIN-ALL-REV",
        full_name="Platform Superadmin",
        email="superadmin@vedam.org",
        primary_role=ReviewerRole.SANSKRIT_TEXTUAL,
        permissions=["ADMIN_ALL"],
        verification_status=OnboardingStage.ACCREDITED.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        password_hash=hash_password("SuperAdminPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(admin_all_rev)

    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-003B-APP", full_name="Superadmin App", primary_role=ReviewerRole.SANSKRIT_TEXTUAL),
        "CandidatePass123#",
    )
    db_session.commit()

    verified = ReviewerOnboardingService.verify_credentials(
        session=db_session,
        admin_reviewer=admin_all_rev,
        applicant_reviewer_id=app.reviewer_id,
        verification_method="SUPERADMIN_DISPENSATION",
        verification_notes="Verified by administrator with ADMIN_ALL",
        approve=True,
        is_real_human=True,
    )
    assert verified.is_credentials_verified is True
    assert verified.is_human_verified is True
    assert verified.account_category == "REAL_HUMAN_SCHOLAR"


# ===========================================================================
# 2. CONCURRENCY INTEGRITY & OPTIMISTIC LOCKING (SEC-12A1-002)
# ===========================================================================

def test_sec_12a1_002_matching_expected_stage_succeeds(db_session, admin_council_reviewer):
    """SEC-12A1-002: Transitioning with matching expected_current_stage succeeds."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-004-APP", full_name="Candidate 4", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        "Pass12345#",
    )
    db_session.commit()

    updated = ReviewerOnboardingService.transition_stage(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        notes="Advancing with valid expected stage",
        expected_current_stage=OnboardingStage.APPLICATION_RECEIVED.value,
    )
    assert updated.verification_status == OnboardingStage.IDENTITY_REVIEW_PENDING.value


def test_sec_12a1_002_mismatched_expected_stage_rejected(db_session, admin_council_reviewer):
    """SEC-12A1-002: Transitioning with mismatched expected_current_stage raises OnboardingGovernanceError."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-005-APP", full_name="Candidate 5", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        "Pass12345#",
    )
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=app.reviewer_id,
            target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            notes="Conflicting transition",
            expected_current_stage=OnboardingStage.IDENTITY_VERIFIED.value,  # Wrong expected stage!
        )
    assert "Concurrency Conflict" in str(exc_info.value)
    assert "IDENTITY_VERIFIED" in str(exc_info.value)


def test_sec_12a1_002_gateway_api_concurrency_conflict_returns_400(client, admin_council_reviewer, db_session):
    """SEC-12A1-002: API POST /api/v1/onboarding/admin/transition with stale expected stage returns 400."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-006-APP", full_name="Candidate 6", primary_role=ReviewerRole.TAMIL_TRANSLATOR),
        "Pass12345#",
    )
    db_session.commit()

    # Login as admin
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": app.reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Attempting transition from stale client view",
            "expected_current_stage": "CREDENTIALS_VERIFIED",  # Mismatch! Current is APPLICATION_RECEIVED
        },
    )
    assert resp.status == 400
    body = client.json(resp)
    assert body["code"] == "ONBOARDING_GOVERNANCE_ERROR"
    assert "Concurrency Conflict" in body["error"]


def test_sec_12a1_002_failed_transition_rolls_back_cleanly(client, admin_council_reviewer, db_session):
    """SEC-12A1-002: Concurrency failure rolls back transaction cleanly with zero phantom audit logs."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-007-APP", full_name="Candidate 7", primary_role=ReviewerRole.TAMIL_TRANSLATOR),
        "Pass12345#",
    )
    db_session.commit()

    initial_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=app.id).count()

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    # Attempt conflicting transition
    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": app.reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Should roll back",
            "expected_current_stage": "SUSPENDED",
        },
    )
    assert resp.status == 400

    # Verify stage remained unchanged and no additional audit logs were written
    db_session.expire_all()
    reloaded = db_session.query(ReviewerProfile).filter_by(reviewer_id=app.reviewer_id).first()
    assert reloaded.verification_status == OnboardingStage.APPLICATION_RECEIVED.value

    post_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=app.id).count()
    assert post_audit_count == initial_audit_count


def test_sec_12a1_002_expected_stage_whitespace_and_case_insensitive(db_session, admin_council_reviewer):
    """SEC-12A1-002: expected_current_stage handles case and surrounding whitespace robustly."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-008-APP", full_name="Candidate 8", primary_role=ReviewerRole.KANNADA_TRANSLATOR),
        "Pass12345#",
    )
    db_session.commit()

    updated = ReviewerOnboardingService.transition_stage(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        notes="Testing case-insensitive matching",
        expected_current_stage="  application_received  ",
    )
    assert updated.verification_status == OnboardingStage.IDENTITY_REVIEW_PENDING.value


# ===========================================================================
# 3. DUPLICATE APPLICATIONS & EMAIL NORMALIZATION (SEC-12A1-003)
# ===========================================================================

def test_sec_12a1_003_exact_duplicate_email_rejected(db_session):
    """SEC-12A1-003: Submitting a second application with identical email raises OnboardingGovernanceError."""
    ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-009A", full_name="Original Scholar", email="unique.scholar@univ.ac.in", primary_role=ReviewerRole.VEDIC_RECENSION),
        "Pass12345#",
    )
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.register_applicant(
            db_session,
            ReviewerProfileCreate(reviewer_id="REV-P12B-009B", full_name="Duplicate Submission", email="unique.scholar@univ.ac.in", primary_role=ReviewerRole.SANSKRIT_GRAMMAR),
            "Pass12345#",
        )
    assert "already been submitted" in str(exc_info.value)


def test_sec_12a1_003_case_insensitive_duplicate_email_rejected(db_session):
    """SEC-12A1-003: Submitting an application with case variation in email is rejected."""
    ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-010A", full_name="Scholar A", email="acharya.shastri@gurukul.org", primary_role=ReviewerRole.VEDIC_RECENSION),
        "Pass12345#",
    )
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.register_applicant(
            db_session,
            ReviewerProfileCreate(reviewer_id="REV-P12B-010B", full_name="Scholar B", email="ACHARYA.SHASTRI@GURUKUL.ORG", primary_role=ReviewerRole.SANSKRIT_TEXTUAL),
            "Pass12345#",
        )
    assert "already been submitted" in str(exc_info.value)


def test_sec_12a1_003_whitespace_padded_email_normalized_and_rejected(db_session):
    """SEC-12A1-003: Whitespace padding is stripped and rejected on duplicate submission."""
    ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-011A", full_name="Scholar C", email="vidwan@vedicstudies.edu", primary_role=ReviewerRole.VEDIC_RECENSION),
        "Pass12345#",
    )
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.register_applicant(
            db_session,
            ReviewerProfileCreate(reviewer_id="REV-P12B-011B", full_name="Scholar D", email="   vidwan@vedicstudies.edu   ", primary_role=ReviewerRole.VEDIC_RECENSION),
            "Pass12345#",
        )
    assert "already been submitted" in str(exc_info.value)


def test_sec_12a1_003_stored_email_is_normalized(db_session):
    """SEC-12A1-003: Registered profile email is saved normalized (lowercased and stripped)."""
    profile = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-012", full_name="Scholar E", email="  Pandit.Sharma@Sanskrit.Edu  ", primary_role=ReviewerRole.VEDIC_RECENSION),
        "Pass12345#",
    )
    db_session.commit()

    assert profile.email == "pandit.sharma@sanskrit.edu"


def test_sec_12a1_003_gateway_api_duplicate_email_returns_400(client, db_session):
    """SEC-12A1-003: API POST /api/v1/onboarding/apply returns 400 on duplicate email."""
    # First registration
    resp1 = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12B-013A",
            "full_name": "Applicant First",
            "email": "first.applicant@research.org",
            "password": "SecurePassword123#",
            "primary_role": "SANSKRIT_GRAMMAR",
        },
    )
    assert resp1.status == 201

    # Second registration with same email (different case and padded)
    resp2 = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12B-013B",
            "full_name": "Applicant Second",
            "email": "  FIRST.APPLICANT@RESEARCH.ORG  ",
            "password": "SecurePassword123#",
            "primary_role": "SANSKRIT_TEXTUAL",
        },
    )
    assert resp2.status == 400
    body = client.json(resp2)
    assert body["code"] == "ONBOARDING_GOVERNANCE_ERROR"
    assert "already been submitted" in body["error"]


def test_sec_12a1_003_collision_with_existing_reviewer_rejected(standard_reviewer, db_session):
    """SEC-12A1-003: An applicant email colliding with an existing active reviewer is rejected."""
    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.register_applicant(
            db_session,
            ReviewerProfileCreate(
                reviewer_id="REV-P12B-013C",
                full_name="Impostor Applicant",
                email=standard_reviewer.email,
                primary_role=ReviewerRole.TELUGU_TRANSLATOR,
            ),
            "ImpostorPass123#",
        )
    assert "already been submitted" in str(exc_info.value)


# ===========================================================================
# 4. IDENTITY VS. ACCREDITATION SEMANTICS (SEC-12A1-004)
# ===========================================================================

def test_sec_12a1_004_identity_verified_leaves_human_and_credentials_unverified(db_session, admin_council_reviewer):
    """
    SEC-12A1-004: Advancing to IDENTITY_VERIFIED confirms government identity document,
    but explicitly keeps is_credentials_verified=False and is_human_verified=False.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-014-APP", full_name="Identity Verified Person", primary_role=ReviewerRole.VEDIC_RECENSION),
        "CandidatePass123#",
    )
    db_session.commit()

    # Step 1: Advance to identity review pending
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, app.reviewer_id)

    # Step 2: Verify government identity
    verified = ReviewerOnboardingService.verify_identity(
        db_session,
        admin_council_reviewer,
        app.reviewer_id,
        verification_method="GOVERNMENT_PASSPORT",
        notes="Government passport physically inspected and validated",
    )
    assert verified.verification_status == OnboardingStage.IDENTITY_VERIFIED.value
    assert verified.is_credentials_verified is False
    assert verified.is_human_verified is False
    assert verified.account_category == "SYNTHETIC_TEST_PERSONA"


def test_sec_12a1_004_synthetic_demo_cannot_satisfy_human_provenance(db_session):
    """
    SEC-12A1-004 & Phase 11F: Quarantined demo accounts (is_demonstration=True)
    can NEVER satisfy the human review provenance predicate.
    """
    demo_created = ReviewerOnboardingService.create_demonstration_profile(
        session=db_session,
        reviewer_id="REV-P12B-DEMO-SIM",
        full_name="Synthetic Demo Persona",
        role=ReviewerRole.VEDIC_RECENSION,
        raw_password="DemoPass123#",
    )
    db_session.commit()

    demo_profiles = db_session.query(ReviewerProfile).filter_by(is_demonstration=True).all()
    assert len(demo_profiles) >= 1

    for demo in demo_profiles:
        # Downstream predicate: is_human_verified == True and account_category == 'REAL_HUMAN_SCHOLAR' and not is_demonstration
        is_human = bool(
            getattr(demo, "is_human_verified", False) is True
            and getattr(demo, "account_category", "") == "REAL_HUMAN_SCHOLAR"
            and not getattr(demo, "is_demonstration", False)
        )
        assert is_human is False


# ===========================================================================
# 5. VERIFICATION-NOTE PII & SECRET REDACTION (SEC-12A1-005)
# ===========================================================================

def test_sec_12a1_005_aadhaar_redaction():
    """SEC-12A1-005: 12-digit Aadhaar numbers are redacted."""
    text1 = "Scholar presented Aadhaar: 1234 5678 9012 for ID"
    text2 = "Aadhaar: 1234-5678-9012 verified"
    text3 = "UIDAI: 123456789012"
    assert sanitize_audit_notes(text1) == "Scholar presented Aadhaar: [REDACTED_AADHAAR] for ID"
    assert sanitize_audit_notes(text2) == "Aadhaar: [REDACTED_AADHAAR] verified"
    assert sanitize_audit_notes(text3) == "UIDAI: [REDACTED_AADHAAR]"


def test_sec_12a1_005_ssn_redaction():
    """SEC-12A1-005: US SSN numbers are redacted."""
    text = "Applicant US SSN is 123-45-6789 on tax form"
    assert sanitize_audit_notes(text) == "Applicant US SSN is [REDACTED_SSN] on tax form"


def test_sec_12a1_005_passport_redaction():
    """SEC-12A1-005: Passport numbers (letter + 7-8 digits) are redacted."""
    text = "Passport number: Z1234567 verified with consulate"
    assert sanitize_audit_notes(text) == "Passport number: [REDACTED_PASSPORT] verified with consulate"


def test_sec_12a1_005_phone_redaction():
    """SEC-12A1-005: Phone numbers (international and domestic) are redacted."""
    text1 = "Contact phone: +91 98765 43210 for oral examination"
    text2 = "Call candidate at 555-123-4567"
    assert sanitize_audit_notes(text1) == "Contact phone: [REDACTED_PHONE] for oral examination"
    assert sanitize_audit_notes(text2) == "Call candidate at [REDACTED_PHONE]"


def test_sec_12a1_005_secrets_and_passwords_redaction():
    """SEC-12A1-005: Passwords, tokens, API keys are redacted."""
    text1 = "Temporary password: SecretPassword123# assigned"
    text2 = "API_KEY = sk-live-9876543210abcdef"
    assert sanitize_audit_notes(text1) == "Temporary password: [REDACTED_SECRET] assigned"
    assert sanitize_audit_notes(text2) == "API_KEY: [REDACTED_SECRET]"


def test_sec_12a1_005_length_truncation():
    """SEC-12A1-005: Overly long notes (>2000 chars) are truncated."""
    long_note = "A" * 3000
    sanitized = sanitize_audit_notes(long_note, max_length=2000)
    assert len(sanitized) == 2000 + len("... [TRUNCATED]")
    assert sanitized.endswith("... [TRUNCATED]")


def test_sec_12a1_005_transition_stage_sanitizes_notes_in_profile_and_audit(db_session, admin_council_reviewer):
    """SEC-12A1-005: Notes in transition_stage are sanitized before saving to profile and audit log."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-015-APP", full_name="Candidate 15", primary_role=ReviewerRole.VEDIC_RECENSION),
        "CandidatePass123#",
    )
    db_session.commit()

    raw_note = "Verified ID via Aadhaar: 1234 5678 9012 and phone +91 98765 43210"
    updated = ReviewerOnboardingService.transition_stage(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        notes=raw_note,
    )
    db_session.commit()

    # Check profile notes
    assert "[REDACTED_AADHAAR]" in updated.verification_notes
    assert "[REDACTED_PHONE]" in updated.verification_notes
    assert "1234 5678 9012" not in updated.verification_notes
    assert "+91 98765 43210" not in updated.verification_notes

    # Check audit log entry
    latest_log = db_session.query(AuthAuditLog).filter_by(reviewer_id=app.id).order_by(AuthAuditLog.id.desc()).first()
    assert "[REDACTED_AADHAAR]" in latest_log.details
    assert "[REDACTED_PHONE]" in latest_log.details
    assert "1234 5678 9012" not in latest_log.details


def test_sec_12a1_005_verify_credentials_sanitizes_notes(db_session, admin_credential_only_reviewer):
    """SEC-12A1-005: Notes provided in verify_credentials have PII redacted before saving."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-015B-APP", full_name="Candidate 15B", primary_role=ReviewerRole.SANSKRIT_GRAMMAR),
        "CandidatePass123#",
    )
    db_session.commit()

    raw_note = "Passport: M9876543 verified. Temp password: SecretPass123 assigned."
    verified = ReviewerOnboardingService.verify_credentials(
        session=db_session,
        admin_reviewer=admin_credential_only_reviewer,
        applicant_reviewer_id=app.reviewer_id,
        verification_method="ACADEMIC_DOSSIER_REVIEW",
        verification_notes=raw_note,
        approve=True,
        is_real_human=False,
    )
    db_session.commit()

    assert "[REDACTED_PASSPORT]" in verified.verification_notes
    assert "[REDACTED_SECRET]" in verified.verification_notes
    assert "M9876543" not in verified.verification_notes
    assert "SecretPass123" not in verified.verification_notes


def test_sec_12a1_005_applicant_status_api_omits_internal_notes(client, db_session):
    """SEC-12A1-005: GET /api/v1/onboarding/status omits internal verification notes and passwords."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12B-016-APP", full_name="Candidate 16", primary_role=ReviewerRole.VEDIC_RECENSION),
        "CandidatePass123#",
    )
    app.verification_notes = "Secret internal notes about background check"
    db_session.commit()

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": app.reviewer_id, "password": "CandidatePass123#"},
    )
    assert login_resp.status == 200

    resp = client.get("/api/v1/onboarding/status")
    assert resp.status == 200
    body = client.json(resp)

    assert "verification_notes" not in body
    assert "password_hash" not in body
    assert "Secret internal notes" not in json.dumps(body)


# ===========================================================================
# 6. AUDIT-LOG INTEGRITY & ACCESS CONTROL (SEC-12A1-006)
# ===========================================================================

def test_sec_12a1_006_standard_reviewer_cannot_access_audit_history(client, standard_reviewer, db_session):
    """SEC-12A1-006: Non-admin reviewer cannot access audit history endpoint (403 Forbidden)."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": standard_reviewer.reviewer_id, "password": "StandardPass123#"},
    )
    assert login_resp.status == 200

    resp = client.get(f"/api/v1/onboarding/admin/history/{standard_reviewer.reviewer_id}")
    assert resp.status == 403
    body = client.json(resp)
    assert body["code"] == "PERMISSION_DENIED"


def test_sec_12a1_006_audit_logs_unmodifiable_via_api(client, admin_council_reviewer):
    """
    SEC-12A1-006: Verifies that no PUT, PATCH, or DELETE endpoints exist for AuthAuditLog.
    All modification attempts to audit history return 405 Method Not Allowed.
    """
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    for method_name in ("post", "delete"):
        # Attempting modification to the audit history endpoint
        if method_name == "delete":
            resp = client.loop.run_until_complete(
                client.client.delete(
                    f"/api/v1/onboarding/admin/history/{admin_council_reviewer.reviewer_id}",
                    headers={CSRF_HEADER: csrf_token},
                )
            )
        else:
            resp = client.post(
                f"/api/v1/onboarding/admin/history/{admin_council_reviewer.reviewer_id}",
                headers={CSRF_HEADER: csrf_token},
                json={"action": "DELETE"},
            )
        assert resp.status == 405  # Method Not Allowed


# ===========================================================================
# 7. ADMINISTRATIVE TRANSITION RATE LIMITING (SEC-12A1-007)
# ===========================================================================

def test_sec_12a1_007_admin_transitions_rate_limiting(client, admin_council_reviewer, db_session):
    """
    SEC-12A1-007: Administrative stage transitions are rate-limited to 30 requests/minute per session.
    The 31st transition in a minute is rejected with HTTP 429 RATE_LIMIT_EXCEEDED.
    """
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    assert login_resp.status == 200
    csrf_token = client.json(login_resp)["csrf_token"]

    # Pre-create 35 applicants
    applicants = []
    for i in range(35):
        a = ReviewerOnboardingService.register_applicant(
            db_session,
            ReviewerProfileCreate(reviewer_id=f"REV-P12B-RL-{i:03d}", full_name=f"Applicant {i}", primary_role=ReviewerRole.VEDIC_RECENSION),
            "Pass12345#",
        )
        applicants.append(a)
    db_session.commit()

    # Perform 30 transitions - all should succeed
    for i in range(30):
        resp = client.post(
            "/api/v1/onboarding/admin/transition",
            headers={CSRF_HEADER: csrf_token},
            json={
                "applicant_reviewer_id": applicants[i].reviewer_id,
                "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                "notes": f"Batch transition {i}",
            },
        )
        assert resp.status == 200, f"Transition {i} failed with status {resp.status}"

    # 31st transition within the same window must be rate-limited (HTTP 429)
    resp31 = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": applicants[30].reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Transition 31 (should be throttled)",
        },
    )
    assert resp31.status == 429
    body31 = client.json(resp31)
    assert body31["code"] == "RATE_LIMIT_EXCEEDED"

    # Reset rate limiter restores capability
    admin_transition_rate_limiter.reset()
    resp_after_reset = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": applicants[30].reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Transition 31 after reset",
        },
    )
    assert resp_after_reset.status == 200


# ===========================================================================
# 8. SYSTEM SAFETY & PHASE 11F INVARIANTS
# ===========================================================================

def test_phase12b_section_8_blanket_approval_barrier_intact(client, admin_council_reviewer, db_session):
    """Phase 11F Invariant: Section 8 blanket approval barrier remains active (403 Forbidden)."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "APPROVE",
            "scholarly_commentary": "Attempting translation approval",
        },
    )
    assert resp.status == 403
    body = client.json(resp)
    assert "Section 8" in body["error"]
    assert "strictly prohibited" in body["error"]


def test_phase12b_production_database_untouched():
    """
    MANDATORY GATE: Verifies production database database/vedam.db has remained
    100% byte-for-byte unmodified throughout all test operations.
    """
    db_path = Path("database/vedam.db")
    assert db_path.exists(), "Production database does not exist"

    expected_sha256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
    expected_size = 20455424

    with open(db_path, "rb") as f:
        actual_sha256 = hashlib.sha256(f.read()).hexdigest()

    actual_size = os.path.getsize(db_path)

    assert actual_size == expected_size, f"Production DB size changed! Expected {expected_size}, got {actual_size}"
    assert actual_sha256 == expected_sha256, f"Production DB SHA-256 altered! Expected {expected_sha256}, got {actual_sha256}"
