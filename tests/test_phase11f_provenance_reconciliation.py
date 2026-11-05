"""
VEDAM PHASE 11F: PROVENANCE RECONCILIATION AND ANALYTICS AUDIT
Targeted test suite verifying:
1. Reconciling the 6 quarantined reviewer accounts (5 synthetic test personas + 1 demonstration account).
2. Deep audit of analytics metrics, per-reviewer productivity, and language completion.
3. Trusted provenance derivation and compound fail-closed enforcement.
4. Handling of ambiguous, null, or inconsistent provenance.
"""

import asyncio
from datetime import datetime, timezone
import pytest
from aiohttp.test_utils import TestClient, TestServer
from sqlalchemy.orm import Session

from automation.reporting.library_analytics import LibraryAnalyticsEngine
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
from automation.workbench.review_action_engine import ReviewActionEngine
from automation.workbench.translation_view_backfill import TranslationViewBackfillEngine
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
    Text,
    Translation,
    TranslationView,
    TranslationType,
    Verse,
)
from database.schemas import ReviewActionLogCreate


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


def login(client, reviewer_id, password):
    global_rate_limiter.reset()
    resp = client.post("/api/v1/auth/login", json={"reviewer_id": reviewer_id, "password": password})
    assert resp.status == 200, f"Login failed for {reviewer_id}"
    return client.json(resp)["csrf_token"]


PROD_BASELINE_REVIEWER_IDS = {
    "REV-ADMIN-001",
    "REV-PROD-VEDIC",
    "REV-PROD-CLASSICAL",
    "REV-PROD-AWADHI",
    "REV-DEMO-SIM",
    "REV-APPLICANT-PENDING",
}


# ===========================================================================
# 1. SIX-ACCOUNT RECONCILIATION TESTS
# ===========================================================================

def test_six_accounts_reconciliation_and_quarantine(db_session):
    """
    Reconciles the 6 production accounts:
    - 5 Synthetic Test Personas (REV-ADMIN-001, REV-PROD-VEDIC, REV-PROD-CLASSICAL, REV-PROD-AWADHI, REV-APPLICANT-PENDING)
    - 1 Demonstration Account (REV-DEMO-SIM)
    Total = 6. All 6 remain quarantined with is_human_verified = False.
    """
    reviewers = (
        db_session.query(ReviewerProfile)
        .filter(ReviewerProfile.reviewer_id.in_(PROD_BASELINE_REVIEWER_IDS))
        .all()
    )
    assert len(reviewers) == 6, f"Expected exactly 6 baseline reviewer profiles, found {len(reviewers)}"

    demo_accounts = [r for r in reviewers if r.is_demonstration or r.account_category == "DEMONSTRATION_HARNESS"]
    synthetic_personas = [r for r in reviewers if r.account_category == "SYNTHETIC_TEST_PERSONA"]

    assert len(demo_accounts) == 1, "Expected exactly 1 demonstration account"
    assert len(synthetic_personas) == 5, "Expected exactly 5 synthetic test personas"
    assert len(demo_accounts) + len(synthetic_personas) == 6

    # Verify REV-DEMO-SIM
    demo = demo_accounts[0]
    assert demo.reviewer_id == "REV-DEMO-SIM"
    assert demo.is_demonstration is True
    assert demo.account_category == "DEMONSTRATION_HARNESS"
    assert demo.verification_status == "DEMO"
    assert demo.is_human_verified is False

    # Verify the 5 synthetic personas
    expected_syn_ids = {
        "REV-ADMIN-001",
        "REV-PROD-VEDIC",
        "REV-PROD-CLASSICAL",
        "REV-PROD-AWADHI",
        "REV-APPLICANT-PENDING",
    }
    actual_syn_ids = {r.reviewer_id for r in synthetic_personas}
    assert actual_syn_ids == expected_syn_ids

    for syn in synthetic_personas:
        assert syn.is_demonstration is False
        assert syn.account_category == "SYNTHETIC_TEST_PERSONA"
        assert syn.is_human_verified is False

    # Verify that NONE of the 6 can pass PermissionGuard.require_human_scholar
    for r in reviewers:
        with pytest.raises(PermissionDeniedError):
            PermissionGuard.require_human_scholar(r)


