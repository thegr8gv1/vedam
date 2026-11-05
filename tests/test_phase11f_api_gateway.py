"""
Phase 11F: Authenticated HTTP API Gateway & Real Multilingual Workbench Integration Tests
Validates all API gateway routes, authentication lifecycle, CSRF tokens, server-side RBAC,
anti-self-approval restrictions, input sanitization, non-approving review logging,
and live workbench HTML rendering under strict test database isolation.
"""

import asyncio
from datetime import datetime, timedelta, timezone
import json
import pytest
from aiohttp.test_utils import TestClient, TestServer

from automation.workbench.auth import (
    AuthService,
    generate_csrf_token,
    hash_password,
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
    Verse,
)


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
def cleanup_phase11f_test_artifacts(db_session):
    """Ensure all test reviewer profiles, sessions, and logs are completely removed."""
    yield
    test_revs = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-P11F%")).all()
    test_rev_ids = [r.id for r in test_revs]
    if test_rev_ids:
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
def test_reviewer(db_session):
    """Provisions a test accredited reviewer in the isolated test database."""
    rev_id = "REV-P11F-TEST-SCHOLAR"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    reviewer = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Dr. Test Hindi Scholar",
        email="hindi.scholar@vedam.org",
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
        password_hash=hash_password("ValidP11fScholarPass!"),
    )
    db_session.add(reviewer)
    db_session.commit()
    return reviewer


@pytest.fixture
def test_tamil_reviewer(db_session):
    """Provisions a test Tamil reviewer in the isolated test database."""
    rev_id = "REV-P11F-TEST-TAMIL"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    reviewer = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Vidvan Test Tamil Scholar",
        email="tamil.scholar@vedam.org",
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
        password_hash=hash_password("ValidP11fTamilPass!"),
    )
    db_session.add(reviewer)
    db_session.commit()
    return reviewer


# ===========================================================================
# 1. HEALTH & METADATA ENDPOINTS
# ===========================================================================

def test_health_endpoint(client):
    """Verify GET /api/v1/health returns 200 OK and system metadata."""
    resp = client.get("/api/v1/health")
    assert resp.status == 200
    data = client.json(resp)
    assert data["status"] == "HEALTHY"
    assert data["service"] == "Vedam Multilingual Scholarly Workbench API Gateway"
    assert data["supported_languages"] == 23
    assert data["supported_scripts"] == 14
    assert resp.headers["X-Content-Type-Options"] == "nosniff"


def test_languages_endpoint(client):
    """Verify GET /api/v1/languages returns 23 languages."""
    resp = client.get("/api/v1/languages")
    assert resp.status == 200
    data = client.json(resp)
    assert data["total_languages"] == 23
    lang_codes = [l["iso_639_1"] for l in data["languages"]]
    assert "sa" in lang_codes
    assert "hi" in lang_codes
    assert "ur" in lang_codes
    assert "en" in lang_codes


def test_scripts_endpoint(client):
    """Verify GET /api/v1/scripts returns 14 scripts."""
    resp = client.get("/api/v1/scripts")
    assert resp.status == 200
    data = client.json(resp)
    assert data["total_scripts"] == 14
    script_codes = [s["iso_15924"] for s in data["scripts"]]
    assert "Deva" in script_codes
    assert "Arab" in script_codes
    assert "Telu" in script_codes


def test_texts_and_verses_endpoints(client):
    """Verify GET /api/v1/texts returns canonical compositions and verses list."""
    resp_texts = client.get("/api/v1/texts")
    assert resp_texts.status == 200
    texts_data = client.json(resp_texts)
    assert texts_data["total_compositions"] == 18

    # Detail
    resp_detail = client.get("/api/v1/texts/VEDA-TXT-00001")
    assert resp_detail.status == 200
    detail = client.json(resp_detail)
    assert detail["content_id"] == "VEDA-TXT-00001"

    # Non-existent detail
    resp_404 = client.get("/api/v1/texts/NON-EXISTENT-ID")
    assert resp_404.status == 404

    # Verses list
    resp_verses = client.get("/api/v1/texts/VEDA-TXT-00001/verses")
    assert resp_verses.status == 200
    v_data = client.json(resp_verses)
    assert v_data["total_verses"] > 0


