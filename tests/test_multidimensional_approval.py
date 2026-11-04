"""
Tests for Phase 4D: Multidimensional Approval Workflow & Publication Gate
Validates orthogonal decoupling of 6 approval dimensions and strict pre-flight gatekeeper.
"""

import pytest
from sqlalchemy.orm import Session

from automation.rights.approval_workflow import (
    AcquisitionStatus,
    ApprovalWorkflowEngine,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.validators.publication_gate import GateSeverity, PublicationPreflightGate
from database.connection import get_db_session
from database.models import Text


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestMultidimensionalApprovalWorkflow:
    """Verifies that all 6 approval dimensions are decoupled and publication gate operates strictly."""

    def test_all_eight_pilots_ready_for_publication(self, db_session: Session):
        pilot_ids = [
            "VEDA-TXT-00001", "VEDA-TXT-00002", "VEDA-TXT-00003", "VEDA-TXT-00004",
            "VEDA-TXT-00005", "VEDA-TXT-00006", "VEDA-TXT-00007", "VEDA-TXT-00008",
        ]
        for cid in pilot_ids:
            t = db_session.query(Text).filter_by(content_id=cid).first()
            assert t.acquisition_status == AcquisitionStatus.VERIFIED_SOURCE
            assert t.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED
            assert t.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED
            assert t.translation_status == TranslationStatus.APPROVED
            assert t.editorial_approval_status == EditorialApprovalStatus.APPROVED
            assert t.publication_status == PublicationStatus.READY_FOR_EXPORT

            # Verify workflow engine transition logic
            can_publish, blocking = ApprovalWorkflowEngine.can_transition_to_publication(t)
            assert can_publish is True, f"Failed for {cid}: {blocking}"
            assert len(blocking) == 0

            # Verify preflight publication gate
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is True
            assert report.failed_blockers == 0
            assert report.passed_checks == 15

    def test_gate_blocks_on_unapproved_rights(self, db_session: Session):
        """Simulate an unapproved rights state and verify publication gate raises PermissionError."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()

        # Temporarily mock rights_clearance_status to PENDING
        original_status = t.rights_clearance_status
        try:
            t.rights_clearance_status = RightsClearanceStatus.PENDING
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is False
            assert report.failed_blockers > 0
            failed_names = [c.rule_name for c in report.checks if not c.passed and c.severity == GateSeverity.BLOCKER]
            assert "RIGHTS_CLEARANCE_STATUS_CHECK" in failed_names

            with pytest.raises(PermissionError) as exc_info:
                PublicationPreflightGate.assert_can_publish(t)
            assert "RIGHTS_CLEARANCE_STATUS_CHECK" in str(exc_info.value)
        finally:
            t.rights_clearance_status = original_status

    def test_gate_blocks_on_missing_editorial_approval(self, db_session: Session):
        """Simulate pending editorial status and verify gate blocks export."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00002").first()

        original_editorial = t.editorial_approval_status
        try:
            t.editorial_approval_status = EditorialApprovalStatus.IN_REVIEW
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is False
            failed_names = [c.rule_name for c in report.checks if not c.passed and c.severity == GateSeverity.BLOCKER]
            assert "EDITORIAL_APPROVAL_CHECK" in failed_names

            with pytest.raises(PermissionError):
                PublicationPreflightGate.assert_can_publish(t)
        finally:
            t.editorial_approval_status = original_editorial

    def test_gate_blocks_on_missing_or_broken_verse_sequence(self, db_session: Session):
        """Simulate broken verse sequence and verify gate blocks."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00004").first()

        original_count = t.verse_count
        try:
            t.verse_count = 999  # Mismatch with actual verses
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is False
            failed_names = [c.rule_name for c in report.checks if not c.passed]
            assert "VERSE_COUNT_MATCH_CHECK" in failed_names
        finally:
            t.verse_count = original_count

    def test_gate_blocks_on_missing_critical_edition(self, db_session: Session):
        """Simulate missing critical edition and verify gate blocks."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        saved_editions = list(t.source_editions)
        try:
            t.source_editions = []
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is False
            failed_names = [c.rule_name for c in report.checks if not c.passed and c.severity == GateSeverity.BLOCKER]
            assert "CRITICAL_EDITION_CHECK" in failed_names
        finally:
            t.source_editions = saved_editions

    def test_gate_blocks_on_missing_titles(self, db_session: Session):
        """Simulate missing devanagari title and verify gate blocks."""
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00003").first()
        saved_title = t.devanagari_title
        try:
            t.devanagari_title = ""
            report = PublicationPreflightGate.evaluate(t)
            assert report.can_publish is False
            failed_names = [c.rule_name for c in report.checks if not c.passed and c.severity == GateSeverity.BLOCKER]
            assert "TITLE_CHECK" in failed_names
        finally:
            t.devanagari_title = saved_title
