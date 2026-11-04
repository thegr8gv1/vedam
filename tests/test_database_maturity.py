"""
Vedic Heritage Platform — Database Maturity & Integrity Test Suite
Verifies Alembic migrations, atomic snapshot backups, database recovery,
foreign key cascades, uniqueness constraints, and diagnostic reporting.
"""

import os
import shutil
import tempfile
import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import sessionmaker

from alembic import command
from alembic.config import Config
from database.backup import create_backup, restore_backup, verify_database_integrity
from database.models import (
    Base,
    Category,
    ContentRights,
    Contributor,
    Deity,
    IPLayerType,
    Jurisdiction,
    MediaAsset,
    MediaType,
    ReleaseStatus,
    ReviewStatus,
    RightsGrant,
    RightsReleaseStatus,
    Source,
    SourceEdition,
    Text,
    TextVersion,
    Translation,
    Transliteration,
    Verse,
    VerseType,
    VersionType,
)
from database.reporter import DatabaseReporter


@pytest.fixture
def clean_db():
    """Provides a fresh, isolated SQLite database for integrity testing."""
    temp_dir = tempfile.mkdtemp()
    db_path = os.path.join(temp_dir, "test_vedam.db")
    engine = create_engine(f"sqlite:///{db_path}")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    yield session, db_path, engine

    session.close()
    engine.dispose()
    shutil.rmtree(temp_dir, ignore_errors=True)


def test_alembic_upgrade_and_downgrade():
    """Verifies that Alembic can upgrade from scratch and downgrade cleanly."""
    temp_dir = tempfile.mkdtemp()
    temp_db_path = os.path.join(temp_dir, "alembic_test.db").replace("\\", "/")
    
    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", f"sqlite:///{temp_db_path}")

    try:
        # 1. Run upgrade to head
        command.upgrade(cfg, "head")
        assert os.path.exists(temp_db_path)
        assert verify_database_integrity(temp_db_path) is True

        # 2. Run downgrade to base
        command.downgrade(cfg, "base")
        assert verify_database_integrity(temp_db_path) is True

        # 3. Upgrade back to head
        command.upgrade(cfg, "head")
        assert verify_database_integrity(temp_db_path) is True
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def test_database_backup_and_recovery(clean_db):
    """Verifies atomic snapshot backup and restoration."""
    session, db_path, engine = clean_db

    # Seed one test category
    cat = Category(slug="stotra-test", name="Test Stotra")
    session.add(cat)
    session.commit()

    # Create backup
    backup_path = create_backup(db_path=db_path, label="unit_test")
    assert os.path.exists(backup_path)
    assert verify_database_integrity(backup_path) is True

    # Mutate DB (delete category)
    session.delete(cat)
    session.commit()
    assert session.query(Category).count() == 0

    # Restore from backup
    restored_path = restore_backup(backup_path, target_db_path=db_path)
    assert restored_path == db_path

    # Verify restored state
    session.expire_all()
    assert session.query(Category).count() == 1
    assert session.query(Category).first().slug == "stotra-test"

    # Cleanup backup file
    if os.path.exists(backup_path):
        os.remove(backup_path)


def test_unique_constraints_and_foreign_keys(clean_db):
    """Verifies that unique constraints and relationships behave correctly."""
    session, _, _ = clean_db

    cat = Category(slug="veda-suktam", name="Veda Suktam")
    deity = Deity(slug="shiva", name="Lord Shiva")
    session.add_all([cat, deity])
    session.commit()

    t1 = Text(
        content_id="TX-TEST-001",
        uuid="uuid-test-001",
        canonical_title="Test Hymn 1",
        devanagari_title="परीक्षार्थम्",
        primary_category_id=cat.id,
        deity_id=deity.id,
        content_hash="hash-001",
    )
    session.add(t1)
    session.commit()

    # Attempt duplicate content_id
    t2 = Text(
        content_id="TX-TEST-001",  # Duplicate!
        uuid="uuid-test-002",
        canonical_title="Duplicate Hymn",
        devanagari_title="द्वितीयम्",
        primary_category_id=cat.id,
        content_hash="hash-002",
    )
    session.add(t2)
    with pytest.raises(IntegrityError):
        session.commit()
    session.rollback()


