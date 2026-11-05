"""
VEDAM PHASE 11F: QUARANTINED REVIEWER SECURITY & RBAC VERIFICATION AUDIT
Formal test suite verifying all 13 quarantined reviewer scenarios:
- Scenario 1: Quarantined DEMO persona submits REQUEST_REVISION (200 OK, is_human_review=False, status=DRAFT)
- Scenario 2: Quarantined DEMO persona submits FLAG_UNCERTAINTY (200 OK, is_human_review=False)
- Scenario 3: Quarantined DEMO persona submits REJECT, ESCALATE, FLAG_TERMINOLOGY, FLAG_MISSING_SOURCE
- Scenario 4: Active test reviewer submits feedback vs quarantined demo persona
- Scenario 5: Unauthenticated user submits feedback (401 Unauthorized)
- Scenario 6: Authenticated, unauthorized user / wrong language (403 Forbidden)
- Scenario 7: Quarantined persona attempts to impersonate active reviewer (session identity enforced)
- Scenario 8: Quarantined persona attempts to forge reviewer ID in body (body ID ignored)
- Scenario 9: Quarantined persona attempts to submit APPROVE (403 Forbidden under Section 8 Invariant)
- Scenario 10: Quarantined persona attempts to submit APPROVE_WITH_CORRECTIONS (403 Forbidden)
- Scenario 11: Route accessibility & sandbox isolation audit
- Scenario 12: Role & permission parameter manipulation in body ignored (DB profile enforced)
- Scenario 13: Session / CSRF token reuse and replay across sessions rejected
"""

import asyncio
from datetime import datetime, timedelta, timezone
import pytest
from aiohttp.test_utils import TestClient, TestServer

from automation.workbench.auth import (
    DEFAULT_IDLE_TIMEOUT_MINUTES,
    global_rate_limiter,
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
    Text,
    Translation,
    Verse,
)


class SyncGatewayTestClient:
    """Deterministic synchronous wrapper for aiohttp API Gateway test client."""

    def __init__(self):
        self.loop = asyncio.new_event_loop()
        self.app = create_app(db_session_factory=get_db_session)
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

    def clear_cookies(self):
        self.client.session.cookie_jar.clear()

    def close(self):
        self.loop.run_until_complete(self.client.close())
        self.loop.close()


@pytest.fixture
def api_client():
    global_rate_limiter.reset()
    client = SyncGatewayTestClient()
    yield client
    client.close()
    global_rate_limiter.reset()


@pytest.fixture
def target_translation(db_session):
    """Finds canonical verse 1 English translation for deterministic testing."""
    trans = (
        db_session.query(Translation)
        .join(Verse)
        .join(Text)
        .filter(Text.content_id == "VEDA-TXT-00001", Verse.verse_number == 1, Translation.target_language == "en")
        .first()
    )
    assert trans is not None, "Canonical English translation must exist in test database"
    return trans


def login_user(client: SyncGatewayTestClient, reviewer_id: str, password: str) -> str:
    global_rate_limiter.reset()
    resp = client.post("/api/v1/auth/login", json={"reviewer_id": reviewer_id, "password": password})
    assert resp.status == 200, f"Login failed: {reviewer_id}"
    data = client.json(resp)
    return data["csrf_token"]


# ===========================================================================
# 13 QUARANTINED REVIEWER AUDIT SCENARIO TESTS
# ===========================================================================

def test_scenario_1_quarantined_demo_request_revision(api_client, target_translation, db_session):
    """Scenario 1: Quarantined DEMO persona submits REQUEST_REVISION -> 200 OK, is_human_review=False, status=DRAFT."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()
    orig_text = target_translation.translated_text

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Refine English archaic syntax in line 2.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 200
    data = api_client.json(resp)
    assert data["status"] == "RECORDED"
    assert data["action_type"] == "REQUEST_REVISION"
    assert data["review_status"] == "DRAFT"
    assert data["is_human_review"] is False

    logs_after = db_session.query(ReviewActionLog).count()
    assert logs_after == logs_before + 1

    created_log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert created_log is not None
    assert created_log.is_human_review is False
    assert created_log.reviewer.reviewer_id == "REV-DEMO-SIM"
    assert created_log.reviewer.is_demonstration is True
    assert created_log.reviewer.verification_status == "DEMO"

    # Invariants
    trans_check = db_session.query(Translation).filter_by(id=target_translation.id).first()
    assert trans_check.review_status == ReviewStatus.DRAFT
    assert trans_check.translated_text == orig_text


def test_scenario_2_quarantined_demo_flag_uncertainty(api_client, target_translation, db_session):
    """Scenario 2: Quarantined DEMO persona submits FLAG_UNCERTAINTY -> 200 OK, is_human_review=False."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "FLAG_UNCERTAINTY",
        "scholarly_commentary": "Theological nuance in commentary noted.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 200
    data = api_client.json(resp)
    assert data["status"] == "RECORDED"
    assert data["is_human_review"] is False

    created_log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert created_log.is_human_review is False


