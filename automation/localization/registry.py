"""
Vedic Heritage Platform — Multilingual Language & Script Architecture Registry
Part C.1: Normalized language and script definitions for all 22 Scheduled Indian Languages
of the Eighth Schedule + English as global bridge language.

Rules:
- Language identifiers (ISO 639-1 / ISO 639-3) decoupled from Script identifiers (ISO 15924).
- One language can support multiple scripts (e.g. Sanskrit in Devanagari, Telugu, Grantha, etc.).
- One script can support multiple languages (e.g. Devanagari for Sanskrit, Hindi, Marathi, Nepali, Bodo).
- Sanskrit is properly listed as one of the 22 scheduled languages (never counted twice).
"""

from dataclasses import dataclass, field
import enum
from typing import Dict, List, Optional, Set


class LanguageFamily(str, enum.Enum):
    INDO_ARYAN = "Indo-Aryan"
    DRAVIDIAN = "Dravidian"
    TIBETO_BURMAN = "Tibeto-Burman"
    AUSTROASIATIC = "Austroasiatic"
    GERMANIC = "Germanic"


@dataclass(frozen=True)
class ScriptDefinition:
    iso_15924: str               # 4-letter ISO 15924 code (e.g. Deva, Telu, Taml, Gran)
    name: str                    # English name
    native_name: str             # Script autonym in its own script
    direction: str = "ltr"       # ltr or rtl
    supports_vedic_swaras: bool = False
    requires_opentype_shaping: bool = True
    recommended_fonts: List[str] = field(default_factory=list)


@dataclass(frozen=True)
class LanguageDefinition:
    iso_639_1: str               # 2-letter ISO 639-1 code (e.g. hi, te, ta, kn, sa, en)
    iso_639_3: str               # 3-letter ISO 639-3 code (e.g. hin, tel, tam, kan, san, eng)
    bcp47: str                   # Primary BCP-47 tag (e.g. sa-Deva, hi-Deva, te-Telu)
    name: str                    # English canonical name
    native_name: str             # Autonym in primary script
    family: LanguageFamily
    is_eighth_schedule: bool     # True for the 22 Scheduled Indian Languages
    primary_script: str          # Primary ISO 15924 code
    supported_scripts: List[str] = field(default_factory=list)
    has_sacred_liturgical_tradition: bool = True


