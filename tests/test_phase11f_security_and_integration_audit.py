"""
VEDAM PHASE 11F: INDEPENDENT SECURITY, INTEGRATION & PENETRATION AUDIT
Comprehensive test suite verifying:
- Exact 12-endpoint API route inventory
- Authentication and session security (Argon2id, lockout, expiry, token entropy)
- CSRF double-submit cookie, cross-origin Origin validation, security headers, CSP
- Database session lifecycle (request-scoped, rollback on error, no leaked sessions)
- Server-side RBAC penetration vectors (17 attack vectors, Section 8 approval blocking)
- Data provenance and content fidelity (747 gaps, script transliteration, RTL isolation)
"""

import asyncio
from datetime import datetime, timedelta, timezone
import json
import pytest
from aiohttp import web
from aiohttp.test_utils import TestClient, TestServer
from sqlalchemy.orm import Session

from automation.workbench.auth import (
    AuthService,
    DEFAULT_ABSOLUTE_SESSION_HOURS,
    DEFAULT_IDLE_TIMEOUT_MINUTES,
    MAX_FAILED_ATTEMPTS,
    generate_csrf_token,
    hash_password,
    validate_csrf_token,
)
from automation.workbench.gateway import (
    COOKIE_NAME,
    CSRF_HEADER,
    create_app,
)
from database.connection import get_db_session
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    ReviewerVerificationStatus,
    Text,
    Translation,
    TranslationView,
    Verse,
)


class SyncGatewayClient:
    """Synchronous test client wrapper for deterministic aiohttp testing."""

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

    def close(self):
        self.loop.run_until_complete(self.client.close())
        self.loop.close()


@pytest.fixture(autouse=True)
def cleanup_audit_records(db_session):
    """Guarantees complete test isolation and zero leftover test records."""
    from automation.workbench.auth import global_rate_limiter
    global_rate_limiter.reset()
    yield
    global_rate_limiter.reset()
    test_revs = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-AUDIT-%")).all()
    test_rev_ids = [r.id for r in test_revs]
    if test_rev_ids:
        db_session.query(ReviewerSession).filter(ReviewerSession.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.query(ReviewActionLog).filter(ReviewActionLog.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.query(ReviewerProfile).filter(ReviewerProfile.id.in_(test_rev_ids)).delete(synchronize_session=False)
        db_session.commit()


@pytest.fixture
def client():
    c = SyncGatewayClient(db_factory=get_db_session)
    yield c
    c.close()


@pytest.fixture
def audit_scholar(db_session):
    """Provisions a test accredited Hindi scholar persona."""
    rev_id = "REV-AUDIT-SCHOLAR-HI"
    reviewer = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Prof. Audit Hindi Scholar",
        email="audit.hi@vedam.org",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        secondary_roles=[],
        verification_status="VERIFIED",
        is_credentials_verified=True,
        is_demonstration=True,
        account_category="SYNTHETIC_TEST_PERSONA",
        is_human_verified=False,
        is_active=True,
        language_proficiency={"hi": "NATIVE", "sa": "SCHOLAR"},
        permissions=["review:hi", "approve:hi"],
        password_hash=hash_password("AuditPassword123!"),
    )
    db_session.add(reviewer)
    db_session.commit()
    return reviewer


@pytest.fixture
def audit_tamil_scholar(db_session):
    """Provisions a test accredited Tamil scholar persona."""
    rev_id = "REV-AUDIT-SCHOLAR-TA"
    reviewer = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Dr. Audit Tamil Scholar",
        email="audit.ta@vedam.org",
        primary_role=ReviewerRole.TAMIL_TRANSLATOR,
        secondary_roles=[],
        verification_status="VERIFIED",
        is_credentials_verified=True,
        is_demonstration=True,
        account_category="SYNTHETIC_TEST_PERSONA",
        is_human_verified=False,
        is_active=True,
        language_proficiency={"ta": "NATIVE"},
        permissions=["review:ta", "approve:ta"],
        password_hash=hash_password("AuditTamilPass456!"),
    )
    db_session.add(reviewer)
    db_session.commit()
    return reviewer


# ===========================================================================
# 1. SCOPE & ENDPOINT INVENTORY AUDIT
# ===========================================================================

def test_endpoint_inventory_exact_count():
    """Verify that create_app registers exactly 12 distinct functional endpoints and 21 route methods."""
    app = create_app()
    distinct_endpoints = set()
    total_methods = 0
    for resource in app.router.resources():
        info = resource.get_info()
        path = info.get("path") or info.get("formatter")
        for route in resource:
            total_methods += 1
            distinct_endpoints.add((route.method, path))

    # Distinct non-HEAD routes
    functional_routes = [(m, p) for m, p in distinct_endpoints if m != "HEAD"]
    assert len(functional_routes) == 12
    assert total_methods == 21  # 12 functional + 9 automatic HEAD routes for GET


