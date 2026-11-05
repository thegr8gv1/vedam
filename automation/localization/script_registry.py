"""
Vedic Heritage Platform — Centralized Multilingual Script Registry & Detector
Part C.3: Authoritative script definitions, writing directions, Unicode block mappings,
script detection, mixed-script identification, and language-script compatibility validation.

Rules:
- Script identity is completely decoupled from Language identity.
- Shared scripts (e.g. Devanagari shared by Sanskrit, Hindi, Marathi, Nepali) must never
  be used to infer language identity with certainty.
- Bi-directional text flows (LTR vs RTL) are explicitly modeled for rendering and exporters.
- Strict detection with confidence scoring and ambiguity flags.
"""

from dataclasses import dataclass, field
import enum
import re
from typing import Any, Dict, List, Optional, Set, Tuple
import unicodedata


class ScriptDirection(str, enum.Enum):
    LTR = "ltr"  # Left-to-Right
    RTL = "rtl"  # Right-to-Left


class ScriptCategory(str, enum.Enum):
    BRAHMIC_INDIC = "Brahmic Indic"
    PERSO_ARABIC = "Perso-Arabic"
    INDIGENOUS = "Indigenous Indic"
    LATIN_ROMANIC = "Latin Romanic"


@dataclass(frozen=True)
class UnicodeBlock:
    start: int
    end: int
    name: str

    def contains(self, char: str) -> bool:
        if not char:
            return False
        return self.start <= ord(char) <= self.end


@dataclass(frozen=True)
class ScriptProfile:
    iso_15924: str                     # 4-letter ISO 15924 script code (e.g. Deva, Telu, Arab)
    name: str                          # Canonical English script name
    native_name: str                   # Script autonym in its native script
    direction: ScriptDirection         # LTR or RTL
    category: ScriptCategory           # Brahmic, Perso-Arabic, Indigenous, Latin
    unicode_blocks: Tuple[UnicodeBlock, ...]
    supports_vedic_swaras: bool        # Direct combining tone support
    requires_opentype_shaping: bool    # HarfBuzz / Uniscribe complex shaping needed
    recommended_fonts: Tuple[str, ...]
    primary_languages: Tuple[str, ...] # Primary languages using this script


