"""
Post-Phase 11B Verification Script
Compares current database state against pre-execution fingerprints
to prove 100% whole-file and table-level immutability.
"""

import hashlib
import json
import sqlite3

PROD_DB = "database/vedam.db"
FINGERPRINT_PATH = "exports/reports/phase11b_pre_execution_fingerprints.json"

with open(FINGERPRINT_PATH, "r", encoding="utf-8") as f:
    baseline = json.load(f)

# 1. Whole DB file SHA-256
with open(PROD_DB, "rb") as f:
    current_db_hash = hashlib.sha256(f.read()).hexdigest()

baseline_db_hash = baseline["database_file_sha256"]
print(f"Baseline DB SHA-256: {baseline_db_hash}")
print(f"Current  DB SHA-256: {current_db_hash}")
is_db_identical = (current_db_hash == baseline_db_hash)
print(f"Whole-database file unmodified: {is_db_identical}")

# 2. Table-level checks
conn = sqlite3.connect(PROD_DB)

def hash_table(conn, table_name, order_col):
    c = conn.cursor()
    c.execute(f"SELECT * FROM {table_name} ORDER BY {order_col}")
    rows = c.fetchall()
    hasher = hashlib.sha256()
    for row in rows:
        hasher.update(str(row).encode("utf-8"))
    return len(rows), hasher.hexdigest()

order_cols = {
    "texts": "id",
    "verses": "id",
    "translations": "id",
    "translation_views": "id",
    "reviewer_profiles": "id",
    "review_action_logs": "id",
    "sources": "id",
    "categories": "id",
    "content_rights": "id",
}

all_tables_match = True
for tbl, b_data in baseline["table_fingerprints"].items():
    cnt, hsh = hash_table(conn, tbl, order_cols[tbl])
    match = (cnt == b_data["count"] and hsh == b_data["sha256"])
    if not match:
        all_tables_match = False
    print(f"  {tbl}: count={cnt} (expected {b_data['count']}), hash_match={match}")

# 3. Census
canonical_filter = "content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099')"
cur = conn.cursor()
cur.execute(f"SELECT count(*) FROM texts WHERE {canonical_filter}")
canonical_texts = cur.fetchone()[0]

cur.execute(f"SELECT count(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE {canonical_filter})")
canonical_verses = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations")
active_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations WHERE review_status = 'DRAFT'")
draft_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translations WHERE review_status = 'APPROVED'")
approved_translations = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM translation_views")
total_views = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM reviewer_profiles")
total_reviewers = cur.fetchone()[0]

cur.execute("SELECT count(*) FROM review_action_logs")
total_review_logs = cur.fetchone()[0]

cur.execute("PRAGMA integrity_check")
integrity = cur.fetchone()[0]

print(f"Integrity check: {integrity}")
assert integrity == "ok"
assert is_db_identical
assert all_tables_match
assert canonical_texts == 18
assert canonical_verses == 307
assert active_translations == 3070
assert draft_translations == 3070
assert approved_translations == 0
assert total_views == 7716
assert total_reviewers == 6
assert total_review_logs == 20

print("\nALL VERIFICATIONS PASSED: Production database is 100% byte-for-byte identical to baseline!")
conn.close()
