"""
Vedic Heritage Platform — Phase 11A Multilingual Infrastructure Test Suite
Validates:
1. Authoritative 22 Eighth Schedule Indian Languages inventory (+ English global bridge).
2. ISO 639-1, ISO 639-3, and BCP 47 language metadata consistency.
3. ISO 15924 script definitions, OpenType shaping requirements, and text direction.
4. Vedic swara preservation and Unicode NFC normalization guardrails.
5. Database schema compatibility (VARCHAR(16) language tags, VARCHAR(32) script tags).
6. Operational test database isolation and zero production mutation.
"""

import unicodedata
import pytest
from sqlalchemy import inspect
from sqlalchemy.orm import Session

from automation.cleaners.unicode_preserver import UnicodePreserver, VedicSwara
from automation.database.safety import assert_not_production_database, get_canonical_production_db_path, is_production_database
from automation.localization.registry import LanguageFamily, MultilingualRegistry
from database.connection import get_active_database_url, get_db_session
from database.models import Text, Translation, TranslationView, Transliteration, Verse


class TestAuthoritativeLanguageInventory:
    """Group 1: Validates the 22 Eighth Schedule languages + English global bridge."""

    def test_exact_twenty_two_eighth_schedule_languages(self):
        """Ensures exactly 22 languages are designated as Eighth Schedule (Sanskrit included once)."""
        eighth_schedule = MultilingualRegistry.get_eighth_schedule_languages()
        assert len(eighth_schedule) == 22, f"Expected exactly 22 languages, got {len(eighth_schedule)}"

        # Verify Sanskrit is included exactly once
        sanskrit_entries = [l for l in eighth_schedule if l.iso_639_1 == "sa"]
        assert len(sanskrit_entries) == 1
        assert sanskrit_entries[0].name == "Sanskrit"
        assert sanskrit_entries[0].iso_639_3 == "san"
        assert sanskrit_entries[0].is_eighth_schedule is True

    def test_total_registry_languages_is_twenty_three(self):
        """Ensures the canonical platform registry contains exactly 23 languages (22 Scheduled + English)."""
        all_langs = MultilingualRegistry.LANGUAGES
        assert len(all_langs) == 23
        assert "en" in all_langs
        assert all_langs["en"].is_eighth_schedule is False
        assert all_langs["en"].family == LanguageFamily.GERMANIC

    def test_bcp47_tags_and_iso_codes_integrity(self):
        """Verifies that all 23 languages possess valid ISO 639-1, ISO 639-3, and BCP 47 tags."""
        for code, lang in MultilingualRegistry.LANGUAGES.items():
            assert lang.iso_639_1, f"Missing ISO 639-1 for {code}"
            assert lang.iso_639_3, f"Missing ISO 639-3 for {code}"
            assert len(lang.iso_639_3) == 3, f"Invalid ISO 639-3 length for {code}: {lang.iso_639_3}"
            assert lang.bcp47, f"Missing BCP 47 for {code}"
            assert lang.primary_script in MultilingualRegistry.SCRIPTS, f"Unknown primary script {lang.primary_script} for {code}"

    def test_active_nine_regional_pilot_languages_present(self):
        """Verifies that the 9 operational pilot regional languages are properly registered."""
        operational_codes = ["hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or"]
        for code in operational_codes:
            lang = MultilingualRegistry.get_language(code)
            assert lang is not None, f"Operational language '{code}' missing from registry!"
            assert lang.is_eighth_schedule is True

    def test_expansion_thirteen_scheduled_languages_present(self):
        """Verifies that all 13 planned expansion languages are properly registered."""
        expansion_codes = ["sa", "as", "pa", "mai", "ne", "kok", "doi", "brx", "sat", "ks", "sd", "mni", "ur"]
        for code in expansion_codes:
            lang = MultilingualRegistry.get_language(code)
            assert lang is not None, f"Expansion language '{code}' missing from registry!"
            assert lang.is_eighth_schedule is True


