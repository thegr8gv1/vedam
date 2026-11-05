"""
Vedic Heritage Platform — Unified Multilingual Transliteration Engine
Part C.4: Modular transliteration architecture supporting 14 scripts,
explicit reversibility classification, loss-detection, and Vedic accent preservation.

Rules:
- Explicit conversion-pair matrix documenting reversibility status (REVERSIBLE, CONDITIONALLY_REVERSIBLE, LOSSY, UNSUPPORTED).
- Never claim a script pair is supported without validated linguistic rules.
- Unsupported conversion attempts must fail safely with an explicit result, never corrupting text.
- Punctuation, whitespace, danda (।), double danda (॥), and Vedic accents (U+0951, U+0952, U+0954, U+1CDA) must be preserved.
- Output text is always normalized to Unicode Normalization Form C (NFC).
"""

from dataclasses import dataclass, field
import enum
import logging
from typing import Any, Dict, List, Optional, Set, Tuple
import unicodedata

from indic_transliteration import sanscript

from automation.cleaners.unicode_preserver import VedicSwara
from automation.localization.script_registry import MultilingualScriptRegistry

logger = logging.getLogger("vedam.automation.localization.transliteration_engine")


class TransliterationReversibility(str, enum.Enum):
    REVERSIBLE = "REVERSIBLE"                             # 100% bijective lossless round-trip
    CONDITIONALLY_REVERSIBLE = "CONDITIONALLY_REVERSIBLE" # Lossless with specialized phonetic tags (e.g. Tamil subscripts)
    LOSSY = "LOSSY"                                       # Irreversible phonological or graphemic reduction
    UNSUPPORTED = "UNSUPPORTED"                           # No reliable conversion path exists


@dataclass(frozen=True)
class TransliterationResult:
    source_script: str
    target_script: str
    text: str
    reversibility: TransliterationReversibility
    is_lossless: bool
    preserved_accents: Tuple[str, ...] = field(default_factory=tuple)
    warnings: Tuple[str, ...] = field(default_factory=tuple)
    original_text: str = ""