def test_roles_and_proficiency_never_confer_human_status(db_session):
    """
    Verifies that roles (e.g. EDITORIAL_BOARD), degrees, Sanskrit proficiency (Acharya/Ghanapathi),
    and permissions (e.g. APPROVE_TRANSLATION) NEVER confer human status without
    account_category == 'REAL_HUMAN_SCHOLAR' and is_human_verified == True.
    """
    admin = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-ADMIN-001").first()
    assert admin.primary_role == ReviewerRole.EDITORIAL_BOARD
    assert "APPROVE_TRANSLATION" in (admin.permissions or [])
    assert admin.sanskrit_proficiency == "Acharya"

    # Even with EDITORIAL_BOARD, Acharya, and APPROVE_TRANSLATION, require_human_scholar strictly rejects
    with pytest.raises(PermissionDeniedError) as exc_info:
        PermissionGuard.require_human_scholar(admin)
    assert "synthetic test persona" in str(exc_info.value).lower()


# ===========================================================================
# 2. DEEP ANALYTICS EXCLUSION TESTS
# ===========================================================================

def test_analytics_strictly_segregates_synthetic_and_human(db_session):
    """
    Inspects all analytics calculations to confirm:
    - Baseline 6 accounts are strictly segregated into synthetic_test_personas and demonstration_accounts.
    - Zero baseline accounts are counted under real_human_scholars_count.
    - scholar_approved_translations is 0 across all active translations.
    - all language review completion percentages and approved translation counts are 0.
    """
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)

    # All baseline synthetic accounts are segregated
    assert metrics.synthetic_test_personas_count >= 5
    assert metrics.demonstration_accounts >= 1
    assert metrics.scholar_approved_translations == 0
    assert metrics.human_corrected_ai_annotations == 0

    # Ensure none of the 6 production personas contribute to real_human_scholars_count
    baseline_reviewers = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.in_(PROD_BASELINE_REVIEWER_IDS)).all()
    assert all(not (r.account_category == "REAL_HUMAN_SCHOLAR" and r.is_human_verified) for r in baseline_reviewers)

    # Check language review completion map
    for lang, comp in metrics.language_review_completion.items():
        assert comp["approved_translations"] == 0, f"Expected 0 approved translations for {lang}"
        assert comp["completion_pct"] == 0.0, f"Expected 0.0% completion for {lang}"
    # Approved views reflect legacy Phase 7/8 pilot fixtures (8 EN, 1 TE)
    assert metrics.language_review_completion["en"]["approved_views"] == 8
    assert metrics.language_review_completion["te"]["approved_views"] == 1
    assert metrics.approved_translation_views == 9


def test_reviewer_productivity_cards_isolate_actions_and_provenance(db_session):
    """
    Verifies that reviewer_productivity_stats:
    - Provides explicit is_human_verified and account_category for each reviewer.
    - Isolates review_actions_logged to the specific reviewer ID.
    - Does not contain rankings or leaderboards that combine human and synthetic activity.
    """
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db_session)
    stats = metrics.reviewer_productivity_stats
    prod_stats = [s for s in stats if s["reviewer_id"] in PROD_BASELINE_REVIEWER_IDS]
    assert len(prod_stats) == 6

    for s in prod_stats:
        assert s["is_human_verified"] is False
        assert s["account_category"] in ("SYNTHETIC_TEST_PERSONA", "DEMONSTRATION_HARNESS")
        # Ensure count matches the actual DB actions for that reviewer
        actual_cnt = db_session.query(ReviewActionLog).filter_by(reviewer_id=db_session.query(ReviewerProfile).filter_by(reviewer_id=s["reviewer_id"]).first().id).count()
        assert s["review_actions_logged"] == actual_cnt


# ===========================================================================
# 3. COMPOUND TRUSTED PROVENANCE DERIVATION TESTS
# ===========================================================================

