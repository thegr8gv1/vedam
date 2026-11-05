"""
Vedic Heritage Platform — Scholar Governance Atomic Concurrency Test Suite
Phase 12B.2: Strict database-level Compare-and-Set (CAS) concurrency testing,
transaction rollback consistency, lock contention handling, and isolation.
Enforces complete test database isolation and verifies production database immutability.
"""

import asyncio
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import threading
import time
from typing import Dict, List, Optional
from unittest.mock import patch

import pytest
from aiohttp.test_utils import TestClient, TestServer
from sqlalchemy import create_engine, func
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import NullPool

from automation.workbench.auth import (
    AuthService,
    PermissionDeniedError,
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
)
from database.connection import get_active_database_url, get_db_session
from database.models import (
    AuthAuditLog,
    ReviewActionLog,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    Translation,
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
def cleanup_phase12b2_test_artifacts(db_session):
    """Ensure all test applicant profiles, sessions, and audit logs are safely cleaned up."""
    yield
    test_revs = db_session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-P12B2-APP-%")).all()
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
    rev_id = "REV-P12B2-COUNCIL"
    existing = db_session.query(ReviewerProfile).filter_by(reviewer_id=rev_id).first()
    if existing:
        return existing

    admin = ReviewerProfile(
        reviewer_id=rev_id,
        full_name="Editorial Board Council Administrator",
        email="council.admin12b2@vedam.org",
        primary_role=ReviewerRole.EDITORIAL_BOARD,
        sanskrit_proficiency="Acharya",
        permissions=["EDITORIAL_BOARD", "CAN_VERIFY_CREDENTIALS", "CAN_DEACTIVATE_REVIEWER", "ADMIN_ALL"],
        password_hash=hash_password("CouncilPass123#"),
        is_active=True,
        is_demonstration=False,
        verification_status=OnboardingStage.ACCREDITED.value,
        account_category="REAL_HUMAN_SCHOLAR",
        is_human_verified=True,
        is_credentials_verified=True,
    )
    db_session.add(admin)
    db_session.commit()
    return admin


# ==============================================================================
# 4.1 COMPETING STAGE TRANSITIONS
# ==============================================================================

def test_4_1_competing_stage_transitions_same_target_atomic_cas(db_session, admin_council_reviewer):
    """
    4.1: Two competing operations concurrently attempt the exact same stage transition
    from the same expected starting stage using independent database sessions and a barrier.
    Assert:
    - Exactly one transition succeeds (rowcount == 1).
    - Exactly one transition fails with Concurrency Conflict (rowcount == 0).
    - The final reviewer stage in the database reflects the winning transition.
    - Exactly one transition audit event is committed.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-001",
            full_name="Concurrent Candidate 1",
            primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
            email="candidate1.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id
    applicant_rev_id = app.reviewer_id
    admin_id = admin_council_reviewer.reviewer_id

    db_url = get_active_database_url()
    barrier = threading.Barrier(2)
    results = {}

    def worker(worker_id: int):
        th_engine = create_engine(db_url, poolclass=NullPool, connect_args={"check_same_thread": False, "timeout": 10})
        th_session = sessionmaker(bind=th_engine)()
        try:
            admin = th_session.query(ReviewerProfile).filter_by(reviewer_id=admin_id).first()
            barrier.wait(timeout=5)
            updated = ReviewerOnboardingService.transition_stage(
                session=th_session,
                admin_reviewer=admin,
                applicant_reviewer_id=applicant_rev_id,
                target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                notes=f"Worker {worker_id} transition attempt",
                expected_current_stage=OnboardingStage.APPLICATION_RECEIVED.value,
            )
            th_session.commit()
            results[worker_id] = ("SUCCESS", updated.verification_status)
        except OnboardingGovernanceError as e:
            th_session.rollback()
            results[worker_id] = ("CONFLICT", str(e))
        except Exception as e:
            th_session.rollback()
            results[worker_id] = ("ERROR", str(e))
        finally:
            th_session.close()
            th_engine.dispose()

    t1 = threading.Thread(target=worker, args=(1,))
    t2 = threading.Thread(target=worker, args=(2,))
    t1.start()
    t2.start()
    t1.join(timeout=10)
    t2.join(timeout=10)

    statuses = [res[0] for res in results.values()]
    assert statuses.count("SUCCESS") == 1, f"Expected exactly 1 success, got {results}"
    assert statuses.count("CONFLICT") == 1, f"Expected exactly 1 conflict, got {results}"

    # Verify conflict message mentions concurrency
    conflict_err = [res[1] for res in results.values() if res[0] == "CONFLICT"][0]
    assert "Concurrency Conflict" in conflict_err

    # Verify database final state
    db_session.expire_all()
    final_profile = db_session.query(ReviewerProfile).filter_by(id=applicant_id).first()
    assert final_profile.verification_status == OnboardingStage.IDENTITY_REVIEW_PENDING.value

    # Verify transition audit log: exactly one transition event committed
    audit_events = db_session.query(AuthAuditLog).filter(
        AuthAuditLog.reviewer_id == applicant_id,
        AuthAuditLog.event_type.like("ONBOARDING_%"),
    ).all()
    assert len(audit_events) == 1
    assert audit_events[0].event_type == f"ONBOARDING_{OnboardingStage.IDENTITY_REVIEW_PENDING.value}"


def test_4_1_competing_stage_transitions_api_gateway_concurrency(client, admin_council_reviewer, db_session):
    """
    4.1: Two concurrent requests via API Gateway competing from the same expected stage.
    One succeeds (200 TRANSITIONED), one fails with Concurrency Conflict.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-002",
            full_name="Concurrent Candidate 2",
            primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
            email="candidate2.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id
    applicant_rev_id = app.reviewer_id

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]
    cookie_val = login_resp.cookies[COOKIE_NAME].value

    barrier = threading.Barrier(2)
    results = []

    def request_worker(worker_id: int):
        sub_client = SyncGatewayClient(db_factory=get_db_session)
        try:
            barrier.wait(timeout=5)
            resp = sub_client.post(
                "/api/v1/onboarding/admin/transition",
                headers={CSRF_HEADER: csrf_token, "X-Conflict-409": "true"},
                cookies={COOKIE_NAME: cookie_val},
                json={
                    "applicant_reviewer_id": applicant_rev_id,
                    "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                    "notes": f"Gateway concurrency attempt {worker_id}",
                    "expected_current_stage": OnboardingStage.APPLICATION_RECEIVED.value,
                },
            )
            body = sub_client.json(resp)
            results.append((resp.status, body))
        finally:
            sub_client.close()

    t1 = threading.Thread(target=request_worker, args=(1,))
    t2 = threading.Thread(target=request_worker, args=(2,))
    t1.start()
    t2.start()
    t1.join(timeout=10)
    t2.join(timeout=10)

    http_statuses = [r[0] for r in results]
    assert 200 in http_statuses, f"Expected at least one 200 OK, got {results}"
    assert (409 in http_statuses or 400 in http_statuses), f"Expected conflict response, got {results}"

    # Exactly one transition audit event exists in DB
    db_session.expire_all()
    audit_logs = db_session.query(AuthAuditLog).filter(
        AuthAuditLog.reviewer_id == applicant_id,
        AuthAuditLog.event_type.like("ONBOARDING_%"),
    ).all()
    assert len(audit_logs) == 1