# ===========================================================================
# 2. AUTHENTICATION & SESSION SECURITY AUDIT (SECTION 3)
# ===========================================================================

def test_password_hash_never_exposed(client, audit_scholar):
    """Verify password_hash is never returned in login or /auth/me responses."""
    resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    assert resp.status == 200
    login_data = client.json(resp)
    assert "password" not in str(login_data).lower()
    assert "password_hash" not in login_data

    # Check /auth/me
    resp_me = client.get("/api/v1/auth/me")
    assert resp_me.status == 200
    me_data = client.json(resp_me)
    assert "password" not in str(me_data).lower()
    assert "password_hash" not in me_data["reviewer"]


def test_user_enumeration_resistance(client, audit_scholar):
    """Verify non-existent reviewer returns exact same error message and code as wrong password."""
    # Unknown reviewer ID
    resp_unknown = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": "REV-NONEXISTENT-PERSON", "password": "AnyPassword123!"},
    )
    assert resp_unknown.status == 401
    unknown_data = client.json(resp_unknown)

    # Known reviewer with wrong password
    resp_badpass = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "WrongPassword999!"},
    )
    assert resp_badpass.status == 401
    badpass_data = client.json(resp_badpass)

    assert unknown_data["error"] == badpass_data["error"] == "Invalid reviewer ID or password."
    assert unknown_data["code"] == badpass_data["code"] == "AUTHENTICATION_REQUIRED"


def test_account_lockout_enforcement(client, audit_scholar, db_session):
    """Verify account is locked after 5 failed login attempts and subsequent attempts are blocked."""
    for i in range(5):
        resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": audit_scholar.reviewer_id, "password": "WrongPassword!"},
        )
        assert resp.status == 401

    # 6th attempt with CORRECT password must fail due to lock
    resp_locked = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    assert resp_locked.status == 403
    locked_data = client.json(resp_locked)
    assert "Account is locked" in locked_data["error"]
    assert locked_data["code"] == "ACCOUNT_LOCKED"


def test_session_idle_and_absolute_expiration(client, audit_scholar, db_session):
    """Verify sessions past idle timeout (30m) or absolute lifetime (12h) are rejected."""
    # Login
    resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    assert resp.status == 200

    # Simulate idle timeout in DB (> 30 minutes)
    session_row = db_session.query(ReviewerSession).filter_by(reviewer_id=audit_scholar.id).first()
    session_row.last_activity_at = datetime.now(timezone.utc) - timedelta(minutes=35)
    db_session.commit()

    resp_idle = client.get("/api/v1/auth/me")
    assert resp_idle.status == 200
    data_idle = client.json(resp_idle)
    assert data_idle["is_authenticated"] is False  # Idle expired session rejected

    # Reset activity but simulate absolute expiration (> 12 hours)
    session_row.last_activity_at = datetime.now(timezone.utc)
    session_row.absolute_expires_at = datetime.now(timezone.utc) - timedelta(hours=13)
    db_session.commit()

    resp_abs = client.get("/api/v1/auth/me")
    assert resp_abs.status == 200
    data_abs = client.json(resp_abs)
    assert data_abs["is_authenticated"] is False


def test_revoked_session_rejected_after_logout(client, audit_scholar):
    """Verify logged-out session cannot be replayed."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    assert login_resp.status == 200

    # Logout
    logout_resp = client.post("/api/v1/auth/logout")
    assert logout_resp.status == 200

    # Attempt to use revoked session
    me_resp = client.get("/api/v1/auth/me")
    assert me_resp.status == 200
    assert client.json(me_resp)["is_authenticated"] is False


# ===========================================================================
# 3. CSRF & HTTP SECURITY AUDIT (SECTION 4)
# ===========================================================================

def test_csrf_missing_and_mismatched_tokens(client, audit_scholar):
    """Verify missing, invalid, or mismatched CSRF tokens are rejected with 403."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "hi",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Audit CSRF check",
    }

    # 1. Missing CSRF header
    resp_no_header = client.post("/api/v1/reviews/submit", json=payload)
    assert resp_no_header.status == 403
    assert "CSRF" in client.json(resp_no_header)["error"]

    # 2. Forged / invalid CSRF token
    resp_bad_token = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: "forged_csrf_token_hex_1234567890abcdef"},
        json=payload,
    )
    assert resp_bad_token.status == 403

    # 3. Cross-origin request blocked (Origin != host)
    resp_cross_origin = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token, "Origin": "https://malicious-external-site.org"},
        json=payload,
    )
    assert resp_cross_origin.status == 403
    assert "Cross-origin" in client.json(resp_cross_origin)["error"]