def test_scenario_3_quarantined_demo_non_approving_actions(api_client, target_translation, db_session):
    """Scenario 3: Quarantined DEMO persona submits REJECT, ESCALATE, FLAG_TERMINOLOGY, FLAG_MISSING_SOURCE."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")

    for action in ("REJECT", "ESCALATE", "FLAG_TERMINOLOGY", "FLAG_MISSING_SOURCE"):
        payload = {
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": action,
            "scholarly_commentary": f"Testing action {action}.",
        }
        resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
        assert resp.status == 200
        data = api_client.json(resp)
        assert data["status"] == "RECORDED"
        assert data["action_type"] == action
        assert data["is_human_review"] is False

        log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
        assert log.is_human_review is False


def test_scenario_4_active_test_reviewer_vs_quarantined_demo(api_client, target_translation, db_session):
    """Scenario 4: Active test reviewer submits feedback vs quarantined demo persona."""
    csrf_vedic = login_user(api_client, "REV-PROD-VEDIC", "VedicScholar2026!Pass")

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Vedic recensionist feedback on English rendering.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_vedic}, json=payload)
    assert resp.status == 200
    data = api_client.json(resp)
    assert data["is_human_review"] is False

    log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert log.is_human_review is False
    assert log.reviewer.account_category == "SYNTHETIC_TEST_PERSONA"
    assert log.reviewer.is_demonstration is False
    assert log.reviewer.verification_status == "VERIFIED"


def test_scenario_5_unauthenticated_user_rejected(api_client, target_translation, db_session):
    """Scenario 5: Unauthenticated user submits feedback -> 401 Unauthorized."""
    api_client.clear_cookies()
    logs_before = db_session.query(ReviewActionLog).count()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Unauthenticated submission attempt.",
    }
    resp = api_client.post("/api/v1/reviews/submit", json=payload)
    assert resp.status == 401
    assert "Authentication is strictly required" in api_client.json(resp)["error"]
    assert db_session.query(ReviewActionLog).count() == logs_before


def test_scenario_6_unauthorized_language_rejected(api_client, target_translation, db_session):
    """Scenario 6: Authenticated, unauthorized user / wrong language -> 403 Forbidden."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()

    # REV-DEMO-SIM is authorized for 'sa' and 'en', attempting 'te' (Telugu)
    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "te",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Unauthorized attempt on Telugu translation.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 403
    assert "lacks certified credentials for language 'TE'" in api_client.json(resp)["error"]
    assert db_session.query(ReviewActionLog).count() == logs_before


def test_scenario_7_impersonation_prevented_session_identity(api_client, target_translation, db_session):
    """Scenario 7: Quarantined persona attempts to impersonate active reviewer -> session identity enforced."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    demo_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-DEMO-SIM").first()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Attempting impersonation via body.",
        "reviewer_id": "REV-PROD-VEDIC",  # Impersonation attempt
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 200
    data = api_client.json(resp)

    log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert log.reviewer_id == demo_profile.id
    assert log.reviewer.reviewer_id == "REV-DEMO-SIM"


def test_scenario_8_forged_reviewer_id_in_body_ignored(api_client, target_translation, db_session):
    """Scenario 8: Quarantined persona attempts to forge reviewer ID in body -> body ID ignored."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    demo_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-DEMO-SIM").first()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Forged ID attempt.",
        "reviewer_id": "REV-ADMIN-001",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 200
    data = api_client.json(resp)

    log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert log.reviewer_id == demo_profile.id