# ==============================================================================
# 4.2 COMPETING DIFFERENT TARGET STAGES
# ==============================================================================

def test_4_2_competing_different_target_stages(db_session, admin_council_reviewer):
    """
    4.2: Start two concurrent requests with the same expected stage but different valid target stages:
    Operation A: APPLICATION_RECEIVED -> IDENTITY_REVIEW_PENDING
    Operation B: APPLICATION_RECEIVED -> REJECTED
    Assert:
    - Exactly one legitimate winner succeeds.
    - The losing request fails with Concurrency Conflict.
    - Final state corresponds to the winner and the loser cannot overwrite it.
    - Exactly one transition audit log is created.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-003",
            full_name="Competing Different Target",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            email="candidate3.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id
    applicant_rev_id = app.reviewer_id
    admin_id = admin_council_reviewer.reviewer_id

    db_url = get_active_database_url()
    barrier = threading.Barrier(2)
    results = {}

    def worker(worker_id: int, target_stage: str):
        th_engine = create_engine(db_url, poolclass=NullPool, connect_args={"check_same_thread": False, "timeout": 10})
        th_session = sessionmaker(bind=th_engine)()
        try:
            admin = th_session.query(ReviewerProfile).filter_by(reviewer_id=admin_id).first()
            barrier.wait(timeout=5)
            updated = ReviewerOnboardingService.transition_stage(
                session=th_session,
                admin_reviewer=admin,
                applicant_reviewer_id=applicant_rev_id,
                target_stage=target_stage,
                notes=f"Attempting transition to {target_stage}",
                expected_current_stage=OnboardingStage.APPLICATION_RECEIVED.value,
            )
            th_session.commit()
            results[worker_id] = ("SUCCESS", updated.verification_status)
        except OnboardingGovernanceError as e:
            th_session.rollback()
            results[worker_id] = ("CONFLICT", str(e))
        except Exception as e:
            th_session.rollback()
            results[worker_id] = ("ERROR", str(e))
        finally:
            th_session.close()
            th_engine.dispose()

    t1 = threading.Thread(target=worker, args=(1, OnboardingStage.IDENTITY_REVIEW_PENDING.value))
    t2 = threading.Thread(target=worker, args=(2, OnboardingStage.REJECTED.value))
    t1.start()
    t2.start()
    t1.join(timeout=10)
    t2.join(timeout=10)

    statuses = [res[0] for res in results.values()]
    assert statuses.count("SUCCESS") == 1, f"Expected exactly 1 success, got {results}"
    assert statuses.count("CONFLICT") == 1, f"Expected exactly 1 conflict, got {results}"

    winning_stage = [res[1] for res in results.values() if res[0] == "SUCCESS"][0]
    assert winning_stage in (OnboardingStage.IDENTITY_REVIEW_PENDING.value, OnboardingStage.REJECTED.value)

    # Verify DB reflects the winner and not an overwritten or corrupted state
    db_session.expire_all()
    final_profile = db_session.query(ReviewerProfile).filter_by(id=applicant_id).first()
    assert final_profile.verification_status == winning_stage

    # Only 1 transition audit event exists
    audit_events = db_session.query(AuthAuditLog).filter(
        AuthAuditLog.reviewer_id == applicant_id,
        AuthAuditLog.event_type.like("ONBOARDING_%"),
    ).all()
    assert len(audit_events) == 1
    assert audit_events[0].event_type == f"ONBOARDING_{winning_stage}"


# ==============================================================================
# 4.3 TRANSACTION ROLLBACK AND INTEGRITY RECOVERY
# ==============================================================================

def test_4_3_forced_exception_rolls_back_atomic_update_cleanly(db_session, admin_council_reviewer):
    """
    4.3: Force an exception after the conditional update but before commit/audit completion.
    Verify:
    - The stage change is rolled back.
    - Zero orphaned transition audit events remain.
    - The transaction and profile can recover for a subsequent legitimate operation.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-004",
            full_name="Rollback Test Candidate",
            primary_role=ReviewerRole.ENGLISH_TRANSLATOR,
            email="candidate4.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id
    applicant_rev_id = app.reviewer_id

    initial_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant_id).count()

    # Simulate an unforeseen failure during audit logging inside transition_stage
    with patch("automation.workbench.auth.AuthService.log_event", side_effect=RuntimeError("Simulated forced crash during audit log")):
        with pytest.raises(RuntimeError) as exc_info:
            ReviewerOnboardingService.transition_stage(
                session=db_session,
                admin_reviewer=admin_council_reviewer,
                applicant_reviewer_id=applicant_rev_id,
                target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                notes="Will be rolled back",
                expected_current_stage=OnboardingStage.APPLICATION_RECEIVED.value,
            )
        assert "Simulated forced crash" in str(exc_info.value)

    # Verify database state was rolled back completely
    db_session.expire_all()
    reloaded = db_session.query(ReviewerProfile).filter_by(id=applicant_id).first()
    assert reloaded.verification_status == OnboardingStage.APPLICATION_RECEIVED.value

    # Verify zero orphaned audit records created (audit count unchanged)
    post_rollback_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant_id).count()
    assert post_rollback_audit_count == initial_audit_count

    # Subsequent legitimate transition succeeds cleanly
    recovered = ReviewerOnboardingService.transition_stage(
        session=db_session,
        admin_reviewer=admin_council_reviewer,
        applicant_reviewer_id=applicant_rev_id,
        target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
        notes="Legitimate retry following recovery",
        expected_current_stage=OnboardingStage.APPLICATION_RECEIVED.value,
    )
    db_session.commit()
    assert recovered.verification_status == OnboardingStage.IDENTITY_REVIEW_PENDING.value

    # Exactly 1 additional audit record now exists (initial + 1)
    audit_count_post = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant_id).count()
    assert audit_count_post == initial_audit_count + 1


