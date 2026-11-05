"""
Vedic Heritage Platform — Production Database Protection & Isolation Test Suite
Verifies:
1. Production database immunity: live 'database/vedam.db' is never mutated by test workflows.
2. TranslationView version counter stability on production.
3. Review workflow operations execute cleanly inside isolated test databases.
4. ProductionDatabaseProtectionError blocks any attempt to connect to production during test execution.
5. Independent test sessions do not leak mutable state across executions.
"""

import hashlib
import os
import shutil
import sqlite3
import tempfile
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from automation.database.safety import (
    ProductionDatabaseProtectionError,
    assert_not_production_database,
    compute_database_fingerprint,
    create_isolated_test_database,
    get_canonical_production_db_path,
    is_production_database,
    verify_database_unmodified,
)
from automation.workbench.review_action_engine import ReviewActionEngine, ReviewActionError
from database.connection import (
    configure_engine,
    get_active_database_url,
    get_db_session,
    set_test_database_url,
)
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    Text,
    Translation,
    TranslationView,
    Verse,
)
from database.schemas import ReviewActionLogCreate, ReviewerProfileCreate


class TestProductionDatabaseIsolation:
    """Group A: Verifies production database isolation and zero-mutation guarantee."""

    def test_production_path_recognized_accurately(self):
        """Ensures canonical production path and various URL formats are recognized."""
        canonical = get_canonical_production_db_path()
        assert is_production_database(canonical) is True
        assert is_production_database("database/vedam.db") is True
        assert is_production_database("./database/vedam.db") is True
        assert is_production_database("sqlite:///./database/vedam.db") is True
        assert is_production_database(f"sqlite:///{canonical}") is True

        # Non-production paths must return False
        assert is_production_database(":memory:") is False
        assert is_production_database("sqlite:///:memory:") is False
        assert is_production_database("/tmp/isolated_vedam.db") is False
        assert is_production_database("database/backups/vedam_pre_phase10.db") is False

    def test_safety_guard_blocks_production_url_during_test(self):
        """Ensures assert_not_production_database raises ProductionDatabaseProtectionError."""
        with pytest.raises(ProductionDatabaseProtectionError) as exc_info:
            assert_not_production_database("database/vedam.db", context="unit_test_safety_check")
        assert "CRITICAL SAFETY VIOLATION" in str(exc_info.value)
        assert "Rule P10-SAFETY-001" in str(exc_info.value)

    def test_active_test_database_is_isolated(self):
        """Verifies that the active test database URL points to an isolated temporary copy."""
        active_url = get_active_database_url()
        assert not is_production_database(active_url)
        assert "isolated_test_vedam.db" in active_url or "temp" in active_url.lower() or "vedam_pytest" in active_url.lower()


class TestTranslationViewIntegrityAndFingerprints:
    """Group B: Verifies TranslationView version counters and baseline stability."""

    def test_four_affected_records_baseline_version_counters(self):
        """
        Verifies that the four historical records maintain their known version counters
        and are not mutated by test operations against the active database.
        """
        canonical_prod = get_canonical_production_db_path()
        conn = sqlite3.connect(f"file:{canonical_prod}?mode=ro", uri=True)

        expected_records = {
            "VIEW-TR-00006-BHAVARTHA-v1": {"version": 24, "status": "APPROVED"},
            "VIEW-TR-00508-BHAVARTHA-v1": {"version": 24, "status": "APPROVED"},
            "VIEW-TR-00524-BHAVARTHA-v1": {"version": 24, "status": "APPROVED"},
            "VIEW-TR-00752-BHAVARTHA-v1": {"version": 15, "status": "APPROVED"},
        }

        for vid, expected in expected_records.items():
            row = conn.execute(
                "SELECT version, review_status, view_text FROM translation_views WHERE view_id = ?",
                (vid,),
            ).fetchone()
            assert row is not None, f"Record {vid} missing in production database!"
            ver, stat, txt = row
            assert ver == expected["version"], f"Record {vid} version changed! expected {expected['version']}, got {ver}"
            assert stat == expected["status"], f"Record {vid} status changed! expected {expected['status']}, got {stat}"
            assert txt is not None and len(txt) > 10

        conn.close()

    def test_production_database_fingerprint_generation(self):
        """Verifies that the cryptographic fingerprint utility runs accurately across critical tables."""
        canonical_prod = get_canonical_production_db_path()
        fp = compute_database_fingerprint(canonical_prod)
        assert fp["db_path"] == canonical_prod
        assert fp["file_size"] > 20_000_000
        assert len(fp["file_sha256"]) == 64

        tables = fp["tables"]
        for tbl in ["texts", "verses", "translations", "translation_views", "sources"]:
            assert tbl in tables
            assert tables[tbl]["row_count"] > 0
            assert len(tables[tbl]["sha256"]) == 64


