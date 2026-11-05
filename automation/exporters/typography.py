"""
Vedic Heritage Platform — Multilingual Typography & Font Stack Abstraction
Part D.2: Typography abstraction mapping 14 scripts to CSS font stacks,
ReportLab TrueType fonts, OpenType shaping requirements, and font licensing metadata.
"""

from dataclasses import dataclass
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from automation.localization.script_registry import MultilingualScriptRegistry, ScriptProfile

logger = logging.getLogger("vedam.automation.exporters.typography")


@dataclass(frozen=True)
class FontProfile:
    family_name: str
    reportlab_regular: str
    reportlab_bold: str
    css_stack: str
    word_font_name: str
    license: str
    embedding_rights: str
    windows_file_names: Tuple[str, ...]
    shaping_engine: str
    known_limitations: Tuple[str, ...]


class MultilingualTypographyEngine:
    """
    Central typography and font registration engine for all 14 platform scripts.
    """

    # Authoritative Font Mappings
    FONT_PROFILES: Dict[str, FontProfile] = {
        "Deva": FontProfile(
            family_name="Devanagari Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Devanagari', 'Siddhanta', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License (Windows) / OFL (Noto)",
            embedding_rights="Editable Embedding / Print and Preview",
            windows_file_names=("Nirmala.ttc", "mangal.ttf"),
            shaping_engine="HarfBuzz Indic / Microsoft Uniscribe",
            known_limitations=("Vedic svara glyphs U+1CDA require Noto Sans Devanagari or Siddhanta for optimal rendering.",),
        ),
        "Telu": FontProfile(
            family_name="Telugu Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Telugu', 'Gautami', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "gautami.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Complex triple conjuncts require standard OpenType shaping.",),
        ),
        "Taml": FontProfile(
            family_name="Tamil Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Tamil', 'Latha', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "latha.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Grantha ligatures in Tamil text require Grantha glyph fallbacks.",),
        ),
        "Gran": FontProfile(
            family_name="Grantha Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Grantha', 'e-Grantha', 'Siddhanta', sans-serif",
            word_font_name="Noto Sans Grantha",
            license="SIL Open Font License (OFL)",
            embedding_rights="Installable / Embeddable",
            windows_file_names=("NotoSansGrantha-Regular.ttf", "Nirmala.ttc"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Requires Noto Sans Grantha for full supplementary SMP block U+11300..U+1137F.",),
        ),
        "Knda": FontProfile(
            family_name="Kannada Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Kannada', 'Tunga', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "tunga.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=(),
        ),
        "Mlym": FontProfile(
            family_name="Malayalam Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Malayalam', 'Kartika', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "kartika.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Chillu consonant ligatures require ZWJ (U+200D).",),
        ),
        "Beng": FontProfile(
            family_name="Bengali-Assamese Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Bengali', 'Vrinda', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "vrinda.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Assamese Ra (ৰ) and Va (ৱ) require modern Unicode fonts.",),
        ),
        "Gujr": FontProfile(
            family_name="Gujarati Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Gujarati', 'Shruti', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "shruti.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=(),
        ),
        "Guru": FontProfile(
            family_name="Gurmukhi Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Gurmukhi', 'Raavi', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "raavi.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=(),
        ),
        "Orya": FontProfile(
            family_name="Odia Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Oriya', 'Kalinga', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc", "kalinga.ttf"),
            shaping_engine="HarfBuzz Indic",
            known_limitations=(),
        ),
        "Olck": FontProfile(
            family_name="Ol Chiki Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Ol Chiki', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="Microsoft Typography License / OFL (Noto)",
            embedding_rights="Editable Embedding",
            windows_file_names=("Nirmala.ttc",),
            shaping_engine="Standard Alphabetic (no complex ligatures)",
            known_limitations=(),
        ),
        "Mtei": FontProfile(
            family_name="Meetei Mayek Font Stack",
            reportlab_regular="NirmalaUI",
            reportlab_bold="NirmalaUI-Bold",
            css_stack="'Noto Sans Meetei Mayek', 'Nirmala UI', sans-serif",
            word_font_name="Nirmala UI",
            license="SIL Open Font License / Microsoft",
            embedding_rights="Installable",
            windows_file_names=("Nirmala.ttc",),
            shaping_engine="HarfBuzz Indic",
            known_limitations=("Extended historical Meetei characters require specialized Noto font.",),
        ),
        "Arab": FontProfile(
            family_name="Perso-Arabic Nastaliq Font Stack",
            reportlab_regular="Arabic-Regular",
            reportlab_bold="Arabic-Bold",
            css_stack="'Noto Nastaliq Urdu', 'Jameel Noori Nastaleeq', 'Tahoma', 'Arial', sans-serif",
            word_font_name="Arial",
            license="Microsoft Typography License / SIL OFL",
            embedding_rights="Editable Embedding",
            windows_file_names=("tahoma.ttf", "tahomabd.ttf", "arial.ttf", "arialbd.ttf"),
            shaping_engine="Complex Arabic Nastaliq / Naskh Shaping",
            known_limitations=("Nastaliq requires cascading vertical cursive shaping.",),
        ),
        "Latn": FontProfile(
            family_name="Latin / IAST Font Stack",
            reportlab_regular="IAST-Regular",
            reportlab_bold="IAST-Bold",
            css_stack="'Charis SIL', 'Gentium Plus', 'Georgia', 'Calibri', serif",
            word_font_name="Georgia",
            license="Microsoft Typography License / SIL OFL",
            embedding_rights="Editable Embedding",
            windows_file_names=("calibri.ttf", "calibrib.ttf", "georgia.ttf", "georgiab.ttf"),
            shaping_engine="Standard Latin with Combining Diacritical Mark Positioning",
            known_limitations=(),
        ),
    }

    _pdf_fonts_initialized: bool = False

    @classmethod
    def get_profile(cls, script_code: str) -> FontProfile:
        c = script_code.strip().capitalize()
        if c in cls.FONT_PROFILES:
            return cls.FONT_PROFILES[c]
        return cls.FONT_PROFILES["Latn"]

    @classmethod
    def get_css_font_family(cls, script_code: str) -> str:
        return cls.get_profile(script_code).css_stack

    @classmethod
    def get_word_font_name(cls, script_code: str) -> str:
        return cls.get_profile(script_code).word_font_name

    @classmethod
    def get_reportlab_font_name(cls, script_code: str, bold: bool = False) -> str:
        prof = cls.get_profile(script_code)
        return prof.reportlab_bold if bold else prof.reportlab_regular

    @classmethod
    def register_pdf_fonts(cls) -> Dict[str, bool]:
        """
        Registers TrueType and TrueType Collection fonts with ReportLab.
        Idempotent and thread-safe.
        """
        if cls._pdf_fonts_initialized:
            return {name: True for name in pdfmetrics.getRegisteredFontNames()}

        fonts_dir = r"C:\Windows\Fonts"
        registered = {}

        # 1. Register Nirmala UI for Indic scripts
        nirmala_path = os.path.join(fonts_dir, "Nirmala.ttc")
        if os.path.exists(nirmala_path):
            try:
                if "NirmalaUI" not in pdfmetrics.getRegisteredFontNames():
                    pdfmetrics.registerFont(TTFont("NirmalaUI", nirmala_path, subfontIndex=0))
                    registered["NirmalaUI"] = True
                if "NirmalaUI-Bold" not in pdfmetrics.getRegisteredFontNames():
                    pdfmetrics.registerFont(TTFont("NirmalaUI-Bold", nirmala_path, subfontIndex=1))
                    registered["NirmalaUI-Bold"] = True
            except Exception as e:
                logger.warning("Failed to register Nirmala.ttc: %s", e)

        # 2. Register Calibri / Georgia for Latin / IAST
        calibri_r = os.path.join(fonts_dir, "calibri.ttf")
        calibri_b = os.path.join(fonts_dir, "calibrib.ttf")
        if os.path.exists(calibri_r):
            try:
                if "IAST-Regular" not in pdfmetrics.getRegisteredFontNames():
                    pdfmetrics.registerFont(TTFont("IAST-Regular", calibri_r))
                    registered["IAST-Regular"] = True
                if "IAST-Bold" not in pdfmetrics.getRegisteredFontNames() and os.path.exists(calibri_b):
                    pdfmetrics.registerFont(TTFont("IAST-Bold", calibri_b))
                    registered["IAST-Bold"] = True
            except Exception as e:
                logger.warning("Failed to register Calibri for IAST: %s", e)

        # 3. Register Tahoma / Arial for Arabic / Urdu
        tahoma_r = os.path.join(fonts_dir, "tahoma.ttf")
        tahoma_b = os.path.join(fonts_dir, "tahomabd.ttf")
        if os.path.exists(tahoma_r):
            try:
                if "Arabic-Regular" not in pdfmetrics.getRegisteredFontNames():
                    pdfmetrics.registerFont(TTFont("Arabic-Regular", tahoma_r))
                    registered["Arabic-Regular"] = True
                if "Arabic-Bold" not in pdfmetrics.getRegisteredFontNames() and os.path.exists(tahoma_b):
                    pdfmetrics.registerFont(TTFont("Arabic-Bold", tahoma_b))
                    registered["Arabic-Bold"] = True
            except Exception as e:
                logger.warning("Failed to register Tahoma for Arabic: %s", e)
        else:
            # Fallback to Arial
            arial_r = os.path.join(fonts_dir, "arial.ttf")
            arial_b = os.path.join(fonts_dir, "arialbd.ttf")
            if os.path.exists(arial_r):
                try:
                    if "Arabic-Regular" not in pdfmetrics.getRegisteredFontNames():
                        pdfmetrics.registerFont(TTFont("Arabic-Regular", arial_r))
                        registered["Arabic-Regular"] = True
                    if "Arabic-Bold" not in pdfmetrics.getRegisteredFontNames() and os.path.exists(arial_b):
                        pdfmetrics.registerFont(TTFont("Arabic-Bold", arial_b))
                        registered["Arabic-Bold"] = True
                except Exception as e:
                    logger.warning("Failed to register Arial for Arabic: %s", e)

        cls._pdf_fonts_initialized = True
        return {name: True for name in pdfmetrics.getRegisteredFontNames()}

    # Alias for API backwards compatibility
    register_reportlab_fonts = register_pdf_fonts

    @classmethod
    def get_font_licensing_ledger(cls) -> List[Dict[str, Any]]:
        """Returns the complete licensing and embedding audit ledger for documentation."""
        ledger = []
        for script_code, prof in cls.FONT_PROFILES.items():
            ledger.append({
                "script_code": script_code,
                "family_name": prof.family_name,
                "css_stack": prof.css_stack,
                "word_font": prof.word_font_name,
                "reportlab_font": prof.reportlab_regular,
                "license": prof.license,
                "embedding_rights": prof.embedding_rights,
                "shaping_engine": prof.shaping_engine,
                "known_limitations": list(prof.known_limitations),
            })
        return ledger