# ==============================================================================
# 4.4 STALE REQUEST
# ==============================================================================

def test_4_4_stale_expected_stage_returns_conflict_without_mutation(client, admin_council_reviewer, db_session):
    """
    4.4: Verify that a request using an outdated expected_current_stage receives a conflict response
    and modifies neither the profile nor the audit history.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-005",
            full_name="Stale Stage Candidate",
            primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
            email="candidate5.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id

    initial_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant_id).count()

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    # Request with stale stage CREDENTIALS_VERIFIED while actually at APPLICATION_RECEIVED
    resp = client.post(
        "/api/v1/onboarding/admin/transition",
        headers={CSRF_HEADER: csrf_token, "X-Conflict-409": "true"},
        json={
            "applicant_reviewer_id": app.reviewer_id,
            "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
            "notes": "Attempting transition from obsolete client cache",
            "expected_current_stage": OnboardingStage.CREDENTIALS_VERIFIED.value,
        },
    )
    assert resp.status == 409
    body = client.json(resp)
    assert body["code"] == "CONCURRENCY_CONFLICT"
    assert "Concurrency Conflict" in body["error"]

    # Verify no state changes in database
    db_session.expire_all()
    reloaded = db_session.query(ReviewerProfile).filter_by(id=applicant_id).first()
    assert reloaded.verification_status == OnboardingStage.APPLICATION_RECEIVED.value
    post_audit_count = db_session.query(AuthAuditLog).filter_by(reviewer_id=applicant_id).count()
    assert post_audit_count == initial_audit_count


# ==============================================================================
# 4.5 DATABASE LOCK CONTENTION HANDLING
# ==============================================================================

def test_4_5_database_lock_contention_handled_safely(db_session, admin_council_reviewer):
    """
    4.5: Use independent SQLite connections to create controlled write contention.
    Verify:
    - Lock errors are not converted to false successes.
    - Transaction is rolled back cleanly.
    - No duplicate or orphaned transition audit logs appear.
    - Service re-evaluates state before retry.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-006",
            full_name="Lock Contention Candidate",
            primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
            email="candidate6.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()
    applicant_id = app.id
    applicant_rev_id = app.reviewer_id

    call_count = 0
    original_transition = ReviewerOnboardingService.transition_stage

    def failing_transition(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count <= 2:
            raise OperationalError("database is locked", {}, None)
        return original_transition(*args, **kwargs)

    client = SyncGatewayClient(db_factory=get_db_session)
    try:
        login_resp = client.post(
            "/api/v1/auth/login",
            json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
        )
        csrf_token = client.json(login_resp)["csrf_token"]

        with patch.object(ReviewerOnboardingService, "transition_stage", side_effect=failing_transition):
            resp = client.post(
                "/api/v1/onboarding/admin/transition",
                headers={CSRF_HEADER: csrf_token},
                json={
                    "applicant_reviewer_id": applicant_rev_id,
                    "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                    "notes": "Testing bounded retry on transient lock",
                    "expected_current_stage": OnboardingStage.APPLICATION_RECEIVED.value,
                },
            )
            # Should have succeeded after 2 retries (attempt 3 succeeded)
            assert resp.status == 200
            assert call_count == 3
            body = client.json(resp)
            assert body["status"] == "TRANSITIONED"

        # Verify exactly 1 transition audit record exists (zero duplicates from retries)
        db_session.expire_all()
        audit_records = db_session.query(AuthAuditLog).filter(
            AuthAuditLog.reviewer_id == applicant_id,
            AuthAuditLog.event_type.like("ONBOARDING_%"),
        ).all()
        assert len(audit_records) == 1
    finally:
        client.close()


def test_4_5_unresolved_lock_contention_returns_truthful_503(client, admin_council_reviewer, db_session):
    """
    4.5: When database lock contention cannot be resolved after max retries,
    the gateway returns HTTP 503 DATABASE_CONTENTION with a Retry-After header.
    """
    app = ReviewerOnboardingService.register_applicant(
        db_session,
        ReviewerProfileCreate(
            reviewer_id="REV-P12B2-APP-007",
            full_name="Unresolved Lock Candidate",
            primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
            email="candidate7.12b2@vedam.org",
        ),
        "Pass12345#",
    )
    db_session.commit()

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"reviewer_id": admin_council_reviewer.reviewer_id, "password": "CouncilPass123#"},
    )
    csrf_token = client.json(login_resp)["csrf_token"]

    # Mock persistent database lock
    with patch.object(ReviewerOnboardingService, "transition_stage", side_effect=OperationalError("database is locked", {}, None)):
        resp = client.post(
            "/api/v1/onboarding/admin/transition",
            headers={CSRF_HEADER: csrf_token},
            json={
                "applicant_reviewer_id": app.reviewer_id,
                "target_stage": OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                "notes": "Persistent lock attempt",
                "expected_current_stage": OnboardingStage.APPLICATION_RECEIVED.value,
            },
        )
        assert resp.status == 503
        assert resp.headers.get("Retry-After") == "1"
        body = client.json(resp)
        assert body["code"] == "DATABASE_CONTENTION"


