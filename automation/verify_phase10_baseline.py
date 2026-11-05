"""
Pre-Phase 10 Baseline Verification Script
Validates all 12 pre-execution requirements before starting Phase 10.
"""

import os
import sqlite3
import subprocess
from database.backup import create_backup

def verify_all_baselines():
    print("=" * 70)
    print("PHASE 10 PRE-EXECUTION RECONCILIATION & VERIFICATION")
    print("=" * 70)

    # 1. Create Atomic Database Backup
    backup_path = create_backup(label="pre_phase10")
    backup_size = os.path.getsize(backup_path)
    print(f"[1] Atomic Database Backup: {backup_path} ({backup_size:,} bytes)")

    # 2. Verify Latest Git Commit
    res_commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, check=True)
    git_commit = res_commit.stdout.strip()
    expected_commit = "04f8ba82f7e901da7c43bc4b0eda96c7c38388bf"
    print(f"[2] Git Commit: {git_commit}")
    assert git_commit == expected_commit, f"Commit mismatch! Expected {expected_commit}, got {git_commit}"

    # 3. Confirm Active Git Branch
    res_branch = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True, check=True)
    git_branch = res_branch.stdout.strip()
    print(f"[3] Git Branch: {git_branch}")
    assert git_branch == "master", f"Branch mismatch! Expected master, got {git_branch}"

    # 4. Confirm Clean Working Tree
    res_status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, check=True)
    # Check untracked or modified (ignoring newly created verify script)
    lines = [l for l in res_status.stdout.strip().splitlines() if not l.endswith("verify_phase10_baseline.py")]
    print(f"[4] Working Tree: {'Clean' if len(lines) == 0 else 'Dirty: ' + str(lines)}")
    assert len(lines) == 0, f"Working tree not clean: {lines}"

    # 5. Verify Alembic Migration Head
    res_alembic = subprocess.run(["alembic", "current"], capture_output=True, text=True, check=True)
    alembic_head = res_alembic.stdout.strip()
    print(f"[5] Alembic Migration: {alembic_head}")
    assert "9f3c8a1b2d4e" in alembic_head, f"Alembic head mismatch! Expected 9f3c8a1b2d4e, got {alembic_head}"

    # Database connection
    conn = sqlite3.connect("database/vedam.db")
    cur = conn.cursor()

    # 6. Confirm 18 Canonical Compositions
    cur.execute("""
        SELECT COUNT(*) FROM texts 
        WHERE content_id NOT IN ('VEDA-TXT-00009', 'VEDA-TXT-00099')
          AND content_id LIKE 'VEDA-TXT-%'
    """)
    canonical_comps = cur.fetchone()[0]
    print(f"[6] Canonical Compositions: {canonical_comps}")
    assert canonical_comps == 18, f"Expected 18 canonical compositions, got {canonical_comps}"

    # 7. Confirm 307 Canonical Source Verse Units
    cur.execute("""
        SELECT COUNT(v.id) 
        FROM verses v 
        JOIN texts t ON v.text_id = t.id 
        WHERE t.content_id NOT IN ('VEDA-TXT-00009', 'VEDA-TXT-00099')
          AND t.content_id LIKE 'VEDA-TXT-%'
    """)
    canonical_verses = cur.fetchone()[0]
    print(f"[7] Canonical Source Verses: {canonical_verses}")
    assert canonical_verses == 307, f"Expected 307 canonical verses, got {canonical_verses}"

    # 8. Confirm 3,070 Active Translation Records
    cur.execute("SELECT COUNT(*) FROM translations")
    active_trans = cur.fetchone()[0]
    cur.execute("SELECT review_status, COUNT(*) FROM translations GROUP BY review_status")
    status_dist = cur.fetchall()
    print(f"[8] Active Translations: {active_trans} (Distribution: {status_dist})")
    assert active_trans == 3070, f"Expected 3070 active translations, got {active_trans}"

    # 9. Confirm 580 Archived Historical Records
    cur.execute("SELECT COUNT(*) FROM archived_translations")
    archived_trans = cur.fetchone()[0]
    print(f"[9] Archived Historical Records: {archived_trans}")
    assert archived_trans == 580, f"Expected 580 archived translations, got {archived_trans}"

    # 10. Confirm 7,706 TranslationView Records
    cur.execute("SELECT COUNT(*) FROM translation_views")
    active_views = cur.fetchone()[0]
    cur.execute("SELECT view_type, COUNT(*) FROM translation_views GROUP BY view_type")
    view_types = cur.fetchall()
    print(f"[10] TranslationView Records: {active_views} (Breakdown: {view_types})")
    assert active_views == 7706, f"Expected 7706 translation views, got {active_views}"

    # 11. Confirm 752-Record Legacy Translation-View Gap
    cur.execute("""
        SELECT COUNT(t.id)
        FROM translations t
        WHERE (
            (SELECT COUNT(*) FROM translation_views tv WHERE tv.translation_id = t.id AND tv.view_type = 'LITERAL') = 0
            OR
            (SELECT COUNT(*) FROM translation_views tv WHERE tv.translation_id = t.id AND tv.view_type = 'TATPARYA') = 0
        )
    """)
    gap_records = cur.fetchone()[0]
    print(f"[11] Legacy Translation-View Gap: {gap_records}")
    assert gap_records == 752, f"Expected 752 legacy gap records, got {gap_records}"

    conn.close()

    print("=" * 70)
    print("ALL 11 PRE-TEST DATABASE & REPOSITORY BASELINES MATCH CANONICAL EXPECTATIONS!")
    print("=" * 70)

if __name__ == "__main__":
    verify_all_baselines()
