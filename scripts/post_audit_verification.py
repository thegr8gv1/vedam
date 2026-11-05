import hashlib
import json
import sqlite3
from pathlib import Path

with open("exports/reports/phase11c_addendum_pre_audit_fingerprints.json", "r", encoding="utf-8") as f:
    pre = json.load(f)

db_path = Path("database/vedam.db")
hasher = hashlib.sha256()
with open(db_path, "rb") as f:
    while chunk := f.read(65536):
        hasher.update(chunk)
post_hash = hasher.hexdigest()
post_size = db_path.stat().st_size

print(f"Pre-Audit  Hash: {pre['file_sha256']}")
print(f"Post-Audit Hash: {post_hash}")
assert pre["file_sha256"] == post_hash, "Hash mismatch!"
assert pre["file_size"] == post_size, "Size mismatch!"

conn = sqlite3.connect(db_path)
integrity = conn.execute("PRAGMA integrity_check").fetchall()
print(f"Integrity check: {integrity[0][0]}")
assert integrity == [("ok",)]

# Census
cur = conn.cursor()
canonical_filter = "content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099')"
canonical_texts = cur.execute(f"SELECT count(*) FROM texts WHERE {canonical_filter}").fetchone()[0]
canonical_verses = cur.execute(f"SELECT count(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE {canonical_filter})").fetchone()[0]
active_translations = cur.execute("SELECT count(*) FROM translations").fetchone()[0]
draft_translations = cur.execute("SELECT count(*) FROM translations WHERE review_status = 'DRAFT'").fetchone()[0]
archived_translations = cur.execute("SELECT count(*) FROM archived_translations").fetchone()[0]
total_views = cur.execute("SELECT count(*) FROM translation_views").fetchone()[0]
literal_views = cur.execute("SELECT count(*) FROM translation_views WHERE view_type = 'LITERAL'").fetchone()[0]
legacy_gaps = active_translations - literal_views
total_reviewers = cur.execute("SELECT count(*) FROM reviewer_profiles").fetchone()[0]
total_logs = cur.execute("SELECT count(*) FROM review_action_logs").fetchone()[0]

conn.close()

print("\nPost-Audit Census:")
print(f"  Canonical texts: {canonical_texts}")
print(f"  Canonical verses: {canonical_verses}")
print(f"  Active translations: {active_translations} (DRAFT: {draft_translations})")
print(f"  Archived translations: {archived_translations}")
print(f"  TranslationViews: {total_views}")
print(f"  Legacy gaps: {legacy_gaps}")
print(f"  Reviewer profiles: {total_reviewers}")
print(f"  Review action logs: {total_logs}")

assert canonical_texts == 18
assert canonical_verses == 307
assert active_translations == 3070
assert draft_translations == 3070
assert archived_translations == 580
assert total_views == 7716
assert legacy_gaps == 747
assert total_reviewers == 6
assert total_logs == 20

print("\nALL PRODUCTION DATABASE INVARIANTS PRESERVED 100% BIT-FOR-BIT!")
