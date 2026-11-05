"""
Vedic Heritage Platform — Database Backup and Recovery Test Suite
Verifies atomic backup generation, integrity checks, and restoration safety.
"""

import os
import sqlite3
import tempfile
import pytest

from database.backup import (
    create_backup,
    restore_backup,
    verify_database_integrity,
    list_backups,
)
from database.connection import get_db_session
from database.models import Text, Verse, Translation, TranslationView


def test_database_integrity_check():
    """Verify that current live database passes SQLite integrity check."""
    assert verify_database_integrity("database/vedam.db") is True


def test_atomic_backup_creation(tmp_path):
    """Test creating an atomic backup in a temporary backup directory."""
    backup_dir = str(tmp_path / "backups")
    backup_file = create_backup(
        db_path="database/vedam.db",
        backup_dir=backup_dir,
        label="test_run",
    )
    assert os.path.exists(backup_file)
    assert os.path.getsize(backup_file) > 1_000_000  # At least 1 MB
    assert verify_database_integrity(backup_file) is True


def test_database_restoration_to_temp_target(tmp_path):
    """Test restoring a backup to a separate target file and verifying data fidelity."""
    backup_dir = str(tmp_path / "backups")
    backup_file = create_backup(
        db_path="database/vedam.db",
        backup_dir=backup_dir,
        label="test_restore",
    )

    restored_db_path = str(tmp_path / "restored_test.db")
    restore_backup(backup_file, target_db_path=restored_db_path)

    assert os.path.exists(restored_db_path)
    assert verify_database_integrity(restored_db_path) is True

    # Compare row counts between live DB and restored DB
    conn_live = sqlite3.connect("database/vedam.db")
    conn_restored = sqlite3.connect(restored_db_path)

    for table in ["texts", "verses", "translations", "translation_views"]:
        live_count = conn_live.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        restored_count = conn_restored.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        assert live_count == restored_count, f"Mismatch in table {table}: live {live_count} vs restored {restored_count}"

    conn_live.close()
    conn_restored.close()
