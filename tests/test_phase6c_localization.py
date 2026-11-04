"""
Tests for Phase 6C: Complete Multilingual Localization (Batch 1 & Governance)
Validates:
1. Database reconciliation and archived translations preservation.
2. Human review workflow engine and qualification enforcement.
3. Expanded 28-term multilingual terminology glossary.
4. Audio preparation handoff engine and script/translation separation.
5. Batch 1 localization (Sankata Nashana Ganesha, Madhurashtakam, Surya Ashtakam) across all 9 regional languages.
6. LanguageQualityAssuranceEngine 12-rule verification.
7. Comparative multilingual publication exports (Excel 13-column, Word 12-row, JSON).
"""

from pathlib import Path
import openpyxl
from docx import Document
import pytest
from sqlalchemy.orm import Session

from automation.localization.audio_preparation import AudioPreparationEngine
from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.glossary import SanskritTerminologyGlossary
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.localization.review_workflow import (
    HumanReviewWorkflowEngine,
    TranslationReviewWorkflowError,
)
from database.connection import get_db_session
from database.models import (
    ArchivedTranslation,
    ReviewStatus,
    Text,
    Translation,
    TranslationReviewFeedback,
    TranslationType,
    Verse,
)


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestPhase6CLocalization:
    """Comprehensive test suite for Phase 6C Batch 1 localization and review architecture."""

    BATCH1_TEXTS = [
        ("VEDA-TXT-00012", "Sankata Nashana Ganesha Stotram", 8),
        ("VEDA-TXT-00004", "Madhurashtakam", 9),
        ("VEDA-TXT-00017", "Surya Ashtakam", 10),
    ]

    ALL_NINE_REGIONAL_LANGS = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]

    def test_database_reconciliation_and_archived_records_preserved(self, db_session: Session):
        """Ensures all 580 historical records are safely preserved in archived_translations without loss."""
        archived_count = db_session.query(ArchivedTranslation).count()
        assert archived_count == 580, f"Expected 580 archived records, found {archived_count}"

        # Verify active translations referential integrity
        active_translations = db_session.query(Translation).all()
        verse_ids = set(row[0] for row in db_session.query(Verse.id).all())
        unlinked = [tr for tr in active_translations if tr.verse_id not in verse_ids]
        assert len(unlinked) == 0, f"Found {len(unlinked)} unlinked translations in active table!"

    def test_human_review_workflow_enforces_qualifications(self, db_session: Session):
        """Verifies that translations CANNOT be marked APPROVED without accredited human reviewer credentials."""
        first_trans = db_session.query(Translation).first()
        assert first_trans is not None

        # 1. Attempt approval without credentials -> Must fail
        with pytest.raises(TranslationReviewWorkflowError):
            HumanReviewWorkflowEngine.record_verse_feedback(
                session=db_session,
                translation_id=first_trans.id,
                reviewer_name="Anonymous Tester",
                native_language="hi",
                linguistic_expertise="Hindi",
                review_status=ReviewStatus.APPROVED,
                reviewer_qualification=None,  # Missing qualification
            )

        # 2. Record qualified draft review feedback with suggestion
        feedback = HumanReviewWorkflowEngine.record_verse_feedback(
            session=db_session,
            translation_id=first_trans.id,
            reviewer_name="Dr. Vidwan Sharma",
            reviewer_qualification="PhD in Sanskrit Literature, Rashtriya Sanskrit Sansthan",
            native_language="sa",
            linguistic_expertise="Sanskrit",
            review_status=ReviewStatus.SCHOLAR_REVIEWED,
            scholarly_comment="Bhavartha faithfully captures the devotional sentiment of the traditional bhashya.",
            terminology_adherence_verified=True,
        )
        assert feedback.id is not None
        assert feedback.review_status == ReviewStatus.SCHOLAR_REVIEWED

        # 3. Retrieve feedback history
        history = HumanReviewWorkflowEngine.get_feedback_history(db_session, first_trans.id)
        assert len(history) >= 1
        assert history[-1]["reviewer_name"] == "Dr. Vidwan Sharma"

    def test_glossary_expanded_twenty_eight_terms_all_nine_languages(self):
        """Verifies the Sanskrit terminology glossary contains at least 28 canonical terms across all 9 regional languages."""
        terms = SanskritTerminologyGlossary.get_all_terms()
        assert len(terms) >= 28

        # The foundational 28 terms are human-reviewed
        for term in terms[:28]:
            assert term.is_human_reviewed is True
            for lang_code in self.ALL_NINE_REGIONAL_LANGS:
                assert lang_code in term.translations, f"Term {term.term_id} missing {lang_code}"
                assert len(term.translations[lang_code].strip()) > 0

    def test_audio_preparation_engine_produces_clean_manifests(self, db_session: Session, tmp_path: Path):
        """Verifies audio handoff package preparation and separation of sacred original text from commentary."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00017").first()
        pkg = AudioPreparationEngine.prepare_handoff_package(text)

        assert pkg.content_id == "VEDA-TXT-00017"
        assert len(pkg.cues) == 10
        for cue in pkg.cues:
            assert cue.original_text and len(cue.original_text.strip()) > 0
            assert cue.pause_after_verse_sec > 0
            assert len(cue.pronunciation_notes) >= 1

        # Test manifest export
        manifest_path = AudioPreparationEngine.export_audio_manifest(text)
        assert Path(manifest_path).exists()

    @pytest.mark.parametrize("content_id,expected_title,expected_verses", BATCH1_TEXTS)
    def test_batch1_localization_coverage_and_draft_governance(
        self, db_session: Session, content_id: str, expected_title: str, expected_verses: int
    ):
        """Ensures all 3 Batch 1 texts have draft Bhavartha translations across all 9 regional languages."""
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        assert text is not None
        assert text.canonical_title == expected_title
        assert len(text.verses) == expected_verses

        for v in text.verses:
            trans_by_lang = {
                t.target_language: t
                for t in v.translations
                if t.translation_type == TranslationType.BHAVARTHA
            }

            for lang_code in self.ALL_NINE_REGIONAL_LANGS:
                assert lang_code in trans_by_lang, f"Verse {v.verse_id} missing translation in {lang_code}"
                tr = trans_by_lang[lang_code]
                assert tr.translated_text and len(tr.translated_text.strip()) > 10
                assert tr.review_status == ReviewStatus.DRAFT
                assert "Awaiting Native Scholarly Panel" in tr.translator

    @pytest.mark.parametrize("content_id,expected_title,expected_verses", BATCH1_TEXTS)
    def test_batch1_language_qa_audits_pass(
        self, db_session: Session, content_id: str, expected_title: str, expected_verses: int
    ):
        """Runs LanguageQualityAssuranceEngine on all Batch 1 compositions across all 9 regional languages."""
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        for lang_code in self.ALL_NINE_REGIONAL_LANGS:
            report = LanguageQualityAssuranceEngine.audit_text_language(text, lang_code)
            assert report.passed_all_mandatory is True, (
                f"QA Audit failed for {content_id} in {lang_code}: "
                f"{[c.message for c in report.checks if c.status == QACheckStatus.FAILED]}"
            )
            assert report.total_verses == expected_verses
            assert report.translated_verses == expected_verses
            assert report.failed_checks == 0

    def test_batch1_multilingual_comparative_excel_export(self, db_session: Session, tmp_path: Path):
        """Verifies Batch 1 Excel comparative matrix export with 13 columns."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00004").first()
        out_file = tmp_path / "madhurashtakam_comparative.xlsx"
        res = MultilingualPublicationExporter.export_excel(text, str(out_file))

        wb = openpyxl.load_workbook(res)
        assert "Comparative All-Languages" in wb.sheetnames
        ws = wb["Comparative All-Languages"]
        assert ws.max_column == 13
        assert ws.cell(row=3, column=8).value == "Marathi (मराठी)"
        assert ws.cell(row=3, column=9).value == "Bengali (বাংলা)"
        assert ws.cell(row=3, column=10).value == "Gujarati (ગુજરાતી)"
        assert ws.cell(row=3, column=11).value == "Malayalam (മലയാളം)"
        assert ws.cell(row=3, column=12).value == "Odia (ଓଡ଼ିଆ)"
