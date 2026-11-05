"""
Phase 11C: Multilingual Script Engines, Akshara Collation and Transliteration Tests
Tests centralized script registry, multi-script detection, Sanskrit IAST/Devanagari
transliteration, reversibility classification, Akshara-aware collation, and Unicode preservation.
"""

from datetime import datetime, timezone
import pytest
import unicodedata

from automation.cleaners.unicode_preserver import VedicSwara
from automation.localization.registry import MultilingualRegistry
from automation.localization.script_registry import (
    MultilingualScriptRegistry,
    ScriptCategory,
    ScriptDirection,
    ScriptProfile,
)
from automation.localization.transliteration_engine import (
    MultilingualTransliterationEngine,
    TransliterationReversibility,
    TransliterationResult,
)
from automation.localization.akshara_collator import AksharaCollator
from automation.localization.unicode_inspector import (
    UnicodeFidelityInspector,
    UnicodeFidelityReport,
)
from automation.workbench.multilingual_rbac import MultilingualRBACEngine


# ---------------------------------------------------------------------------
# 1. Script Registry & Detection Tests
# ---------------------------------------------------------------------------
class TestScriptRegistryAndDetection:
    """Verifies all 14 script profiles, directionality, detection, and validation."""

    def test_all_14_scripts_registered(self):
        """All 14 platform scripts must be defined in MultilingualScriptRegistry."""
        expected_scripts = [
            "Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", "Beng",
            "Gujr", "Guru", "Orya", "Olck", "Arab", "Mtei", "Latn"
        ]
        for s in expected_scripts:
            profile = MultilingualScriptRegistry.get_script(s)
            assert profile is not None, f"Missing script profile for '{s}'"
            assert profile.iso_15924 == s
            assert len(profile.unicode_blocks) >= 1

    def test_perso_arabic_is_rtl(self):
        """Perso-Arabic script must be marked as RTL."""
        arab = MultilingualScriptRegistry.get_script("Arab")
        assert arab.direction == ScriptDirection.RTL
        assert MultilingualScriptRegistry.is_rtl("Arab") is True
        assert MultilingualScriptRegistry.is_rtl("ur") is True
        assert MultilingualScriptRegistry.is_rtl("ks") is True

    def test_brahmic_scripts_are_ltr(self):
        """Devanagari, Telugu, Tamil, Kannada, etc. must be marked as LTR."""
        for s in ["Deva", "Telu", "Taml", "Knda", "Mlym", "Beng", "Gujr", "Guru", "Orya", "Olck", "Mtei", "Latn"]:
            assert MultilingualScriptRegistry.is_rtl(s) is False
            profile = MultilingualScriptRegistry.get_script(s)
            assert profile.direction == ScriptDirection.LTR

    def test_script_detection_accuracy(self):
        """Detects dominant script across various pure language samples."""
        samples = [
            ("ॐ नमः शिवाय", "Deva"),
            ("ఓం నమః శివాయ", "Telu"),
            ("ஓம் நமஃ சிவாய", "Taml"),
            ("ಓಂ ನಮಃ ಶಿವಾಯ", "Knda"),
            ("ഓം നമഃ ശിവായ", "Mlym"),
            ("ওঁ নমঃ শিবায়", "Beng"),
            ("ૐ નમઃ શિવાય", "Gujr"),
            ("ੴ ਸਤਿ ਨਾਮੁ", "Guru"),
            ("ଓଁ ନମଃ ଶିଵାୟ", "Orya"),
            ("ᱱᱚᱢᱚᱷ ᱥᱚᱤᱣᱚᱟᱭᱚ", "Olck"),
            ("ꯅꯃꯍ꯭ ꯁꯤꯋꯥꯌ", "Mtei"),
            ("نَمَہ شَِوَایَ", "Arab"),
            ("oṃ namaḥ śivāya", "Latn"),
        ]
        for text, expected in samples:
            det = MultilingualScriptRegistry.detect_script(text)
            assert det["primary_script"] == expected, f"Failed for '{text}': got {det['primary_script']}, expected {expected}"
            assert det["confidence"] == 1.0
            assert det["is_mixed_script"] is False

    def test_mixed_script_detection(self):
        """Correctly identifies mixed script strings with proportional distribution."""
        mixed_text = "The sacred mantra is ॐ नमः शिवाय chant it daily."
        det = MultilingualScriptRegistry.detect_script(mixed_text)
        assert det["is_mixed_script"] is True
        assert "Latn" in det["script_distribution"]
        assert "Deva" in det["script_distribution"]
        assert det["primary_script"] == "Latn"

    def test_language_script_compatibility_validation(self):
        """Validates allowable script combinations per language."""
        # Valid pairs
        ok_pairs = [
            ("sa", "Deva"), ("sa", "Telu"), ("sa", "Gran"), ("sa", "Latn"),
            ("hi", "Deva"), ("te", "Telu"), ("ta", "Taml"), ("kn", "Knda"),
            ("ur", "Arab"), ("sat", "Olck"), ("mni", "Mtei"), ("mni", "Beng"),
            ("as", "Beng"), ("pa", "Guru"),
        ]
        for lang, script in ok_pairs:
            is_valid, reason = MultilingualScriptRegistry.validate_script_for_language(lang, script)
            assert is_valid is True, f"Failed for ({lang}, {script}): {reason}"

        # Invalid pairs
        invalid_pairs = [
            ("hi", "Arab"), ("ta", "Guru"), ("ur", "Olck"), ("kn", "Arab"),
        ]
        for lang, script in invalid_pairs:
            is_valid, reason = MultilingualScriptRegistry.validate_script_for_language(lang, script)
            assert is_valid is False
            assert "is not registered for language" in reason