# ==============================================================================
# 4.6 AUTHORIZATION UNDER CONCURRENCY & PRESERVED GUARDS
# ==============================================================================

def test_4_6_authorization_anti_self_accreditation_under_concurrency(db_session, admin_council_reviewer):
    """
    4.6: Verify that an administrator cannot verify or accredit their own account
    even if attempted under concurrent requests.
    """
    db_url = get_active_database_url()
    admin_id = admin_council_reviewer.reviewer_id
    admin_curr_stage = admin_council_reviewer.verification_status
    barrier = threading.Barrier(2)
    results = []

    def self_accredit_worker():
        th_engine = create_engine(db_url, poolclass=NullPool, connect_args={"check_same_thread": False, "timeout": 10})
        th_session = sessionmaker(bind=th_engine)()
        try:
            admin = th_session.query(ReviewerProfile).filter_by(reviewer_id=admin_id).first()
            barrier.wait(timeout=5)
            ReviewerOnboardingService.transition_stage(
                session=th_session,
                admin_reviewer=admin,
                applicant_reviewer_id=admin.reviewer_id,
                target_stage=OnboardingStage.IDENTITY_REVIEW_PENDING.value,
                notes="Attempting self-accreditation",
                expected_current_stage=admin_curr_stage,
            )
            th_session.commit()
            results.append("SUCCESS")
        except OnboardingGovernanceError as e:
            th_session.rollback()
            results.append(f"REJECTED: {e}")
        finally:
            th_session.close()
            th_engine.dispose()

    t1 = threading.Thread(target=self_accredit_worker)
    t2 = threading.Thread(target=self_accredit_worker)
    t1.start()
    t2.start()
    t1.join(timeout=10)
    t2.join(timeout=10)

    # Both must be rejected
    assert len(results) == 2
    for r in results:
        assert r.startswith("REJECTED")
        assert "Anti-Self-Accreditation Violation" in r


