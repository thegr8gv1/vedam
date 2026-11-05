import hashlib
import sqlite3
import datetime
import json
from pathlib import Path

db_path = Path("database/vedam.db")
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_path = Path(f"database/backups/vedam_pre_phase11d_{timestamp}.db")
backup_path.parent.mkdir(parents=True, exist_ok=True)

# 1. Full SHA-256 of production database
hasher = hashlib.sha256()
with open(db_path, "rb") as f:
    while chunk := f.read(65536):
        hasher.update(chunk)
full_sha256 = hasher.hexdigest()
size_bytes = db_path.stat().st_size

print(f"Production DB Path: {db_path}")
print(f"Production DB Size: {size_bytes} bytes")
print(f"Production DB Full SHA-256: {full_sha256}")

# 2. Atomic backup via SQLite backup API
src_conn = sqlite3.connect(db_path)
backup_conn = sqlite3.connect(backup_path)
with backup_conn:
    src_conn.backup(backup_conn, pages=100)
backup_conn.close()

# Verify backup integrity
b_conn = sqlite3.connect(backup_path)
b_integrity = b_conn.execute("PRAGMA integrity_check").fetchall()
b_conn.close()
print(f"Backup created at: {backup_path}")
print(f"Backup integrity check: {b_integrity[0][0]}")

# 3. Census
cur = src_conn.cursor()
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

src_conn.close()

census = {
    "canonical_texts": canonical_texts,
    "total_texts": total_texts,
    "canonical_verses": canonical_verses,
    "total_verses": total_verses,
    "active_translations": active_translations,
    "draft_translations": draft_translations,
    "archived_translations": archived_translations,
    "total_translation_views": total_views,
    "legacy_gaps": legacy_gaps,
    "total_reviewers": total_reviewers,
    "total_review_logs": total_logs,
    "total_disputes": total_disputes
}

fingerprints = {
    "timestamp": timestamp,
    "database_file": str(db_path),
    "file_size": size_bytes,
    "file_sha256": full_sha256,
    "backup_path": str(backup_path),
    "backup_integrity": b_integrity[0][0],
    "census": census
}

Path("exports/reports").mkdir(parents=True, exist_ok=True)
with open("exports/reports/phase11d_pre_execution_fingerprints.json", "w", encoding="utf-8") as f:
    json.dump(fingerprints, f, indent=2)

print("\nCensus Summary:")
print(json.dumps(census, indent=2))

expected_hash = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
assert full_sha256 == expected_hash, f"Hash mismatch: got {full_sha256}, expected {expected_hash}"
assert canonical_texts == 18
assert canonical_verses == 307
assert active_translations == 3070
assert draft_translations == 3070
assert archived_translations == 580
assert total_views == 7716
assert legacy_gaps == 747
assert total_reviewers == 6
assert total_logs == 20
print("\nALL PRE-EXECUTION CHECKS PASSED: Baseline is 100% verified!")