class MultilingualRegistry:
    """Canonical registry of languages, scripts, and orthographic mappings."""

    # -----------------------------------------------------------------------
    # ISO 15924 Script Definitions
    # -----------------------------------------------------------------------
    SCRIPTS: Dict[str, ScriptDefinition] = {
        "Deva": ScriptDefinition(
            iso_15924="Deva",
            name="Devanagari",
            native_name="देवनागरी",
            supports_vedic_swaras=True,
            recommended_fonts=["Nirmala UI", "Noto Sans Devanagari", "Siddhanta"],
        ),
        "Telu": ScriptDefinition(
            iso_15924="Telu",
            name="Telugu",
            native_name="తెలుగు",
            supports_vedic_swaras=True,
            recommended_fonts=["Nirmala UI", "Gautami", "Noto Sans Telugu"],
        ),
        "Taml": ScriptDefinition(
            iso_15924="Taml",
            name="Tamil",
            native_name="தமிழ்",
            supports_vedic_swaras=False,  # Classical Tamil lacks plosive voicing distinctions
            recommended_fonts=["Nirmala UI", "Latha", "Noto Sans Tamil"],
        ),
        "Gran": ScriptDefinition(
            iso_15924="Gran",
            name="Grantha",
            native_name="𑌗𑍍𑌰𑌨𑍍𑌥",
            supports_vedic_swaras=True,   # Traditional South Indian Vedic script
            recommended_fonts=["Noto Sans Grantha", "e-Grantha"],
        ),
        "Knda": ScriptDefinition(
            iso_15924="Knda",
            name="Kannada",
            native_name="ಕನ್ನಡ",
            supports_vedic_swaras=True,
            recommended_fonts=["Nirmala UI", "Tunga", "Noto Sans Kannada"],
        ),
        "Mlym": ScriptDefinition(
            iso_15924="Mlym",
            name="Malayalam",
            native_name="മലയാളം",
            supports_vedic_swaras=True,
            recommended_fonts=["Nirmala UI", "Kartika", "Noto Sans Malayalam"],
        ),
        "Beng": ScriptDefinition(
            iso_15924="Beng",
            name="Bengali-Assamese",
            native_name="বাংলা-অসমীয়া",
            supports_vedic_swaras=False,
            recommended_fonts=["Nirmala UI", "Vrinda", "Noto Sans Bengali"],
        ),
        "Gujr": ScriptDefinition(
            iso_15924="Gujr",
            name="Gujarati",
            native_name="ગુજરાતી",
            supports_vedic_swaras=False,
            recommended_fonts=["Nirmala UI", "Shruti", "Noto Sans Gujarati"],
        ),
        "Guru": ScriptDefinition(
            iso_15924="Guru",
            name="Gurmukhi",
            native_name="ਗੁਰਮੁਖੀ",
            supports_vedic_swaras=False,
            recommended_fonts=["Nirmala UI", "Raavi", "Noto Sans Gurmukhi"],
        ),
        "Orya": ScriptDefinition(
            iso_15924="Orya",
            name="Odia",
            native_name="ଓଡ଼ିଆ",
            supports_vedic_swaras=False,
            recommended_fonts=["Nirmala UI", "Kalinga", "Noto Sans Oriya"],
        ),
        "Olck": ScriptDefinition(
            iso_15924="Olck",
            name="Ol Chiki",
            native_name="ᱚᱞ ᱪᱤᱠᱤ",
            supports_vedic_swaras=False,
            recommended_fonts=["Noto Sans Ol Chiki"],
        ),
        "Mtei": ScriptDefinition(
            iso_15924="Mtei",
            name="Meetei Mayek",
            native_name="ꯃꯤꯇꯩ ꯃꯌꯦꯛ",
            supports_vedic_swaras=False,
            recommended_fonts=["Noto Sans Meetei Mayek"],
        ),
        "Arab": ScriptDefinition(
            iso_15924="Arab",
            name="Perso-Arabic",
            native_name="اُردُو / کٲشُر",
            direction="rtl",
            supports_vedic_swaras=False,
            recommended_fonts=["Noto Nastaliq Urdu", "Arial"],
        ),
        "Latn": ScriptDefinition(
            iso_15924="Latn",
            name="Latin / IAST",
            native_name="IAST / English",
            supports_vedic_swaras=True,   # Via combining diacritics
            requires_opentype_shaping=False,
            recommended_fonts=["Calibri", "Segoe UI", "Gentium Plus", "Noto Serif"],
        ),
    }

    # -----------------------------------------------------------------------
    # The 22 Scheduled Indian Languages + English (23 Total)
    # -----------------------------------------------------------------------
    LANGUAGES: Dict[str, LanguageDefinition] = {
        # 1. Sanskrit (Eighth Schedule Language #17 alphabetically, primary liturgical root)
        "sa": LanguageDefinition(
            iso_639_1="sa",
            iso_639_3="san",
            bcp47="sa-Deva",
            name="Sanskrit",
            native_name="संस्कृतम्",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Telu", "Gran", "Taml", "Knda", "Mlym", "Beng", "Gujr", "Orya", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 2. Hindi
        "hi": LanguageDefinition(
            iso_639_1="hi",
            iso_639_3="hin",
            bcp47="hi-Deva",
            name="Hindi",
            native_name="हिन्दी",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 3. Telugu
        "te": LanguageDefinition(
            iso_639_1="te",
            iso_639_3="tel",
            bcp47="te-Telu",
            name="Telugu",
            native_name="తెలుగు",
            family=LanguageFamily.DRAVIDIAN,
            is_eighth_schedule=True,
            primary_script="Telu",
            supported_scripts=["Telu", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 4. Tamil
        "ta": LanguageDefinition(
            iso_639_1="ta",
            iso_639_3="tam",
            bcp47="ta-Taml",
            name="Tamil",
            native_name="தமிழ்",
            family=LanguageFamily.DRAVIDIAN,
            is_eighth_schedule=True,
            primary_script="Taml",
            supported_scripts=["Taml", "Gran", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 5. Kannada
        "kn": LanguageDefinition(
            iso_639_1="kn",
            iso_639_3="kan",
            bcp47="kn-Knda",
            name="Kannada",
            native_name="ಕನ್ನಡ",
            family=LanguageFamily.DRAVIDIAN,
            is_eighth_schedule=True,
            primary_script="Knda",
            supported_scripts=["Knda", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 6. Malayalam
        "ml": LanguageDefinition(
            iso_639_1="ml",
            iso_639_3="mal",
            bcp47="ml-Mlym",
            name="Malayalam",
            native_name="മലയാളം",
            family=LanguageFamily.DRAVIDIAN,
            is_eighth_schedule=True,
            primary_script="Mlym",
            supported_scripts=["Mlym", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 7. Bengali
        "bn": LanguageDefinition(
            iso_639_1="bn",
            iso_639_3="ben",
            bcp47="bn-Beng",
            name="Bengali",
            native_name="বাংলা",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Beng",
            supported_scripts=["Beng", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 8. Gujarati
        "gu": LanguageDefinition(
            iso_639_1="gu",
            iso_639_3="guj",
            bcp47="gu-Gujr",
            name="Gujarati",
            native_name="ગુજરાતી",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Gujr",
            supported_scripts=["Gujr", "Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 9. Marathi
        "mr": LanguageDefinition(
            iso_639_1="mr",
            iso_639_3="mar",
            bcp47="mr-Deva",
            name="Marathi",
            native_name="मराठी",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 10. Odia
        "or": LanguageDefinition(
            iso_639_1="or",
            iso_639_3="ori",
            bcp47="or-Orya",
            name="Odia",
            native_name="ଓଡ଼ିଆ",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Orya",
            supported_scripts=["Orya", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 11. Punjabi
        "pa": LanguageDefinition(
            iso_639_1="pa",
            iso_639_3="pan",
            bcp47="pa-Guru",
            name="Punjabi",
            native_name="ਪੰਜਾਬੀ",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Guru",
            supported_scripts=["Guru", "Deva", "Arab", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 12. Assamese
        "as": LanguageDefinition(
            iso_639_1="as",
            iso_639_3="asm",
            bcp47="as-Beng",
            name="Assamese",
            native_name="অসমীয়া",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Beng",
            supported_scripts=["Beng", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 13. Maithili
        "mai": LanguageDefinition(
            iso_639_1="mai",
            iso_639_3="mai",
            bcp47="mai-Deva",
            name="Maithili",
            native_name="मैथिली",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 14. Nepali
        "ne": LanguageDefinition(
            iso_639_1="ne",
            iso_639_3="nep",
            bcp47="ne-Deva",
            name="Nepali",
            native_name="नेपाली",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 15. Konkani
        "kok": LanguageDefinition(
            iso_639_1="kok",
            iso_639_3="kok",
            bcp47="kok-Deva",
            name="Konkani",
            native_name="कोंकणी",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Knda", "Mlym", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 16. Dogri
        "doi": LanguageDefinition(
            iso_639_1="doi",
            iso_639_3="doi",
            bcp47="doi-Deva",
            name="Dogri",
            native_name="डोगरी",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 17. Bodo
        "brx": LanguageDefinition(
            iso_639_1="brx",
            iso_639_3="brx",
            bcp47="brx-Deva",
            name="Bodo",
            native_name="बर'",
            family=LanguageFamily.TIBETO_BURMAN,
            is_eighth_schedule=True,
            primary_script="Deva",
            supported_scripts=["Deva", "Beng", "Latn"],
            has_sacred_liturgical_tradition=False,
        ),
        # 18. Santali
        "sat": LanguageDefinition(
            iso_639_1="sat",
            iso_639_3="sat",
            bcp47="sat-Olck",
            name="Santali",
            native_name="ᱥᱟᱱᱛᱟᱲᱤ",
            family=LanguageFamily.AUSTROASIATIC,
            is_eighth_schedule=True,
            primary_script="Olck",
            supported_scripts=["Olck", "Deva", "Beng", "Orya", "Latn"],
            has_sacred_liturgical_tradition=False,
        ),
        # 19. Kashmiri
        "ks": LanguageDefinition(
            iso_639_1="ks",
            iso_639_3="kas",
            bcp47="ks-Arab",
            name="Kashmiri",
            native_name="کٲشُر",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Arab",
            supported_scripts=["Arab", "Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 20. Sindhi
        "sd": LanguageDefinition(
            iso_639_1="sd",
            iso_639_3="snd",
            bcp47="sd-Arab",
            name="Sindhi",
            native_name="سنڌي / सिन्धी",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Arab",
            supported_scripts=["Arab", "Deva", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 21. Manipuri (Meitei)
        "mni": LanguageDefinition(
            iso_639_1="mni",
            iso_639_3="mni",
            bcp47="mni-Beng",
            name="Manipuri",
            native_name="মৈতৈলোন্",
            family=LanguageFamily.TIBETO_BURMAN,
            is_eighth_schedule=True,
            primary_script="Beng",
            supported_scripts=["Beng", "Mtei", "Latn"],
            has_sacred_liturgical_tradition=True,
        ),
        # 22. Urdu
        "ur": LanguageDefinition(
            iso_639_1="ur",
            iso_639_3="urd",
            bcp47="ur-Arab",
            name="Urdu",
            native_name="اُردُو",
            family=LanguageFamily.INDO_ARYAN,
            is_eighth_schedule=True,
            primary_script="Arab",
            supported_scripts=["Arab", "Deva", "Latn"],
            has_sacred_liturgical_tradition=False,
        ),
        # 23. English (Additional Global Bridge Language)
        "en": LanguageDefinition(
            iso_639_1="en",
            iso_639_3="eng",
            bcp47="en-US",
            name="English",
            native_name="English",
            family=LanguageFamily.GERMANIC,
            is_eighth_schedule=False,
            primary_script="Latn",
            supported_scripts=["Latn"],
            has_sacred_liturgical_tradition=False,
        ),
    }

    @classmethod
    def get_eighth_schedule_languages(cls) -> List[LanguageDefinition]:
        """Returns the exact 22 Eighth Schedule languages (Sanskrit included once)."""
        return [lang for lang in cls.LANGUAGES.values() if lang.is_eighth_schedule]

    @classmethod
    def get_language(cls, code: str) -> Optional[LanguageDefinition]:
        """Look up by ISO 639-1 or ISO 639-3."""
        code_clean = code.lower().strip()
        if code_clean in cls.LANGUAGES:
            return cls.LANGUAGES[code_clean]
        for lang in cls.LANGUAGES.values():
            if lang.iso_639_3 == code_clean:
                return lang
        return None

    @classmethod
    def get_script(cls, code: str) -> Optional[ScriptDefinition]:
        """Look up by ISO 15924 code."""
        code_title = code.capitalize().strip()
        return cls.SCRIPTS.get(code_title)

    @classmethod
    def is_script_supported_for_language(cls, lang_code: str, script_code: str) -> bool:
        """Validates if a script is linguistically and orthographically registered for a language."""
        lang = cls.get_language(lang_code)
        if not lang:
            return False
        script_code_title = script_code.capitalize().strip()
        return script_code_title in lang.supported_scripts