class TestScriptDefinitionsAndDirectionality:
    """Group 2: Validates script definitions, font requirements, and RTL direction."""

    def test_script_registry_definitions(self):
        """Verifies ISO 15924 scripts registered in the platform."""
        expected_scripts = [
            "Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", 
            "Beng", "Gujr", "Guru", "Orya", "Olck", "Arab", "Mtei", "Latn"
        ]
        for s_code in expected_scripts:
            script = MultilingualRegistry.get_script(s_code)
            assert script is not None, f"Script {s_code} missing from SCRIPTS registry"
            assert script.iso_15924 == s_code
            assert script.name
            assert script.native_name

    def test_perso_arabic_rtl_direction(self):
        """Verifies that Arabic script for Urdu, Kashmiri, and Sindhi is marked RTL."""
        arab = MultilingualRegistry.get_script("Arab")
        assert arab is not None
        assert arab.direction == "rtl"

        # All Indic and Latin scripts must be LTR
        for s_code in ["Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", "Beng", "Gujr", "Guru", "Orya", "Olck", "Mtei", "Latn"]:
            s = MultilingualRegistry.get_script(s_code)
            assert s.direction == "ltr", f"Script {s_code} expected LTR, got {s.direction}"

    def test_vedic_swara_supporting_scripts(self):
        """Verifies which scripts are accredited for Vedic liturgical accents."""
        swara_scripts = ["Deva", "Telu", "Gran", "Knda", "Mlym"]
        for s_code in swara_scripts:
            s = MultilingualRegistry.get_script(s_code)
            assert s.supports_vedic_swaras is True, f"Script {s_code} should support Vedic swaras"

        non_swara_scripts = ["Taml", "Beng", "Gujr", "Guru", "Orya", "Arab", "Olck", "Mtei"]
        for s_code in non_swara_scripts:
            s = MultilingualRegistry.get_script(s_code)
            assert s.supports_vedic_swaras is False, f"Script {s_code} should not support Vedic swaras"


class TestUnicodeNormalizationAndVedicPreservation:
    """Group 3: Validates Unicode normalization and swara diacritic protection."""

    def test_vedic_swara_code_points_preserved_in_nfc(self):
        """Verifies that combining accents remain intact through NFC normalization."""
        # Rigveda 7.59.12 sample: tryambakaṃ yajāmahe sugandhiṃ puṣṭivardhanam
        sample_devanagari = "त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम्"
        
        # Verify accents present
        assert VedicSwara.SVARITA in sample_devanagari
        assert VedicSwara.ANUDATTA in sample_devanagari

        normalized = unicodedata.normalize("NFC", sample_devanagari)
        assert VedicSwara.SVARITA in normalized
        assert VedicSwara.ANUDATTA in normalized
        assert normalized == sample_devanagari

    def test_unicode_preserver_cleans_without_stripping_swaras(self):
        """Ensures UnicodePreserver.clean_text_preserving_accents preserves sacred swaras."""
        sample_text = "  ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।  "
        cleaned = UnicodePreserver.clean_text_preserving_accents(sample_text)
        assert cleaned.startswith("ॐ")
        assert VedicSwara.SVARITA in cleaned
        assert VedicSwara.ANUDATTA in cleaned


class TestDatabaseSchemaCompatibility:
    """Group 4: Validates database column capacities and constraints for 22 languages."""

    def test_target_language_column_length_sufficient(self):
        """
        Validates that Translation and TranslationView target_language columns
        have VARCHAR(16) length, which safely stores all ISO 639-1, 639-3, and BCP 47 tags.
        """
        for model in [Translation, TranslationView]:
            col = model.__table__.columns["target_language"]
            assert col.type.length >= 16, f"{model.__name__}.target_language column too short ({col.type.length})"

        # Check maximum BCP 47 tag length in registry
        max_bcp47_len = max(len(l.bcp47) for l in MultilingualRegistry.LANGUAGES.values())
        assert max_bcp47_len <= 16, f"BCP 47 tag exceeds 16 chars: {max_bcp47_len}"

    def test_target_script_column_length_sufficient(self):
        """Validates that Transliteration target_script column accommodates script tags."""
        col = Transliteration.__table__.columns["target_script"]
        assert col.type.length >= 16

    def test_isolated_database_session_active(self):
        """Verifies that test execution runs strictly against the isolated test database."""
        active_url = get_active_database_url()
        assert not is_production_database(active_url)
        assert_not_production_database(active_url, context="TestDatabaseSchemaCompatibility")
