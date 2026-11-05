"""
Vedic Heritage Platform — Database Backup and Recovery Test Suite
Verifies atomic backup generation, integrity checks, and restoration safety.
Operates strictly against the isolated test database to protect production data.
"""

import os
import sqlite3
import pytest

from database.backup import (
    create_backup,
    get_db_path_from_url,
    list_backups,
    restore_backup,
    verify_database_integrity,
)
from database.connection import get_db_session
from database.models import Text, Verse, Translation, TranslationView


def test_database_integrity_check():
    """Verify that current isolated database passes SQLite integrity check."""
    active_db = get_db_path_from_url()
    assert verify_database_integrity(active_db) is True


def test_atomic_backup_creation(tmp_path):
    """Test creating an atomic backup in a temporary backup directory."""
    active_db = get_db_path_from_url()
    backup_dir = str(tmp_path / "backups")
    backup_file = create_backup(
        db_path=active_db,
        backup_dir=backup_dir,
        label="test_run",
    )
    assert os.path.exists(backup_file)
    assert os.path.getsize(backup_file) > 1_000_000  # At least 1 MB
    assert verify_database_integrity(backup_file) is True


def test_database_restoration_to_temp_target(tmp_path):
    """Test restoring a backup to a separate target file and verifying data fidelity."""
    active_db = get_db_path_from_url()
    backup_dir = str(tmp_path / "backups")
    backup_file = create_backup(
        db_path=active_db,
        backup_dir=backup_dir,
        label="test_restore",
    )

    restored_db_path = str(tmp_path / "restored_test.db")
    restore_backup(backup_file, target_db_path=restored_db_path)

    assert os.path.exists(restored_db_path)
    assert verify_database_integrity(restored_db_path) is True

    # Compare row counts between source DB and restored DB
    conn_source = sqlite3.connect(f"file:{active_db}?mode=ro", uri=True)
    conn_restored = sqlite3.connect(f"file:{restored_db_path}?mode=ro", uri=True)

    for table in ["texts", "verses", "translations", "translation_views"]:
        source_count = conn_source.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        restored_count = conn_restored.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        assert source_count == restored_count, f"Mismatch in table {table}: source {source_count} vs restored {restored_count}"

    conn_source.close()
    conn_restored.close()
