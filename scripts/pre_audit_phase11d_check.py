"""
Pre-audit backup and baseline verification for Phase 11D Verification Addendum.
"""

from datetime import datetime, timezone
import hashlib
from pathlib import Path
import sqlite3
import sys

DB_PATH = Path("database/vedam.db")
BACKUP_DIR = Path("database/backups")
BACKUP_DIR.mkdir(parents=True, exist_ok=True)

EXPECTED_SHA256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
EXPECTED_DB_REV = "9f3c8a1b2d4e"

# 1. Calculate SHA-256
h = hashlib.sha256()
with open(DB_PATH, "rb") as f:
    while chunk := f.read(65536):
        h.update(chunk)
current_sha = h.hexdigest()
size_bytes = DB_PATH.stat().st_size

print(f"Production Database SHA-256: {current_sha}")
print(f"Expected SHA-256:            {EXPECTED_SHA256}")
print(f"Size:                       {size_bytes:,} bytes")
assert current_sha == EXPECTED_SHA256, f"SHA-256 MISMATCH! {current_sha} != {EXPECTED_SHA256}"
print("SHA-256 check: PASSED (Bit-for-bit identical)")

# 2. Create timestamped atomic backup using SQLite backup API
timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
backup_file = BACKUP_DIR / f"vedam_pre_audit_phase11d_{timestamp}.db"

src = sqlite3.connect(DB_PATH)
dst = sqlite3.connect(backup_file)
with dst:
    src.backup(dst, pages=100)
dst.close()

# 3. Verify backup integrity
b_conn = sqlite3.connect(backup_file)
b_cur = b_conn.cursor()
b_cur.execute("PRAGMA integrity_check;")
b_integrity = b_cur.fetchone()[0]
b_conn.close()

print(f"Created atomic backup: {backup_file.resolve()}")
print(f"Backup PRAGMA integrity_check: {b_integrity}")
assert b_integrity == "ok", f"Backup corrupted: {b_integrity}"

# 4. Census on source DB
cur = src.cursor()
cur.execute("PRAGMA integrity_check;")
src_integrity = cur.fetchone()[0]
assert src_integrity == "ok"

cur.execute("SELECT version_num FROM alembic_version;")
db_rev = cur.fetchone()[0]
print(f"Database Alembic revision: {db_rev}")
assert db_rev == EXPECTED_DB_REV, f"Revision mismatch: {db_rev} != {EXPECTED_DB_REV}"

canonical_filter = "content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099')"
canonical_texts = cur.execute(f"SELECT count(*) FROM texts WHERE {canonical_filter}").fetchone()[0]
total_texts = cur.execute("SELECT count(*) FROM texts").fetchone()[0]
canonical_verses = cur.execute(f"SELECT count(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE {canonical_filter})").fetchone()[0]
total_verses = cur.execute("SELECT count(*) FROM verses").fetchone()[0]
active_translations = cur.execute("SELECT count(*) FROM translations").fetchone()[0]
draft_translations = cur.execute("SELECT count(*) FROM translations WHERE review_status = 'DRAFT'").fetchone()[0]
archived_translations = cur.execute("SELECT count(*) FROM archived_translations").fetchone()[0]
total_views = cur.execute("SELECT count(*) FROM translation_views").fetchone()[0]
literal_views = cur.execute("SELECT count(*) FROM translation_views WHERE view_type = 'LITERAL'").fetchone()[0]
legacy_gaps = active_translations - literal_views
total_reviewers = cur.execute("SELECT count(*) FROM reviewer_profiles").fetchone()[0]
total_logs = cur.execute("SELECT count(*) FROM review_action_logs").fetchone()[0]
total_disputes = cur.execute("SELECT count(*) FROM textual_disputes").fetchone()[0]

src.close()

print("\n--- Production Database Census ---")
print(f"  Canonical compositions:   {canonical_texts} (total: {total_texts})")
print(f"  Canonical source verses:  {canonical_verses} (total: {total_verses})")
print(f"  Active translations:      {active_translations} (DRAFT: {draft_translations})")
print(f"  Archived translations:    {archived_translations}")
print(f"  TranslationViews:         {total_views}")
print(f"  Legacy gaps:              {legacy_gaps}")
print(f"  Reviewer profiles:        {total_reviewers}")
print(f"  Review action logs:       {total_logs}")
print(f"  Textual disputes:         {total_disputes}")

assert canonical_texts == 18
assert canonical_verses == 307
assert active_translations == 3070
assert draft_translations == 3070
assert archived_translations == 580
assert total_views == 7716
assert legacy_gaps == 747
assert total_reviewers == 6
assert total_logs == 20

print("\nALL PRE-AUDIT SAFEGUARDS AND BASELINE INVARIANTS VERIFIED!")
