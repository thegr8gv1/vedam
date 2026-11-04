"""
Unit & Regression Tests for Unicode, Vedic Swaras, and Indic Transliteration
"""

import pytest

from automation.cleaners.unicode_preserver import (
    TransliterationEngine,
    UnicodePreserver,
    VedicSwara,
)


def test_vedic_swara_detection():
    # Rigveda 7.59.12 with Anudatta (U+0952) and Svarita (U+0951)
    text_with_swaras = "त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम्"
    analysis = UnicodePreserver.analyze_vedic_swaras(text_with_swaras)

    assert analysis["has_vedic_accents"] is True
    assert analysis["svarita_count"] >= 2  # on त्र्य and धिं
    assert analysis["anudatta_count"] >= 2  # on ग and वर्


def test_clean_text_preserves_swaras_and_diacritics():
    raw_with_spaces = "  त्र्य॑म्बकं   यजामहे \t सु॒गन्धिं॑ \n\n पुष्टि॒वर्ध॑नम्  ॥ "
    cleaned = UnicodePreserver.clean_text_preserving_accents(raw_with_spaces)

    # Asserts whitespace normalized but swaras untouched
    assert VedicSwara.SVARITA in cleaned
    assert VedicSwara.ANUDATTA in cleaned
    assert "  " not in cleaned  # Double spaces removed


def test_multilingual_transliterations_round_trip():
    # Canonical Sanskrit Verse (Ganesha Pancharatnam line)
    original_devanagari = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम्"

    # 1. Telugu Transliteration & Round-Trip
    telugu_text = TransliterationEngine.to_script(original_devanagari, "telugu")
    assert "ముదాకరాత్తమోదకం" in telugu_text
    is_lossless, ratio, msg = TransliterationEngine.verify_round_trip(original_devanagari, "telugu")
    assert is_lossless is True
    assert ratio == 1.0

    # 2. Kannada Transliteration & Round-Trip
    kannada_text = TransliterationEngine.to_script(original_devanagari, "kannada")
    assert "ಮುದಾಕರಾತ್ತಮೋದಕಂ" in kannada_text
    is_lossless, ratio, msg = TransliterationEngine.verify_round_trip(original_devanagari, "kannada")
    assert is_lossless is True
    assert ratio == 1.0

    # 3. Malayalam Transliteration & Round-Trip
    malayalam_text = TransliterationEngine.to_script(original_devanagari, "malayalam")
    assert "മുദാകരാത്തമോദകം" in malayalam_text
    is_lossless, ratio, msg = TransliterationEngine.verify_round_trip(original_devanagari, "malayalam")
    assert is_lossless is True
    assert ratio == 1.0

    # 4. Roman IAST Transliteration & Round-Trip
    iast_text = TransliterationEngine.to_script(original_devanagari, "iast")
    assert "mudākarāttamodaka" in iast_text
    is_lossless, ratio, msg = TransliterationEngine.verify_round_trip(original_devanagari, "iast")
    assert is_lossless is True

    # 5. Tamil Transliteration with documented phonetic limitation
    tamil_text = TransliterationEngine.to_script(original_devanagari, "tamil")
    assert "முதாகராத்தமோதகம்" in tamil_text
    is_lossless, ratio, msg = TransliterationEngine.verify_round_trip(original_devanagari, "tamil", allow_script_limitations=True)
    assert is_lossless is True  # Verified with allow_script_limitations flag