def test_compound_check_fails_closed_if_synthetic_has_human_verified_flag(client, db_session):
    """
    CRITICAL EDGE CASE TEST:
    If a synthetic account somehow has is_human_verified=True set in the DB,
    the compound check (account_category == 'REAL_HUMAN_SCHOLAR' AND is_human_verified == True)
    must STILL fail closed and stamp is_human_review = False.
    """
    # Create a test reviewer with mismatched flags: SYNTHETIC_TEST_PERSONA but is_human_verified=True
    mismatched = ReviewerProfile(
        reviewer_id="REV-TEST-MISMATCHED",
        full_name="Mismatched Flag Reviewer",
        email="mismatched@example.com",
        primary_role=ReviewerRole.ENGLISH_TRANSLATOR,
        secondary_roles=[],
        verification_status="VERIFIED",
        is_credentials_verified=True,
        is_demonstration=False,
        account_category="SYNTHETIC_TEST_PERSONA",  # Not REAL_HUMAN_SCHOLAR!
        is_human_verified=True,                      # Inconsistent flag
        is_active=True,
        permissions=["review:en"],
        password_hash=hash_password("MismatchedPass2026!"),
    )
    db_session.add(mismatched)
    db_session.commit()

    # 1. Gateway API submission
    csrf = login(client, "REV-TEST-MISMATCHED", "MismatchedPass2026!")
    resp = client.post(
        "/api/v1/reviews/submit",
        headers={CSRF_HEADER: csrf},
        json={
            "content_id": "VEDA-TXT-00001",
            "verse_number": 1,
            "target_language": "en",
            "action_type": "REQUEST_REVISION",
            "scholarly_commentary": "Testing compound check fail-closed behavior.",
        },
    )
    assert resp.status == 200
    assert client.json(resp)["is_human_review"] is False

    # 2. ReviewActionEngine submission
    t = db_session.query(Translation).first()
    v = db_session.query(Verse).filter_by(id=t.verse_id).first()
    engine_log = ReviewActionEngine.execute_action(
        session=db_session,
        action_data=ReviewActionLogCreate(
            translation_id=t.id,
            verse_id=v.id,
            reviewer_id=mismatched.id,
            action_type=ReviewActionType.REQUEST_REVISION,
            previous_status="DRAFT",
            new_status="DRAFT",
            scholarly_commentary="Engine compound check test.",
        ),
    )
    assert engine_log.is_human_review is False

    # 3. TranslationViewBackfill submission
    view = db_session.query(TranslationView).first()
    if view:
        backfill_view = TranslationViewBackfillEngine.approve_view_independently(
            session=db_session,
            view_id=view.view_id,
            reviewer_id=mismatched.id,
            scholarly_commentary="Backfill compound check test.",
        )
        backfill_log = db_session.query(ReviewActionLog).filter_by(translation_view_id=view.id, reviewer_id=mismatched.id).first()
        assert backfill_log is not None
        assert backfill_log.is_human_review is False


# ===========================================================================
# 4. AMBIGUOUS / NULL PROVENANCE TESTS
# ===========================================================================

def test_ambiguous_or_null_provenance_fails_closed(db_session):
    """
    Verifies that historical or corrupted log entries with is_human_review = None
    fail closed across all query and presentation engines.
    """
    t = db_session.query(Translation).first()
    v = db_session.query(Verse).filter_by(id=t.verse_id).first()
    rev = db_session.query(ReviewerProfile).first()

    null_log = ReviewActionLog(
        action_id="ACT-TEST-NULL-PROVENANCE",
        translation_id=t.id,
        verse_id=v.id,
        reviewer_id=rev.id,
        action_type=ReviewActionType.REQUEST_REVISION,
        previous_status="DRAFT",
        new_status="DRAFT",
        scholarly_commentary="Testing null provenance.",
        original_text_immutable_verified=True,
        is_human_review=None,  # Null provenance
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(null_log)
    db_session.commit()

    # 1. MultilingualWorkbenchService
    payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
        session=db_session,
        content_id=v.text.content_id,
        verse_number=v.verse_number,
        target_language=t.target_language,
        reviewer_id=rev.reviewer_id,
    )
    history = payload.get("column_6_governance", {}).get("recent_actions", [])
    matching = [h for h in history if h.get("action_id") == "ACT-TEST-NULL-PROVENANCE"]
    assert len(matching) == 1
    assert matching[0]["is_human_review"] is False

    # 2. WorkbenchComparisonEngine (api.py)
    legacy_payload = WorkbenchComparisonEngine.get_verse_workbench_payload(
        session=db_session,
        verse_id=v.verse_id,
        target_language=t.target_language,
    )
    legacy_actions = legacy_payload.get("column_6_governance", {}).get("recent_actions", [])
    legacy_matching = [a for a in legacy_actions if a.get("action_id") == "ACT-TEST-NULL-PROVENANCE"]
    assert len(legacy_matching) == 1
    assert legacy_matching[0]["is_human_review"] is False

    # 3. TranslationWorkflowEngine
    workflow_ctx = TranslationWorkflowEngine.get_translation_view_workflow_context(
        session=db_session,
        translation_id=t.id,
        view_type="LITERAL",
    )
    wf_history = workflow_ctx.get("dimension_6_reviewer_corrections", [])
    wf_matching = [a for a in wf_history if a.get("action_id") == "ACT-TEST-NULL-PROVENANCE"]
    assert len(wf_matching) == 1
    assert wf_matching[0]["is_human_review"] is False
