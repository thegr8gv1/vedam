"""
Tests for Phase 6A: Multilingual Localization Architecture & Language QA Engine
Validates language registry, terminology glossary, transliteration engine,
pilot translations across Hindi, Telugu, Tamil, and Kannada, QA checks, and exporters.
"""

from pathlib import Path
import json
import pytest
from sqlalchemy.orm import Session

from automation.localization.exporters import MultilingualPublicationExporter
from automation.localization.glossary import SanskritTerminologyGlossary, TerminologyCategory
from automation.localization.qa_framework import LanguageQualityAssuranceEngine, QACheckStatus
from automation.localization.registry import MultilingualRegistry
from automation.localization.transliteration import SpecializedTransliterationEngine, TamilTransliterationMode
from database.connection import get_db_session
from database.models import ReviewStatus, Text, TranslationType


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestMultilingualLocalizationRegistry:
    """Verifies normalized language and script architecture."""

    def test_twenty_two_eighth_schedule_languages(self):
        eighth_sched = MultilingualRegistry.get_eighth_schedule_languages()
        assert len(eighth_sched) == 22, f"Expected exactly 22 languages, found {len(eighth_sched)}"

        # Verify Sanskrit is included
        sanskrit = MultilingualRegistry.get_language("sa")
        assert sanskrit is not None
        assert sanskrit.is_eighth_schedule is True
        assert sanskrit.name == "Sanskrit"

        # Verify English is excluded from Eighth Schedule but present in overall registry
        english = MultilingualRegistry.get_language("en")
        assert english is not None
        assert english.is_eighth_schedule is False

        # Total languages in registry = 23
        assert len(MultilingualRegistry.LANGUAGES) == 23

    def test_scripts_and_font_stacks(self):
        required_scripts = ["Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", "Latn"]
        for s_code in required_scripts:
            s_def = MultilingualRegistry.get_script(s_code)
            assert s_def is not None, f"Script {s_code} not found in registry"
            assert s_def.name
            assert len(s_def.recommended_fonts) >= 1

    def test_multiscript_language_support(self):
        # Sanskrit supports multiple scripts
        sa = MultilingualRegistry.get_language("sa")
        assert "Deva" in sa.supported_scripts
        assert "Telu" in sa.supported_scripts
        assert "Gran" in sa.supported_scripts
        assert "Latn" in sa.supported_scripts


class TestSanskritTerminologyGlossary:
    """Verifies theological and liturgical terminology glossary."""

    def test_glossary_categories_represented(self):
        terms = SanskritTerminologyGlossary.get_all_terms()
        assert len(terms) >= 16

        categories = {t.category for t in terms}
        required_cats = {
            TerminologyCategory.DEITY_NAMES,
            TerminologyCategory.VEDIC_TERMS,
            TerminologyCategory.RITUAL_TERMS,
            TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            TerminologyCategory.GRAMMATICAL_TERMS,
            TerminologyCategory.MANTRA_TERMS,
            TerminologyCategory.PUJA_TERMS,
            TerminologyCategory.CALENDAR_TERMS,
        }
        missing_cats = required_cats - categories
        assert not missing_cats, f"Missing categories: {missing_cats}"

    def test_multilingual_term_lookup(self):
        shiva_term = SanskritTerminologyGlossary.find_term("Śivaḥ")
        assert shiva_term is not None
        assert shiva_term.translations["hi"]
        assert shiva_term.translations["te"]
        assert shiva_term.translations["ta"]
        assert shiva_term.translations["kn"]