# ---------------------------------------------------------------------------
# 2. Transliteration Engine Tests
# ---------------------------------------------------------------------------
class TestTransliterationEngine:
    """Verifies multi-script transliteration, reversibility, and Vedic accent preservation."""

    def test_sanskrit_iast_to_devanagari_lossless(self):
        """IAST to Devanagari transliteration is lossless and exact."""
        iast = "oṃ namo bhagavate vāsudevāya"
        res = MultilingualTransliterationEngine.transliterate(iast, "Latn", "Deva")
        assert res.text == "ॐ नमो भगवते वासुदेवाय"
        assert res.reversibility == TransliterationReversibility.REVERSIBLE
        assert res.is_lossless is True

    def test_sanskrit_devanagari_to_iast_lossless(self):
        """Devanagari to IAST transliteration is lossless and exact."""
        deva = "ॐ नमो भगवते वासुदेवाय"
        res = MultilingualTransliterationEngine.transliterate(deva, "Deva", "Latn")
        assert res.text == "oṃ namo bhagavate vāsudevāya"
        assert res.reversibility == TransliterationReversibility.REVERSIBLE

    def test_round_trip_devanagari_iast(self):
        """Round-trip conversion Devanagari -> IAST -> Devanagari preserves exact characters."""
        original = "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यम् । भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥"
        rt = MultilingualTransliterationEngine.verify_round_trip(original, "Deva", "Latn")
        assert rt["is_exact_match"] is True
        assert rt["character_diff_count"] == 0
        assert rt["reversibility"] == TransliterationReversibility.REVERSIBLE.value

    def test_vedic_accent_preservation_round_trip(self):
        """Preserves Rigvedic anudatta (U+0952) and svarita (U+0951) across transliteration."""
        # Rigveda 1.1.1: अग्निमीळे पुरोहितम् with accents
        accented_verse = "अ॒ग्निमी॑ळे पु॒रोहि॑तम्"
        forward = MultilingualTransliterationEngine.transliterate(accented_verse, "Deva", "Latn")
        assert len(forward.preserved_accents) >= 2
        # Reverse back to Devanagari
        reverse = MultilingualTransliterationEngine.transliterate(forward.text, "Latn", "Deva")
        assert reverse.text == accented_verse

    def test_devanagari_to_southern_brahmic_scripts(self):
        """Devanagari converts losslessly into Telugu, Kannada, and Malayalam for Sanskrit phonology."""
        deva = "ॐ नमः शिवाय"
        for target in ["Telu", "Knda", "Mlym"]:
            res = MultilingualTransliterationEngine.transliterate(deva, "Deva", target)
            assert res.reversibility == TransliterationReversibility.REVERSIBLE
            assert len(res.text) > 0
            # Round trip
            back = MultilingualTransliterationEngine.transliterate(res.text, target, "Deva")
            assert back.text == deva

    def test_tamil_transliteration_modes(self):
        """Tests standard Tamil (lossy) vs scholarly phonetic Tamil with subscript varga numbers."""
        deva = "धर्मक्षेत्रे कुरुक्षेत्रे"
        # Standard Tamil (lossy)
        res_std = MultilingualTransliterationEngine.transliterate(deva, "Deva", "Taml", tamil_mode="standard")
        assert res_std.reversibility == TransliterationReversibility.LOSSY

        # Scholarly Phonetic Tamil (conditionally reversible with subscripts)
        res_phon = MultilingualTransliterationEngine.transliterate(deva, "Deva", "Taml", tamil_mode="phonetic")
        assert res_phon.reversibility == TransliterationReversibility.CONDITIONALLY_REVERSIBLE
        # Phonetic Tamil must contain subscript indicators (₁ ₂ ₃ ₄)
        assert any(sub in res_phon.text for sub in ["₁", "₂", "₃", "₄"])

    def test_ol_chiki_meitei_and_urdu_reversibility_is_lossy(self):
        """Ol Chiki, Meetei Mayek, and Urdu conversions are marked as LOSSY."""
        deva = "नमः शिवाय"
        for target in ["Olck", "Mtei", "Arab"]:
            res = MultilingualTransliterationEngine.transliterate(deva, "Deva", target)
            assert res.reversibility == TransliterationReversibility.LOSSY
            assert res.is_lossless is False
            assert len(res.warnings) >= 1

    def test_unsupported_conversion_fails_safely(self):
        """Unsupported script pairs return explicit UNSUPPORTED status without corrupting text."""
        res = MultilingualTransliterationEngine.transliterate("Sample Text", "Olck", "Arab")
        assert res.reversibility == TransliterationReversibility.UNSUPPORTED
        assert res.is_lossless is False
        assert "unsupported" in res.warnings[0].lower()
        # Original text returned untouched
        assert res.text == "Sample Text"