def test_scenario_9_quarantined_persona_approve_strictly_403(api_client, target_translation, db_session):
    """Scenario 9: Quarantined persona attempts to submit APPROVE -> strictly 403 Forbidden."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "APPROVE",
        "scholarly_commentary": "Attempting unauthorized approval.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 403
    assert "Translation approval is strictly prohibited in Phase 11F" in api_client.json(resp)["error"]
    assert db_session.query(ReviewActionLog).count() == logs_before


def test_scenario_10_quarantined_persona_approve_with_corrections_strictly_403(api_client, target_translation, db_session):
    """Scenario 10: Quarantined persona attempts to submit APPROVE_WITH_CORRECTIONS -> strictly 403 Forbidden."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "APPROVE_WITH_CORRECTIONS",
        "scholarly_commentary": "Attempting unauthorized approval with edits.",
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 403
    assert "Translation approval is strictly prohibited in Phase 11F" in api_client.json(resp)["error"]
    assert db_session.query(ReviewActionLog).count() == logs_before


def test_scenario_11_protected_reviewer_routes_and_sandbox_warning(api_client, target_translation):
    """Scenario 11: Route accessibility & sandbox boundary audit."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")

    # /auth/me returns quarantined status
    resp_me = api_client.get("/api/v1/auth/me")
    assert resp_me.status == 200
    me_data = api_client.json(resp_me)["reviewer"]
    assert me_data["verification_status"] == "DEMO"
    assert me_data["is_demonstration"] is True
    assert me_data["account_category"] == "DEMONSTRATION_HARNESS"
    assert me_data["is_human_verified"] is False

    # Attempt administrative routes -> 404 (not exposed on gateway)
    resp_admin = api_client.get("/api/v1/admin/reviewers")
    assert resp_admin.status == 404

    # Workbench UI renders sandbox warning
    resp_ui = api_client.get("/workbench?content_id=VEDA-TXT-00001&verse_number=1&target_language=en")
    assert resp_ui.status == 200
    html = api_client.text(resp_ui)
    assert "auth-demo" in html
    assert "disabled" in html


def test_scenario_12_role_parameter_manipulation_ignored(api_client, target_translation, db_session):
    """Scenario 12: Role & permission parameter manipulation in body ignored (DB profile enforced)."""
    csrf_token = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    logs_before = db_session.query(ReviewActionLog).count()

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "te",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Attempting role injection via body.",
        "role": "EDITORIAL_BOARD",
        "primary_role": "EDITORIAL_BOARD",
        "permissions": ["ADMIN_ALL", "approve:te", "review:te"],
    }
    resp = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_token}, json=payload)
    assert resp.status == 403
    assert db_session.query(ReviewActionLog).count() == logs_before


def test_scenario_13_session_csrf_reuse_and_replay_rejected(api_client, target_translation, db_session):
    """Scenario 13: Session / CSRF token reuse and replay across sessions rejected."""
    # Sub-test 13A: Cross-user CSRF token reuse -> 403
    csrf_vedic = login_user(api_client, "REV-PROD-VEDIC", "VedicScholar2026!Pass")
    csrf_demo = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")

    payload = {
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "target_language": "en",
        "action_type": "REQUEST_REVISION",
        "scholarly_commentary": "Cross-user CSRF test.",
    }
    resp_cross = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_vedic}, json=payload)
    assert resp_cross.status == 403
    assert "CSRF token validation failed" in api_client.json(resp_cross)["error"]

    # Sub-test 13B: Replay after logout -> 401
    resp_logout = api_client.post("/api/v1/auth/logout")
    assert resp_logout.status == 200
    resp_replay = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_demo}, json=payload)
    assert resp_replay.status == 401
    assert "Authentication is strictly required" in api_client.json(resp_replay)["error"]

    # Sub-test 13C: Idle timeout expiration -> 401
    csrf_fresh = login_user(api_client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    demo_profile = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-DEMO-SIM").first()
    sess_record = (
        db_session.query(ReviewerSession)
        .filter_by(reviewer_id=demo_profile.id, is_revoked=False)
        .order_by(ReviewerSession.created_at.desc())
        .first()
    )
    sess_record.last_activity_at = datetime.now(timezone.utc) - timedelta(minutes=DEFAULT_IDLE_TIMEOUT_MINUTES + 5)
    db_session.commit()

    resp_expired = api_client.post("/api/v1/reviews/submit", headers={CSRF_HEADER: csrf_fresh}, json=payload)
    assert resp_expired.status == 401
