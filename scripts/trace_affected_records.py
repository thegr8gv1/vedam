import sqlite3

def main():
    conn = sqlite3.connect('file:database/vedam.db?mode=ro', uri=True)

    print('--- 1. Gayatri (TID 6) ---')
    r = conn.execute("""
        SELECT t.id, tv.id, tv.view_id, tv.version, tv.review_status, tv.updated_at
        FROM translations t 
        JOIN translation_views tv ON tv.translation_id = t.id 
        WHERE t.id = 6
    """).fetchall()
    for row in r:
        print(row)

    print('--- 2. Affected Views Details ---')
    r = conn.execute("""
        SELECT tv.view_id, tv.version, tv.review_status, t.id as trans_id, t.target_language, tx.content_id, tx.canonical_title, v.verse_number, tv.updated_at
        FROM translation_views tv
        JOIN translations t ON tv.translation_id = t.id
        JOIN verses v ON t.verse_id = v.id
        JOIN texts tx ON v.text_id = tx.id
        WHERE tv.view_id IN (
            'VIEW-TR-00006-BHAVARTHA-v1',
            'VIEW-TR-00508-BHAVARTHA-v1',
            'VIEW-TR-00524-BHAVARTHA-v1',
            'VIEW-TR-00752-BHAVARTHA-v1'
        )
    """).fetchall()
    for row in r:
        print(row)

    print('--- 3. Review Action Logs for these views ---')
    r = conn.execute("""
        SELECT a.id, a.action_id, a.translation_id, a.translation_view_id, a.action_type, a.reviewer_id, a.created_at, a.scholarly_commentary
        FROM review_action_logs a
        WHERE a.translation_view_id IN (SELECT id FROM translation_views WHERE view_id IN (
            'VIEW-TR-00006-BHAVARTHA-v1',
            'VIEW-TR-00508-BHAVARTHA-v1',
            'VIEW-TR-00524-BHAVARTHA-v1',
            'VIEW-TR-00752-BHAVARTHA-v1'
        )) OR a.translation_id IN (6, 508, 524, 752)
        ORDER BY a.created_at ASC
    """).fetchall()
    for row in r:
        print(row)

    conn.close()

if __name__ == '__main__':
    main()
