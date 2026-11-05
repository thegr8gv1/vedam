"""
Pre-Phase 11C Reconciliation Script
Performs atomic database backup, integrity verification, table-level hashing,
and census capture before any Phase 11C operations.
"""

from datetime import datetime, timezone
import hashlib
import json
import os
import sqlite3

PROD_DB = "database/vedam.db"
BACKUP_DIR = "database/backups"
TIMESTAMP = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
BACKUP_PATH = os.path.join(BACKUP_DIR, f"vedam_pre_phase11c_{TIMESTAMP}.db")
FINGERPRINT_PATH = "exports/reports/phase11c_pre_execution_fingerprints.json"

os.makedirs(BACKUP_DIR, exist_ok=True)
os.makedirs(os.path.dirname(FINGERPRINT_PATH), exist_ok=True)

# 1. Atomic Backup
print(f"Starting atomic backup to {BACKUP_PATH}...")
source_conn = sqlite3.connect(PROD_DB)
backup_conn = sqlite3.connect(BACKUP_PATH)
with backup_conn:
    source_conn.backup(backup_conn, pages=100)
backup_conn.close()

backup_size = os.path.getsize(BACKUP_PATH)
print(f"Backup complete: {BACKUP_PATH}, size={backup_size} bytes")

# 2. Integrity Check on Backup
verify_conn = sqlite3.connect(BACKUP_PATH)
integrity = verify_conn.execute("PRAGMA integrity_check").fetchall()
verify_conn.close()
print(f"Backup integrity check: {integrity}")
assert integrity == [("ok",)], f"Backup integrity check failed: {integrity}"

# 3. Census
cur = source_conn.cursor()

canonical_filter = "content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099')"

cur.execute(f"SELECT count(*) FROM texts WHERE {canonical_filter}")
canonical_texts = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM texts")
total_texts = cur.fetchone()[0]

cur.execute(f"SELECT count(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE {canonical_filter})")
canonical_verses = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM verses")
total_verses = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations")
active_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations WHERE review_status = 'DRAFT'")
draft_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations WHERE review_status = 'APPROVED'")
approved_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM archived_translations")
archived_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translation_views")
total_views = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translation_views WHERE view_type = 'BHAVARTHA'")
bhavartha_views = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translation_views WHERE view_type = 'LITERAL'")
literal_views = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translation_views WHERE view_type = 'TATPARYA'")
tatparya_views = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM reviewer_profiles")
total_reviewers = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM review_action_logs")
total_review_logs = cur.fetchone()[0]

census = {
    "canonical_texts": canonical_texts,
    "total_texts": total_texts,
    "canonical_verses": canonical_verses,
    "total_verses": total_verses,
    "active_translations": active_translations,
    "draft_translations": draft_translations,
    "approved_translations": approved_translations,
    "archived_translations": archived_translations,
    "total_translation_views": total_views,
    "bhavartha_views": bhavartha_views,
    "literal_views": literal_views,
    "tatparya_views": tatparya_views,
    "total_reviewers": total_reviewers,
    "total_review_logs": total_review_logs,
}
print("Census:\n", json.dumps(census, indent=2))

# 4. Table Fingerprints
def hash_table(conn, table_name, order_col):
    c = conn.cursor()
    c.execute(f"SELECT * FROM {table_name} ORDER BY {order_col}")
    rows = c.fetchall()
    hasher = hashlib.sha256()
    for row in rows:
        hasher.update(str(row).encode("utf-8"))
    return len(rows), hasher.hexdigest()

tables_to_hash = [
    ("texts", "id"),
    ("verses", "id"),
    ("translations", "id"),
    ("translation_views", "id"),
    ("reviewer_profiles", "id"),
    ("review_action_logs", "id"),
    ("sources", "id"),
    ("categories", "id"),
    ("content_rights", "id"),
]

table_fingerprints = {}
for tbl, ocol in tables_to_hash:
    cnt, hsh = hash_table(source_conn, tbl, ocol)
    table_fingerprints[tbl] = {"count": cnt, "sha256": hsh}
    print(f"  {tbl}: count={cnt}, sha256={hsh[:16]}...")

# Whole DB file SHA-256
with open(PROD_DB, "rb") as f:
    db_file_hash = hashlib.sha256(f.read()).hexdigest()

print(f"Database file SHA-256: {db_file_hash}")

pre_execution_data = {
    "timestamp": TIMESTAMP,
    "commit": "75aa321fd3498454004b10fd84ccaaadb9dd686f",
    "backup_path": BACKUP_PATH,
    "backup_size_bytes": backup_size,
    "database_file_sha256": db_file_hash,
    "census": census,
    "table_fingerprints": table_fingerprints,
}

with open(FINGERPRINT_PATH, "w", encoding="utf-8") as f:
    json.dump(pre_execution_data, f, indent=2)

print(f"Saved baseline fingerprint to {FINGERPRINT_PATH}")
source_conn.close()
