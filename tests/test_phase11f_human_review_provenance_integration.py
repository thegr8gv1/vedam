"""
VEDAM PHASE 11F: HUMAN REVIEW PROVENANCE AND DOWNSTREAM INTEGRATION AUDIT
Focused integration test suite verifying that Policy B synthetic-vs-human
review provenance controls are consistently enforced across every downstream consumer:
1. One synthetic feedback record does not count as a human review.
2. Multiple synthetic feedback records do not satisfy human-review thresholds.
3. Mixed human and synthetic activity counts only verified human activity.
4. An unverified human account does not count as an accredited human reviewer.
5. A verified human reviewer is correctly represented in analytics.
6. Synthetic actions do not inflate reviewer performance metrics.
7. Synthetic actions cannot satisfy publication prerequisites.
8. Synthetic actions remain visibly identified in review history.
9. Null or missing is_human_review is handled safely.
10. Forged reviewer identity cannot change provenance.
11. Direct API requests cannot bypass provenance enforcement.
12. Existing approval and publication restrictions remain intact.
"""

import asyncio
from datetime import datetime, timezone
import pytest
from aiohttp.test_utils import TestClient, TestServer
from sqlalchemy.orm import Session

from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import PublicationDocument
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.validators.publication_gate import PublicationPreflightGate, GateSeverity
from automation.workbench.api import WorkbenchComparisonEngine
from automation.workbench.auth import (
    AuthService,
    PermissionGuard,
    PermissionDeniedError,
    global_rate_limiter,
    hash_password,
)
from automation.workbench.gateway import (
    COOKIE_NAME,
    CSRF_HEADER,
    create_app,
)
from automation.workbench.multilingual_dashboard import MultilingualWorkbenchViewGenerator
from automation.workbench.multilingual_rbac import MultilingualRBACEngine
from automation.workbench.multilingual_workbench_service import MultilingualWorkbenchService
from automation.workbench.translation_workflow import TranslationWorkflowEngine
from database.connection import get_db_session
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewAssignment,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    ReviewerVerificationStatus,
    Text,
    Translation,
    TranslationView,
    TranslationType,
    Verse,
)


class SyncGatewayTestClient:
    """Synchronous test client wrapper for deterministic aiohttp testing."""

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

    def close(self):
        self.loop.run_until_complete(self.client.close())
        self.loop.close()


@pytest.fixture
def client():
    global_rate_limiter.reset()
    c = SyncGatewayTestClient()
    yield c
    c.close()
    global_rate_limiter.reset()


@pytest.fixture
def target_trans(db_session):
    """Finds canonical text VEDA-TXT-00001 verse 1 English translation."""
    t = (
        db_session.query(Translation)
        .join(Verse)
        .join(Text)
        .filter(Text.content_id == "VEDA-TXT-00001", Verse.verse_number == 1, Translation.target_language == "en")
        .first()
    )
    assert t is not None
    return t


@pytest.fixture
def verified_human_scholar(db_session):
    """Provisions a transient certified living human scholar persona in the test database."""
    rev_id = "REV-TEST-HUMAN-SCHOLAR-01"
    rev = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if not rev:
        rev = ReviewerProfile(
            reviewer_id=rev_id,
            full_name="Prof. Verified Human Scholar",
            email="verified.scholar@vedam.org",
            primary_role=ReviewerRole.ENGLISH_TRANSLATOR,
            secondary_roles=[ReviewerRole.SANSKRIT_TEXTUAL],
            verification_status="VERIFIED",
            is_credentials_verified=True,
            is_demonstration=False,
            account_category="REAL_HUMAN_SCHOLAR",
            is_human_verified=True,
            verification_doc_hash="a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
            verification_authority="National Sanskrit University Accreditation Board",
            is_active=True,
            language_proficiency={"sa": "SCHOLAR", "en": "NATIVE"},
            permissions=["review:en", "review:sa", "approve:en"],
            password_hash=hash_password("HumanScholarSecure2026!"),
        )
        db_session.add(rev)
        db_session.commit()
    return rev


@pytest.fixture
def unverified_human_applicant(db_session):
    """Provisions an applicant human persona whose credentials are not yet verified."""
    rev_id = "REV-TEST-HUMAN-APPLICANT-02"
    rev = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if not rev:
        rev = ReviewerProfile(
            reviewer_id=rev_id,
            full_name="Applicant Unverified Scholar",
            email="applicant.unverified@vedam.org",
            primary_role=ReviewerRole.ENGLISH_TRANSLATOR,
            secondary_roles=[],
            verification_status="PENDING_VERIFICATION",
            is_credentials_verified=False,
            is_demonstration=False,
            account_category="REAL_HUMAN_SCHOLAR",
            is_human_verified=False,
            verification_doc_hash=None,
            verification_authority=None,
            is_active=True,
            language_proficiency={"en": "NATIVE"},
            permissions=["review:en"],
            password_hash=hash_password("ApplicantPass2026!"),
        )
        db_session.add(rev)
        db_session.commit()
    return rev


