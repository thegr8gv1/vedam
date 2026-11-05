"""
Phase 12A: Authentic Scholar Onboarding and Accreditation Readiness Test Suite
Verifies all 30 mandatory security, lifecycle, RBAC, and data protection scenarios
under complete test database isolation.
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
    hash_password,
    PermissionDeniedError,
)
from automation.workbench.gateway import (
    COOKIE_NAME,
    CSRF_HEADER,
    create_app,
)
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from automation.workbench.onboarding import (
    ALLOWED_TRANSITIONS,
    OnboardingGovernanceError,
    OnboardingStage,
    ReviewerOnboardingService,
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
def cleanup_phase12a_test_artifacts(db_session):
    """Ensure all test reviewer profiles, sessions, and audit logs are safely cleaned up."""
    yield
    test_revs = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-P12A%")).all()
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
    rev_id = "REV-P12A-ADMIN-COUNCIL"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    profile = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Senior Acharya Council Director",
        email="council.director@vedam.org",
        primary_role=ReviewerRole.EDITORIAL_BOARD,
        secondary_roles=[],
        verification_status=OnboardingStage.ACCREDITED.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        permissions=["ADMIN_ALL", "EDITORIAL_BOARD", "CAN_VERIFY_CREDENTIALS", "CAN_DEACTIVATE_REVIEWER"],
        password_hash=hash_password("AdminCouncilPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(profile)
    db_session.commit()
    return profile


@pytest.fixture
def standard_reviewer(db_session):
    """Provisions a standard reviewer without editorial board or verification permissions."""
    rev_id = "REV-P12A-STANDARD-REV"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    profile = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Standard Junior Reviewer",
        email="junior.reviewer@vedam.org",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        secondary_roles=[],
        verification_status=OnboardingStage.ACTIVE_REVIEWER.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="SYNTHETIC_TEST_PERSONA",
        is_human_verified=False,
        is_active=True,
        permissions=["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"],
        password_hash=hash_password("JuniorPass123#"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(profile)
    db_session.commit()
    return profile


# ===========================================================================
# GROUP 1: APPLICATION LIFECYCLE TESTS (SCENARIOS 1 - 8)
# ===========================================================================

def test_scenario_01_applicant_starts_in_application_received_stage(db_session):
    """Scenario 1: New applicant starts in APPLICATION_RECEIVED stage with unverified credentials."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-001",
        full_name="Dr. Candidate Vidwan",
        email="candidate.vidwan@univ.edu",
        primary_role=ReviewerRole.VEDIC_RECENSION,
        academic_qualifications="PhD in Vedic Exegesis",
        institutional_affiliation="National Sanskrit University",
    )
    applicant = ReviewerOnboardingService.register_applicant(
        session=db_session,
        application_data=app_data,
        raw_password="CandidatePass123#",
    )
    db_session.commit()

    assert applicant.verification_status == OnboardingStage.APPLICATION_RECEIVED.value
    assert applicant.is_credentials_verified is False
    assert applicant.is_human_verified is False
    assert applicant.account_category == "SYNTHETIC_TEST_PERSONA"
    assert applicant.is_demonstration is False
    assert applicant.is_active is True
    assert applicant.permissions == ["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"]