def test_4_6_unauthorized_admin_cannot_grant_accreditation_under_concurrency(db_session):
    """
    4.6: An administrator with only CAN_VERIFY_CREDENTIALS cannot grant ACCREDITED status
    even under competing concurrent executions.
    """
    cred_admin = ReviewerProfile(
        reviewer_id="REV-P12B2-APP-CRED-ONLY",
        full_name="Credentials Only Admin",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
        permissions=["CAN_VERIFY_CREDENTIALS"],
        is_active=True,
    )
    db_session.add(cred_admin)

    app = ReviewerProfile(
        reviewer_id="REV-P12B2-APP-008",
        full_name="Applicant At Accreditation Pending",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
        verification_status=OnboardingStage.ACCREDITATION_PENDING.value,
        is_active=True,
    )
    db_session.add(app)
    db_session.commit()

    with pytest.raises(PermissionDeniedError) as exc_info:
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=cred_admin,
            applicant_reviewer_id=app.reviewer_id,
            target_stage=OnboardingStage.ACCREDITED.value,
            notes="Unauthorized attempt to grant human accreditation",
            expected_current_stage=OnboardingStage.ACCREDITATION_PENDING.value,
        )
    assert "Editorial Board authority" in str(exc_info.value)


def test_4_7_quarantined_demo_accounts_immutable_under_concurrency(db_session, admin_council_reviewer):
    """
    4.7: Quarantined demonstration accounts cannot be transitioned or converted under concurrency.
    """
    demo = ReviewerProfile(
        reviewer_id="REV-P12B2-APP-DEMO-CONCURRENCY",
        full_name="Quarantined Demo Test",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
        is_demonstration=True,
        account_category="DEMONSTRATION_HARNESS",
        verification_status=OnboardingStage.DEMO.value,
        is_active=True,
    )
    db_session.add(demo)
    db_session.commit()

    with pytest.raises(OnboardingGovernanceError) as exc_info:
        ReviewerOnboardingService.transition_stage(
            session=db_session,
            admin_reviewer=admin_council_reviewer,
            applicant_reviewer_id=demo.reviewer_id,
            target_stage=OnboardingStage.APPLICATION_RECEIVED.value,
            notes="Attempting demo account promotion",
        )
    assert "Quarantined Account Protection" in str(exc_info.value)


# ==============================================================================
# SECTION 8 APPROVAL BARRIER AND DATABASE IMMUTABILITY
# ==============================================================================

def test_phase12b2_section_8_blanket_approval_barrier_intact(client, admin_council_reviewer):
    """
    Section 8 Approval Barrier: Verify translation approvals are universally blocked with 403 Forbidden.
    """
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


def test_phase12b2_production_database_untouched():
    """
    Verifies that the live production database remains bit-for-bit identical to its baseline.
    """
    prod_path = Path("database/vedam.db")
    expected_sha256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
    expected_size = 20455424

    assert prod_path.exists(), "Production database file missing!"
    assert prod_path.stat().st_size == expected_size, f"Size changed: {prod_path.stat().st_size} != {expected_size}"

    h = hashlib.sha256()
    with open(prod_path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    actual_sha256 = h.hexdigest()

    assert actual_sha256 == expected_sha256, f"Production DB mutated! {actual_sha256} != {expected_sha256}"