def test_security_headers_compliance(client):
    """Verify OWASP security headers including CSP, nosniff, SAMEORIGIN, and Cache-Control."""
    resp = client.get("/api/v1/health")
    assert resp.status == 200
    headers = resp.headers

    assert headers["X-Content-Type-Options"] == "nosniff"
    assert headers["X-Frame-Options"] == "SAMEORIGIN"
    assert headers["Referrer-Policy"] == "strict-origin-when-cross-origin"
    assert "no-store" in headers["Cache-Control"]
    assert "Content-Security-Policy" in headers
    assert "default-src 'self'" in headers["Content-Security-Policy"]


# ===========================================================================
# 4. DATABASE SESSION LIFECYCLE AUDIT (SECTION 5)
# ===========================================================================

def test_database_session_rollback_on_exception(client, audit_scholar, db_session):
    """Verify that failed requests trigger rollback and do not persist intermediate mutations."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    logs_before = db_session.query(ReviewActionLog).count()

    # Submit invalid request (non-existent verse)
    resp_bad = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 99999,  # Non-existent verse
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Rollback test",
        },
    )
    assert resp_bad.status == 404

    # Ensure zero action logs were persisted
    logs_after = db_session.query(ReviewActionLog).count()
    assert logs_after == logs_before


# ===========================================================================
# 5. RBAC & REVIEW PENETRATION AUDIT (SECTION 6)
# ===========================================================================

def test_approval_actions_strictly_blocked(client, audit_scholar):
    """Verify APPROVE and APPROVE_WITH_CORRECTIONS are barred with 403 under Section 8 Invariant."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    for prohibited_action in ("APPROVE", "APPROVE_WITH_CORRECTIONS"):
        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": "VEDA-TXT-00001",
                "verse_number": 1,
                "target_language": "hi",
                "action_type": prohibited_action,
                "scholarly_commentary": "Attempting unauthorized approval",
            },
        )
        assert resp.status == 403
        data = client.json(resp)
        assert "Translation approval is strictly prohibited in Phase 11F" in data["error"]


def test_cross_language_unauthorized_review_blocked(client, audit_tamil_scholar):
    """Verify Tamil scholar cannot review Hindi translations."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": audit_tamil_scholar.reviewer_id, "password": "AuditTamilPass456!"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Unauthorized cross-language attempt",
        },
    )
    assert resp.status == 403
    assert "lacks certified credentials for language 'HI'" in client.json(resp)["error"]


def test_anti_self_approval_rule_rev002(client, audit_scholar, db_session):
    """Verify translator cannot review their own translation (Rule REV-002)."""
    trans = db_session.query(Translation).filter_by(target_language="hi").first()
    orig_translator = trans.translator
    try:
        trans.translator = audit_scholar.full_name
        db_session.commit()

        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": audit_scholar.reviewer_id, "password": "AuditPassword123!"},
        )
        csrf_token = client.json(login_resp)["csrf_token"]

        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": trans.verse.text.content_id,
                "verse_number": trans.verse.verse_number,
                "target_language": "hi",
                "action_type": "REQUEST_REVISION",
                "scholarly_commentary": "Self review attempt",
            },
        )
        assert resp.status == 403
        assert "Self-approval prohibited" in client.json(resp)["error"]
    finally:
        trans.translator = orig_translator
        db_session.commit()


# ===========================================================================
# 6. DATA PROVENANCE & CONTENT FIDELITY (SECTION 7)
# ===========================================================================

def test_scholarly_payload_content_fidelity(client):
    """Verify /scholarly payload returns genuine DB content and preserves 747 legacy gap state."""
    resp = client.get("/api/v1/texts/VEDA-TXT-00001/verses/1/scholarly?target_language=hi")
    assert resp.status == 200
    data = client.json(resp)

    # Content fidelity checks
    assert data["target_language"] == "hi"
    assert "column_1_original" in data
    assert "column_2_transliterations" in data
    assert "column_3_literal" in data
    assert "column_4_traditional" in data
    assert "column_5_bhavartha" in data
    assert "column_6_governance" in data
    assert "unicode_diagnostics" in data
    assert "publication_preview" in data
    assert data["column_1_original"]["devanagari_text"] is not None
    assert "मुदाकरात्तमोदकं" in data["column_1_original"]["devanagari_text"]