def test_scenario_02_cannot_skip_identity_review_stage(db_session, admin_council_reviewer):
    """Scenario 2: Applicant in APPLICATION_RECEIVED cannot jump straight to credentials or accreditation."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-002",
        full_name="Dr. Impatient Scholar",
        primary_role=ReviewerRole.SANSKRIT_TEXTUAL,
    )
    applicant = ReviewerOnboardingService.register_applicant(
        session=db_session,
        application_data=app_data,
        raw_password="ImpatientPass123#",
    )
    db_session.commit()

    # Attempting to bypass identity review directly to CREDENTIAL_REVIEW_PENDING must fail
    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=applicant.reviewer_id,
            target_stage=OnboardingStage.CREDENTIAL_REVIEW_PENDING.value,
            notes="Attempting bypass",
        )
    assert "Invalid stage transition" in str(exc_info.value)

    # Attempting to jump directly to ACCREDITED must fail
    with pytest.raises(OnboardingGovernanceError):
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=applicant.reviewer_id,
            target_stage=OnboardingStage.ACCREDITED.value,
            notes="Attempting direct accreditation",
        )


def test_scenario_03_identity_verification_does_not_verify_credentials_or_grant_human_verification(db_session, admin_council_reviewer):
    """Scenario 3: Identity verification confirms physical personhood but explicitly does NOT verify credentials or grant accreditation."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-003",
        full_name="Prof. Identity Verified",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
    )
    applicant = ReviewerOnboardingService.register_applicant(
        session=db_session,
        application_data=app_data,
        raw_password="IdentityPass123#",
    )

    # Move to IDENTITY_REVIEW_PENDING then IDENTITY_VERIFIED
    ReviewerOnboardingService.advance_to_identity_review(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        notes="Reviewing passport/national ID",
    )
    verified = ReviewerOnboardingService.verify_identity(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        verification_method="OFFICIAL_GOVERNMENT_ID",
        notes="Identity documents matched national registry",
    )
    db_session.commit()

    assert verified.verification_status == OnboardingStage.IDENTITY_VERIFIED.value
    assert verified.is_credentials_verified is False  # Explicit invariant!
    assert verified.is_human_verified is False        # Explicit invariant!
    assert verified.account_category == "SYNTHETIC_TEST_PERSONA"
    assert "APPROVE_TRANSLATION" not in (verified.permissions or [])


