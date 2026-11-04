"""
Tests for Phase 4C: Professional Publication Exporters
Validates 11-sheet Excel workbooks, Word manuscripts, and Indic searchable PDF exports.
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
from database.connection import get_db_session
from database.models import Text


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestPublicationEngine:
    """Verifies professional publication export engines across Excel, Word, and PDF."""

    def test_excel_11_sheets_structure_and_styling(self, db_session: Session, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        out_path = tmp_path / "test_ganesha.xlsx"
        ExcelPublicationExporter.export_publication_workbook(text, str(out_path))

        assert out_path.exists()
        wb = openpyxl.load_workbook(str(out_path))
        expected_sheets = [
            "Overview & Metadata",
            "Original Sanskrit",
            "Verse Breakdown",
            "IAST Transliteration",
            "Regional Scripts",
            "Padachheda & Word Analysis",
            "Translations & Bhavartha",
            "Recensions & Variants",
            "Scholarly References",
            "Rights & Permissions",
            "Verification & QA Audit History",
        ]
        assert len(wb.sheetnames) == 11
        for s in expected_sheets:
            assert s in wb.sheetnames, f"Missing sheet: {s}"

        # Check Overview sheet content
        ws_overview = wb["Overview & Metadata"]
        assert "॥ गणेशपञ्चरत्नम् ॥" in ws_overview["A1"].value

        # Check Regional scripts sheet content
        ws_regional = wb["Regional Scripts"]
        assert ws_regional.max_row >= 7  # header + 6 verses

    def test_word_manuscript_generation(self, db_session: Session, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        out_path = tmp_path / "test_ganesha.docx"
        WordPublicationExporter.export_publication_manuscript(text, str(out_path))

        assert out_path.exists()
        doc = Document(str(out_path))

        # Check title page elements
        full_text = "\n".join([p.text for p in doc.paragraphs])
        assert "॥ ॐ श्रीपरमात्मने नमः ॥" in full_text
        assert "Ganesha Pancharatnam" in full_text
        assert "Mudakaratta Modakam" in full_text or "मुदाकरात्तमोदकं" in full_text
        assert "Colophon & Provenance Verification" in full_text

        # Check sections (cover page + body section with header/footer)
        assert len(doc.sections) >= 2
        header_text = doc.sections[1].header.paragraphs[0].text
        assert "Ganesha Pancharatnam" in header_text

    def test_pdf_publication_generation_and_searchability(self, db_session: Session, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        out_path = tmp_path / "test_ganesha.pdf"
        PDFPublicationExporter.export_publication_pdf(text, str(out_path))

        assert out_path.exists()
        doc = fitz.open(str(out_path))
        assert doc.page_count >= 2

        # Extract text from page 1 and page 2
        page1_text = doc[0].get_text()
        page2_text = doc[1].get_text()

        assert "Ganesha Pancharatnam" in page1_text
        assert "॥ गणेशपञ्चरत्नम् ॥" in page1_text
        assert "Adi Shankaracharya" in page1_text

        # Verify Indic searchability in PyMuPDF
        search_results = doc[1].search_for("मुदाकरात्तमोदकं")
        assert len(search_results) > 0, "Indic Devanagari text should be searchable in PDF."

    def test_publication_for_awadhi_hanuman_chalisa(self, db_session: Session, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00008").first()
        out_path = tmp_path / "test_hanuman.pdf"
        PDFPublicationExporter.export_publication_pdf(text, str(out_path))

        assert out_path.exists()
        doc = fitz.open(str(out_path))
        assert doc.page_count >= 3

        # Check that Dohas and Chaupais are present and searchable
        all_text = ""
        for page in doc:
            all_text += page.get_text()

        assert "जय हनुमान ज्ञान गुन सागर" in all_text
        assert "पवनतनय संकट हरन" in all_text