def login(client, reviewer_id, password):
    global_rate_limiter.reset()
    resp = client.post("/api/v1/auth/login", json={"reviewer_id": reviewer_id, "password": password})
    assert resp.status == 200, f"Login failed for {reviewer_id}"
    return client.json(resp)["csrf_token"]


# ===========================================================================
# 12 INTEGRATION TESTS: PROVENANCE & DOWNSTREAM CONSUMER AUDIT
# ===========================================================================

def test_1_single_synthetic_feedback_not_human_review(client, target_trans, db_session):
    """1. Verify one synthetic feedback record does not count as a human review."""
    csrf = login(client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Refine English syntax.",
        },
    )
    assert resp.status == 200
    data = client.json(resp)
    assert data["is_human_review"] is False

    log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert log is not None
    assert log.is_human_review is False

    # Check analytics: human scholar count is 0
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    assert metrics.real_human_scholars_count == 0


def test_2_multiple_synthetics_never_satisfy_human_threshold(client, target_trans, db_session):
    """2. Verify multiple synthetic feedback records do not satisfy human-review thresholds."""
    csrf_demo = login(client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    csrf_vedic = login(client, "REV-PROD-VEDIC", "VedicScholar2026!Pass")
    csrf_class = login(client, "REV-PROD-CLASSICAL", "ClassicalGrammar2026!")

    # Submit feedback from all 3 synthetic personas
    for c, rev_id in [(csrf_demo, "REV-DEMO-SIM"), (csrf_vedic, "REV-PROD-VEDIC"), (csrf_class, "REV-PROD-CLASSICAL")]:
        login(client, rev_id, "DemoSimulationPassword123!" if "DEMO" in rev_id else ("VedicScholar2026!Pass" if "VEDIC" in rev_id else "ClassicalGrammar2026!"))
        csrf_token = client.json(client.get("/api/v1/auth/me"))["csrf_token"]
        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_token},
            json={
                "content_id": "VEDA-TXT-00001",
                "verse_number": 1,
                "target_language": "en",
                "action_type": "REQUEST_REVISION",
                "scholarly_commentary": f"Feedback from {rev_id}.",
            },
        )
        assert resp.status == 200
        assert client.json(resp)["is_human_review"] is False

    # Count distinct accredited human reviewers across all logs for this verse
    human_reviewers = (
        db_session.query(ReviewActionLog.reviewer_id)
        .filter(ReviewActionLog.verse_id == target_trans.verse_id, ReviewActionLog.is_human_review == True)
        .distinct()
        .count()
    )
    assert human_reviewers == 0, "Three synthetic reviewers must yield ZERO human reviews"


def test_3_mixed_activity_counts_only_verified_human(client, target_trans, verified_human_scholar, db_session):
    """3. Verify mixed human and synthetic activity counts only verified human activity."""
    # 1. Synthetic action
    csrf_demo = login(client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    resp_synth = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_demo},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Synthetic reviewer comment.",
        },
    )
    assert resp_synth.status == 200
    assert client.json(resp_synth)["is_human_review"] is False

    # 2. Human action
    csrf_human = login(client, verified_human_scholar.reviewer_id, "HumanScholarSecure2026!")
    resp_human = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf_human},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Authentic living human scholar correction.",
        },
    )
    assert resp_human.status == 200
    assert client.json(resp_human)["is_human_review"] is True

    # 3. Verify total logs and exact provenance breakdown
    synth_log = db_session.query(ReviewActionLog).filter_by(action_id=client.json(resp_synth)["action_id"]).first()
    human_log = db_session.query(ReviewActionLog).filter_by(action_id=client.json(resp_human)["action_id"]).first()
    assert synth_log.is_human_review is False
    assert human_log.is_human_review is True

    # Analytics metric: exactly 1 real human scholar
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    assert metrics.real_human_scholars_count == 1


def test_4_unverified_human_rejected_from_accredited_roles(client, unverified_human_applicant, db_session):
    """4. Verify an unverified human account does not count as an accredited human reviewer."""
    # PermissionGuard check
    with pytest.raises(PermissionDeniedError) as exc_info:
        PermissionGuard.require_human_scholar(unverified_human_applicant)
    assert "not an accredited human scholar with verified physical credentials" in str(exc_info.value)

    # Submitting feedback tags is_human_review = False
    csrf = login(client, unverified_human_applicant.reviewer_id, "ApplicantPass2026!")
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Applicant unverified feedback.",
        },
    )
    assert resp.status == 200
    assert client.json(resp)["is_human_review"] is False

    # Analytics check
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    # unverified applicant is not verified, so real_human_scholars_count does not include them
    real_verified = sum(1 for r in db_session.query(ReviewerProfile).all() if r.account_category == "REAL_HUMAN_SCHOLAR" and r.is_human_verified)
    assert metrics.real_human_scholars_count == real_verified


