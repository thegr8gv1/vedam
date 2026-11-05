import os
import sys
sys.path.insert(0, os.path.abspath("."))

import sqlite3
import datetime
import hashlib
import json
from automation.database.safety import compute_database_fingerprint

def main():
    prod_db = 'database/vedam.db'
    backup_dir = 'database/backups'
    os.makedirs(backup_dir, exist_ok=True)
    timestamp_str = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')
    backup_filename = f'vedam_pre_phase11a_{timestamp_str}.db'
    backup_path = os.path.join(backup_dir, backup_filename)

    print(f'Starting atomic backup to {backup_path}...')
    src = sqlite3.connect(f'file:{prod_db}?mode=ro', uri=True)
    dst = sqlite3.connect(backup_path)
    src.backup(dst)
    dst.close()
    src.close()

    size = os.path.getsize(backup_path)
    print(f'Backup complete: {backup_path}, size={size} bytes')

    bconn = sqlite3.connect(f'file:{backup_path}?mode=ro', uri=True)
    integrity = bconn.execute('PRAGMA integrity_check;').fetchall()
    print(f'Backup integrity check: {integrity}')

    census = {
        'canonical_texts': bconn.execute("SELECT COUNT(*) FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099');").fetchone()[0],
        'total_texts': bconn.execute("SELECT COUNT(*) FROM texts;").fetchone()[0],
        'canonical_verses': bconn.execute("SELECT COUNT(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01', 'VEDA-TXT-00009', 'VEDA-TXT-00099'));").fetchone()[0],
        'total_verses': bconn.execute("SELECT COUNT(*) FROM verses;").fetchone()[0],
        'active_translations': bconn.execute("SELECT COUNT(*) FROM translations;").fetchone()[0],
        'draft_translations': bconn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'DRAFT';").fetchone()[0],
        'approved_translations': bconn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'APPROVED';").fetchone()[0],
        'archived_translations': bconn.execute("SELECT COUNT(*) FROM archived_translations;").fetchone()[0],
        'total_translation_views': bconn.execute("SELECT COUNT(*) FROM translation_views;").fetchone()[0],
        'bhavartha_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'BHAVARTHA';").fetchone()[0],
        'literal_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'LITERAL';").fetchone()[0],
        'tatparya_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'TATPARYA';").fetchone()[0],
    }
    print('Census:\n', json.dumps(census, indent=2))

    fp = compute_database_fingerprint(prod_db)
    print('Fingerprint file SHA-256:', fp['file_sha256'])
    for tbl, tinfo in fp['tables'].items():
        print(f"  {tbl}: count={tinfo['row_count']}, sha256={tinfo['sha256'][:16]}...")

    fingerprint_file = 'exports/reports/phase11a_pre_execution_fingerprints.json'
    with open(fingerprint_file, 'w', encoding='utf-8') as f:
        json.dump({'census': census, 'fingerprint': fp, 'backup_path': backup_path}, f, indent=2)
    print(f'Saved baseline fingerprint to {fingerprint_file}')

    bconn.close()

if __name__ == '__main__':
    main()
