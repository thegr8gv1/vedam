"""
Vedic Heritage Platform — Bidirectional (BiDi) & RTL Layout Engine
Part D.3: Standards-compliant Right-to-Left (RTL) layout management,
mixed-directionality isolation (<bdi>), Arabic contextual shaping, and typography layout.
"""

from dataclasses import dataclass
import enum
import html
import logging
import re
from typing import Any, Dict, List, Optional, Tuple
import unicodedata

from automation.localization.script_registry import MultilingualScriptRegistry, ScriptDirection

logger = logging.getLogger("vedam.automation.exporters.bidi_layout")


class BidiDirection(str, enum.Enum):
    LTR = "ltr"
    RTL = "rtl"
    AUTO = "auto"


# ---------------------------------------------------------------------------
# Arabic Contextual Glyphs (Presentation Forms-B)
# Enables correct cursive joining in PDF environments without external packages.
# Map: Base Unicode -> (Isolated, Final, Initial, Medial)
# ---------------------------------------------------------------------------
ARABIC_JOINING_MAP: Dict[str, Tuple[str, str, str, str]] = {
    # Hamza / Alif
    "\u0621": ("\uFE80", "\uFE80", "\uFE80", "\uFE80"),  # ء
    "\u0622": ("\uFE81", "\uFE82", "\uFE81", "\uFE82"),  # آ (non-connector)
    "\u0623": ("\uFE83", "\uFE84", "\uFE83", "\uFE84"),  # أ (non-connector)
    "\u0624": ("\uFE85", "\uFE86", "\uFE85", "\uFE86"),  # ؤ (non-connector)
    "\u0625": ("\uFE87", "\uFE88", "\uFE87", "\uFE88"),  # إ (non-connector)
    "\u0626": ("\uFE89", "\uFE8A", "\uFE8B", "\uFE8C"),  # ئ
    "\u0627": ("\uFE8D", "\uFE8E", "\uFE8D", "\uFE8E"),  # ا (non-connector)
    # Baa, Taa, Thaa
    "\u0628": ("\uFE8F", "\uFE90", "\uFE91", "\uFE92"),  # ب
    "\u0629": ("\uFE93", "\uFE94", "\uFE93", "\uFE94"),  # ة
    "\u062A": ("\uFE95", "\uFE96", "\uFE97", "\uFE98"),  # ت
    "\u062B": ("\uFE99", "\uFE9A", "\uFE9B", "\uFE9C"),  # ث
    # Jeem, Haa, Khaa
    "\u062C": ("\uFE9D", "\uFE9E", "\uFE9F", "\uFEA0"),  # ج
    "\u062D": ("\uFEA1", "\uFEA2", "\uFEA3", "\uFEA4"),  # ح
    "\u062E": ("\uFEA5", "\uFEA6", "\uFEA7", "\uFEA8"),  # خ
    # Dal, Dhal, Raa, Zay (non-connectors)
    "\u062F": ("\uFEA9", "\uFEAA", "\uFEA9", "\uFEAA"),  # د
    "\u0630": ("\uFEAB", "\uFEAC", "\uFEAB", "\uFEAC"),  # ذ
    "\u0631": ("\uFEAD", "\uFEAE", "\uFEAD", "\uFEAE"),  # ر
    "\u0632": ("\uFEAF", "\uFEB0", "\uFEAF", "\uFEB0"),  # ز
    # Seen, Sheen, Saad, Daad
    "\u0633": ("\uFEB1", "\uFEB2", "\uFEB3", "\uFEB4"),  # س
    "\u0634": ("\uFEB5", "\uFEB6", "\uFEB7", "\uFEB8"),  # ش
    "\u0635": ("\uFEB9", "\uFEBA", "\uFEBB", "\uFEBC"),  # ص
    "\u0636": ("\uFEBD", "\uFEBE", "\uFEBF", "\uFEC0"),  # ض
    # Taa, Zaa
    "\u0637": ("\uFEC1", "\uFEC2", "\uFEC3", "\uFEC4"),  # ط
    "\u0638": ("\uFEC5", "\uFEC6", "\uFEC7", "\uFEC8"),  # ظ
    # Ayn, Ghayn
    "\u0639": ("\uFEC9", "\uFECA", "\uFECB", "\uFECC"),  # ع
    "\u063A": ("\uFECD", "\uFECE", "\uFECF", "\uFED0"),  # غ
    # Faa, Qaaf, Kaaf, Laam, Meem, Noon, Haa, Waaw, Yaa
    "\u0641": ("\uFED1", "\uFED2", "\uFED3", "\uFED4"),  # ف
    "\u0642": ("\uFED5", "\uFED6", "\uFED7", "\uFED8"),  # ق
    "\u0643": ("\uFED9", "\uFEDA", "\uFEDB", "\uFEDC"),  # ك
    "\u0644": ("\uFEDD", "\uFEDE", "\uFEDF", "\uFEE0"),  # ل
    "\u0645": ("\uFEE1", "\uFEE2", "\uFEE3", "\uFEE4"),  # م
    "\u0646": ("\uFEE5", "\uFEE6", "\uFEE7", "\uFEE8"),  # ن
    "\u0647": ("\uFEE9", "\uFEEA", "\uFEEB", "\uFEEC"),  # ه
    "\u0648": ("\uFEED", "\uFEEE", "\uFEED", "\uFEEE"),  # و (non-connector)
    "\u0649": ("\uFEEF", "\uFEF0", "\uFBE8", "\uFBE9"),  # ى
    "\u064A": ("\uFEF1", "\uFEF2", "\uFEF3", "\uFEF4"),  # ي
    # Urdu extensions (Peh, Tteh, Cheh, Dal retroflex, Raa retroflex, Gaf, Choti Yeh, Bari Yeh)
    "\u067E": ("\uFB56", "\uFB57", "\uFB58", "\uFB59"),  # پ
    "\u0679": ("\uFB66", "\uFB67", "\uFB68", "\uFB69"),  # ٹ
    "\u0686": ("\uFB7A", "\uFB7B", "\uFB7C", "\uFB7D"),  # چ
    "\u0688": ("\uFB88", "\uFB89", "\uFB88", "\uFB89"),  # ڈ (non-connector)
    "\u0691": ("\uFB8C", "\uFB8D", "\uFB8C", "\uFB8D"),  # ڑ (non-connector)
    "\u0698": ("\uFB8A", "\uFB8B", "\uFB8A", "\uFB8B"),  # ژ (non-connector)
    "\u06A9": ("\uFB8E", "\uFB8F", "\uFB90", "\uFB91"),  # ک
    "\u06AF": ("\uFB92", "\uFB93", "\uFB94", "\uFB95"),  # گ
    "\u06BA": ("\uFB9E", "\uFB9F", "\uFB9E", "\uFB9F"),  # ں
    "\u06D2": ("\uFBAE", "\uFBAF", "\uFBAE", "\uFBAF"),  # ے
    "\u06BE": ("\uFBAA", "\uFBAB", "\uFBAC", "\uFBAD"),  # ھ
}

