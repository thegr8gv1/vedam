"""
Centralized Pytest Database Isolation & Safety Configuration
Guarantees 100% test isolation by automatically provisioning a disposable
copy of the database in a temporary directory for all test executions.
Enforces that tests NEVER connect to or mutate 'database/vedam.db'.
"""

from datetime import datetime, timezone
import logging
import os
import shutil
import sqlite3
import tempfile
from typing import Generator
import pytest
from sqlalchemy.orm import Session

# Enforce test mode flag immediately before importing database components
os.environ["VEDAM_TEST_MODE"] = "1"

from automation.database.safety import (
    ProductionDatabaseProtectionError,
    assert_not_production_database,
    compute_database_fingerprint,
    create_isolated_test_database,
    get_canonical_production_db_path,
    is_production_database,
    verify_database_unmodified,
)
from database.connection import (
    configure_engine,
    get_active_database_url,
    get_db_session,
    set_test_database_url,
)

logger = logging.getLogger("vedam.tests.conftest")

# Global session-wide isolated temporary directory and database path
_session_temp_dir = tempfile.mkdtemp(prefix="vedam_pytest_session_")
_canonical_prod = get_canonical_production_db_path()
_session_test_db_path = os.path.normpath(os.path.join(_session_temp_dir, "isolated_test_vedam.db"))

# Capture baseline fingerprint of the production database before test session begins
_prod_baseline_fingerprint = compute_database_fingerprint(_canonical_prod)

# Initialize the isolated test database copy from production
create_isolated_test_database(
    source_db_path=_canonical_prod,
    target_dir=_session_temp_dir,
    filename="isolated_test_vedam.db",
)

# Reconfigure the database connection to the isolated test database
set_test_database_url(f"sqlite:///{_session_test_db_path}")

print(f"\n[TEST SAFETY GUARD] Session initialized with isolated database: {_session_test_db_path}")
print(f"[TEST SAFETY GUARD] Production database '{_canonical_prod}' is protected against mutation.\n")


def pytest_sessionfinish(session, exitstatus):
    """
    Called after whole test run finishes.
    Verifies that the production database was never mutated during tests,
    then cleans up the temporary test directory.
    """
    print("\n[TEST SAFETY GUARD] Running post-session production database integrity verification...")
    is_unmodified, discrepancies = verify_database_unmodified(
        baseline_fingerprint=_prod_baseline_fingerprint,
        current_db_path=_canonical_prod,
    )
    if not is_unmodified:
        msg = f"[CRITICAL BREACH] Production database was mutated during tests: {discrepancies}"
        print(f"[TEST SAFETY GUARD ERROR] {msg}")
        raise ProductionDatabaseProtectionError(msg)
    else:
        print("[TEST SAFETY GUARD] Production database verified 100% UNMODIFIED. Zero bytes altered.")

    # Clean up session temp directory
    try:
        shutil.rmtree(_session_temp_dir, ignore_errors=True)
    except Exception as e:
        logger.warning(f"Failed to remove session temp dir: {e}")


@pytest.fixture(autouse=True)
def enforce_test_database_safety():
    """
    Autouse fixture executing before every test.
    Strictly asserts that the active database URL is NOT the production database.
    """
    active_url = get_active_database_url()
    assert_not_production_database(active_url, context="enforce_test_database_safety autouse fixture")
    yield


@pytest.fixture(scope="session")
def session_isolated_db_path() -> str:
    """Returns the path to the session-wide isolated test database."""
    return _session_test_db_path


@pytest.fixture
def isolated_disposable_db(tmp_path) -> str:
    """
    Function-scoped fixture providing an independent, disposable copy of the database
    for tests requiring isolated mutations that should not affect other tests.
    """
    db_copy_path = str(tmp_path / "disposable_test_vedam.db")
    shutil.copy2(_session_test_db_path, db_copy_path)
    return db_copy_path


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Function-scoped database session against the isolated test database."""
    with get_db_session() as session:
        yield session
