"""
Unit and Integration Test Suite for Phase 10:
TranslationView Architecture, Controlled Pilot, Scholarly Certification Governance,
and Publication Gate Enforcement.
"""

import json
import os
import sqlite3
import pytest

from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.rights.approval_workflow import RightsClearanceStatus
from automation.validators.publication_gate import PublicationPreflightGate
from automation.workbench.auth import PermissionDeniedError, PermissionGuard
from automation.workbench.gap_analyzer import analyze_752_legacy_gaps
from automation.workbench.translation_workflow import TranslationWorkflowEngine
from database.connection import get_db_session
from database.models import (
    ReleaseStatus,
    ReviewActionLog,
    ReviewStatus,
    ReviewerProfile,
    Text,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)


class TestPhase10TranslationViewAndScholarlyCertification:
    """Test suite covering the 14 required Phase 10 validation dimensions."""

    def test_pre_phase10_baseline_counts_and_reconciliation(self):
        """Verifies canonical baseline: 18 compositions, 307 verses, 3070 translations, 580 archived."""
        with get_db_session() as session:
            canonical_texts = session.query(Text).filter(
                Text.content_id.like("VEDA-TXT-%"),
                ~Text.content_id.in_(["VEDA-TXT-00009", "VEDA-TXT-00099"])
            ).all()
            assert len(canonical_texts) == 18

            total_verses = sum(len(t.verses) for t in canonical_texts)
            assert total_verses == 307

            active_translations = session.query(Translation).count()
            assert active_translations == 3070

    def test_translation_view_tripartite_separation(self):
        """Verifies that the 5 pilot records maintain three distinct segregated views."""
        pilot_tids = [5, 6, 567, 724, 855]
        with get_db_session() as session:
            for tid in pilot_tids:
                views = session.query(TranslationView).filter_by(translation_id=tid).all()
                assert len(views) == 3, f"Translation {tid} must have exactly 3 views, found {len(views)}"
                view_types = {v.view_type for v in views}
                assert view_types == {TranslationType.BHAVARTHA, TranslationType.LITERAL, TranslationType.TATPARYA}

                # Verify distinct texts
                lit = next(v for v in views if v.view_type == TranslationType.LITERAL)
                tat = next(v for v in views if v.view_type == TranslationType.TATPARYA)
                bhav = next(v for v in views if v.view_type == TranslationType.BHAVARTHA)

                assert len(lit.view_text) > 20
                assert len(tat.view_text) > 50
                assert len(bhav.view_text) > 20
                assert lit.view_text != tat.view_text
                assert tat.view_text != bhav.view_text

    def test_original_text_immutability(self):
        """Ensures source Sanskrit verses remain pristine and unchanged after pilot ingestion."""
        with get_db_session() as session:
            # Check Gayatri Mantra (Verse 6)
            v6 = session.query(Verse).filter_by(verse_id="VEDA-TXT-00006-V001").first()
            assert v6 is not None
            assert "तत्स॑वि॒तुर्वरे॑ण्यं॒" in v6.devanagari_text
            assert "भर्गो॑ दे॒वस्य॑ धीमहि" in v6.devanagari_text

            # Check Mahamrityunjaya (Verse 5)
            v5 = session.query(Verse).filter_by(verse_id="VEDA-TXT-00005-V001").first()
            assert v5 is not None
            assert "त्र्य॑म्बकं यजामहे" in v5.devanagari_text

    def test_verse_to_translation_alignment(self):
        """Verifies that each TranslationView accurately maps to its parent translation and verse."""
        with get_db_session() as session:
            pilot_views = session.query(TranslationView).filter(
                TranslationView.translation_id.in_([5, 6, 567, 724, 855])
            ).all()
            for v in pilot_views:
                assert v.translation is not None
                assert v.verse is not None
                assert v.translation.verse_id == v.verse_id
                assert v.target_language == v.translation.target_language

    def test_duplicate_view_prevention(self):
        """Verifies unique constraint uq_translation_view_type_version prevents duplicate views."""
        with get_db_session() as session:
            existing = session.query(TranslationView).filter_by(
                translation_id=5, view_type=TranslationType.LITERAL, version=1
            ).first()
            assert existing is not None

            # Attempt duplicate insert
            dup_view = TranslationView(
                view_id="VIEW-TR-00005-LITERAL-DUP",
                translation_id=5,
                verse_id=existing.verse_id,
                target_language="en",
                view_type=TranslationType.LITERAL,
                view_text="Duplicate text",
                version=1,
            )
            session.add(dup_view)
            with pytest.raises(Exception):
                session.commit()
            session.rollback()

    def test_source_reference_validity(self):
        """Verifies that pilot views cite verified traditional commentaries."""
        with get_db_session() as session:
            tat_views = session.query(TranslationView).filter(
                TranslationView.translation_id.in_([5, 6, 567, 724, 855]),
                TranslationView.view_type == TranslationType.TATPARYA
            ).all()
            assert len(tat_views) == 5
            for v in tat_views:
                ref = v.source_reference
                assert ref is not None
                assert any(trad in ref for trad in ["Sayana", "Bhatta Bhaskara", "Vidyaranya", "Mahidhara"])

    def test_translation_version_history(self):
        """Verifies version numbering and audit history integrity."""
        with get_db_session() as session:
            views = session.query(TranslationView).filter(
                TranslationView.translation_id.in_([5, 6, 567, 724, 855]),
                TranslationView.view_type.in_([TranslationType.LITERAL, TranslationType.TATPARYA])
            ).all()
            for v in views:
                assert v.version == 1
                assert v.approval_history_json is not None
                history = json.loads(v.approval_history_json) if isinstance(v.approval_history_json, str) else v.approval_history_json
                assert len(history) >= 1
                assert history[0]["action"] == "PILOT_INGESTION_SUGGESTION"

    def test_reviewer_provenance_and_zero_fabrication(self):
        """Verifies zero living human scholars onboarded and proper categorization."""
        with get_db_session() as session:
            real_humans = session.query(ReviewerProfile).filter_by(
                account_category="REAL_HUMAN_SCHOLAR", is_human_verified=True
            ).all()
            assert len(real_humans) == 0, "Zero living human scholars should be onboarded without authorization"

            # Check pilot views have no fabricated human reviewer
            pilot_views = session.query(TranslationView).filter(
                TranslationView.translation_id.in_([5, 6, 567, 724, 855]),
                TranslationView.view_type.in_([TranslationType.LITERAL, TranslationType.TATPARYA])
            ).all()
            for v in pilot_views:
                assert v.reviewer is None
                assert v.reviewer_affiliation is None
                assert v.reviewed_at is None
                assert v.review_status == ReviewStatus.DRAFT

    def test_ai_suggestion_only_flagging(self):
        """Verifies that all pilot provenance records enforce is_suggestion_only=True."""
        prov_file = "exports/reports/phase10_pilot_provenance_and_references.json"
        assert os.path.exists(prov_file)
        with open(prov_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        assert data["total_views_generated"] == 10
        assert data["total_records_processed"] == 5
        for item in data["provenance_ledger"]:
            assert item["is_suggestion_only"] is True
            assert item["review_status"] == "DRAFT"

    def test_review_authorization_and_permission_guard(self):
        """Verifies that non-human accounts cannot certify translation views."""
        with get_db_session() as session:
            synthetic_reviewer = session.query(ReviewerProfile).filter_by(
                reviewer_id="REV-PROD-VEDIC"
            ).first()
            assert synthetic_reviewer is not None
            assert synthetic_reviewer.account_category == "SYNTHETIC_TEST_PERSONA"

            # Test permission guard
            with pytest.raises((PermissionDeniedError, PermissionError)):
                PermissionGuard.require_human_scholar(synthetic_reviewer)

            # Test TranslationWorkflowEngine gate
            view = session.query(TranslationView).first()
            with pytest.raises(PermissionError):
                TranslationWorkflowEngine.enforce_scholarly_gate(view, synthetic_reviewer)

    def test_publication_gate_enforcement(self):
        """Verifies PublicationPreflightGate blocks commercial release for unapproved views."""
        with get_db_session() as session:
            text = session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()
            # Commercial channel must fail due to unapproved draft translations (Rule PUB-010)
            res_comm = PublicationPreflightGate.evaluate(text, target_channel="commercial_release")
            assert not res_comm.can_publish
            failed_rules = [c.rule_id for c in res_comm.checks if not c.passed]
            assert "PUB-010" in failed_rules

            # Scholarly review channel passes for internal peer evaluation
            res_review = PublicationPreflightGate.evaluate(text, target_channel="scholarly_review")
            assert res_review.can_publish

    def test_rights_separation_orthogonality(self):
        """Verifies legal clearance is independent from scholarly certification."""
        with get_db_session() as session:
            text = session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()
            assert text.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED
            # Even though rights are GREEN_CLEARED, translations remain DRAFT
            for tr in text.verses[0].translations:
                assert tr.review_status == ReviewStatus.DRAFT

    def test_unicode_integrity_in_views(self):
        """Verifies that Indic characters, Vedic swaras, and diacritics are preserved intact."""
        with get_db_session() as session:
            v724 = session.query(TranslationView).filter_by(
                view_id="VIEW-TR-00724-LITERAL-v1"
            ).first()
            assert v724 is not None
            assert "puruṣaḥ" in v724.view_text
            assert "sahasra-śīrṣā" in v724.view_text

    def test_export_completeness_and_draft_disclaimer(self):
        """Verifies that JSON, Excel, and Word pilot exports exist and feature DRAFT disclaimers."""
        json_path = "exports/phase10_pilot/phase10_pilot_five_records_bundle.json"
        excel_path = "exports/phase10_pilot/phase10_pilot_five_records_export.xlsx"
        word_path = "exports/phase10_pilot/phase10_pilot_five_records_manuscript.docx"

        assert os.path.exists(json_path)
        assert os.path.exists(excel_path)
        assert os.path.exists(word_path)

        with open(json_path, "r", encoding="utf-8") as f:
            jdata = json.load(f)
        assert len(jdata["records"]) == 5
        assert "DRAFT" in jdata["export_metadata"]["governance_alert"]

    def test_analytics_accuracy_and_gap_reduction(self):
        """Verifies analytics report total views as 7716 and remaining gap as 747."""
        with get_db_session() as session:
            metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(session)
            assert metrics.translation_views_total == 7716
            assert metrics.number_of_devotional_bhavarthas == 3070
            assert metrics.number_of_literal_translations == 2323
            assert metrics.number_of_traditional_meanings == 2323
            assert metrics.translation_view_gaps_count == 747
            assert metrics.missing_translation_views == 747
            assert metrics.real_human_scholars_count == 0
            assert metrics.scholar_approved_translations == 0

    def test_workflow_engine_7_dimensions(self):
        """Verifies that TranslationWorkflowEngine returns all 7 workflow dimensions."""
        with get_db_session() as session:
            ctx = TranslationWorkflowEngine.get_translation_view_workflow_context(
                session, translation_id=5, view_type="LITERAL"
            )
            for i in range(1, 8):
                key = f"dimension_{i}_"
                matching = [k for k in ctx.keys() if k.startswith(key)]
                assert len(matching) == 1, f"Missing dimension {i} in workflow context"
