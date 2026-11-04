"""
Database Migration: Archive Orphan Translation Records
Moves the 580 historical English translation records unlinked from earlier ingestion runs
into the schema-backed `archived_translations` table, preserving all data and audit provenance.
"""

from datetime import datetime, timezone
from sqlalchemy import create_engine
from database.connection import get_db_session, engine
from database.models import Base, ArchivedTranslation, Translation, Verse


def run_migration():
    # Create tables if not already created
    Base.metadata.create_all(bind=engine)

    with get_db_session() as session:
        verse_ids = set(row[0] for row in session.query(Verse.id).all())
        orphans = session.query(Translation).filter(Translation.verse_id.notin_(verse_ids)).all()
        print(f"Found {len(orphans)} orphan translation records to archive.")

        archived_count = 0
        for tr in orphans:
            archived = ArchivedTranslation(
                original_translation_id=tr.id,
                original_verse_id=tr.verse_id,
                target_language=tr.target_language,
                translation_type=tr.translation_type.value if hasattr(tr.translation_type, "value") else str(tr.translation_type),
                translated_text=tr.translated_text,
                translator=tr.translator,
                review_status=tr.review_status.value if hasattr(tr.review_status, "value") else str(tr.review_status),
                archived_at=datetime.now(timezone.utc),
                archival_reason="Prior-iteration duplicate translation record unlinked after verse re-insertion",
            )
            session.add(archived)
            session.delete(tr)
            archived_count += 1

        session.commit()
        print(f"Successfully archived {archived_count} records into `archived_translations`.")

        active_count = session.query(Translation).count()
        total_archived = session.query(ArchivedTranslation).count()
        print(f"Current active translations count: {active_count}")
        print(f"Current archived translations count: {total_archived}")
        print(f"Total preserved translations: {active_count + total_archived}")


if __name__ == "__main__":
    run_migration()