class MultilingualScriptRegistry:
    """Central registry and inspection engine for all platform-supported scripts."""

    # -----------------------------------------------------------------------
    # Canonical Script Profiles (14 Scripts)
    # -----------------------------------------------------------------------
    SCRIPTS: Dict[str, ScriptProfile] = {
        "Deva": ScriptProfile(
            iso_15924="Deva",
            name="Devanagari",
            native_name="देवनागरी",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0900, 0x097F, "Devanagari"),
                UnicodeBlock(0xA8E0, 0xA8FF, "Devanagari Extended"),
                UnicodeBlock(0x1CD0, 0x1CFA, "Vedic Extensions"),
            ),
            supports_vedic_swaras=True,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Noto Sans Devanagari", "Siddhanta"),
            primary_languages=("sa", "hi", "mr", "ne", "kok", "doi", "brx", "mai", "awa"),
        ),
        "Telu": ScriptProfile(
            iso_15924="Telu",
            name="Telugu",
            native_name="తెలుగు",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0C00, 0x0C7F, "Telugu"),
                UnicodeBlock(0x1CD0, 0x1CFA, "Vedic Extensions"),
            ),
            supports_vedic_swaras=True,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Gautami", "Noto Sans Telugu"),
            primary_languages=("te", "sa"),
        ),
        "Taml": ScriptProfile(
            iso_15924="Taml",
            name="Tamil",
            native_name="தமிழ்",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0B80, 0x0BFF, "Tamil"),
                UnicodeBlock(0x11300, 0x1137F, "Grantha"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Latha", "Noto Sans Tamil"),
            primary_languages=("ta",),
        ),
        "Gran": ScriptProfile(
            iso_15924="Gran",
            name="Grantha",
            native_name="𑌗𑍍𑌰𑌨𑍍𑌥",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x11300, 0x1137F, "Grantha"),
                UnicodeBlock(0x1CD0, 0x1CFA, "Vedic Extensions"),
            ),
            supports_vedic_swaras=True,
            requires_opentype_shaping=True,
            recommended_fonts=("Noto Sans Grantha", "e-Grantha"),
            primary_languages=("sa", "ta"),
        ),
        "Knda": ScriptProfile(
            iso_15924="Knda",
            name="Kannada",
            native_name="ಕನ್ನಡ",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0C80, 0x0CFF, "Kannada"),
                UnicodeBlock(0x1CD0, 0x1CFA, "Vedic Extensions"),
            ),
            supports_vedic_swaras=True,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Tunga", "Noto Sans Kannada"),
            primary_languages=("kn", "sa", "kok"),
        ),
        "Mlym": ScriptProfile(
            iso_15924="Mlym",
            name="Malayalam",
            native_name="മലയാളം",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0D00, 0x0D7F, "Malayalam"),
                UnicodeBlock(0x1CD0, 0x1CFA, "Vedic Extensions"),
            ),
            supports_vedic_swaras=True,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Kartika", "Noto Sans Malayalam"),
            primary_languages=("ml", "sa"),
        ),
        "Beng": ScriptProfile(
            iso_15924="Beng",
            name="Bengali-Assamese",
            native_name="বাংলা-অসমীয়া",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0980, 0x09FF, "Bengali"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Vrinda", "Noto Sans Bengali"),
            primary_languages=("bn", "as", "mni", "sa"),
        ),
        "Gujr": ScriptProfile(
            iso_15924="Gujr",
            name="Gujarati",
            native_name="ગુજરાતી",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0A80, 0x0AFF, "Gujarati"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Shruti", "Noto Sans Gujarati"),
            primary_languages=("gu", "sa"),
        ),
        "Guru": ScriptProfile(
            iso_15924="Guru",
            name="Gurmukhi",
            native_name="ਗੁਰਮੁਖੀ",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0A00, 0x0A7F, "Gurmukhi"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Raavi", "Noto Sans Gurmukhi"),
            primary_languages=("pa",),
        ),
        "Orya": ScriptProfile(
            iso_15924="Orya",
            name="Odia",
            native_name="ଓଡ଼ିଆ",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.BRAHMIC_INDIC,
            unicode_blocks=(
                UnicodeBlock(0x0B00, 0x0B7F, "Oriya"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Nirmala UI", "Kalinga", "Noto Sans Oriya"),
            primary_languages=("or", "sa"),
        ),
        "Olck": ScriptProfile(
            iso_15924="Olck",
            name="Ol Chiki",
            native_name="ᱥᱟᱱᱛᱟᱲᱤ",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.INDIGENOUS,
            unicode_blocks=(
                UnicodeBlock(0x1C50, 0x1C7F, "Ol Chiki"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=False,
            recommended_fonts=("Nirmala UI", "Noto Sans Ol Chiki"),
            primary_languages=("sat",),
        ),
        "Mtei": ScriptProfile(
            iso_15924="Mtei",
            name="Meetei Mayek",
            native_name="ꯃৈতৈ ꯃꯌꯦꯛ",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.INDIGENOUS,
            unicode_blocks=(
                UnicodeBlock(0xABC0, 0xABFF, "Meetei Mayek"),
                UnicodeBlock(0xAAE0, 0xAAFF, "Meetei Mayek Extensions"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Noto Sans Meetei Mayek",),
            primary_languages=("mni",),
        ),
        "Arab": ScriptProfile(
            iso_15924="Arab",
            name="Perso-Arabic",
            native_name="اُردُو / العربية",
            direction=ScriptDirection.RTL,
            category=ScriptCategory.PERSO_ARABIC,
            unicode_blocks=(
                UnicodeBlock(0x0600, 0x06FF, "Arabic"),
                UnicodeBlock(0x0750, 0x077F, "Arabic Supplement"),
                UnicodeBlock(0x08A0, 0x08FF, "Arabic Extended-A"),
                UnicodeBlock(0xFB50, 0xFDFF, "Arabic Presentation Forms-A"),
                UnicodeBlock(0xFE70, 0xFEFF, "Arabic Presentation Forms-B"),
            ),
            supports_vedic_swaras=False,
            requires_opentype_shaping=True,
            recommended_fonts=("Noto Nastaliq Urdu", "Jameel Noori Nastaleeq", "Arial"),
            primary_languages=("ur", "ks", "sd"),
        ),
        "Latn": ScriptProfile(
            iso_15924="Latn",
            name="Latin (IAST / English)",
            native_name="Latin",
            direction=ScriptDirection.LTR,
            category=ScriptCategory.LATIN_ROMANIC,
            unicode_blocks=(
                UnicodeBlock(0x0020, 0x007F, "Basic Latin"),
                UnicodeBlock(0x0080, 0x00FF, "Latin-1 Supplement"),
                UnicodeBlock(0x0100, 0x017F, "Latin Extended-A"),
                UnicodeBlock(0x0180, 0x024F, "Latin Extended-B"),
                UnicodeBlock(0x1E00, 0x1EFF, "Latin Extended Additional"),  # Essential for IAST
                UnicodeBlock(0x0300, 0x036F, "Combining Diacritical Marks"),
            ),
            supports_vedic_swaras=True,  # Combining acute / grave / macron below
            requires_opentype_shaping=False,
            recommended_fonts=("Charis SIL", "Gentium Plus", "Segoe UI", "Calibri"),
            primary_languages=("en", "sa"),
        ),
    }

    # -----------------------------------------------------------------------
    # Query & Validation Methods
    # -----------------------------------------------------------------------
    @classmethod
    def get_script(cls, code: str) -> Optional[ScriptProfile]:
        """Resolves a script profile by 4-letter ISO 15924 code or common name."""
        if not code:
            return None
        c_title = code.strip().capitalize()
        if c_title in cls.SCRIPTS:
            return cls.SCRIPTS[c_title]
        # Search by name
        c_lower = code.strip().lower()
        for p in cls.SCRIPTS.values():
            if p.name.lower() == c_lower or p.iso_15924.lower() == c_lower:
                return p
        return None

    @classmethod
    def detect_script(cls, text: str) -> Dict[str, Any]:
        """
        Analyzes a string and identifies its script composition.
        Returns:
            - primary_script: ISO 15924 code of dominant script
            - confidence: float 0.0 to 1.0 (proportion of recognized letters)
            - script_distribution: dict mapping script codes to character counts
            - is_mixed_script: boolean true if multiple scripts detected
            - unsupported_characters: list of characters outside all known blocks
            - direction: dominant writing direction ('ltr' or 'rtl')
            - ambiguity_flag: boolean true if multiple scripts share substantial counts
        """
        if not text or not text.strip():
            return {
                "primary_script": "Latn",
                "confidence": 0.0,
                "script_distribution": {},
                "is_mixed_script": False,
                "unsupported_characters": [],
                "direction": "ltr",
                "ambiguity_flag": False,
            }

        distribution: Dict[str, int] = {}
        unsupported: List[str] = []
        total_counted = 0

        # Ignore common punctuation, numbers, and whitespace during initial script counting
        common_symbols = set(" \t\r\n.,;:!?()[]{}\"'`~@#$%^&*-_+=|\\/<>0123456789।॥–—")

        for ch in text:
            if ch in common_symbols:
                continue

            matched_script = None
            for script_code, profile in cls.SCRIPTS.items():
                for block in profile.unicode_blocks:
                    if block.contains(ch):
                        matched_script = script_code
                        break
                if matched_script:
                    break

            if matched_script:
                distribution[matched_script] = distribution.get(matched_script, 0) + 1
                total_counted += 1
            else:
                unsupported.append(ch)

        if not distribution:
            return {
                "primary_script": "Latn",
                "confidence": 0.0,
                "script_distribution": {},
                "is_mixed_script": False,
                "unsupported_characters": unsupported,
                "direction": "ltr",
                "ambiguity_flag": False,
            }

        sorted_scripts = sorted(distribution.items(), key=lambda x: x[1], reverse=True)
        primary_script, primary_count = sorted_scripts[0]
        confidence = primary_count / total_counted if total_counted > 0 else 0.0

        is_mixed = len(distribution) > 1
        ambiguity = False
        if len(sorted_scripts) > 1:
            second_script, second_count = sorted_scripts[1]
            if (second_count / total_counted) >= 0.25:
                ambiguity = True

        profile = cls.SCRIPTS[primary_script]

        return {
            "primary_script": primary_script,
            "confidence": round(confidence, 4),
            "script_distribution": distribution,
            "is_mixed_script": is_mixed,
            "unsupported_characters": unsupported[:50],  # Cap list to prevent payload bloat
            "direction": profile.direction.value,
            "ambiguity_flag": ambiguity,
        }

    @classmethod
    def validate_script_for_language(cls, lang_code: str, script_code: str) -> Tuple[bool, Optional[str]]:
        """
        Validates whether a script is officially supported for a specific language
        under project orthographic and liturgical standards.
        """
        from automation.localization.registry import MultilingualRegistry

        lang = MultilingualRegistry.get_language(lang_code)
        if not lang:
            return False, f"Unrecognized language code: '{lang_code}'."

        script = cls.get_script(script_code)
        if not script:
            return False, f"Unrecognized script code: '{script_code}'."

        s_code = script.iso_15924
        if s_code not in lang.supported_scripts:
            return False, (
                f"Script '{s_code}' ({script.name}) is not registered for language '{lang.iso_639_1}' ({lang.name}). "
                f"Supported scripts: {lang.supported_scripts}."
            )

        return True, None

    @classmethod
    def is_rtl(cls, script_or_lang_code: str) -> bool:
        """Determines if a script or language is right-to-left."""
        # Check script
        script = cls.get_script(script_or_lang_code)
        if script:
            return script.direction == ScriptDirection.RTL

        # Check language
        from automation.localization.registry import MultilingualRegistry
        lang = MultilingualRegistry.get_language(script_or_lang_code)
        if lang:
            primary_s = cls.get_script(lang.primary_script)
            if primary_s:
                return primary_s.direction == ScriptDirection.RTL

        return False
