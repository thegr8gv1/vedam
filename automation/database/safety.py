"""
Vedic Heritage Platform — Database Safety Guard & Test Isolation Architecture
Prevents automated test suites, scripts, or demonstration harnesses from
connecting to, mutating, or corrupting the live production database.
"""

from datetime import datetime, timezone
import hashlib
import logging
import os
import shutil
import sqlite3
import sys
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger("vedam.database.safety")

# Canonical production database baselines (Post-Phase 13 schema migration e3a7b1c9f2d5)
CANONICAL_PRODUCTION_DB_SIZE = 20455424
CANONICAL_PRODUCTION_DB_SHA256 = "0b3500f36434217d0e35b1b3f0bb1e12c4598b406177d11979e1fc2a46b7ab97"
CANONICAL_ALEMBIC_VERSION = "e3a7b1c9f2d5"


class ProductionDatabaseProtectionError(RuntimeError):
    """Raised when test execution or an unauthorized harness attempts to access the production database."""
    pass


def get_canonical_production_db_path() -> str:
    """Returns the absolute, normalized filesystem path to the production database."""
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    prod_path = os.path.join(base_dir, "database", "vedam.db")
    return os.path.normpath(os.path.abspath(prod_path))


def normalize_db_path(path_or_url: str) -> str:
    """
    Strips sqlite connection scheme prefixes and returns a normalized absolute path.
    Handles 'sqlite:///', 'sqlite://', and plain file paths.
    """
    if not path_or_url:
        return ""
    clean = path_or_url.strip()
    if clean.startswith("sqlite:///"):
        clean = clean[len("sqlite:///"):]
    elif clean.startswith("sqlite://"):
        clean = clean[len("sqlite://"):]
    
    # On Windows, clean up leading slash if path is e.g. /C:/Vedam/...
    if os.name == "nt" and len(clean) > 2 and clean[0] == "/" and clean[2] == ":":
        clean = clean[1:]

    # In-memory special case
    if clean in (":memory:", ""):
        return clean

    return os.path.normpath(os.path.abspath(clean))


def is_production_database(path_or_url: str) -> bool:
    """
    Determines whether a given path or database URL points to the production database.
    Case-insensitive on Windows.
    """
    normalized = normalize_db_path(path_or_url)
    if not normalized or normalized == ":memory:":
        return False

    prod_canonical = get_canonical_production_db_path()
    
    if os.name == "nt":
        if normalized.lower() == prod_canonical.lower():
            return True
        # Check if basename is vedam.db inside a database directory
        parts = normalized.lower().replace("/", "\\").split("\\")
        if len(parts) >= 2 and parts[-1] == "vedam.db" and parts[-2] == "database":
            # Extra safety: check if it's the repository's database directory
            if os.path.dirname(normalized).lower() == os.path.dirname(prod_canonical).lower():
                return True
    else:
        if normalized == prod_canonical:
            return True
        if normalized.endswith("/database/vedam.db"):
            if os.path.dirname(normalized) == os.path.dirname(prod_canonical):
                return True

    return False


def is_test_environment() -> bool:
    """
    Checks multiple environment signals to determine if Python is executing
    in a test runner context (pytest, unittest, or explicit test flag).
    """
    if os.getenv("VEDAM_TEST_MODE") == "1":
        return True
    if "PYTEST_CURRENT_TEST" in os.environ:
        return True
    if os.getenv("ENV") in ("test", "testing"):
        return True
    if "pytest" in sys.modules:
        # Check if pytest is currently running a session
        return True
    return False


def assert_not_production_database(path_or_url: str, context: str = "") -> None:
    """
    Enforces that test execution must NEVER resolve to the production database.
    Raises ProductionDatabaseProtectionError if a test attempts to connect to production.
    """
    if not is_production_database(path_or_url):
        return

    if is_test_environment():
        msg = (
            f"CRITICAL SAFETY VIOLATION: Test execution attempted to connect to the "
            f"live production database at '{path_or_url}' (context: '{context}'). "
            f"Rule P10-SAFETY-001 strictly prohibits test connections to production. "
            f"All tests must use an isolated temporary database copy or SQLite :memory:."
        )
        logger.critical(msg)
        raise ProductionDatabaseProtectionError(msg)