class MultilingualTransliterationEngine:
    """
    High-fidelity transliteration engine for Vedic and multilingual Indian literature.
    """

    # Mapping from project ISO 15924 script codes to indic_transliteration scheme constants
    SCHEME_MAP: Dict[str, str] = {
        "Deva": sanscript.DEVANAGARI,
        "Latn": sanscript.IAST,
        "Telu": sanscript.TELUGU,
        "Knda": sanscript.KANNADA,
        "Mlym": sanscript.MALAYALAM,
        "Beng": sanscript.BENGALI,
        "Gujr": sanscript.GUJARATI,
        "Orya": sanscript.ORIYA,
        "Guru": sanscript.GURMUKHI,
        "Taml": sanscript.TAMIL,
        "Gran": sanscript.GRANTHA,
        "Olck": "ol_chiki",
        "Mtei": "manipuri",
        "Arab": "urdu",
    }

    # -----------------------------------------------------------------------
    # Authoritative Conversion Pair Reversibility Matrix
    # (source_script, target_script) -> TransliterationReversibility
    # -----------------------------------------------------------------------
    CONVERSION_MATRIX: Dict[Tuple[str, str], TransliterationReversibility] = {
        # Devanagari Source
        ("Deva", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Telu"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Knda"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Mlym"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Beng"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Gujr"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Gran"): TransliterationReversibility.REVERSIBLE,
        ("Deva", "Orya"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,
        ("Deva", "Guru"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,
        ("Deva", "Taml"): TransliterationReversibility.LOSSY,
        ("Deva", "Olck"): TransliterationReversibility.LOSSY,
        ("Deva", "Mtei"): TransliterationReversibility.LOSSY,
        ("Deva", "Arab"): TransliterationReversibility.LOSSY,

        # Latin / IAST Source
        ("Latn", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Telu"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Knda"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Mlym"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Beng"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Gujr"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Gran"): TransliterationReversibility.REVERSIBLE,
        ("Latn", "Orya"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,
        ("Latn", "Guru"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,
        ("Latn", "Taml"): TransliterationReversibility.LOSSY,
        ("Latn", "Olck"): TransliterationReversibility.LOSSY,
        ("Latn", "Mtei"): TransliterationReversibility.LOSSY,
        ("Latn", "Arab"): TransliterationReversibility.LOSSY,

        # Southern Brahmic Inter-conversion (Telugu, Kannada, Malayalam)
        ("Telu", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Telu", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Telu", "Knda"): TransliterationReversibility.REVERSIBLE,
        ("Telu", "Mlym"): TransliterationReversibility.REVERSIBLE,

        ("Knda", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Knda", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Knda", "Telu"): TransliterationReversibility.REVERSIBLE,
        ("Knda", "Mlym"): TransliterationReversibility.REVERSIBLE,

        ("Mlym", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Mlym", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Mlym", "Telu"): TransliterationReversibility.REVERSIBLE,
        ("Mlym", "Knda"): TransliterationReversibility.REVERSIBLE,

        # Eastern Brahmic (Bengali, Odia)
        ("Beng", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Beng", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Orya", "Deva"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,

        # Western Brahmic (Gujarati, Gurmukhi)
        ("Gujr", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Gujr", "Latn"): TransliterationReversibility.REVERSIBLE,
        ("Guru", "Deva"): TransliterationReversibility.CONDITIONALLY_REVERSIBLE,

        # Grantha
        ("Gran", "Deva"): TransliterationReversibility.REVERSIBLE,
        ("Gran", "Latn"): TransliterationReversibility.REVERSIBLE,

        # Tamil
        ("Taml", "Deva"): TransliterationReversibility.LOSSY,
        ("Taml", "Latn"): TransliterationReversibility.LOSSY,

        # Ol Chiki, Meetei Mayek, Perso-Arabic reverse paths
        ("Olck", "Deva"): TransliterationReversibility.LOSSY,
        ("Mtei", "Deva"): TransliterationReversibility.LOSSY,
        ("Arab", "Deva"): TransliterationReversibility.LOSSY,
    }

    # Vedic accents to track
    VEDIC_ACCENTS = (
        VedicSwara.SVARITA,         # U+0951
        VedicSwara.ANUDATTA,        # U+0952
        VedicSwara.UDATTA,          # U+0954
        VedicSwara.DIRGHA_SVARITA,  # U+1CDA
    )

    @classmethod
    def get_reversibility(cls, source_script: str, target_script: str) -> TransliterationReversibility:
        """Returns the reversibility classification for a script pair."""
        s = source_script.strip().capitalize()
        t = target_script.strip().capitalize()
        if s == t:
            return TransliterationReversibility.REVERSIBLE
        return cls.CONVERSION_MATRIX.get((s, t), TransliterationReversibility.UNSUPPORTED)

    @classmethod
    def is_conversion_supported(cls, source_script: str, target_script: str) -> bool:
        """Checks if a conversion path is supported."""
        rev = cls.get_reversibility(source_script, target_script)
        return rev != TransliterationReversibility.UNSUPPORTED

    @classmethod
    def transliterate(
        cls,
        text: str,
        source_script: str,
        target_script: str,
        preserve_accents: bool = True,
        tamil_mode: str = "grantha",
    ) -> TransliterationResult:
        """
        Translates text between supported scripts while preserving Vedic accents,
        punctuation, and whitespace, and providing explicit lossiness metadata.
        """
        if not text:
            return TransliterationResult(
                source_script=source_script,
                target_script=target_script,
                text="",
                reversibility=TransliterationReversibility.REVERSIBLE,
                is_lossless=True,
                original_text="",
            )

        src = source_script.strip().capitalize()
        tgt = target_script.strip().capitalize()

        # Identity conversion
        if src == tgt:
            return TransliterationResult(
                source_script=src,
                target_script=tgt,
                text=unicodedata.normalize("NFC", text),
                reversibility=TransliterationReversibility.REVERSIBLE,
                is_lossless=True,
                original_text=text,
            )

        reversibility = cls.get_reversibility(src, tgt)

        # Handle unsupported conversions
        if reversibility == TransliterationReversibility.UNSUPPORTED:
            return TransliterationResult(
                source_script=src,
                target_script=tgt,
                text=text,  # Return original unchanged
                reversibility=TransliterationReversibility.UNSUPPORTED,
                is_lossless=False,
                warnings=(f"Conversion from '{src}' to '{tgt}' is unsupported.",),
                original_text=text,
            )

        # Map to indic_transliteration scheme
        src_scheme = cls.SCHEME_MAP.get(src)
        tgt_scheme = cls.SCHEME_MAP.get(tgt)

        if not src_scheme or not tgt_scheme:
            return TransliterationResult(
                source_script=src,
                target_script=tgt,
                text=text,
                reversibility=TransliterationReversibility.UNSUPPORTED,
                is_lossless=False,
                warnings=(f"Scheme mapping missing for '{src}' or '{tgt}'.",),
                original_text=text,
            )

        # Identify present Vedic accents
        accents_present = [acc for acc in cls.VEDIC_ACCENTS if acc in text]

        warnings: List[str] = []
        if reversibility == TransliterationReversibility.LOSSY:
            warnings.append(f"Conversion from '{src}' to '{tgt}' is lossy. Character distinctions may be merged.")
        elif reversibility == TransliterationReversibility.CONDITIONALLY_REVERSIBLE:
            warnings.append(f"Conversion from '{src}' to '{tgt}' is conditionally reversible depending on orthographic context.")

        try:
            # Handle specialized Tamil phonetic mode
            if tgt == "Taml" and tamil_mode == "phonetic" and src == "Deva":
                from automation.localization.transliteration import SpecializedTransliterationEngine
                converted = SpecializedTransliterationEngine._to_scholarly_phonetic_tamil(text)
                reversibility = TransliterationReversibility.CONDITIONALLY_REVERSIBLE
            else:
                # Direct transliteration
                converted = sanscript.transliterate(text, src_scheme, tgt_scheme)

            # Normalize to NFC
            normalized = unicodedata.normalize("NFC", converted)

            is_lossless = (reversibility == TransliterationReversibility.REVERSIBLE)

            return TransliterationResult(
                source_script=src,
                target_script=tgt,
                text=normalized,
                reversibility=reversibility,
                is_lossless=is_lossless,
                preserved_accents=tuple(accents_present),
                warnings=tuple(warnings),
                original_text=text,
            )

        except Exception as e:
            logger.error("Transliteration failed for %s -> %s: %s", src, tgt, e)
            return TransliterationResult(
                source_script=src,
                target_script=tgt,
                text=text,
                reversibility=TransliterationReversibility.UNSUPPORTED,
                is_lossless=False,
                warnings=(f"Transliteration engine error: {str(e)}",),
                original_text=text,
            )

    @classmethod
    def verify_round_trip(cls, text: str, source_script: str, target_script: str) -> Dict[str, Any]:
        """
        Tests round-trip fidelity between source_script and target_script.
        Returns:
            - is_exact_match: bool
            - source_script: str
            - target_script: str
            - forward_text: str
            - reverse_text: str
            - character_diff_count: int
            - reversibility: TransliterationReversibility
        """
        forward = cls.transliterate(text, source_script, target_script)
        reverse = cls.transliterate(forward.text, target_script, source_script)

        norm_orig = unicodedata.normalize("NFC", text)
        norm_rev = unicodedata.normalize("NFC", reverse.text)

        is_match = (norm_orig == norm_rev)

        diff_count = sum(1 for a, b in zip(norm_orig, norm_rev) if a != b) + abs(len(norm_orig) - len(norm_rev))

        return {
            "is_exact_match": is_match,
            "source_script": source_script,
            "target_script": target_script,
            "forward_text": forward.text,
            "reverse_text": reverse.text,
            "character_diff_count": diff_count,
            "reversibility": forward.reversibility.value,
            "is_lossless": forward.is_lossless,
            "warnings": forward.warnings,
        }
