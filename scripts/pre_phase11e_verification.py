"""
Pre-Phase 11E Baseline Verification and Backup Script
"""
import hashlib
import os
from pathlib import Path
import shutil
import sqlite3
import sys
from datetime import datetime, timezone

from alembic.config import Config
from alembic.script import ScriptDirectory

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from database.models import ReviewerRole

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

DB_PATH = Path("database/vedam.db")
EXPECTED_SHA256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
EXPECTED_ALEMBIC_HEAD = "e3a7b1c9f2d5"
EXPECTED_DB_REV = "9f3c8a1b2d4e"

print("=================================================================")
print("Vedam Platform — Pre-Phase 11E Baseline Verification")
print("=================================================================")

# 1. Check DB Path & SHA-256
if not DB_PATH.exists():
    print(f"CRITICAL ERROR: Database file not found at {DB_PATH}")
    sys.exit(1)

file_bytes = open(DB_PATH, "rb").read()
file_size = len(file_bytes)
actual_sha256 = hashlib.sha256(file_bytes).hexdigest()

print(f"Production DB Path: {DB_PATH.resolve()}")
print(f"File Size:          {file_size:,} bytes")
print(f"Actual SHA-256:     {actual_sha256}")
print(f"Expected SHA-256:   {EXPECTED_SHA256}")

assert actual_sha256 == EXPECTED_SHA256, f"SHA-256 mismatch! Expected {EXPECTED_SHA256}, got {actual_sha256}"
print("SHA-256 Verification: PASSED")

# 2. Database Integrity Check
conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()
cursor.execute("PRAGMA integrity_check;")
res = cursor.fetchall()
assert res == [("ok",)], f"Integrity check failed: {res}"
print("PRAGMA integrity_check: PASSED (ok)")

# 3. Alembic Head & Revision
alembic_cfg = Config("alembic.ini")
script = ScriptDirectory.from_config(alembic_cfg)
repo_head = script.get_current_head()
print(f"Alembic Repo Head:  {repo_head}")
assert repo_head == EXPECTED_ALEMBIC_HEAD, f"Alembic repo head mismatch: expected {EXPECTED_ALEMBIC_HEAD}, got {repo_head}"

cursor.execute("SELECT version_num FROM alembic_version;")
db_rev = cursor.fetchone()[0]
print(f"Database Revision:  {db_rev}")
assert db_rev == EXPECTED_DB_REV, f"Database revision mismatch: expected {EXPECTED_DB_REV}, got {db_rev}"

# 4. Baseline Census
canonical_filter = "content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099')"
cursor.execute(f"SELECT count(*) FROM texts WHERE {canonical_filter};")
canon_texts = cursor.fetchone()[0]
cursor.execute("SELECT count(*) FROM texts;")
total_texts = cursor.fetchone()[0]

cursor.execute(f"SELECT count(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE {canonical_filter});")
canon_verses = cursor.fetchone()[0]
cursor.execute("SELECT count(*) FROM verses;")
total_verses = cursor.fetchone()[0]

cursor.execute("SELECT count(*) FROM translations;")
active_trans = cursor.fetchone()[0]
cursor.execute("SELECT count(*) FROM translations WHERE review_status = 'DRAFT';")
draft_trans = cursor.fetchone()[0]
cursor.execute("SELECT count(*) FROM archived_translations;")
archived_trans = cursor.fetchone()[0]

cursor.execute("SELECT count(*) FROM translation_views;")
total_views = cursor.fetchone()[0]

cursor.execute("SELECT count(*) FROM translation_views WHERE view_type = 'LITERAL';")
literal_views = cursor.fetchone()[0]
legacy_gaps = active_trans - literal_views

cursor.execute("SELECT count(*) FROM reviewer_profiles;")
reviewer_profiles = cursor.fetchone()[0]

total_roles = len(ReviewerRole)

cursor.execute("SELECT count(*) FROM review_action_logs;")
action_logs = cursor.fetchone()[0]

cursor.execute("SELECT count(*) FROM textual_disputes;")
total_disputes = cursor.fetchone()[0]

print("\n--- Baseline Census Verification ---")
print(f"  Canonical Compositions: {canon_texts} (Target: 18) [Total: {total_texts}]")
print(f"  Canonical Verses:       {canon_verses} (Target: 307) [Total: {total_verses}]")
print(f"  Active Translations:    {active_trans} (Target: 3,070, all DRAFT: {draft_trans})")
print(f"  Archived Translations:  {archived_trans} (Target: 580)")
print(f"  TranslationViews:       {total_views} (Target: 7,716)")
print(f"  Legacy Gaps:            {legacy_gaps} (Target: 747)")
print(f"  Reviewer Profiles:      {reviewer_profiles} (Target: 6)")
print(f"  Reviewer Roles:         {total_roles} (Target: 29)")
print(f"  Review Action Logs:     {action_logs} (Target: 20)")
print(f"  Text Disputes:          {total_disputes} (Target: 2)")

assert canon_texts == 18, f"Canonical texts mismatch: {canon_texts}"
assert total_texts == 20, f"Total texts mismatch: {total_texts}"
assert canon_verses == 307, f"Canonical verses mismatch: {canon_verses}"
assert total_verses == 310, f"Total verses mismatch: {total_verses}"
assert active_trans == 3070, f"Active translations mismatch: {active_trans}"
assert draft_trans == 3070, f"Draft translations mismatch: {draft_trans}"
assert archived_trans == 580, f"Archived translations mismatch: {archived_trans}"
assert total_views == 7716, f"Total views mismatch: {total_views}"
assert legacy_gaps == 747, f"Legacy gaps mismatch: {legacy_gaps}"
assert reviewer_profiles == 6, f"Reviewer profiles mismatch: {reviewer_profiles}"
assert total_roles == 29, f"Reviewer roles mismatch: {total_roles}"
assert action_logs == 20, f"Action logs mismatch: {action_logs}"
assert total_disputes == 2, f"Disputes mismatch: {total_disputes}"

conn.close()

# 5. Create Timestamped Pre-Phase-11E Backup
os.makedirs("database/backups", exist_ok=True)
ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
backup_path = Path(f"database/backups/vedam_pre_phase11e_{ts}.db")
shutil.copy2(DB_PATH, backup_path)

backup_bytes = open(backup_path, "rb").read()
backup_sha256 = hashlib.sha256(backup_bytes).hexdigest()
assert backup_sha256 == actual_sha256, "Backup hash mismatch!"

backup_conn = sqlite3.connect(backup_path)
b_res = backup_conn.cursor().execute("PRAGMA integrity_check;").fetchall()
assert b_res == [("ok",)], f"Backup integrity check failed: {b_res}"
backup_conn.close()

print(f"\nPre-Phase 11E Backup Created: {backup_path}")
print(f"Backup Size:   {len(backup_bytes):,} bytes")
print(f"Backup SHA:    {backup_sha256}")
print("Backup Integrity Check: PASSED (ok)")
print("\nALL PRE-EXECUTION CHECKS PASSED PERFECTLY!")
