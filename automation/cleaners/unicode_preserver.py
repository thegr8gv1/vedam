"""
Vedic Heritage Platform — Unicode & Multilingual Preservation Engine
Guarantees immutable preservation of raw source text, Vedic accents (swaras),
anusvara, visarga, chandrabindu, and validates lossless Indic script transliteration.
"""

import unicodedata
import re
from typing import Any, Dict, List, Optional, Set, Tuple

from indic_transliteration import sanscript
from indic_transliteration.sanscript import SchemeMap, SCHEMES, transliterate


class VedicSwara:
    """Unicode combining code points for sacred Vedic tones."""
    UDATTA = "\u0954"          # Devanagari Acute Accent (High tone)
    ANUDATTA = "\u0952"        # Devanagari Stress Sign Anudatta (Low tone)
    SVARITA = "\u0951"         # Devanagari Stress Sign Udatta / Svarita (Circumflex/Rising)
    DIRGHA_SVARITA = "\u1CDA"  # Vedic Tone Double Svarita
    CHANDRABINDU = "\u0901"    # Devanagari Sign Chandrabindu
    ANUSVARA = "\u0902"        # Devanagari Sign Anusvara
    VISARGA = "\u0903"         # Devanagari Sign Visarga
    VIRAMA = "\u094D"          # Devanagari Sign Virama (Halant)

    ALL_SWARAS: Set[str] = {UDATTA, ANUDATTA, SVARITA, DIRGHA_SVARITA}
    ALL_DIACRITICS: Set[str] = {UDATTA, ANUDATTA, SVARITA, DIRGHA_SVARITA, CHANDRABINDU, ANUSVARA, VISARGA}


class UnicodePreserver:
    """
    Ensures absolute integrity of Indic texts and Vedic liturgical marks.
    Enforces immutable raw text preservation and creates sanitized canonical representations.
    """

    @classmethod
    def analyze_vedic_swaras(cls, text: str) -> Dict[str, Any]:
        """
        Analyze and extract all Vedic musical accents from a text.
        Returns a dictionary detailing accent frequencies and positional tokens.
        """
        swara_counts = {
            "anudatta_count": text.count(VedicSwara.ANUDATTA),
            "svarita_count": text.count(VedicSwara.SVARITA),
            "udatta_count": text.count(VedicSwara.UDATTA),
            "dirgha_svarita_count": text.count(VedicSwara.DIRGHA_SVARITA),
            "chandrabindu_count": text.count(VedicSwara.CHANDRABINDU),
            "has_vedic_accents": False,
        }
        total_swaras = (
            swara_counts["anudatta_count"]
            + swara_counts["svarita_count"]
            + swara_counts["udatta_count"]
            + swara_counts["dirgha_svarita_count"]
        )
        swara_counts["has_vedic_accents"] = total_swaras > 0
        swara_counts["total_accent_count"] = total_swaras
        return swara_counts

    @classmethod
    def clean_text_preserving_accents(cls, raw_text: str) -> str:
        """
        Normalize Unicode to NFC and trim superficial whitespace without altering
        any accents, ligatures, viramas, or punctuation.
        """
        if not raw_text:
            return ""

        # Normalize to Unicode NFC standard
        nfc_text = unicodedata.normalize("NFC", raw_text)

        # Normalize whitespace (tabs and multiple spaces) while retaining paragraph newlines
        lines = []
        for line in nfc_text.splitlines():
            # Replace non-breaking spaces with standard space
            clean_line = line.replace("\u00A0", " ").replace("\u200B", "")
            # Collapse multiple inline spaces to single space
            clean_line = re.sub(r"[ \t]+", " ", clean_line).strip()
            if clean_line:
                lines.append(clean_line)

        return "\n".join(lines)

    @classmethod
    def extract_canonical_text(cls, raw_text: str) -> Tuple[str, Dict[str, Any]]:
        """
        Process raw immutable text into canonical scholarly representation
        while cataloging all accent annotations.
        """
        cleaned = cls.clean_text_preserving_accents(raw_text)
        analysis = cls.analyze_vedic_swaras(cleaned)
        return cleaned, analysis


class TransliterationEngine:
    """
    Multi-script transliteration engine supporting Devanagari, Telugu, Tamil,
    Kannada, Malayalam, and Roman IAST with round-trip verification.
    """

    SCHEME_MAP = {
        "devanagari": sanscript.DEVANAGARI,
        "telugu": sanscript.TELUGU,
        "tamil": sanscript.TAMIL,
        "kannada": sanscript.KANNADA,
        "malayalam": sanscript.MALAYALAM,
        "bengali": sanscript.BENGALI,
        "gujarati": sanscript.GUJARATI,
        "odia": sanscript.ORIYA,
        "iast": sanscript.IAST,
    }

    @classmethod
    def to_script(cls, devanagari_text: str, target_script: str) -> str:
        """
        Project Devanagari Sanskrit into target Indic script or IAST Roman transliteration.
        """
        script_key = target_script.lower().strip()
        if script_key not in cls.SCHEME_MAP:
            raise ValueError(f"Unsupported target script '{target_script}'. Available: {list(cls.SCHEME_MAP.keys())}")

        target_scheme = cls.SCHEME_MAP[script_key]
        if target_scheme == sanscript.DEVANAGARI:
            return devanagari_text

        # Use indic-transliteration
        converted = transliterate(devanagari_text, sanscript.DEVANAGARI, target_scheme)
        return unicodedata.normalize("NFC", converted)

    @classmethod
    def verify_round_trip(
        cls,
        source_text: str,
        target_script: str,
        allow_script_limitations: bool = False,
    ) -> Tuple[bool, float, str]:
        """
        Execute round-trip test: Devanagari -> Target Script -> Devanagari.
        Verifies character retention and returns (is_lossless, similarity_ratio, diff_summary).
        """
        script_key = target_script.lower().strip()
        converted = cls.to_script(source_text, script_key)
        round_tripped = transliterate(converted, cls.SCHEME_MAP[script_key], sanscript.DEVANAGARI)
        round_tripped = unicodedata.normalize("NFC", round_tripped)
        original_nfc = unicodedata.normalize("NFC", source_text)

        if original_nfc == round_tripped:
            return True, 1.0, "Lossless 100% round-trip preservation verified."

        # Compute simple character overlap
        import difflib
        matcher = difflib.SequenceMatcher(None, original_nfc, round_tripped)
        ratio = round(matcher.ratio(), 4)

        # Tamil script note: Tamil inherently lacks separate symbols for voiced plosives (g, j, d, b)
        # and aspirated consonants (kh, gh, ch, jh, th, dh, ph, bh) without Grantha extensions.
        if script_key == "tamil" and allow_script_limitations:
            diff = f"Tamil script phonetic simplification (lossless round-trip requires Grantha). Ratio: {ratio}"
            return True, ratio, diff

        diff = f"Round-trip discrepancy detected. Similarity: {ratio}"
        return False, ratio, diff