def test_scenario_04_credential_verification_does_not_grant_accreditation(db_session, admin_council_reviewer):
    """Scenario 4: Credential verification confirms academic credentials but does NOT grant living scholar accreditation."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-004",
        full_name="Prof. Credentials Checked",
        primary_role=ReviewerRole.AWADHI_SPECIALIST,
    )
    applicant = ReviewerOnboardingService.register_applicant(
        session=db_session,
        application_data=app_data,
        raw_password="CredsPass123#",
    )
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.verify_identity(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.advance_to_credential_review(db_session, admin_council_reviewer, applicant.reviewer_id)

    # Perform credential verification
    cred_verified = ReviewerOnboardingService.transition_stage(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        target_stage=OnboardingStage.CREDENTIALS_VERIFIED.value,
        notes="Verified Awadhi doctorate and publication dossier",
        verification_doc_hash="sha256:dossier9918237192",
        verification_authority="Awadhi Literary Academy",
    )
    db_session.commit()

    assert cred_verified.verification_status == OnboardingStage.CREDENTIALS_VERIFIED.value
    assert cred_verified.is_credentials_verified is True
    assert cred_verified.is_human_verified is False         # Crucial: Not yet accredited!
    assert cred_verified.account_category == "SYNTHETIC_TEST_PERSONA"


def test_scenario_05_accreditation_requires_explicit_editorial_board_decision(db_session, admin_council_reviewer, standard_reviewer):
    """Scenario 5: Accreditation requires explicit Editorial Board authority; regular reviewers cannot accredit."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-005",
        full_name="Acharya Ready for Accreditation",
        primary_role=ReviewerRole.VEDIC_RECENSION,
    )
    applicant = ReviewerOnboardingService.register_applicant(db_session, app_data, "AcharyaPass123#")
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.verify_identity(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.advance_to_credential_review(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.transition_stage(
        db_session, admin_council_reviewer, applicant.reviewer_id,
        OnboardingStage.CREDENTIALS_VERIFIED.value, "Credentials verified"
    )
    ReviewerOnboardingService.advance_to_scholarship_assessment(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.record_scholarship_assessment(
        db_session, admin_council_reviewer, applicant.reviewer_id,
        assessment_notes="100% Swara accentuation accuracy", scansion_score=1.0
    )
    ReviewerOnboardingService.advance_to_accreditation_pending(db_session, admin_council_reviewer, applicant.reviewer_id)

    # Standard reviewer attempts to grant accreditation -> MUST be rejected
    with pytest.raises(PermissionDeniedError):
        ReviewerOnboardingService.grant_accreditation(
            session=db_session,
            admin_reviewer=standard_reviewer,
            applicant_reviewer_id=applicant.reviewer_id,
            accreditation_authority="Vedam Editorial Council",
            notes="Unauthorized attempt",
        )

    # Editorial Board admin grants accreditation -> SUCCESS
    accredited = ReviewerOnboardingService.grant_accreditation(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        accreditation_authority="Vedam Editorial Council Resolution 2026-11",
        notes="Editorial Board unanimous consensus for living scholar accreditation",
        doc_hash="sha256:board_resolution_12a_doc",
    )
    db_session.commit()

    assert accredited.verification_status == OnboardingStage.ACCREDITED.value
    assert accredited.is_human_verified is True
    assert accredited.account_category == "REAL_HUMAN_SCHOLAR"
    assert accredited.verification_authority == "Vedam Editorial Council Resolution 2026-11"


def test_scenario_06_invalid_stage_transitions_rejected(db_session, admin_council_reviewer):
    """Scenario 6: Every transition outside the valid forward transition matrix is rejected."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-006",
        full_name="Test Disordered Transitions",
        primary_role=ReviewerRole.TELUGU_TRANSLATOR,
    )
    applicant = ReviewerOnboardingService.register_applicant(db_session, app_data, "DisorderedPass123#")

    invalid_targets = [
        OnboardingStage.ACTIVE_REVIEWER.value,
        OnboardingStage.ACCREDITED.value,
        OnboardingStage.SCHOLARSHIP_ASSESSED.value,
        OnboardingStage.CREDENTIALS_VERIFIED.value,
    ]
    for target in invalid_targets:
        with pytest.raises(OnboardingGovernanceError):
            ReviewerOnboardingService.transition_stage(
                session=db_session,
                admin_reviewer=admin_council_reviewer,
                applicant_reviewer_id=applicant.reviewer_id,
                target_stage=target,
                notes=f"Trying invalid jump to {target}",
            )


def test_scenario_07_rejected_applicant_cannot_activate_without_new_decision(db_session, admin_council_reviewer):
    """Scenario 7: Rejected applicant enters terminal stage and cannot activate directly."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-007",
        full_name="Rejected Applicant",
        primary_role=ReviewerRole.TAMIL_TRANSLATOR,
    )
    applicant = ReviewerOnboardingService.register_applicant(db_session, app_data, "TamilPass123#")
    rejected = ReviewerOnboardingService.reject_application(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        rejection_reason="Failed institutional credentials verification",
    )
    db_session.commit()

    assert rejected.verification_status == OnboardingStage.REJECTED.value
    assert rejected.is_active is False

    # Attempting to move from REJECTED to ACTIVE_REVIEWER or ACCREDITED must fail
    with pytest.raises(OnboardingGovernanceError):
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=applicant.reviewer_id,
            target_stage=OnboardingStage.ACTIVE_REVIEWER.value,
            notes="Attempting resurrection",
        )


def test_scenario_08_suspended_reviewer_cannot_exercise_permissions(db_session, admin_council_reviewer):
    """Scenario 8: Suspended reviewer has active status cleared and active HTTP sessions revoked."""
    app_data = ReviewerProfileCreate(
        reviewer_id="REV-P12A-APP-008",
        full_name="Scholar To Be Suspended",
        primary_role=ReviewerRole.KANNADA_TRANSLATOR,
    )
    # Move through to ACCREDITED then ACTIVE_REVIEWER
    applicant = ReviewerOnboardingService.register_applicant(db_session, app_data, "KannadaPass123#")
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.verify_identity(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.advance_to_credential_review(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.transition_stage(db_session, admin_council_reviewer, applicant.reviewer_id, OnboardingStage.CREDENTIALS_VERIFIED.value, "ok")
    ReviewerOnboardingService.advance_to_scholarship_assessment(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.record_scholarship_assessment(db_session, admin_council_reviewer, applicant.reviewer_id, "ok")
    ReviewerOnboardingService.advance_to_accreditation_pending(db_session, admin_council_reviewer, applicant.reviewer_id)
    ReviewerOnboardingService.grant_accreditation(db_session, admin_council_reviewer, applicant.reviewer_id, "Board", "ok")
    ReviewerOnboardingService.activate_reviewer(db_session, admin_council_reviewer, applicant.reviewer_id)

    # Create active session via authentic authentication
    _, active_sess = AuthService.authenticate(
        session=db_session,
        reviewer_id=applicant.reviewer_id,
        raw_password="KannadaPass123#",
    )
    db_session.commit()
    assert active_sess.is_revoked is False

    # Suspend reviewer
    suspended = ReviewerOnboardingService.suspend_reviewer(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant.reviewer_id,
        suspension_reason="Ethics investigation pending",
    )
    db_session.commit()

    assert suspended.verification_status == OnboardingStage.SUSPENDED.value
    assert suspended.is_active is False

    # Verify session was revoked
    db_session.refresh(active_sess)
    assert active_sess.is_revoked is True

    # Verify revocation audit log exists
    revocation_logs = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant.id, event_type="ALL_SESSIONS_REVOKED").all()
    assert len(revocation_logs) > 0
    assert "Ethics investigation" in revocation_logs[-1].details


# ===========================================================================
# GROUP 2: AUTHORIZATION & SECURITY TESTS (SCENARIOS 9 - 21)
# ===========================================================================

def test_scenario_09_applicant_cannot_set_is_human_verified_at_registration(client, db_session):
    """Scenario 9: Registration payload attempting to assert is_human_verified=True is stripped server-side."""
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-009",
            "full_name": "Crafty Applicant",
            "password": "ValidApplicantPass123#",
            "primary_role": ReviewerRole.MARATHI_TRANSLATOR.value,
            "is_human_verified": True,  # Attacking payload
        },
    )
    assert resp.status == 201
    data = client.json(resp)
    assert data["is_human_verified"] is False

    db_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-P12A-SEC-009").first()
    assert db_profile.is_human_verified is False


def test_scenario_10_applicant_cannot_set_is_credentials_verified_at_registration(client, db_session):
    """Scenario 10: Registration payload attempting to assert is_credentials_verified=True is stripped server-side."""
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-010",
            "full_name": "Crafty Credentials Applicant",
            "password": "ValidApplicantPass123#",
            "primary_role": ReviewerRole.BENGALI_TRANSLATOR.value,
            "is_credentials_verified": True,  # Attacking payload
        },
    )
    assert resp.status == 201
    data = client.json(resp)
    assert data["is_credentials_verified"] is False

    db_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-P12A-SEC-010").first()
    assert db_profile.is_credentials_verified is False