# ---------------------------------------------------------------------------
# 3. Akshara Collation Engine Tests
# ---------------------------------------------------------------------------
class TestAksharaCollationEngine:
    """Verifies linguistic sorting for Indic scripts and Sanskrit IAST text."""

    def test_sanskrit_devanagari_dictionary_order(self):
        """
        In traditional Sanskrit lexicography (Apte / Monier-Williams):
        Simple consonant syllables finish before conjuncts (virama).
        E.g., कमल, काम, किरण, कृष्ण, केशव sort BEFORE क्रोध!
        """
        words = ["क्रोध", "केशव", "कृष्ण", "किरण", "काम", "कमल", "ईश्वर", "आनन्द", "अग्नि"]
        sorted_words = AksharaCollator.sort_words(words, language="sa")
        expected = [
            "अग्नि", "आनन्द", "ईश्वर",
            "कमल", "काम", "किरण", "कृष्ण", "केशव",
            "क्रोध",
        ]
        assert sorted_words == expected

    def test_sanskrit_iast_resolves_raw_unicode_defect(self):
        """
        Crucial test: In raw Unicode, 'ā' (U+0101 = 257) > 'z' (122), so 'ātman'
        erroneously sorts after 'zebra'! AksharaCollator places 'ātman' immediately after 'agni'.
        """
        words = ["zebra", "krodha", "ātman", "kṛṣṇa", "agni", "īśvara", "kamala"]
        sorted_words = AksharaCollator.sort_words(words, language="sa")
        expected = [
            "agni", "ātman", "īśvara",
            "kamala", "kṛṣṇa", "krodha",
            "zebra",
        ]
        assert sorted_words == expected

    def test_akshara_collation_compare_api(self):
        """compare() returns -1 for smaller, 1 for greater, 0 for equal."""
        assert AksharaCollator.compare("अग्नि", "काम", language="sa") == -1
        assert AksharaCollator.compare("काम", "अग्नि", language="sa") == 1
        assert AksharaCollator.compare("शिव", "शिव", language="sa") == 0

    def test_stable_and_deterministic_sorting(self):
        """Collation keys must be strictly deterministic across repeated invocations."""
        word = "तत्सवितुर्वरेण्यम्"
        k1 = AksharaCollator.get_collation_key(word, language="sa")
        k2 = AksharaCollator.get_collation_key(word, language="sa")
        assert k1 == k2