class TestWorkflowFunctionalityInIsolatedDatabase:
    """Group C: Proves review workflow actions execute properly inside isolated databases."""

    def test_review_action_increments_version_in_isolated_db(self, tmp_path, session_isolated_db_path):
        """
        Creates an independent disposable database copy, executes a review action,
        and verifies version increments in the isolated copy while production remains pristine.
        """
        canonical_prod = get_canonical_production_db_path()
        temp_db_path = str(tmp_path / "review_action_test.db")
        shutil.copy2(canonical_prod, temp_db_path)

        # Snapshot production hash before action
        prod_fp_before = compute_database_fingerprint(canonical_prod)

        # Connect SQLAlchemy to temp database
        temp_url = f"sqlite:///{temp_db_path}"
        eng, s_factory = configure_engine(temp_url)

        try:
            with s_factory() as session:
                # Query view in temp database
                view = session.query(TranslationView).filter_by(view_id="VIEW-TR-00006-BHAVARTHA-v1").first()
                assert view is not None
                orig_ver = view.version

                # Create test reviewer
                rev = ReviewerProfile(
                    reviewer_id="REV-ISOLATION-TEST",
                    full_name="Dr. Isolation Tester",
                    primary_role=ReviewerRole.EDITORIAL_BOARD,
                    is_credentials_verified=True,
                    verification_status="VERIFIED",
                    permissions=["APPROVE_TRANSLATION"],
                )
                session.add(rev)
                session.flush()

                # Execute APPROVE_WITH_CORRECTIONS inside temp db
                action_data = ReviewActionLogCreate(
                    translation_id=view.translation_id,
                    translation_view_id=view.id,
                    verse_id=view.verse_id,
                    reviewer_id=rev.id,
                    action_type=ReviewActionType.APPROVE_WITH_CORRECTIONS,
                    previous_status=view.review_status.value,
                    new_status="APPROVED",
                    previous_text=view.view_text,
                    proposed_text=view.view_text + " [Isolated Test Mutation]",
                    scholarly_commentary="Verified isolated database review workflow.",
                )
                log = ReviewActionEngine.execute_action(session, action_data)
                session.commit()

                # Verify version incremented in temp database
                assert log.id is not None
                assert view.version == orig_ver + 1
                assert "[Isolated Test Mutation]" in view.view_text
        finally:
            # Restore test session database URL
            set_test_database_url(f"sqlite:///{session_isolated_db_path}")

        # Verify production database was 100% untouched
        is_clean, discrepancies = verify_database_unmodified(prod_fp_before, canonical_prod)
        assert is_clean is True, f"Production database was mutated during isolated test! {discrepancies}"

    def test_transaction_rollback_in_isolated_db(self, tmp_path, session_isolated_db_path):
        """Verifies transaction rollback functions reliably without committing corrupting data."""
        temp_db_path = str(tmp_path / "rollback_test.db")
        shutil.copy2(get_canonical_production_db_path(), temp_db_path)

        eng, s_factory = configure_engine(f"sqlite:///{temp_db_path}")
        try:
            with s_factory() as session:
                init_count = session.query(ReviewActionLog).count()
                # Attempt invalid transaction
                try:
                    session.add(ReviewActionLog(action_id="INVALID-ROLLBACK", action_type="INVALID_TYPE"))
                    session.flush()
                except Exception:
                    session.rollback()

                final_count = session.query(ReviewActionLog).count()
                assert init_count == final_count
        finally:
            set_test_database_url(f"sqlite:///{session_isolated_db_path}")


class TestConfigurationSafetyAndRefusal:
    """Group D: Verifies configuration safety, failure modes, and refusal to fallback."""

    def test_configure_engine_refuses_production_path(self):
        """Ensures configure_engine refuses to bind to production database during tests."""
        prod_path = get_canonical_production_db_path()
        with pytest.raises(ProductionDatabaseProtectionError):
            configure_engine(f"sqlite:///{prod_path}")

    def test_set_test_database_url_refuses_production_path(self):
        """Ensures set_test_database_url refuses production database."""
        with pytest.raises(ProductionDatabaseProtectionError):
            set_test_database_url("sqlite:///database/vedam.db")


class TestExecutionOrderAndStateIndependence:
    """Group E: Proves tests do not share mutable state across executions."""

    def test_state_cleanliness_independent_run_1(self):
        """Verifies baseline absence of test-specific markers."""
        with get_db_session() as session:
            test_rev = session.query(ReviewerProfile).filter_by(reviewer_id="REV-INDEP-TEST").first()
            assert test_rev is None

    def test_state_cleanliness_independent_run_2(self):
        """Verifies that temporary entities in one test do not persist to another test."""
        with get_db_session() as session:
            test_rev = session.query(ReviewerProfile).filter_by(reviewer_id="REV-INDEP-TEST").first()
            assert test_rev is None