def test_scenario_11_applicant_cannot_set_account_category_at_registration(client, db_session):
    """Scenario 11: Registration payload attempting to claim REAL_HUMAN_SCHOLAR category is stripped server-side."""
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-011",
            "full_name": "Category Spoofer",
            "password": "ValidApplicantPass123#",
            "primary_role": ReviewerRole.GUJARATI_TRANSLATOR.value,
            "account_category": "REAL_HUMAN_SCHOLAR",  # Attacking payload
        },
    )
    assert resp.status == 201
    data = client.json(resp)
    assert data["account_category"] == "SYNTHETIC_TEST_PERSONA"

    db_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-P12A-SEC-011").first()
    assert db_profile.account_category == "SYNTHETIC_TEST_PERSONA"


def test_scenario_12_applicant_cannot_elevate_permissions_at_registration(client, db_session):
    """Scenario 12: Registration payload attempting to claim administrative or approval permissions is stripped server-side."""
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-012",
            "full_name": "Privilege Escalation Applicant",
            "password": "ValidApplicantPass123#",
            "primary_role": ReviewerRole.MALAYALAM_TRANSLATOR.value,
            "permissions": ["APPROVE_TRANSLATION", "ADMIN_ALL", "CAN_VERIFY_CREDENTIALS"],
        },
    )
    assert resp.status == 201
    db_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-P12A-SEC-012").first()
    assert "ADMIN_ALL" not in db_profile.permissions
    assert "APPROVE_TRANSLATION" not in db_profile.permissions
    assert db_profile.permissions == ["REVIEW_TEXT", "SUBMIT_CORRECTIONS", "FLAG_ISSUES"]


def test_scenario_13_forged_or_invalid_registration_input_rejected(client):
    """Scenario 13: Invalid registration inputs fail closed with 400 Bad Request."""
    # Missing reviewer_id
    resp = client.post("/api/v1/onboarding/apply", json={"full_name": "Name", "password": "pass12345#"})
    assert resp.status == 400

    # Short password (< 8 chars)
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-013-SHORT",
            "full_name": "Short Pass User",
            "password": "123",
            "primary_role": ReviewerRole.HINDI_TRANSLATOR.value,
        },
    )
    assert resp.status == 400

    # Invalid primary_role
    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-SEC-013-ROLE",
            "full_name": "Invalid Role User",
            "password": "ValidPass1234#",
            "primary_role": "ASTRONOMER_SUPREME",
        },
    )
    assert resp.status == 400


