import hashlib
import sqlite3
import datetime
import json
from pathlib import Path

db_path = Path('database/vedam.db')
timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
backup_path = Path(f'database/backups/vedam_pre_phase11c_addendum_{timestamp}.db')
backup_path.parent.mkdir(parents=True, exist_ok=True)

# 1. Compute full SHA-256 of production database
hasher = hashlib.sha256()
with open(db_path, 'rb') as f:
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

# 3. Census of production database
cur = src_conn.cursor()

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

cur.execute("SELECT count(*) FROM textual_disputes")
total_disputes = cur.fetchone()[0]

# Calculate legacy gaps (3070 translations - 2323 literal views = 747 gap records)
legacy_gaps = active_translations - literal_views

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
    "legacy_gaps": legacy_gaps,
    "total_reviewers": total_reviewers,
    "total_review_logs": total_review_logs,
    "total_disputes": total_disputes
}

def hash_table(conn, table_name, order_col):
    c = conn.cursor()
    c.execute(f"SELECT * FROM {table_name} ORDER BY {order_col}")
    rows = c.fetchall()
    h = hashlib.sha256()
    for row in rows:
        h.update(str(row).encode("utf-8"))
    return len(rows), h.hexdigest()

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
    ("textual_disputes", "id")
]

table_hashes = {}
for t, col in tables_to_hash:
    count, thash = hash_table(src_conn, t, col)
    table_hashes[t] = {"count": count, "sha256": thash}

src_conn.close()

fingerprints = {
    "timestamp": timestamp,
    "database_file": str(db_path),
    "file_size": size_bytes,
    "file_sha256": full_sha256,
    "backup_path": str(backup_path),
    "backup_integrity": b_integrity[0][0],
    "census": census,
    "table_hashes": table_hashes
}

Path("exports/reports").mkdir(parents=True, exist_ok=True)
with open("exports/reports/phase11c_addendum_pre_audit_fingerprints.json", "w", encoding="utf-8") as f:
    json.dump(fingerprints, f, indent=2)

print("Pre-Audit Fingerprint Capture Complete:")
print(json.dumps(census, indent=2))