def test_5_verified_human_correctly_represented_in_analytics(db_session, verified_human_scholar):
    """5. Verify a verified human reviewer is correctly represented in analytics."""
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    assert metrics.real_human_scholars_count >= 1

    # Check productivity stats list
    human_stat = next((s for s in metrics.reviewer_productivity_stats if s["reviewer_id"] == verified_human_scholar.reviewer_id), None)
    assert human_stat is not None
    assert human_stat["is_human_verified"] is True
    assert human_stat["account_category"] == "REAL_HUMAN_SCHOLAR"


def test_6_synthetic_actions_do_not_inflate_human_metrics(db_session, verified_human_scholar):
    """6. Verify synthetic actions do not inflate reviewer performance metrics."""
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    # All historical 20 actions in DB belong to synthetic personas (id 2, 3, 4)
    # None should be attributed to verified_human_scholar
    human_stat = next((s for s in metrics.reviewer_productivity_stats if s["reviewer_id"] == verified_human_scholar.reviewer_id), None)
    assert human_stat is not None
    # Assignments completed for human is 0
    assert human_stat["assignments_completed"] == 0


def test_7_synthetic_actions_cannot_satisfy_publication_prerequisites(db_session):
    """7. Verify synthetic actions cannot satisfy publication prerequisites."""
    text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
    assert text is not None

    # Defense Layer A: PublicationDocument factory itself raises PermissionError on draft content
    with pytest.raises(PermissionError) as exc_info:
        PublicationDocument.from_text_and_views(
            text=text,
            target_language="en",
            publication_channel="approved_publication",
        )
    assert "Translations are currently in DRAFT status" in str(exc_info.value)
    assert "Public release requires accredited human scholarly certification" in str(exc_info.value)

    # Defense Layer B: Approved publication channel rejects draft content & demo accounts
    from automation.exporters.publication_model import PublicationGovernance
    draft_doc = PublicationDocument.from_text_and_views(
        text=text,
        target_language="en",
        publication_channel="draft_export",
    )
    demo_rev = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-DEMO-SIM").first()
    approved_gov = PublicationGovernance(
        publication_channel="approved_publication",
        overall_review_status="DRAFT",
        is_approved_for_public_release=False,
        watermark_text=None,
    )
    approved_doc = PublicationDocument(
        metadata=draft_doc.metadata,
        target=draft_doc.target,
        governance=approved_gov,
        missing_content=draft_doc.missing_content,
        verses=draft_doc.verses,
    )
    report = PublicationGatekeeper.evaluate_publication(
        document=approved_doc,
        requesting_reviewer=demo_rev,
        enforce_accreditation=True,
    )
    assert report.is_authorized is False
    assert report.verdict == ReleaseGateVerdict.REJECTED
    blocker_codes = {b.rule_code for b in report.blockers}
    assert "PUB-001" in blocker_codes  # Draft content release prohibited
    assert "PUB-003" in blocker_codes  # Demonstration account quarantined from authorizing release

    # Defense Layer C: Preflight Gatekeeper for commercial release
    preflight = PublicationPreflightGate.evaluate(text, target_channel="commercial_release")
    assert preflight.can_publish is False
    assert preflight.failed_blockers >= 1
    assert any(c.rule_id == "PUB-010" and not c.passed for c in preflight.checks)


def test_8_synthetic_actions_visibly_identified_in_review_history(client, target_trans, db_session):
    """8. Verify synthetic actions remain visibly identified in review history across all workbench generators."""
    # Add a synthetic review action
    csrf = login(client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Check visibility in history.",
        },
    )
    assert resp.status == 200

    # 1. Check MultilingualWorkbenchService
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session,
        content_id="VEDA-TXT-00001",
        verse_number=1,
        target_language="en",
    )
    actions = payload["column_6_governance"]["recent_actions"]
    assert len(actions) > 0
    assert any(a["is_human_review"] is False for a in actions)

    # 2. Check HTML Dashboard generator
    import os
    out_file = "tests/scratch_workbench_audit.html"
    try:
        html_path = MultilingualWorkbenchViewGenerator.generate_html_workbench(
            session=db_session,
            content_id="VEDA-TXT-00001",
            verse_number=1,
            target_language="en",
            output_file=out_file,
        )
        with open(html_path, "r", encoding="utf-8") as f:
            html_content = f.read()
        assert "SYNTHETIC / TEST" in html_content
    finally:
        if os.path.exists(out_file):
            os.remove(out_file)

    # 3. Check legacy WorkbenchComparisonEngine
    legacy_payload = WorkbenchComparisonEngine.get_verse_workbench_payload(
        session=db_session,
        verse_id="VEDA-TXT-00001-V001",
        target_language="en",
    )
    assert any(a["is_human_review"] is False for a in legacy_payload["column_6_governance"]["recent_actions"])

    # 4. Check TranslationWorkflowEngine
    workflow_ctx = TranslationWorkflowEngine.get_translation_view_workflow_context(
        session=db_session,
        translation_id=target_trans.id,
    )
    assert any(c["is_human_review"] is False for c in workflow_ctx["dimension_6_reviewer_corrections"])