def test_scenario_14_unauthorized_admin_cannot_transition_applicants(client, standard_reviewer, db_session):
    """Scenario 14: Reviewer lacking CAN_VERIFY_CREDENTIALS is denied transition capability (403 Forbidden)."""
    # Create an applicant
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12A-SEC-014-TARGET", full_name="Target App", primary_role=ReviewerRole.ODIA_TRANSLATOR),
        "TargetPass123#",
    )
    db_session.commit()

    # Login as standard reviewer
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": standard_reviewer.reviewer_id, "password": "JuniorPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": app.reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Unauthorized attempt",
        },
    )
    assert resp.status == 403
    assert "PERMISSION_DENIED" in client.json(resp)["code"]


def test_scenario_15_self_accreditation_blocked(client, admin_council_reviewer, db_session):
    """Scenario 15: Anti-Self-Accreditation Guard: administrator cannot transition or accredit their own application."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "AdminCouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={
            "applicant_reviewer_id": admin_council_reviewer.reviewer_id,
            "target_stage": OnboardingStage.ACCREDITED.value,
            "notes": "Attempting self-accreditation",
        },
    )
    assert resp.status == 403
    assert "Anti-Self-Accreditation" in client.json(resp)["error"]


def test_scenario_16_self_approval_blocked(db_session, admin_council_reviewer):
    """Scenario 16: Anti-Self-Approval Guard: accredited scholar cannot approve a translation authored by themselves."""
    trans = db_session.query(Translation).first()
    orig_translator = trans.translator
    try:
        # Set translation author to the admin reviewer's reviewer_id
        trans.translator = admin_council_reviewer.reviewer_id
        db_session.commit()

        # Enforce anti-self-approval restriction
        with pytest.raises(SelfApprovalViolationError):
            MultilingualRBACEngine.check_self_approval_restriction(admin_council_reviewer, trans)
    finally:
        trans.translator = orig_translator
        db_session.commit()


def test_scenario_17_quarantined_demonstration_accounts_cannot_be_accredited(db_session, admin_council_reviewer):
    """Scenario 17: Demonstration accounts are strictly quarantined and cannot be transitioned or accredited."""
    demo = ReviewerOnboardingService.create_demonstration_profile(
        session=db_session,
        reviewer_id="REV-P12A-DEMO-SIM",
        full_name="Synthetic Demo Persona",
        role=ReviewerRole.VEDIC_RECENSION,
        raw_password="DemoPass123#",
    )
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=demo.reviewer_id,
            target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            notes="Attempting to de-quarantine demo",
        )
    assert "Quarantined Account Protection" in str(exc_info.value)


def test_scenario_18_quarantined_accounts_cannot_satisfy_human_review_provenance(db_session):
    """Scenario 18: Quarantined demonstration account reviews strictly maintain is_human_review=False."""
    demo = db_session.query(ReviewerProfile).filter_by(is_demonstration=True).first()
    assert demo is not None

    is_human = bool(
        getattr(demo, "is_human_verified", False)
        and getattr(demo, "account_category", "") == "REAL_HUMAN_SCHOLAR"
    )
    assert is_human is False


def test_scenario_19_missing_required_transition_fields_fail_closed(client, admin_council_reviewer):
    """Scenario 19: Missing transition fields (notes, target_stage, applicant) return 400 Bad Request."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "AdminCouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    # Missing notes
    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={"applicant_reviewer_id": "REV-P12A-APP-001", "target_stage": "IDENTITY_REVIEW_PENDING"},
    )
    assert resp.status == 400

    # Missing target_stage
    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token},
        json={"applicant_reviewer_id": "REV-P12A-APP-001", "notes": "No target"},
    )
    assert resp.status == 400


def test_scenario_20_unauthenticated_api_requests_rejected(client):
    """Scenario 20: Unauthenticated requests to administrative and status endpoints are rejected (401)."""
    assert client.get("/api/v1/onboarding/status").status == 401
    assert client.get("/api/v1/onboarding/admin/queue").status == 401
    assert client.post("/api/v1/onboarding/admin/transition", json={}).status == 401
    assert client.get("/api/v1/onboarding/admin/history/REV-001").status == 401