def test_cascade_deletes_and_multi_edition(clean_db):
    """Verifies cascading deletes and 1-to-many relationships for editions, grants, and verses."""
    session, _, _ = clean_db

    cat = Category(slug="stotra", name="Stotra")
    session.add(cat)
    session.commit()

    text = Text(
        content_id="TX-CAS-001",
        uuid="uuid-cas-001",
        canonical_title="Cascade Test",
        devanagari_title="परीक्षार्थम्",
        primary_category_id=cat.id,
        content_hash="hash-cas",
    )
    session.add(text)
    session.commit()

    # Add 2 Source Editions
    ed1 = SourceEdition(text_id=text.id, edition_title="Nirnaya Sagar Press 1912", publication_year=1912)
    ed2 = SourceEdition(text_id=text.id, edition_title="Venkateshwara Steam Press 1908", publication_year=1908)
    session.add_all([ed1, ed2])

    # Add 1 Rights Grant
    rg = RightsGrant(
        text_id=text.id,
        ip_layer=IPLayerType.COMPOSITION,
        jurisdiction=Jurisdiction.IN,
        license_type="PUBLIC_DOMAIN",
        status=RightsReleaseStatus.GREEN,
        legal_reviewer="Legal Counsel",
    )
    session.add(rg)

    # Add 1 Verse with Transliteration and Translation
    v = Verse(
        text_id=text.id,
        verse_id="TX-CAS-001-001",
        verse_number=1,
        devanagari_text="हरिः ॐ",
    )
    session.add(v)
    session.commit()

    tr = Transliteration(verse_id=v.id, target_script="Telugu", script_text="హరిః ఓం")
    tln = Translation(verse_id=v.id, target_language="en", translated_text="Hari Om")
    session.add_all([tr, tln])
    session.commit()

    # Verify counts before delete
    assert session.query(SourceEdition).filter_by(text_id=text.id).count() == 2
    assert session.query(RightsGrant).filter_by(text_id=text.id).count() == 1
    assert session.query(Verse).filter_by(text_id=text.id).count() == 1
    assert session.query(Transliteration).count() == 1
    assert session.query(Translation).count() == 1

    # Cascade delete Text
    session.delete(text)
    session.commit()

    # Assert cascade
    assert session.query(SourceEdition).count() == 0
    assert session.query(RightsGrant).count() == 0
    assert session.query(Verse).count() == 0
    assert session.query(Transliteration).count() == 0
    assert session.query(Translation).count() == 0


def test_database_reporter(clean_db):
    """Verifies that DatabaseReporter accurately aggregates statistics."""
    session, _, _ = clean_db

    cat = Category(slug="stotra", name="Stotra")
    deity = Deity(slug="ganesha", name="Lord Ganesha")
    session.add_all([cat, deity])
    session.commit()

    t = Text(
        content_id="TX-REP-001",
        uuid="uuid-rep-001",
        canonical_title="Report Test",
        devanagari_title="परीक्षार्थम्",
        primary_category_id=cat.id,
        deity_id=deity.id,
        content_hash="hash-rep",
        original_language="sa",
        composer="Adi Shankara",
        source_scripture="Traditional",
    )
    session.add(t)
    session.commit()

    v = Verse(text_id=t.id, verse_id="TX-REP-001-001", verse_number=1, devanagari_text="नमः")
    session.add(v)
    session.commit()

    tr = Translation(verse_id=v.id, target_language="en", translated_text="Salutations")
    session.add(tr)
    session.commit()

    reporter = DatabaseReporter(session=session)
    summary = reporter.generate_report()

    assert summary.total_compositions == 1
    assert summary.total_verses == 1
    assert summary.total_translations == 1
    assert summary.languages_breakdown == {"sa": 1}
    assert summary.translation_languages_breakdown == {"en": 1}
    assert summary.deities_breakdown == {"Lord Ganesha": 1}
    assert summary.categories_breakdown == {"Stotra": 1}
    assert summary.texts_without_confirmed_rights == 1  # No rights record added yet
