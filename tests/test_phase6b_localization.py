"""
Tests for Phase 6B Multilingual Expansion
Validates 5 additional Indian languages:
- Marathi (mr)
- Bengali (bn)
- Gujarati (gu)
- Malayalam (ml)
- Odia (or)

Tests cover:
- 135 new Bhavartha translation records across 5 pilot texts
- Strict ReviewStatus.DRAFT tagging and translator attribution
- LanguageQualityAssuranceEngine 10-rule verification
- Glossary multilingual consistency across all 20 canonical spiritual terms
- OpenType Indic font configuration for all 9 scripts
- Comparative publication exports in Excel, Word, and JSON
"""

import json
from pathlib import Path
from docx import Document
import openpyxl
import pytest
from sqlalchemy.orm import Session

from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.glossary import SanskritTerminologyGlossary
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.localization.registry import MultilingualRegistry
from database.connection import get_db_session
from database.models import ReviewStatus, Text, Translation, TranslationType


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestPhase6BLocalization:
    """Verifies Phase 6B multilingual expansion across registry, glossary, DB records, QA engine, and exports."""

    PILOT_TEXT_IDS = [
        ("VEDA-TXT-00006", 1),   # Gayatri Mantra
        ("VEDA-TXT-00005", 1),   # Mahamrityunjaya Mantra
        ("VEDA-TXT-00001", 6),   # Ganesha Pancharatnam
        ("VEDA-TXT-00010", 10),  # Mahalakshmi Ashtakam
        ("VEDA-TXT-00011", 9),   # Lingashtakam
    ]

    NEW_LANG_CODES = ["mr", "bn", "gu", "ml", "or"]
    ALL_REGIONAL_LANGS = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]

    def test_registry_contains_all_target_languages_and_scripts(self):
        """Ensures all 5 Phase 6B languages and their scripts are properly defined in MultilingualRegistry."""
        for lang_code in self.NEW_LANG_CODES:
            lang_def = MultilingualRegistry.get_language(lang_code)
            assert lang_def is not None, f"Language {lang_code} not found in registry"
            assert lang_def.is_eighth_schedule is True
            assert lang_def.primary_script is not None

            script_def = MultilingualRegistry.get_script(lang_def.primary_script)
            assert script_def is not None, f"Script {lang_def.primary_script} not found in registry"
            assert len(script_def.recommended_fonts) > 0

    def test_glossary_covers_all_twenty_terms_across_all_nine_languages(self):
        """Ensures the 20 canonical spiritual terms have verified translations in all 9 Indian languages."""
        terms = SanskritTerminologyGlossary.get_all_terms()
        assert len(terms) == 20

        for term in terms:
            for lang_code in self.ALL_REGIONAL_LANGS:
                assert lang_code in term.translations, f"Term {term.term_id} missing translation for {lang_code}"
                val = term.translations[lang_code]
                assert val and len(val.strip()) > 0

    @pytest.mark.parametrize("content_id,expected_verses", PILOT_TEXT_IDS)
    def test_phase6b_database_translations_presence_and_governance(
        self, db_session: Session, content_id: str, expected_verses: int
    ):
        """Verifies that all 5 new languages have draft Bhavartha translations on every verse of the 5 pilot compositions."""
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        assert text is not None, f"Text {content_id} not found"
        assert len(text.verses) == expected_verses

        for v in text.verses:
            trans_by_lang = {
                t.target_language: t
                for t in v.translations
                if t.translation_type == TranslationType.BHAVARTHA
            }

            for lang_code in self.NEW_LANG_CODES:
                assert lang_code in trans_by_lang, f"Verse {v.verse_id} missing Bhavartha for {lang_code}"
                tr = trans_by_lang[lang_code]
                assert tr.translated_text and len(tr.translated_text.strip()) > 10
                # Strict governance assertion: MUST be ReviewStatus.DRAFT
                assert tr.review_status == ReviewStatus.DRAFT
                assert "Awaiting Native Scholarly Panel" in tr.translator
                # Cannot have reviewer credentials while in DRAFT
                assert tr.reviewer is None

    @pytest.mark.parametrize("content_id,expected_verses", PILOT_TEXT_IDS)
    def test_language_qa_engine_audit_passes_all_checks(
        self, db_session: Session, content_id: str, expected_verses: int
    ):
        """Runs the 10-rule LanguageQualityAssuranceEngine on each pilot text across all 5 new languages."""
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        for lang_code in self.NEW_LANG_CODES:
            report = LanguageQualityAssuranceEngine.audit_text_language(text, lang_code)
            assert report.passed_all_mandatory, (
                f"QA Audit failed for {content_id} in {lang_code}: "
                f"{[c.message for c in report.checks if c.status == QACheckStatus.FAILED]}"
            )
            assert report.total_verses == expected_verses
            assert report.translated_verses == expected_verses
            assert report.failed_checks == 0

    def test_multilingual_comparative_excel_export(self, db_session: Session, tmp_path: Path):
        """Verifies Excel comparative matrix exports with all 13 columns (Verse, Sanskrit, IAST, 9 Indian languages, English)."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        out_file = tmp_path / "ganesha_pancharatnam_10lang.xlsx"

        res = MultilingualPublicationExporter.export_excel(text, str(out_file))
        assert Path(res).exists()

        wb = openpyxl.load_workbook(res)
        assert "Comparative All-Languages" in wb.sheetnames
        ws = wb["Comparative All-Languages"]
        # Row 3 is headers: 13 columns
        assert ws.max_column == 13
        header_vals = [ws.cell(row=3, column=c).value for c in range(1, 14)]
        assert "Verse #" in header_vals[0]
        assert "Original Sanskrit" in header_vals[1]
        assert "IAST (Roman)" in header_vals[2]
        assert "Marathi (मराठी)" in header_vals[7]
        assert "Bengali (বাংলা)" in header_vals[8]
        assert "Gujarati (ગુજરાતી)" in header_vals[9]
        assert "Malayalam (മലയാളം)" in header_vals[10]
        assert "Odia (ଓଡ଼ିଆ)" in header_vals[11]
        assert "English (Bhavartha)" in header_vals[12]

    def test_multilingual_manuscript_word_export(self, db_session: Session, tmp_path: Path):
        """Verifies Word manuscript comparative export with 12 rendering rows per verse."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()
        out_file = tmp_path / "gayatri_10lang.docx"

        res = MultilingualPublicationExporter.export_word(text, str(out_file))
        assert Path(res).exists()

        doc = Document(res)
        assert len(doc.tables) >= 1
        tbl = doc.tables[0]
        # 12 rows: Sanskrit, IAST, Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Gujarati, Malayalam, Odia, English
        assert len(tbl.rows) == 12

    def test_multilingual_json_export(self, db_session: Session, tmp_path: Path):
        """Verifies JSON comparative export contains all 11 supported languages."""
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
        out_file = tmp_path / "mahamrityunjaya_10lang.json"

        res = MultilingualPublicationExporter.export_json(text, str(out_file))
        assert Path(res).exists()

        with open(res, "r", encoding="utf-8") as f:
            data = json.load(f)

        assert data["content_id"] == "VEDA-TXT-00005"
        assert set(data["supported_languages"]) == {"sa", "hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or", "en"}
        verse1_trans = data["verses"][0]["translations"]
        for lang in ["mr", "bn", "gu", "ml", "or"]:
            assert lang in verse1_trans
            assert verse1_trans[lang]["review_status"] == "DRAFT"
