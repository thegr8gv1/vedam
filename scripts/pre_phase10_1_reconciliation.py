import os
import sys
import sqlite3
import shutil
import datetime
import hashlib
import json

def main():
    # 1. Paths
    prod_db = 'database/vedam.db'
    backup_dir = 'database/backups'
    os.makedirs(backup_dir, exist_ok=True)
    timestamp_str = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')
    backup_filename = f'vedam_pre_phase10_1_{timestamp_str}.db'
    backup_path = os.path.join(backup_dir, backup_filename)

    # 2. Atomic backup using sqlite3 backup API
    print(f'Starting atomic backup from {prod_db} to {backup_path}...')
    src = sqlite3.connect(f'file:{prod_db}?mode=ro', uri=True)
    dst = sqlite3.connect(backup_path)
    src.backup(dst)
    dst.close()
    src.close()

    size = os.path.getsize(backup_path)
    print(f'Backup complete: {backup_path}, size={size} bytes')

    # 3. Verify backup integrity
    bconn = sqlite3.connect(f'file:{backup_path}?mode=ro', uri=True)
    b_integrity = bconn.execute('PRAGMA integrity_check;').fetchall()
    print(f'Backup integrity check: {b_integrity}')

    # 4. Forensic snapshot of the four affected TranslationView records
    view_ids = [
        'VIEW-TR-00006-BHAVARTHA-v1',
        'VIEW-TR-00508-BHAVARTHA-v1',
        'VIEW-TR-00524-BHAVARTHA-v1',
        'VIEW-TR-00752-BHAVARTHA-v1'
    ]

    forensic_data = {
        'captured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'backup_path': backup_path,
        'records': {}
    }

    tables = [t[0] for t in bconn.execute("SELECT name FROM sqlite_master WHERE type='table';").fetchall()]
    print('Tables in database:', tables)

    for vid in view_ids:
        row = bconn.execute('SELECT * FROM translation_views WHERE view_id = ?', (vid,)).fetchone()
        cols = [d[0] for d in bconn.execute('SELECT * FROM translation_views LIMIT 1').description]
        rec_dict = dict(zip(cols, row)) if row else None
        
        t_row = None
        if rec_dict and 'translation_id' in rec_dict:
            t_cur = bconn.execute('SELECT * FROM translations WHERE id = ?', (rec_dict['translation_id'],))
            t_cols = [d[0] for d in t_cur.description]
            t_val = t_cur.fetchone()
            t_row = dict(zip(t_cols, t_val)) if t_val else None

        # Related review actions
        related_actions = []
        if 'review_action_logs' in tables and rec_dict:
            a_cur = bconn.execute('SELECT * FROM review_action_logs WHERE translation_view_id = ? OR translation_id = ?', 
                                  (rec_dict['id'], rec_dict['translation_id']))
            a_cols = [d[0] for d in a_cur.description]
            related_actions = [dict(zip(a_cols, r)) for r in a_cur.fetchall()]
                
        # Related feedbacks
        related_feedbacks = []
        if 'translation_review_feedbacks' in tables and rec_dict:
            f_cur = bconn.execute('SELECT * FROM translation_review_feedbacks WHERE translation_id = ?', (rec_dict['translation_id'],))
            f_cols = [d[0] for d in f_cur.description]
            related_feedbacks = [dict(zip(f_cols, r)) for r in f_cur.fetchall()]

        # Related audit logs
        related_audit = []
        if 'auth_audit_logs' in tables and rec_dict:
            l_cur = bconn.execute("SELECT * FROM auth_audit_logs WHERE details LIKE ? OR details LIKE ?", 
                                  (f"%{vid}%", f"%{rec_dict['translation_id']}%"))
            l_cols = [d[0] for d in l_cur.description]
            related_audit = [dict(zip(l_cols, r)) for r in l_cur.fetchall()]

        forensic_data['records'][vid] = {
            'view_record': rec_dict,
            'translation_record': t_row,
            'review_action_logs': related_actions,
            'review_feedbacks': related_feedbacks,
            'auth_audit_logs': related_audit
        }

    forensic_file = 'exports/reports/phase10_1_forensic_snapshot_affected_records.json'
    os.makedirs(os.path.dirname(forensic_file), exist_ok=True)
    with open(forensic_file, 'w', encoding='utf-8') as f:
        json.dump(forensic_data, f, indent=2, default=str)
    print(f'Forensic snapshot saved to {forensic_file}')

    # 5. Database Census
    census = {
        'canonical_texts': bconn.execute("SELECT COUNT(*) FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01');").fetchone()[0],
        'total_texts': bconn.execute("SELECT COUNT(*) FROM texts;").fetchone()[0],
        'canonical_verses': bconn.execute("SELECT COUNT(*) FROM verses WHERE text_id IN (SELECT id FROM texts WHERE content_id LIKE 'VEDA-TXT-%' AND content_id NOT IN ('VEDA-TXT-TEST01'));").fetchone()[0],
        'total_verses': bconn.execute("SELECT COUNT(*) FROM verses;").fetchone()[0],
        'active_translations': bconn.execute("SELECT COUNT(*) FROM translations;").fetchone()[0],
        'draft_translations': bconn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'DRAFT';").fetchone()[0],
        'approved_translations': bconn.execute("SELECT COUNT(*) FROM translations WHERE review_status = 'APPROVED';").fetchone()[0],
        'archived_translations': bconn.execute("SELECT COUNT(*) FROM archived_translations;").fetchone()[0] if 'archived_translations' in tables else 0,
        'total_translation_views': bconn.execute("SELECT COUNT(*) FROM translation_views;").fetchone()[0],
        'bhavartha_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'BHAVARTHA';").fetchone()[0],
        'literal_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'LITERAL';").fetchone()[0],
        'tatparya_views': bconn.execute("SELECT COUNT(*) FROM translation_views WHERE view_type = 'TATPARYA';").fetchone()[0],
    }
    print('Database Census:\n', json.dumps(census, indent=2))

    # 6. Table row counts & content hashes for critical tables
    critical_tables = ['texts', 'verses', 'translations', 'translation_views', 'sources']
    table_hashes = {}
    for tbl in critical_tables:
        rows = bconn.execute(f"SELECT * FROM {tbl} ORDER BY ROWID").fetchall()
        h = hashlib.sha256()
        for row in rows:
            h.update(str(row).encode('utf-8'))
        table_hashes[tbl] = {
            'row_count': len(rows),
            'sha256': h.hexdigest()
        }
    print('Critical table fingerprints:')
    for tbl, info in table_hashes.items():
        print(f"  {tbl}: count={info['row_count']}, sha256={info['sha256']}")

    fingerprint_file = 'exports/reports/phase10_1_critical_table_fingerprints.json'
    with open(fingerprint_file, 'w', encoding='utf-8') as f:
        json.dump({'census': census, 'table_hashes': table_hashes, 'backup_path': backup_path}, f, indent=2)
    print(f'Fingerprints saved to {fingerprint_file}')

    bconn.close()
    print('Pre-execution reconciliation completed successfully.')

if __name__ == '__main__':
    main()