def test_scholarly_payload_endpoint(client):
    """Verify GET /api/v1/texts/{id}/verses/{num}/scholarly returns 6-column payload."""
    resp = client.get("/api/v1/texts/VEDA-TXT-00001/verses/1/scholarly?target_language=te&target_script=Telu")
    assert resp.status == 200
    payload = client.json(resp)
    assert payload["target_language"] == "te"
    assert payload["target_script"] == "Telu"
    assert "column_1_original" in payload
    assert "column_2_transliterations" in payload
    assert "column_3_literal" in payload
    assert "column_4_traditional" in payload
    assert "column_5_bhavartha" in payload
    assert "column_6_governance" in payload
    assert "unicode_diagnostics" in payload
    assert "publication_preview" in payload


def test_scholarly_payload_urdu_rtl(client):
    """Verify Urdu target language sets is_rtl=true and direction=rtl."""
    resp = client.get("/api/v1/texts/VEDA-TXT-00006/verses/1/scholarly?target_language=ur&target_script=Arab")
    assert resp.status == 200
    payload = client.json(resp)
    assert payload["target_language"] == "ur"
    assert payload["is_rtl"] is True
    assert payload["direction"] == "rtl"


def test_scholarly_payload_manipuri_and_assamese(client):
    """Verify Assamese and Manipuri script handling."""
    # Assamese
    resp_as = client.get("/api/v1/texts/VEDA-TXT-00001/verses/1/scholarly?target_language=as&target_script=Beng")
    assert resp_as.status == 200
    payload_as = client.json(resp_as)
    assert payload_as["target_language"] == "as"

    # Manipuri Meitei Mayek
    resp_mni = client.get("/api/v1/texts/VEDA-TXT-00001/verses/1/scholarly?target_language=mni&target_script=Mtei")
    assert resp_mni.status == 200
    payload_mni = client.json(resp_mni)
    assert payload_mni["target_language"] == "mni"
    assert payload_mni["target_script"] == "Mtei"


# ===========================================================================
# 2. AUTHENTICATION LIFECYCLE & SESSION SECURITY
# ===========================================================================

def test_login_and_logout_lifecycle(client, test_reviewer):
    """Verify login issues HttpOnly session cookie, CSRF token, and logout revokes it."""
    # 1. Login
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
    )
    assert login_resp.status == 200
    login_data = client.json(login_resp)
    assert login_data["status"] == "AUTHENTICATED"
    assert login_data["reviewer_id"] == test_reviewer.reviewer_id
    assert "csrf_token" in login_data

    # Verify session cookie set
    cookies = client.session.cookie_jar.filter_cookies(client.server.make_url("/"))
    assert COOKIE_NAME in cookies
    session_cookie = cookies[COOKIE_NAME].value
    assert len(session_cookie) > 20

    # 2. Verify /api/v1/auth/me returns current user
    me_resp = client.get("/api/v1/auth/me")
    assert me_resp.status == 200
    me_data = client.json(me_resp)
    assert me_data["is_authenticated"] is True
    assert me_data["reviewer"]["reviewer_id"] == test_reviewer.reviewer_id

    # 3. Logout
    logout_resp = client.post("/api/v1/auth/logout")
    assert logout_resp.status == 200
    logout_data = client.json(logout_resp)
    assert logout_data["status"] == "LOGGED_OUT"

    # 4. Verify /api/v1/auth/me returns unauthenticated
    me_after = client.get("/api/v1/auth/me")
    assert me_after.status == 200
    me_after_data = client.json(me_after)
    assert me_after_data["is_authenticated"] is False


def test_login_bad_password(client, test_reviewer):
    """Verify login failure on invalid password."""
    resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": test_reviewer.reviewer_id, "password": "WrongPassword123!"},
    )
    assert resp.status == 401
    data = client.json(resp)
    assert "Invalid reviewer ID or password" in data["error"]


def test_account_lockout(client, db_session):
    """Verify account is locked after 5 consecutive failed attempts."""
    rev_id = "REV-P11F-LOCKOUT-TEST"
    reviewer = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Lockout Scholar",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        verification_status="VERIFIED",
        is_active=True,
        password_hash=hash_password("InitialPass123!"),
    )
    db_session.add(reviewer)
    db_session.commit()

    # Fail 5 times
    for _ in range(5):
        client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": rev_id, "password": "WrongPassword!"},
        )

    # 6th attempt should return 403 Account Locked
    resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": rev_id, "password": "InitialPass123!"},
    )
    assert resp.status == 403
    data = client.json(resp)
    assert "Account is locked" in data["error"]


