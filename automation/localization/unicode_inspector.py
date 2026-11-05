"""
Vedic Heritage Platform — Unicode Fidelity & Preservation Inspector
Part C.6: Non-destructive Unicode inspection, NFC/NFD verification,
Vedic accent audit, and control-character (ZWJ/ZWNJ) analysis.

Rules:
- NEVER silently normalize, rewrite, or mutate stored canonical source text.
- Provide explicit preservation, comparison, and audit APIs.
- Distinguish between pure normalization inspection and content mutation.
- Maintain original source strings and provenance intact.
"""

from dataclasses import dataclass, field
import enum
import logging
from typing import Any, Dict, List, Optional, Set, Tuple
import unicodedata

from automation.cleaners.unicode_preserver import VedicSwara
from automation.localization.script_registry import MultilingualScriptRegistry

logger = logging.getLogger("vedam.automation.localization.unicode_inspector")


@dataclass(frozen=True)
class UnicodeFidelityReport:
    original_text: str
    nfc_text: str
    nfd_text: str
    is_nfc_normalized: bool
    is_nfd_normalized: bool
    byte_count_utf8: int
    char_count: int
    combining_mark_count: int
    vedic_accent_count: int
    vedic_accents: Tuple[str, ...]
    has_zwj: bool
    has_zwnj: bool
    control_characters: Tuple[str, ...]
    script_detected: str
    is_pure_script: bool


class UnicodeFidelityInspector:
    """Non-destructive Unicode inspector for sacred texts and multilingual translations."""

    VEDIC_ACCENTS_SET: Set[str] = {
        VedicSwara.SVARITA,         # U+0951
        VedicSwara.ANUDATTA,        # U+0952
        VedicSwara.UDATTA,          # U+0954
        VedicSwara.DIRGHA_SVARITA,  # U+1CDA
        VedicSwara.CHANDRABINDU,    # U+0901
    }

    ZWJ = "\u200D"   # Zero Width Joiner
    ZWNJ = "\u200C"  # Zero Width Non-Joiner

    @classmethod
    def inspect(cls, text: str) -> UnicodeFidelityReport:
        """
        Conducts a comprehensive, non-destructive Unicode audit of a text string.
        """
        if not text:
            return UnicodeFidelityReport(
                original_text="",
                nfc_text="",
                nfd_text="",
                is_nfc_normalized=True,
                is_nfd_normalized=True,
                byte_count_utf8=0,
                char_count=0,
                combining_mark_count=0,
                vedic_accent_count=0,
                vedic_accents=(),
                has_zwj=False,
                has_zwnj=False,
                control_characters=(),
                script_detected="Latn",
                is_pure_script=True,
            )

        nfc = unicodedata.normalize("NFC", text)
        nfd = unicodedata.normalize("NFD", text)

        is_nfc = (text == nfc)
        is_nfd = (text == nfd)

        combining_count = 0
        found_accents = []
        controls = []
        has_zwj = False
        has_zwnj = False

        for ch in text:
            cat = unicodedata.category(ch)
            # Combining marks (Mn: Nonspacing_Mark, Mc: Spacing_Combining_Mark, Me: Enclosing_Mark)
            if cat.startswith("M"):
                combining_count += 1

            if ch in cls.VEDIC_ACCENTS_SET:
                found_accents.append(ch)

            if ch == cls.ZWJ:
                has_zwj = True
            elif ch == cls.ZWNJ:
                has_zwnj = True
            elif cat.startswith("C") and ch not in "\r\n\t":
                controls.append(f"U+{ord(ch):04X}")

        det = MultilingualScriptRegistry.detect_script(text)

        return UnicodeFidelityReport(
            original_text=text,
            nfc_text=nfc,
            nfd_text=nfd,
            is_nfc_normalized=is_nfc,
            is_nfd_normalized=is_nfd,
            byte_count_utf8=len(text.encode("utf-8")),
            char_count=len(text),
            combining_mark_count=combining_count,
            vedic_accent_count=len(found_accents),
            vedic_accents=tuple(found_accents),
            has_zwj=has_zwj,
            has_zwnj=has_zwnj,
            control_characters=tuple(controls),
            script_detected=det["primary_script"],
            is_pure_script=not det["is_mixed_script"],
        )

    @classmethod
    def verify_nfc_equality(cls, str1: str, str2: str) -> bool:
        """
        Tests whether two strings are canonically equivalent under Unicode NFC
        without modifying either string.
        """
        return unicodedata.normalize("NFC", str1) == unicodedata.normalize("NFC", str2)
