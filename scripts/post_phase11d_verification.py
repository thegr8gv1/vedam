"""
Vedic Heritage Platform — Post-Phase 11D Independent Verification Script
Validates database SHA-256 immutability, zero writes, Alembic migration state,
canonical text/verse census, translation view counts, and exports manifest.
"""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

BASELINE_SHA256 = "8315040257dc3e490646e6e7138f9fd8bb38eae835b84e1f15849badae7318aa"
EXPECTED_ALEMBIC_HEAD = "e3a7b1c9f2d5"
DB_PATH = Path("database/vedam.db")


def calculate_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def run_census(db_path: Path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("PRAGMA integrity_check;")
    integrity = cur.fetchone()[0]

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
    # ReviewerRole is an Enum with 29 roles defined in database.models
    from database.models import ReviewerRole
    total_roles = len(ReviewerRole)
    total_logs = cur.execute("SELECT count(*) FROM review_action_logs").fetchone()[0]
    total_disputes = cur.execute("SELECT count(*) FROM textual_disputes").fetchone()[0]
    alembic_db_rev = cur.execute("SELECT version_num FROM alembic_version").fetchone()[0]

    conn.close()

    return {
        "integrity": integrity,
        "canonical_texts": canonical_texts,
        "total_texts": total_texts,
        "canonical_verses": canonical_verses,
        "total_verses": total_verses,
        "active_translations": active_translations,
        "draft_translations": draft_translations,
        "archived_translations": archived_translations,
        "total_views": total_views,
        "legacy_gaps": legacy_gaps,
        "reviewer_profiles": total_reviewers,
        "reviewer_roles": total_roles,
        "action_logs": total_logs,
        "disputes": total_disputes,
        "alembic_db_rev": alembic_db_rev,
    }


def main():
    print("=================================================================")
    print("Vedic Heritage Platform — Phase 11D Post-Execution Verification")
    print("=================================================================")

    # 1. SHA-256 Verification
    actual_sha = calculate_sha256(DB_PATH)
    file_size = DB_PATH.stat().st_size
    print(f"Production Database Path: {DB_PATH.resolve()}")
    print(f"File Size:               {file_size:,} bytes")
    print(f"Calculated SHA-256:      {actual_sha}")
    print(f"Expected Baseline SHA:   {BASELINE_SHA256}")

    is_identical = (actual_sha == BASELINE_SHA256)
    print(f"Bit-for-bit Immutability Check: {'PASSED (100% UNMODIFIED)' if is_identical else 'FAILED (MUTATION DETECTED!)'}")

    # 2. Database Census
    census = run_census(DB_PATH)
    print("\nDatabase Census:")
    for k, v in census.items():
        print(f"  {k:30s}: {v}")

    # 3. Assertions
    assert is_identical, f"CRITICAL: Production DB modified! Expected {BASELINE_SHA256}, got {actual_sha}"
    assert census["integrity"] == "ok", f"Integrity check failed: {census['integrity']}"
    assert census["canonical_texts"] == 18, f"Expected 18 canonical texts, got {census['canonical_texts']}"
    assert census["canonical_verses"] == 307, f"Expected 307 canonical verses, got {census['canonical_verses']}"
    assert census["active_translations"] == 3070, f"Expected 3,070 active translations, got {census['active_translations']}"
    assert census["draft_translations"] == 3070, f"Expected 3,070 draft translations, got {census['draft_translations']}"
    assert census["archived_translations"] == 580, f"Expected 580 archived translations, got {census['archived_translations']}"
    assert census["total_views"] == 7716, f"Expected 7,716 views, got {census['total_views']}"
    assert census["legacy_gaps"] == 747, f"Expected 747 legacy gaps, got {census['legacy_gaps']}"
    assert census["reviewer_profiles"] == 6, f"Expected 6 reviewer profiles, got {census['reviewer_profiles']}"
    assert census["reviewer_roles"] == 29, f"Expected 29 reviewer roles, got {census['reviewer_roles']}"
    assert census["action_logs"] == 20, f"Expected 20 action logs, got {census['action_logs']}"
    assert census["alembic_db_rev"] == "9f3c8a1b2d4e", f"Expected DB Alembic revision 9f3c8a1b2d4e, got {census['alembic_db_rev']}"

    # Also verify repository Alembic head
    import subprocess
    proc = subprocess.run(["alembic", "heads"], capture_output=True, text=True, check=True)
    repo_head = proc.stdout.split()[0]
    assert repo_head == EXPECTED_ALEMBIC_HEAD, f"Expected repo Alembic head {EXPECTED_ALEMBIC_HEAD}, got {repo_head}"

    # 4. Save report
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database_sha256": actual_sha,
        "database_size_bytes": file_size,
        "immutability_verified": is_identical,
        "census": census,
    }
    out_dir = Path("exports/reports")
    out_dir.mkdir(parents=True, exist_ok=True)
    report_path = out_dir / "phase11d_post_execution_verification.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"\nVerification report written to: {report_path.resolve()}")
    print("ALL POST-EXECUTION IMMUTABILITY & CENSUS CHECKS PASSED SUCCESSFULLY!\n")


if __name__ == "__main__":
    main()