def test_expired_session_rejected(client, test_reviewer, db_session):
    """Verify an expired session token is rejected with 401."""
    # Create an artificially expired session
    expired_time = datetime.now(timezone.utc) - timedelta(hours=1)
    session_obj = ReviewerSession(
        session_token="TEST_EXPIRED_TOKEN_P11F",
        reviewer_id=test_reviewer.id,
        created_at=expired_time - timedelta(hours=12),
        expires_at=expired_time,
        absolute_expires_at=expired_time,
        last_activity_at=expired_time,
        is_revoked=False,
    )
    db_session.add(session_obj)
    db_session.commit()

    # Send request with expired session in Authorization header
    resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer TEST_EXPIRED_TOKEN_P11F"},
    )
    assert resp.status == 200
    data = client.json(resp)
    # Expired session resolves to unauthenticated
    assert data["is_authenticated"] is False


def test_revoked_session_rejected(client, test_reviewer, db_session):
    """Verify a revoked session token is treated as unauthenticated."""
    now_utc = datetime.now(timezone.utc)
    session_obj = ReviewerSession(
        session_token="TEST_REVOKED_TOKEN_P11F",
        reviewer_id=test_reviewer.id,
        created_at=now_utc,
        expires_at=now_utc + timedelta(hours=12),
        absolute_expires_at=now_utc + timedelta(hours=12),
        last_activity_at=now_utc,
        is_revoked=True,
    )
    db_session.add(session_obj)
    db_session.commit()

    resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer TEST_REVOKED_TOKEN_P11F"},
    )
    assert resp.status == 200
    data = client.json(resp)
    assert data["is_authenticated"] is False


# ===========================================================================
# 3. SERVER-SIDE RBAC & REVIEW FEEDBACK SUBMISSION
# ===========================================================================

def test_unauthenticated_review_submission_blocked(client):
    """Verify unauthenticated submission is rejected with 401."""
    resp = client.post(
        "/api/v1/reviews/submit",
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Unauthenticated comment attempt",
        },
    )
    assert resp.status == 401
    data = client.json(resp)
    assert "Authentication is strictly required" in data["error"]


def test_csrf_protection_on_review_submission(client, test_reviewer):
    """Verify missing or invalid CSRF token causes 403 Forbidden."""
    client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
    )

    # Submit without CSRF header
    resp_no_csrf = client.post(
        "/api/v1/reviews/submit",
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Test comment without CSRF",
        },
    )
    assert resp_no_csrf.status == 403
    assert "CSRF" in client.json(resp_no_csrf)["error"]