# ---------------------------------------------------------------------------
# 4. Unicode Preservation & Fidelity Tests
# ---------------------------------------------------------------------------
class TestUnicodePreservationAndFidelity:
    """Verifies non-destructive Unicode auditing, NFC/NFD integrity, and control character detection."""

    def test_nfc_equality_verification(self):
        """verify_nfc_equality returns True for canonically equivalent strings in NFC vs NFD."""
        composed = "शिव"
        decomposed = unicodedata.normalize("NFD", composed)
        assert composed != decomposed or len(composed.encode()) == len(decomposed.encode())
        assert UnicodeFidelityInspector.verify_nfc_equality(composed, decomposed) is True

    def test_vedic_accent_inspection(self):
        """Detects and counts all Vedic accents without altering source string."""
        verse = "अ॒ग्निमी॑ळे पु॒रोहि॑तम्"
        report = UnicodeFidelityInspector.inspect(verse)
        assert isinstance(report, UnicodeFidelityReport)
        assert report.original_text == verse
        assert report.is_nfc_normalized is True
        assert report.vedic_accent_count == 4
        assert VedicSwara.ANUDATTA in report.vedic_accents
        assert VedicSwara.SVARITA in report.vedic_accents
        assert report.script_detected == "Deva"
        assert report.is_pure_script is True

    def test_control_character_and_zero_width_detection(self):
        """Detects Zero Width Joiner (ZWJ) and Zero Width Non-Joiner (ZWNJ)."""
        text_with_zwj = "ക\u0d4d\u200dര"  # Malayalam ligature with ZWJ only
        text_with_zwnj = "মি\u200cল"  # Bengali with ZWNJ only
        rep_zwj = UnicodeFidelityInspector.inspect(text_with_zwj)
        assert rep_zwj.has_zwj is True
        assert rep_zwj.has_zwnj is False

        rep_zwnj = UnicodeFidelityInspector.inspect(text_with_zwnj)
        assert rep_zwnj.has_zwnj is True
        assert rep_zwnj.has_zwj is False


# ---------------------------------------------------------------------------
# 5. Localization & RBAC Integration Tests
# ---------------------------------------------------------------------------
class TestLocalizationRBACIntegration:
    """Verifies harmony between Script Registry, Multilingual Registry, and Reviewer RBAC."""

    def test_all_rbac_roles_supported_by_script_registry(self):
        """Every script required by ReviewerRole in RBAC must exist in Script Registry."""
        for role, allowed_scripts in MultilingualRBACEngine.ROLE_SCRIPT_MAP.items():
            for script_code in allowed_scripts:
                profile = MultilingualScriptRegistry.get_script(script_code)
                assert profile is not None, f"Role {role} references unregistered script {script_code}"

    def test_all_multilingual_registry_scripts_exist_in_script_registry(self):
        """Script registry must encompass every script in MultilingualRegistry."""
        for s_code in MultilingualRegistry.SCRIPTS.keys():
            profile = MultilingualScriptRegistry.get_script(s_code)
            assert profile is not None, f"MultilingualRegistry script '{s_code}' missing in ScriptRegistry"
