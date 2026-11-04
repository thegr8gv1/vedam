"""
Vedic Heritage Platform — Batch Processing & Orchestrator Tests
Verifies bounded batch sizing, dry-run simulation, source permission gates,
checkpointing, and manual legal approval.
"""

import os
import shutil
import tempfile
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from automation.pipeline.batch_processor import (
    BatchConfig,
    BatchExecutionReport,
    BatchIngestionEngine,
    RawBatchItem,
)
from database.models import (
    Base,
    Category,
    Deity,
    RightsReleaseStatus,
    Source,
    Text,
)


@pytest.fixture
def batch_test_env():
    """Sets up an isolated database and checkpoint environment for batch tests."""
    temp_dir = tempfile.mkdtemp()
    db_path = os.path.join(temp_dir, "batch_test.db")
    engine = create_engine(f"sqlite:///{db_path}")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Seed required sources
    s_track_b = Source(source_code="SRC-IND-001", name="Historical Public Domain", terms_url="PD")
    s_red = Source(source_code="SRC-002", name="Commercial Forbidden", terms_url="Copyright")
    session.add_all([s_track_b, s_red])

    # Seed categories and deities
    c_stotra = Category(slug="stotra", name="Stotra")
    d_shiva = Deity(slug="shiva", name="Lord Shiva")
    session.add_all([c_stotra, d_shiva])
    session.commit()

    checkpoint_dir = os.path.join(temp_dir, "checkpoints")

    yield session, db_path, checkpoint_dir

    session.close()
    engine.dispose()
    shutil.rmtree(temp_dir, ignore_errors=True)


def test_batch_sizing_constraint(batch_test_env, monkeypatch):
    """Verifies that a batch of 10 items with batch_size=2 processes only 2 items."""
    session, db_path, checkpoint_dir = batch_test_env

    config = BatchConfig(
        batch_size=2,
        dry_run=False,
        checkpoint_dir=checkpoint_dir,
        job_name="size_test",
    )
    engine = BatchIngestionEngine(config=config, session=session)

    # Prepare 5 dummy items
    items = [
        RawBatchItem(
            raw_text=f"मङ्गलं भगवान् शम्भुः {i} ॥ {i} ॥",
            source_code="SRC-IND-001",
            source_url="https://archive.org",
            proposed_title=f"Test Shiva Stuti {i}",
            proposed_category_slug="stotra",
            deity_slug="shiva",
        )
        for i in range(1, 6)
    ]

    report = engine.process_batch(items)
    assert report.total_submitted == 5
    assert report.processed_count == 2
    assert report.success_count == 2
    assert len(report.ingested_content_ids) == 2


def test_batch_dry_run_mode(batch_test_env, monkeypatch):
    """Verifies that dry_run=True performs validations without writing to the database."""
    session, db_path, checkpoint_dir = batch_test_env

    config = BatchConfig(
        batch_size=5,
        dry_run=True,  # DRY RUN
        checkpoint_dir=checkpoint_dir,
        job_name="dry_run_test",
    )
    engine = BatchIngestionEngine(config=config, session=session)

    items = [
        RawBatchItem(
            raw_text="हरिः ॐ ॥ १ ॥",
            source_code="SRC-IND-001",
            source_url="https://archive.org",
            proposed_title="Dry Run Hymn",
            proposed_category_slug="stotra",
            deity_slug="shiva",
        )
    ]

    report = engine.process_batch(items)
    assert report.dry_run is True
    assert report.success_count == 1

    # Verify nothing was committed to database
    session.expire_all()
    assert session.query(Text).filter_by(canonical_title="Dry Run Hymn").count() == 0


def test_batch_blocks_forbidden_source(batch_test_env, monkeypatch):
    """Verifies that attempting ingestion from forbidden source (SRC-002) is routed to error queue."""
    session, db_path, checkpoint_dir = batch_test_env

    config = BatchConfig(
        batch_size=5,
        dry_run=False,
        checkpoint_dir=checkpoint_dir,
        job_name="forbidden_source_test",
    )
    engine = BatchIngestionEngine(config=config, session=session)

    items = [
        RawBatchItem(
            raw_text="ॐ नमः शिवाय ॥ १ ॥",
            source_code="SRC-002",  # FORBIDDEN SOURCE
            source_url="https://drikpanchang.com",
            proposed_title="Forbidden Item",
            proposed_category_slug="stotra",
            deity_slug="shiva",
        )
    ]

    report = engine.process_batch(items)
    assert report.failed_count == 1
    assert len(report.error_queue) == 1
    assert "PermissionError" in report.error_queue[0]["error_type"]


def test_manual_legal_approval_transition(batch_test_env, monkeypatch):
    """Verifies human legal reviewer approval transitions rights to GREEN."""
    session, db_path, checkpoint_dir = batch_test_env

    config = BatchConfig(
        batch_size=1,
        dry_run=False,
        checkpoint_dir=checkpoint_dir,
        job_name="approval_test",
    )
    engine = BatchIngestionEngine(config=config, session=session)

    items = [
        RawBatchItem(
            raw_text="नमामीशमीशान निर्वाणरूपम् ॥ १ ॥",
            source_code="SRC-IND-001",
            source_url="https://archive.org",
            proposed_title="Rudrashtakam Stuti",
            proposed_category_slug="stotra",
            deity_slug="shiva",
        )
    ]

    report = engine.process_batch(items)
    content_id = report.ingested_content_ids[0]

    # Verify initial rights status is AMBER
    session.expire_all()
    text = session.query(Text).filter_by(content_id=content_id).first()
    assert text.rights_grants[0].status == RightsReleaseStatus.AMBER
    assert text.rights_grants[0].is_legally_approved is False

    # Execute manual legal review approval
    approved = BatchIngestionEngine.approve_for_publication(
        content_id=content_id,
        legal_reviewer="Lead Legal Counsel",
        session=session,
    )
    assert approved is True

    # Verify transition to GREEN
    session.expire_all()
    text_updated = session.query(Text).filter_by(content_id=content_id).first()
    assert text_updated.rights_grants[0].status == RightsReleaseStatus.GREEN
    assert text_updated.rights_grants[0].is_legally_approved is True
    assert text_updated.rights_grants[0].legal_reviewer == "Lead Legal Counsel"
