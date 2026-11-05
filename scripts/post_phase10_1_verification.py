import os
import sys
sys.path.insert(0, os.path.abspath("."))

import json
import sqlite3
import hashlib
from automation.database.safety import compute_database_fingerprint, verify_database_unmodified

def main():
    # Load pre-execution fingerprints
    with open('exports/reports/phase10_1_critical_table_fingerprints.json', 'r', encoding='utf-8') as f:
        saved = json.load(f)

    base_fp = {'tables': saved['table_hashes']}
    is_clean, discrepancies = verify_database_unmodified(base_fp, 'database/vedam.db')
    print(f'Database unmodified check: {is_clean}')
    if discrepancies:
        print('Discrepancies:', discrepancies)

    # Check the four records
    with open('exports/reports/phase10_1_forensic_snapshot_affected_records.json', 'r', encoding='utf-8') as f:
        forensic = json.load(f)

    conn = sqlite3.connect('file:database/vedam.db?mode=ro', uri=True)
    for vid, data in forensic['records'].items():
        vr = data['view_record']
        curr = conn.execute('SELECT version, review_status, updated_at, view_text FROM translation_views WHERE view_id = ?', (vid,)).fetchone()
        print(f'{vid}: baseline_version={vr["version"]} vs curr_version={curr[0]}, baseline_status={vr["review_status"]} vs curr_status={curr[1]}')
        assert vr['version'] == curr[0], f'Version mismatch for {vid}!'
        assert vr['review_status'] == curr[1], f'Status mismatch for {vid}!'
        assert vr['updated_at'] == curr[2], f'Updated at mismatch for {vid}!'
        assert vr['view_text'] == curr[3], f'View text mismatch for {vid}!'
    print('All four affected records are 100% byte-for-byte identical to baseline!')

    # Census check
    census = {
        'canonical_texts': conn.execute("SELECT COUNT(*) FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01');").fetchone()[0],
        'canonical_verses': conn.execute("SELECT COUNT(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01'));").fetchone()[0],
        'active_translations': conn.execute("SELECT COUNT(*) FROM translations;").fetchone()[0],
        'draft_translations': conn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'DRAFT';").fetchone()[0],
        'approved_translations': conn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'APPROVED';").fetchone()[0],
        'archived_translations': conn.execute("SELECT COUNT(*) FROM archived_translations;").fetchone()[0],
        'total_translation_views': conn.execute("SELECT COUNT(*) FROM translation_views;").fetchone()[0],
        'bhavartha_views': conn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'BHAVARTHA';").fetchone()[0],
        'literal_views': conn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'LITERAL';").fetchone()[0],
        'tatparya_views': conn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'TATPARYA';").fetchone()[0],
    }
    print('Census post-test:\n', json.dumps(census, indent=2))
    conn.close()

if __name__ == '__main__':
    main()