def test_scenario_21_csrf_and_origin_checks_enforced_on_state_changing_endpoints(client, admin_council_reviewer, db_session):
    """Scenario 21: Missing/invalid CSRF tokens or spoofed Origin headers result in 403 Forbidden."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "AdminCouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    # Missing CSRF token
    resp_no_csrf = client.post(
        "/api/v1/onboarding/admin/transition",
        json={"applicant_reviewer_id": "REV-P12A-APP-001", "target_stage": "IDENTITY_REVIEW_PENDING", "notes": "test"},
    )
    assert resp_no_csrf.status == 403

    # Spoofed Origin hostname
    resp_bad_origin = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token, "Origin": "http://evil-attacker.com"},
        json={"applicant_reviewer_id": "REV-P12A-APP-001", "target_stage": "IDENTITY_REVIEW_PENDING", "notes": "test"},
    )
    assert resp_bad_origin.status == 403


# ===========================================================================
# GROUP 3: RBAC INTEGRATION TESTS (SCENARIOS 22 - 26)
# ===========================================================================

def test_scenario_22_identity_only_verified_reviewer_cannot_approve(client, db_session, admin_council_reviewer):
    """Scenario 22: Identity-only verified reviewer cannot approve translations."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12A-ID-ONLY", full_name="ID Only", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        "IdentityPass123#",
    )
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, app.reviewer_id)
    ReviewerOnboardingService.verify_identity(db_session, admin_council_reviewer, app.reviewer_id)
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": app.reviewer_id, "password": "IdentityPass123#"})
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "APPROVE",
            "scholarly_commentary": "Trying to approve with ID only",
        },
    )
    assert resp.status == 403