class TestSpecializedTransliterationEngine:
    """Verifies multi-script conversion with Grantha and Phonetic Tamil."""

    def test_transliterations_round_trip_and_coverage(self):
        sample_sanskrit = "ॐ नमो भगवते वासुदेवाय ।"

        iast = SpecializedTransliterationEngine.to_iast(sample_sanskrit)
        assert "vāsudevāya" in iast or "vāsudēvāya" in iast

        tel = SpecializedTransliterationEngine.to_telugu(sample_sanskrit)
        assert "వాసుదేవాయ" in tel

        knd = SpecializedTransliterationEngine.to_kannada(sample_sanskrit)
        assert "ವಾಸುದೇವಾಯ" in knd

        mly = SpecializedTransliterationEngine.to_malayalam(sample_sanskrit)
        assert "വാസുദേവായ" in mly

        # Grantha script conversion
        gran = SpecializedTransliterationEngine.to_grantha(sample_sanskrit)
        assert len(gran) > 0

    def test_tamil_transliteration_modes(self):
        sample = "गणेशः"
        std_tam = SpecializedTransliterationEngine.to_tamil(sample, mode=TamilTransliterationMode.STANDARD)
        assert std_tam

        gran_tam = SpecializedTransliterationEngine.to_tamil(sample, mode=TamilTransliterationMode.GRANTHA_EXTENDED)
        assert gran_tam

        phon_tam = SpecializedTransliterationEngine.to_tamil(sample, mode=TamilTransliterationMode.SCHOLARLY_PHONETIC)
        assert phon_tam


class TestPilotMultilingualLocalizationAndQA:
    """Verifies the 5 localized pilot texts and 10-rule Language QA Engine."""

    @pytest.mark.parametrize(
        "content_id,expected_verses",
        [
            ("VEDA-TXT-00006", 1),   # Gayatri Mantra
            ("VEDA-TXT-00005", 1),   # Mahamrityunjaya Mantra
            ("VEDA-TXT-00001", 6),   # Ganesha Pancharatnam
            ("VEDA-TXT-00010", 10),  # Mahalakshmi Ashtakam
            ("VEDA-TXT-00011", 9),   # Lingashtakam
        ],
    )
    def test_pilot_translations_coverage_and_draft_status(
        self, db_session: Session, content_id: str, expected_verses: int
    ):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        assert text is not None
        assert len(text.verses) == expected_verses

        required_languages = ["hi", "te", "ta", "kn"]
        for v in text.verses:
            trans_by_lang = {t.target_language: t for t in v.translations}
            for lang in required_languages:
                assert lang in trans_by_lang, f"{v.verse_id} missing {lang} translation"
                tr = trans_by_lang[lang]
                assert len(tr.translated_text.strip()) > 10
                # Must be strictly marked DRAFT awaiting scholarly review
                assert tr.review_status == ReviewStatus.DRAFT
                assert "Awaiting Native Scholarly Panel" in tr.translator

    @pytest.mark.parametrize(
        "content_id,target_lang",
        [
            ("VEDA-TXT-00001", "hi"),
            ("VEDA-TXT-00001", "te"),
            ("VEDA-TXT-00001", "ta"),
            ("VEDA-TXT-00001", "kn"),
            ("VEDA-TXT-00010", "hi"),
            ("VEDA-TXT-00010", "te"),
        ],
    )
    def test_language_qa_engine_rules(self, db_session: Session, content_id: str, target_lang: str):
        text = db_session.query(Text).filter_by(content_id=content_id).first()
        report = LanguageQualityAssuranceEngine.audit_text_language(text, target_lang)

        assert report.passed_all_mandatory is True
        assert report.failed_checks == 0
        assert report.translated_verses == report.total_verses


class TestMultilingualExporters:
    """Verifies multilingual comparative Excel, Word, and JSON exports."""

    def test_multilingual_export_generation(self, db_session: Session, tmp_path: Path):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()

        # Excel
        xlsx_file = tmp_path / "test_multi.xlsx"
        MultilingualPublicationExporter.export_excel(text, str(xlsx_file))
        assert xlsx_file.exists()

        # Word
        docx_file = tmp_path / "test_multi.docx"
        MultilingualPublicationExporter.export_word(text, str(docx_file))
        assert docx_file.exists()

        # JSON
        json_file = tmp_path / "test_multi.json"
        MultilingualPublicationExporter.export_json(text, str(json_file))
        assert json_file.exists()

        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            assert data["content_id"] == "VEDA-TXT-00001"
            assert len(data["verses"]) == 6
            assert "hi" in data["verses"][0]["translations"]
            assert "te" in data["verses"][0]["translations"]
            assert "ta" in data["verses"][0]["translations"]
            assert "kn" in data["verses"][0]["translations"]