def test_approval_action_strictly_prohibited(client, test_reviewer):
    """Verify APPROVE action is rejected under Phase 11F Section 8 Invariant."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
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
            "scholarly_commentary": "Attempting illegal approval",
        },
    )
    assert resp.status == 403
    data = client.json(resp)
    assert "Translation approval is strictly prohibited in Phase 11F" in data["error"]


def test_cross_language_unauthorized_review_blocked(client, test_tamil_reviewer):
    """Verify Tamil reviewer cannot submit feedback on Hindi translation."""
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": test_tamil_reviewer.reviewer_id, "password": "ValidP11fTamilPass!"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_token},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "hi",  # Tamil reviewer has no accreditation for Hindi
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Cross-language intrusion",
        },
    )
    assert resp.status == 403
    data = client.json(resp)
    assert "lacks certified credentials for language 'HI'" in data["error"]


def test_self_approval_prohibited(client, test_reviewer, db_session):
    """Verify translator cannot review their own work (Rule REV-002)."""
    trans = db_session.query(Translation).filter_by(target_language="hi").first()
    orig_translator = trans.translator
    try:
        trans.translator = test_reviewer.full_name
        db_session.commit()

        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
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
                "scholarly_commentary": "Self-review attempt",
            },
        )
        assert resp.status == 403
        data = client.json(resp)
        assert "Self-approval prohibited" in data["error"]
    finally:
        trans.translator = orig_translator
        db_session.commit()


def test_forged_reviewer_id_ignored_server_side(client, test_reviewer, db_session):
    """Verify reviewer_id in request body is ignored and server uses session identity."""
    trans = db_session.query(Translation).filter_by(target_language="hi").first()
    orig_translator = trans.translator
    try:
        trans.translator = "External Pandit"
        db_session.commit()

        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
        )
        csrf_token = client.json(login_resp)["csrf_token"]

        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": trans.verse.text.content_id,
                "verse_number": trans.verse.verse_number,
                "target_language": "hi",
                "reviewer_id": "REV-SPOOFED-FAKE-ID",  # Forged ID in body
                "action_type": "REQUEST_REVISION",
                "scholarly_commentary": "Checking spoof resistance",
            },
        )
        assert resp.status == 200
        data = client.json(resp)

        # Verify action log in DB has test_reviewer.id, NOT spoofed ID
        log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
        assert log.reviewer_id == test_reviewer.id
    finally:
        trans.translator = orig_translator
        db_session.commit()


def test_valid_review_feedback_persisted_without_status_change(client, test_reviewer, db_session):
    """Verify accredited reviewer can submit revision request and translation status remains DRAFT."""
    trans = db_session.query(Translation).filter_by(target_language="hi").first()
    orig_translator = trans.translator
    try:
        trans.translator = "Other Translator"
        db_session.commit()

        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
        )
        csrf_token = client.json(login_resp)["csrf_token"]

        logs_before = db_session.query(ReviewActionLog).count()

        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": trans.verse.text.content_id,
                "verse_number": trans.verse.verse_number,
                "target_language": "hi",
                "action_type": "REQUEST_REVISION",
                "scholarly_commentary": "Please refine the grammatical syntax of the third pada.",
            },
        )
        assert resp.status == 200
        data = client.json(resp)
        assert data["status"] == "RECORDED"
        assert data["action_type"] == "REQUEST_REVISION"
        assert data["translation_status_maintained"] == "DRAFT"

        logs_after = db_session.query(ReviewActionLog).count()
        assert logs_after == logs_before + 1

        # Verify translation remains DRAFT
        db_session.refresh(trans)
        assert trans.review_status == ReviewStatus.DRAFT
    finally:
        trans.translator = orig_translator
        db_session.commit()


# ===========================================================================
# 4. INPUT VALIDATION & INJECTION RESISTANCE
# ===========================================================================

def test_malformed_json_and_invalid_inputs(client):
    """Verify malformed JSON, invalid verse numbers, and invalid language codes."""
    # Malformed JSON
    resp_bad_json = client.post(
        "/api/v1/auth/login",
        data="not a valid json",
        headers={"Content-Type": "application/json"},
    )
    assert resp_bad_json.status == 400

    # Non-integer verse
    resp_bad_verse = client.get("/api/v1/texts/VEDA-TXT-00001/verses/notanumber/scholarly")
    assert resp_bad_verse.status == 400

    # Non-existent language
    resp_bad_lang = client.get("/api/v1/texts/VEDA-TXT-00001/verses/1/scholarly?target_language=xyz")
    assert resp_bad_lang.status == 400


def test_xss_injection_in_commentary_escaped_on_render(client, test_reviewer, db_session):
    """Verify XSS payloads in commentary are stored safely and escaped on UI render."""
    trans = db_session.query(Translation).filter_by(target_language="hi").first()
    orig_translator = trans.translator
    try:
        trans.translator = "External Pandit"
        db_session.commit()

        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": test_reviewer.reviewer_id, "password": "ValidP11fScholarPass!"},
        )
        csrf_token = client.json(login_resp)["csrf_token"]

        xss_payload = '<script>alert("gateway_xss")</script>'
        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": trans.verse.text.content_id,
                "verse_number": trans.verse.verse_number,
                "target_language": "hi",
                "action_type": "FLAG_UNCERTAINTY",
                "scholarly_commentary": xss_payload,
            },
        )
        assert resp.status == 200

        # Fetch live workbench HTML to ensure it renders escaped
        ui_resp = client.get(f"/workbench?content_id={trans.verse.text.content_id}&verse_number={trans.verse.verse_number}&target_language=hi")
        assert ui_resp.status == 200
        html_text = client.text(ui_resp)

        assert xss_payload not in html_text
        assert "&lt;script&gt;alert(&quot;gateway_xss&quot;)&lt;/script&gt;" in html_text
    finally:
        trans.translator = orig_translator
        db_session.commit()


# ===========================================================================
# 5. LIVE WORKBENCH UI ROUTE
# ===========================================================================

def test_live_workbench_ui_rendering(client):
    """Verify GET /workbench renders HTML with injected VEDAM_API client script."""
    resp = client.get("/workbench")
    assert resp.status == 200
    assert resp.headers["Content-Type"].startswith("text/html")
    text = client.text(resp)

    assert "window.VEDAM_API" in text
    assert 'role="banner"' in text
    assert 'role="region"' in text
    assert "UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE" in text
    assert "LIMITED PREVIEW ONLY" in text