def create_isolated_test_database(
    source_db_path: Optional[str] = None,
    target_dir: Optional[str] = None,
    filename: str = "isolated_test_vedam.db",
) -> str:
    """
    Creates a dedicated, disposable SQLite copy using SQLite's atomic online backup API.
    The resulting database contains complete production-like tables and data,
    allowing realistic end-to-end testing without risk of mutating production.
    """
    source_path = source_db_path or get_canonical_production_db_path()
    if not os.path.exists(source_path):
        raise FileNotFoundError(f"Source database not found for test isolation: {source_path}")

    if target_dir is None:
        import tempfile
        target_dir = tempfile.mkdtemp(prefix="vedam_test_isolated_")

    os.makedirs(target_dir, exist_ok=True)
    target_path = os.path.normpath(os.path.abspath(os.path.join(target_dir, filename)))

    # Use SQLite online backup API to ensure complete point-in-time copy
    src_conn = sqlite3.connect(f"file:{source_path}?mode=ro", uri=True)
    dst_conn = sqlite3.connect(target_path)
    try:
        with dst_conn:
            src_conn.backup(dst_conn)
    finally:
        dst_conn.close()
        src_conn.close()

    logger.info(f"Isolated test database created at: {target_path}")
    return target_path


def compute_database_fingerprint(db_path: Optional[str] = None) -> Dict[str, Any]:
    """
    Generates a reproducible forensic fingerprint of critical tables in a SQLite database.
    Computes table row counts and SHA-256 hashes of all ordered records.
    """
    target = db_path or get_canonical_production_db_path()
    if not os.path.exists(target):
        raise FileNotFoundError(f"Database not found for fingerprinting: {target}")

    file_size = os.path.getsize(target)
    
    # File-level SHA-256
    file_sha = hashlib.sha256()
    with open(target, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            file_sha.update(chunk)
            
    conn = sqlite3.connect(f"file:{target}?mode=ro", uri=True)
    critical_tables = [
        "texts", "verses", "translations", "translation_views", 
        "reviewer_profiles", "review_action_logs", "sources"
    ]
    
    table_hashes = {}
    for tbl in critical_tables:
        rows = conn.execute(f"SELECT * FROM {tbl} ORDER BY ROWID").fetchall()
        h = hashlib.sha256()
        for row in rows:
            h.update(str(row).encode("utf-8"))
        table_hashes[tbl] = {
            "row_count": len(rows),
            "sha256": h.hexdigest(),
        }
    conn.close()

    return {
        "db_path": target,
        "file_size": file_size,
        "file_sha256": file_sha.hexdigest(),
        "tables": table_hashes,
        "fingerprinted_at": datetime.now(timezone.utc).isoformat(),
    }


def verify_database_unmodified(
    baseline_fingerprint: Dict[str, Any],
    current_db_path: Optional[str] = None,
) -> Tuple[bool, List[str]]:
    """
    Compares the current state of critical database tables against a baseline fingerprint.
    Returns (True, []) if identical, or (False, [discrepancy_details]) if any change occurred.
    """
    current_fp = compute_database_fingerprint(current_db_path)
    discrepancies = []

    base_tables = baseline_fingerprint.get("tables", {})
    curr_tables = current_fp.get("tables", {})

    for tbl, base_info in base_tables.items():
        curr_info = curr_tables.get(tbl)
        if not curr_info:
            discrepancies.append(f"Table '{tbl}' missing in current database.")
            continue
        if base_info["row_count"] != curr_info["row_count"]:
            discrepancies.append(
                f"Table '{tbl}' row count mismatch: baseline {base_info['row_count']} vs current {curr_info['row_count']}."
            )
        if base_info["sha256"] != curr_info["sha256"]:
            discrepancies.append(
                f"Table '{tbl}' SHA-256 hash mismatch: baseline {base_info['sha256'][:16]} vs current {curr_info['sha256'][:16]}."
            )

    is_identical = (len(discrepancies) == 0)
    return is_identical, discrepancies
