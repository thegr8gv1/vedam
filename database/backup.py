"""
Vedic Heritage Platform — Database Backup & Recovery Utility
Provides atomic snapshot backups, integrity verification, and recovery
to guarantee zero data loss during schema migrations and batch ingestions.
"""

from datetime import datetime, timezone
import logging
import os
import shutil
import sqlite3
from typing import List, Optional

logger = logging.getLogger("vedam.database.backup")


def get_db_path_from_url(database_url: Optional[str] = None) -> str:
    """Extract filesystem path from a sqlite:/// URL."""
    url = database_url or os.getenv("DATABASE_URL", "sqlite:///./database/vedam.db")
    if url.startswith("sqlite:///"):
        return os.path.abspath(url.replace("sqlite:///", ""))
    raise ValueError(f"Backup utility currently requires SQLite database URL, got: {url}")


def create_backup(
    db_path: Optional[str] = None,
    backup_dir: str = "database/backups",
    label: str = "pre_migration",
) -> str:
    """
    Creates an atomic, timestamped backup of the SQLite database.
    Verifies database integrity prior to copying.
    
    Returns:
        str: Absolute path to the created backup file.
    """
    source_path = db_path or get_db_path_from_url()
    if not os.path.exists(source_path):
        raise FileNotFoundError(f"Database file does not exist at: {source_path}")

    # Ensure backup directory exists
    os.makedirs(backup_dir, exist_ok=True)

    # 1. Verify SQLite integrity of source database before backing up
    verify_database_integrity(source_path)

    # 2. Generate timestamped backup file name
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    backup_filename = f"vedam_{label}_{timestamp}.db"
    backup_path = os.path.abspath(os.path.join(backup_dir, backup_filename))

    # 3. Use SQLite's online backup API for thread-safe atomic snapshot
    src_conn = sqlite3.connect(source_path)
    dst_conn = sqlite3.connect(backup_path)
    try:
        with dst_conn:
            src_conn.backup(dst_conn)
        logger.info(f"Database successfully backed up to {backup_path}")
    finally:
        dst_conn.close()
        src_conn.close()

    # 4. Verify integrity of the newly created backup
    verify_database_integrity(backup_path)

    return backup_path


def restore_backup(backup_path: str, target_db_path: Optional[str] = None) -> str:
    """
    Restores the database from a verified backup file.
    Safely creates an emergency snapshot of current state before replacing.
    """
    target_path = target_db_path or get_db_path_from_url()
    if not os.path.exists(backup_path):
        raise FileNotFoundError(f"Backup file not found: {backup_path}")

    # Verify backup file integrity before restoring
    verify_database_integrity(backup_path)

    # If target DB exists, make a temporary safety copy
    if os.path.exists(target_path):
        safety_copy = target_path + ".restore_safety"
        shutil.copy2(target_path, safety_copy)

    try:
        src_conn = sqlite3.connect(backup_path)
        dst_conn = sqlite3.connect(target_path)
        with dst_conn:
            src_conn.backup(dst_conn)
        src_conn.close()
        dst_conn.close()
        logger.info(f"Successfully restored database from {backup_path} to {target_path}")
    except Exception as e:
        if os.path.exists(safety_copy):
            shutil.copy2(safety_copy, target_path)
        raise RuntimeError(f"Database restoration failed: {e}")
    finally:
        if os.path.exists(target_path + ".restore_safety"):
            os.remove(target_path + ".restore_safety")

    return target_path


def verify_database_integrity(db_path: str) -> bool:
    """
    Runs SQLite PRAGMA integrity_check to ensure file is non-corrupt.
    Raises ValueError if integrity check fails.
    """
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database file does not exist: {db_path}")

    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check;")
        result = cursor.fetchall()
        if result != [("ok",)]:
            errors = [row[0] for row in result]
            raise ValueError(f"Database integrity check failed for {db_path}: {errors}")
        return True
    finally:
        conn.close()


def list_backups(backup_dir: str = "database/backups") -> List[str]:
    """Returns sorted list of available backup file paths."""
    if not os.path.exists(backup_dir):
        return []
    files = [
        os.path.join(backup_dir, f)
        for f in os.listdir(backup_dir)
        if f.startswith("vedam_") and f.endswith(".db")
    ]
    files.sort(key=os.path.getmtime, reverse=True)
    return files
