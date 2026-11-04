"""
Tests for Expansion Batch 2 (Phase 5)
Validates ingestion, textual authenticity, verse structure, Vedic swaras,
multi-script transliteration, translation provenance, rights clearance, and multi-format publication for:
- VEDA-TXT-00013: Sri Venkateswara Suprabhatam (29 verses)
- VEDA-TXT-00014: Purusha Suktam (16 verses with Vedic swaras)
- VEDA-TXT-00015: Durga Suktam (7 verses with Vedic swaras)
"""

from pathlib import Path
import fitz
from docx import Document
import openpyxl
import pytest
from sqlalchemy.orm import Session

from automation.exporters.excel_publication_exporter import ExcelPublicationExporter
from automation.exporters.pdf_publication_exporter import PDFPublicationExporter
from automation.exporters.word_publication_exporter import WordPublicationExporter
from automation.rights.approval_workflow import (
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.validators.publication_gate import PublicationPreflightGate
from database.connection import get_db_session
from database.models import ReviewStatus, Text, VerseType


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestExpansionBatch2:
    """Verifies all Phase 5 Batch 2 texts across data models, QA gates, and publication exporters."""

    @pytest.mark.parametrize(
        "content_id,expected_title,expected_verse_count,has_swaras",
        [
            ("VEDA-TXT-00013", "Venkateswara Suprabhatam", 29, False),
            ("VEDA-TXT-00014", "Purusha Suktam", 16, True),
            ("VEDA-TXT-00015", "Durga Suktam", 7, True),
        ],
    )
    def test_text_metadata_and_verse_structure(
        self, db_session: Session, content_id: str, expected_title: str, expected_verse_count: int, has_swaras: bool
    ):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        assert text is not None, f"Text {content_id} not found in database"
        assert text.canonical_title == expected_title
        assert text.verse_count == expected_verse_count
        assert len(text.verses) == expected_verse_count

        # Check verse sequence continuity
        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)
        numbers = [v.verse_number for v in sorted_verses]
        assert numbers == list(range(1, expected_verse_count + 1)), "Verse numbers are not continuous 1..N"

        # Check Vedic accents if applicable
        if has_swaras:
            swara_verses = [v for v in sorted_verses if v.vedic_accents_present]
            assert len(swara_verses) == expected_verse_count, f"Expected all {expected_verse_count} verses to have swaras"

        # Check approvals
        assert text.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED
        assert text.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED
        assert text.translation_status == TranslationStatus.DRAFT
        assert text.editorial_approval_status == EditorialApprovalStatus.APPROVED
        assert text.publication_status == PublicationStatus.READY_FOR_EXPORT

    @pytest.mark.parametrize("content_id", ["VEDA-TXT-00013", "VEDA-TXT-00014", "VEDA-TXT-00015"])
    def test_multiscript_transliterations_complete(self, db_session: Session, content_id: str):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        required_scripts = {"telugu", "tamil", "kannada", "malayalam", "iast"}

        for verse in text.verses:
            present_scripts = {t.target_script for t in verse.transliterations}
            missing = required_scripts - present_scripts
            assert not missing, f"{verse.verse_id} is missing transliterations for: {missing}"
            for t in verse.transliterations:
                assert t.script_text and len(t.script_text.strip()) > 5
            assert verse.iast_text and len(verse.iast_text.strip()) > 5

    @pytest.mark.parametrize("content_id", ["VEDA-TXT-00013", "VEDA-TXT-00014", "VEDA-TXT-00015"])
    def test_translation_provenance_and_draft_status(self, db_session: Session, content_id: str):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        for verse in text.verses:
            assert len(verse.translations) >= 1, f"{verse.verse_id} has no translations"
            en_trans = [t for t in verse.translations if t.target_language == "en"][0]
            assert en_trans.translated_text and len(en_trans.translated_text.strip()) > 10
            assert en_trans.review_status == ReviewStatus.DRAFT
            assert "Awaiting Scholarly Panel" in en_trans.translator

    @pytest.mark.parametrize("content_id", ["VEDA-TXT-00013", "VEDA-TXT-00014", "VEDA-TXT-00015"])
    def test_preflight_publication_gate(self, db_session: Session, content_id: str):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        report = PublicationPreflightGate.evaluate(text, target_channel="scholarly_review")
        assert report.can_publish, f"Gate blocked publication: {[c.message for c in report.checks if not c.passed]}"
        assert report.failed_blockers == 0

    @pytest.mark.parametrize("content_id", ["VEDA-TXT-00013", "VEDA-TXT-00014", "VEDA-TXT-00015"])
    def test_publication_exports_validation(self, db_session: Session, content_id: str, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id=content_id).first()

        # 1. Excel 11 Sheets
        xlsx_file = tmp_path / f"{content_id}.xlsx"
        ExcelPublicationExporter.export_publication_workbook(text, str(xlsx_file), enforce_gates=False)
        assert xlsx_file.exists()
        wb = openpyxl.load_workbook(str(xlsx_file))
        assert len(wb.sheetnames) == 11
        assert "Overview & Metadata" in wb.sheetnames
        assert "Original Sanskrit" in wb.sheetnames
        assert "IAST Transliteration" in wb.sheetnames

        # 2. Word Manuscript
        docx_file = tmp_path / f"{content_id}.docx"
        WordPublicationExporter.export_publication_manuscript(text, str(docx_file), enforce_gates=False)
        assert docx_file.exists()
        doc = Document(str(docx_file))
        assert any(p.text and text.canonical_title in p.text for p in doc.paragraphs)

        # 3. PDF
        pdf_file = tmp_path / f"{content_id}.pdf"
        PDFPublicationExporter.export_publication_pdf(text, str(pdf_file), enforce_gates=False)
        assert pdf_file.exists()
        doc_pdf = fitz.open(str(pdf_file))
        assert doc_pdf.page_count >= 1
        pdf_text = "".join(page.get_text() for page in doc_pdf)
        assert text.canonical_title in pdf_text