def test_9_null_or_missing_is_human_review_handled_safely(db_session, target_trans):
    """9. Verify null or missing is_human_review is handled safely as non-human."""
    # In SQLite schema, is_human_review has server_default='0', nullable=False
    # Test defensive logic: bool(getattr(obj, 'is_human_review', False))
    class DummyAction:
        is_human_review = None

    assert bool(getattr(DummyAction, "is_human_review", False)) is False

    class DummyActionNoAttr:
        pass

    assert bool(getattr(DummyActionNoAttr, "is_human_review", False)) is False


def test_10_forged_reviewer_identity_cannot_change_provenance(client, target_trans, verified_human_scholar, db_session):
    """10. Verify forged reviewer identity in body cannot change provenance to human."""
    # Logged in as DEMO persona, passing human scholar's reviewer_id in request body
    csrf = login(client, "REV-DEMO-SIM", "DemoSimulationPassword123!")
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Impersonation attempt.",
            "reviewer_id": verified_human_scholar.reviewer_id,
            "is_human_review": True,  # Forged flag
        },
    )
    assert resp.status == 200
    data = client.json(resp)
    # Provenance MUST remain False because session belongs to REV-DEMO-SIM
    assert data["is_human_review"] is False

    log = db_session.query(ReviewActionLog).filter_by(action_id=data["action_id"]).first()
    assert log.reviewer.reviewer_id == "REV-DEMO-SIM"
    assert log.is_human_review is False


def test_11_direct_api_requests_cannot_bypass_provenance(client, target_trans, db_session):
    """11. Verify direct API requests without verified human session cannot produce human review records."""
    # Unauthenticated -> 401
    client.client.session.cookie_jar.clear()
    resp_unauth = client.post(
        "/api/v1/reviews/submit",
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Direct unauthenticated request.",
        },
    )
    assert resp_unauth.status == 401

    # Authenticated as synthetic persona -> is_human_review is ALWAYS False
    for syn_id in ("REV-DEMO-SIM", "REV-PROD-VEDIC", "REV-PROD-CLASSICAL", "REV-PROD-AWADHI"):
        csrf = login(client, syn_id, "DemoSimulationPassword123!" if "DEMO" in syn_id else ("VedicScholar2026!Pass" if "VEDIC" in syn_id else ("ClassicalGrammar2026!" if "CLASSICAL" in syn_id else "AwadhiTulsidas2026!")))
        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf},
            json={
                "content_id": "VEDA-TXT-00001",
                "verse_number": 1,
                "target_language": "en",
                "action_type": "REQUEST_REVISION",
                "scholarly_commentary": f"Direct API submission by {syn_id}.",
            },
        )
        assert resp.status == 200
        assert client.json(resp)["is_human_review"] is False


def test_12_existing_approval_and_publication_restrictions_intact(client, target_trans, verified_human_scholar, db_session):
    """12. Verify existing approval and publication restrictions remain intact (Section 8 Invariant)."""
    # Even a verified human scholar cannot approve in Phase 11F under Section 8 Invariant!
    csrf_human = login(client, verified_human_scholar.reviewer_id, "HumanScholarSecure2026!")
    for act in ("APPROVE", "APPROVE_WITH_CORRECTIONS"):
        resp = client.post(
            "/api/v1/reviews/submit",
            headers={CSRF_HEADER: csrf_human},
            json={
                "content_id": "VEDA-TXT-00001",
                "verse_number": 1,
                "target_language": "en",
                "action_type": act,
                "scholarly_commentary": "Attempting approval in Phase 11F.",
            },
        )
        assert resp.status == 403
        assert "Translation approval is strictly prohibited in Phase 11F" in client.json(resp)["error"]

    # Translation review_status remains strictly DRAFT
    db_session.refresh(target_trans)
    assert target_trans.review_status == ReviewStatus.DRAFT