def test_scenario_23_credential_only_verified_reviewer_cannot_approve(client, db_session, admin_council_reviewer):
    """Scenario 23: Credential-only verified reviewer cannot approve translations."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12A-CRED-ONLY", full_name="Cred Only", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        "CredsPass123#",
    )
    ReviewerOnboardingService.advance_to_identity_review(db_session, admin_council_reviewer, app.reviewer_id)
    ReviewerOnboardingService.verify_identity(db_session, admin_council_reviewer, app.reviewer_id)
    ReviewerOnboardingService.advance_to_credential_review(db_session, admin_council_reviewer, app.reviewer_id)
    ReviewerOnboardingService.transition_stage(db_session, admin_council_reviewer, app.reviewer_id, OnboardingStage.CREDENTIALS_VERIFIED.value, "ok")
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": app.reviewer_id, "password": "CredsPass123#"})
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "APPROVE",
            "scholarly_commentary": "Trying to approve with creds only",
        },
    )
    assert resp.status == 403


def test_scenario_24_accredited_reviewer_without_language_permission_cannot_review(client, db_session, admin_council_reviewer):
    """Scenario 24: Accredited reviewer without target language permission cannot submit reviews for that language."""
    # Accredited Tamil scholar
    tamil_scholar = ReviewerProfile(
        reviewer_id="REV-P12A-TAMIL-SCHOLAR",
        full_name="Dr. Accredited Tamil Scholar",
        primary_role=ReviewerRole.TAMIL_TRANSLATOR,
        verification_status=OnboardingStage.ACTIVE_REVIEWER.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        language_proficiency={"ta": "NATIVE", "sa": "SCHOLAR"},
        permissions=["review:ta"],
        password_hash=hash_password("TamilScholarPass123#"),
    )
    db_session.add(tamil_scholar)
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": tamil_scholar.reviewer_id, "password": "TamilScholarPass123#"})
    csrf_token = client.json(login_resp)["csrf_token"]

    # Attempt to review Hindi translation
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Reviewing language outside accreditation",
        },
    )
    assert resp.status == 403
    assert "lacks certified credentials" in client.json(resp)["error"]


def test_scenario_25_accredited_reviewer_with_language_passes_eligibility_but_section_8_blocks_approval(client, db_session):
    """Scenario 25: Accredited scholar with language permission passes RBAC, but Section 8 blanket barrier blocks approval."""
    hindi_scholar = ReviewerProfile(
        reviewer_id="REV-P12A-HINDI-SCHOLAR",
        full_name="Dr. Accredited Hindi Scholar",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        verification_status=OnboardingStage.ACTIVE_REVIEWER.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        language_proficiency={"hi": "NATIVE", "sa": "SCHOLAR"},
        permissions=["review:hi", "APPROVE_TRANSLATION"],
        password_hash=hash_password("HindiScholarPass123#"),
    )
    db_session.add(hindi_scholar)
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": hindi_scholar.reviewer_id, "password": "HindiScholarPass123#"})
    csrf_token = client.json(login_resp)["csrf_token"]

    # Attempt translation approval
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "APPROVE",
            "scholarly_commentary": "Attempting approval during readiness phase",
        },
    )
    assert resp.status == 403
    assert "Section 8 Invariant" in client.json(resp)["error"]


def test_scenario_26_phase_11f_provenance_continues_working(client, db_session):
    """Scenario 26: Phase 11F non-approving review logging continues working with is_human_review populated accurately."""
    # Create accredited living human reviewer
    human_scholar = ReviewerProfile(
        reviewer_id="REV-P12A-HUMAN-SCHOLAR",
        full_name="Prof. Living Accredited Scholar",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        verification_status=OnboardingStage.ACTIVE_REVIEWER.value,
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_active=True,
        language_proficiency={"hi": "NATIVE", "sa": "SCHOLAR"},
        permissions=["review:hi"],
        password_hash=hash_password("LivingScholarPass123#"),
    )
    db_session.add(human_scholar)
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": human_scholar.reviewer_id, "password": "LivingScholarPass123#"})
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Refine pada three grammatical endings.",
        },
    )
    assert resp.status == 200
    data = client.json(resp)
    assert data["is_human_review"] is True
    assert data["translation_status_maintained"] == "DRAFT"


# ===========================================================================
# GROUP 4: DATA PROTECTION & AUDIT TESTS (SCENARIOS 27 - 30)
# ===========================================================================

def test_scenario_27_sensitive_fields_not_exposed_in_api(client, db_session, admin_council_reviewer):
    """Scenario 27: Public and applicant status API endpoints never expose password_hash or internal verification notes."""
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12A-SENSITIVE", full_name="Sensitive Scholar", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        "SecretPassword123#",
    )
    db_session.commit()

    login_resp = client.post("/api/v1/auth/login", json={"reviewer_id": app.reviewer_id, "password": "SecretPassword123#"})
    assert login_resp.status == 200

    status_resp = client.get("/api/v1/onboarding/status")
    assert status_resp.status == 200
    data = client.json(status_resp)

    # Asserts that sensitive secrets are absent
    assert "password_hash" not in data
    assert "password" not in data
    assert "verification_notes" not in data
    assert "failed_login_attempts" not in data


def test_scenario_28_passwords_and_secrets_not_in_audit_logs(db_session, admin_council_reviewer):
    """Scenario 28: Audit logs record actions and structured metadata, but never passwords or raw credentials."""
    raw_pass = "SuperSecretPasswordDoNotLog123#"
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(reviewer_id="REV-P12A-AUDIT-SAFE", full_name="Safe Audit Scholar", primary_role=ReviewerRole.HINDI_TRANSLATOR),
        raw_pass,
    )
    db_session.commit()

    logs = db_session.query(AuthAuditLog).filter_by(reviewer_id=app.id).all()
    assert len(logs) > 0
    for log_entry in logs:
        assert raw_pass not in (log_entry.details or "")


def test_scenario_29_applicant_cannot_overwrite_audit_logs(client, db_session):
    """Scenario 29: Audit log table is strictly server-appended; applicant input cannot overwrite audit records."""
    logs_before = db_session.query(AuthAuditLog).count()

    resp = client.post(
        "/api/v1/onboarding/apply",
        json={
            "reviewer_id": "REV-P12A-AUDIT-FORGE",
            "full_name": "Audit Forger",
            "password": "ValidPassword123#",
            "primary_role": ReviewerRole.HINDI_TRANSLATOR.value,
            "audit_log": "HACKED_LOG_ENTRY",
            "details": "FORGED_DETAILS",
        },
    )
    assert resp.status == 201

    logs_after = db_session.query(AuthAuditLog).count()
    assert logs_after == logs_before + 1

    latest_log = db_session.query(AuthAuditLog).order_by(AuthAuditLog.id.desc()).first()
    assert "HACKED_LOG_ENTRY" not in (latest_log.details or "")
    assert latest_log.event_type == "REVIEWER_APPLICANT_REGISTERED"


def test_scenario_30_production_database_untouched():
    """Scenario 30: Absolute safety invariant: production database SHA-256 and size remain bit-for-bit unchanged."""
    prod_path = Path("database/vedam.db")
    assert prod_path.exists()
    assert prod_path.stat().st_size == 20455424

    hasher = hashlib.sha256()
    with open(prod_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)

    expected_sha256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
    assert hasher.hexdigest() == expected_sha256