# Letters that do NOT connect to the following letter (right-joining only)
NON_CONNECTORS = {
    "\u0622", "\u0623", "\u0624", "\u0625", "\u0627", "\u062F", "\u0630",
    "\u0631", "\u0632", "\u0648", "\u0688", "\u0691", "\u0698"
}

# Arabic diacritical marks (Tashkeel / Aerab)
AERAB_MARKS = {
    "\u064B", "\u064C", "\u064D", "\u064E", "\u064F", "\u0650",
    "\u0651", "\u0652", "\u0653", "\u0654", "\u0670"
}


class BidiLayoutEngine:
    """
    Bidirectional layout and text processing engine for HTML, PDF, DOCX, and EPUB.
    """

    @classmethod
    def is_rtl(cls, script_or_lang_code: str) -> bool:
        """Determines if a script or language is right-to-left."""
        return MultilingualScriptRegistry.is_rtl(script_or_lang_code)

    @classmethod
    def has_rtl_characters(cls, text: str) -> bool:
        """Detects whether a string contains Right-to-Left or Arabic-letter characters."""
        if not text:
            return False
        for ch in text:
            bidi_type = unicodedata.bidirectional(ch)
            if bidi_type in ("R", "AL"):
                return True
        return False

    @classmethod
    def get_text_direction(cls, text: str) -> BidiDirection:
        """Determines the primary text direction of a string."""
        return BidiDirection.RTL if cls.has_rtl_characters(text) else BidiDirection.LTR

    @classmethod
    def wrap_html_bidi(
        cls,
        text: str,
        base_dir: Any = "ltr",
        allow_tags: bool = False,
        is_rtl: Optional[bool] = None,
    ) -> str:
        """
        Wraps mixed-directionality text in accessible HTML markup.
        Prevents LTR embedded tokens (verse numbers, Latin IDs) from corrupting RTL punctuation.
        """
        if not text:
            return ""

        escaped = text if allow_tags else html.escape(text)

        target_rtl = is_rtl if is_rtl is not None else (base_dir is True or str(base_dir).lower() == "rtl")
        dir_val = "rtl" if target_rtl else "ltr"

        # If base is RTL, isolate embedded Latin or numbers using <bdi dir="ltr">
        if target_rtl:
            # Pattern matching Latin words, verse IDs, numbers
            def isolate_ltr(match):
                token = match.group(0)
                return f'<bdi dir="ltr">{token}</bdi>'

            # Protect Latin words and IDs
            processed = re.sub(r"[A-Za-z0-9_-]+(?:[:.][A-Za-z0-9_-]+)*", isolate_ltr, escaped)
            return f'<div dir="rtl" class="bidi-rtl">{processed}</div>'
        else:
            # If base is LTR and contains RTL characters, isolate with <bdi dir="rtl">
            if cls.has_rtl_characters(text):
                def isolate_rtl(match):
                    token = match.group(0)
                    return f'<bdi dir="rtl">{token}</bdi>'
                # Match Arabic character sequences
                processed = re.sub(r"[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\s]+", isolate_rtl, escaped)
                return f'<div dir="ltr" class="bidi-ltr">{processed}</div>'

        return f'<div dir="{dir_val}">{escaped}</div>'

    @classmethod
    def shape_arabic_for_pdf(cls, text: str) -> str:
        """
        Applies standard Arabic contextual shaping (Isolated, Initial, Medial, Final)
        to Arabic/Urdu text strings for print PDF canvas rendering where HarfBuzz is unavailable.
        Maintains diacritical marks and numbers correctly.
        """
        if not text or not cls.has_rtl_characters(text):
            return text

        words = text.split(" ")
        shaped_words = []

        for word in words:
            if not cls.has_rtl_characters(word):
                shaped_words.append(word)
                continue

            # Filter characters into base and diacritics
            chars = list(word)
            n = len(chars)
            shaped_chars = []

            for i in range(n):
                ch = chars[i]

                # Non-Arabic or diacritic stays as-is
                if ch not in ARABIC_JOINING_MAP:
                    shaped_chars.append(ch)
                    continue

                prev_char = chars[i - 1] if i > 0 else None
                next_char = chars[i + 1] if i + 1 < n else None

                # Skip diacritics when inspecting neighbors
                p_idx = i - 1
                while p_idx >= 0 and chars[p_idx] in AERAB_MARKS:
                    p_idx -= 1
                prev_char = chars[p_idx] if p_idx >= 0 else None

                n_idx = i + 1
                while n_idx < n and chars[n_idx] in AERAB_MARKS:
                    n_idx += 1
                next_char = chars[n_idx] if n_idx < n else None

                prev_connects = (prev_char in ARABIC_JOINING_MAP and prev_char not in NON_CONNECTORS)
                next_connects = (next_char in ARABIC_JOINING_MAP)

                forms = ARABIC_JOINING_MAP[ch]

                if prev_connects and next_connects:
                    shaped_chars.append(forms[3])  # Medial
                elif prev_connects and not next_connects:
                    shaped_chars.append(forms[1])  # Final
                elif not prev_connects and next_connects:
                    shaped_chars.append(forms[2])  # Initial
                else:
                    shaped_chars.append(forms[0])  # Isolated

            # In standard PDF without native bidi engine, reverse shaped Arabic words
            # so left-to-right PDF pen draws right-to-left visually
            reversed_word = "".join(reversed(shaped_chars))
            shaped_words.append(reversed_word)

        # Reverse word sequence for visual right-to-left ordering on canvas
        return " ".join(reversed(shaped_words))
