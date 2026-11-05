"""
Vedic Heritage Platform — Multilingual Word (DOCX) Publication Exporter
Part D.7: Generates publication-grade Microsoft Word manuscripts (.docx) supporting
all 14 scripts, bidirectional RTL paragraph layout for Urdu/Kashmiri/Sindhi,
granular translation views, and DRAFT warning banners.
"""

from datetime import datetime, timezone
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Inches, Pt, RGBColor

from automation.exporters.bidi_layout import BidiLayoutEngine
from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import PublicationDocument
from automation.exporters.typography import MultilingualTypographyEngine

logger = logging.getLogger("vedam.automation.exporters.docx_multilingual_exporter")


class MultilingualDOCXExporter:
    """
    Renders typeset Microsoft Word documents (.docx) across Indian scripts, Latin IAST, and RTL Arabic.
    """

    DEFAULT_OUTPUT_DIR = "exports/multilingual_publication/docx"

    COLOR_MAROON = RGBColor(128, 0, 32)      # Deep Maroon (#800020)
    COLOR_GOLD = RGBColor(212, 175, 55)       # Gold (#D4AF37)
    COLOR_DARK = RGBColor(31, 41, 55)         # Charcoal (#1F2937)
    COLOR_MUTED = RGBColor(107, 114, 128)     # Muted Slate (#6B7280)
    COLOR_BLUE = RGBColor(30, 58, 138)        # Blue (#1E3A8A)

    @classmethod
    def export(
        cls,
        document: PublicationDocument,
        output_path: Optional[str] = None,
        enforce_gate: bool = True,
    ) -> str:
        """
        Exports a PublicationDocument to a DOCX manuscript.
        Returns the absolute path of the generated DOCX artifact.
        """
        if enforce_gate:
            gate_rep = PublicationGatekeeper.evaluate_publication(document)
            if not gate_rep.can_export:
                blocker_msgs = "; ".join([b.message for b in gate_rep.blockers])
                raise PermissionError(f"Publication Gate Blocked Export: {blocker_msgs}")

        if not output_path:
            out_dir = Path(cls.DEFAULT_OUTPUT_DIR)
            out_dir.mkdir(parents=True, exist_ok=True)
            slug = document.metadata.canonical_title.lower().replace(" ", "_").replace("-", "_")
            fname = f"{document.metadata.content_id}_{slug}_{document.target.bcp47}_{document.governance.publication_channel}.docx"
            output_path = str(out_dir / fname)
        else:
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)

        doc = Document()

        # Set page margins (1 inch)
        for s in doc.sections:
            s.top_margin = Inches(1.0)
            s.bottom_margin = Inches(1.0)
            s.left_margin = Inches(1.0)
            s.right_margin = Inches(1.0)

        target = document.target
        meta = document.metadata
        gov = document.governance
        missing = document.missing_content

        target_font_name = MultilingualTypographyEngine.get_word_font_name(target.script_code)

        # 1. Draft Notice Banner if applicable
        if gov.watermark_text:
            tbl = doc.add_table(rows=1, cols=1)
            tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell = tbl.cell(0, 0)
            shading = parse_xml(r'<w:shd {} w:fill="FEF3C7"/>'.format(nsdecls('w')))
            cell._tc.get_or_add_tcPr().append(shading)
            borders = parse_xml(r'<w:tcBorders {}><w:top w:val="single" w:sz="12" w:space="0" w:color="F59E0B"/><w:bottom w:val="single" w:sz="12" w:space="0" w:color="F59E0B"/><w:left w:val="none"/><w:right w:val="none"/></w:tcBorders>'.format(nsdecls('w')))
            cell._tc.get_or_add_tcPr().append(borders)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            run = p.add_run(f"NOTICE: {gov.watermark_text}")
            run.bold = True
            run.font.size = Pt(10)
            run.font.color.rgb = RGBColor(146, 64, 14)
            doc.add_paragraph()  # Spacer

        # 2. Document Title Header
        p_title_deva = doc.add_paragraph()
        p_title_deva.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_dev = p_title_deva.add_run(meta.devanagari_title)
        r_dev.font.name = "Nirmala UI"
        r_dev.font.size = Pt(22)
        r_dev.bold = True
        r_dev.font.color.rgb = cls.COLOR_MAROON

        p_title_eng = doc.add_paragraph()
        p_title_eng.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_eng = p_title_eng.add_run(f"{meta.canonical_title} — {target.language_name} Edition")
        r_eng.font.name = "Georgia"
        r_eng.font.size = Pt(15)
        r_eng.bold = True
        r_eng.font.color.rgb = cls.COLOR_DARK

        # Metadata Table
        meta_tbl = doc.add_table(rows=3, cols=2)
        meta_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        rows_data = [
            ("Content ID & Category:", f"{meta.content_id} | {meta.primary_category}"),
            ("Language & Script:", f"{target.language_name} ({target.bcp47}) | Direction: {target.direction.upper()}"),
            ("Review & Release Status:", f"{gov.overall_review_status} ({gov.publication_channel})"),
        ]
        for idx, (label, val) in enumerate(rows_data):
            c1, c2 = meta_tbl.cell(idx, 0), meta_tbl.cell(idx, 1)
            c1.text = label
            c2.text = val
            c1.paragraphs[0].runs[0].bold = True
            c1.paragraphs[0].runs[0].font.size = Pt(9)
            c2.paragraphs[0].runs[0].font.size = Pt(9)
            c1.paragraphs[0].runs[0].font.color.rgb = cls.COLOR_MUTED
            c2.paragraphs[0].runs[0].font.color.rgb = cls.COLOR_DARK

        doc.add_paragraph()  # Spacer

        # 3. Legacy Gap Notice if present
        if missing.is_legacy_gap_affected:
            p_gap = doc.add_paragraph()
            r_g = p_gap.add_run(
                f"Editorial Notice: This draft contains {missing.missing_literal_count} missing literal views and "
                f"{missing.missing_tatparya_count} missing traditional tatparya views (legacy 747 gap queue)."
            )
            r_g.font.size = Pt(9)
            r_g.italic = True
            r_g.font.color.rgb = RGBColor(146, 64, 14)

        # 4. Verses Loop
        for ve in document.verses:
            # Verse Heading
            p_vhead = doc.add_paragraph()
            r_vn = p_vhead.add_run(f"Verse {ve.verse_number}")
            r_vn.bold = True
            r_vn.font.size = Pt(12)
            r_vn.font.color.rgb = cls.COLOR_MAROON
            r_vi = p_vhead.add_run(f"  [{ve.verse_id}]")
            r_vi.font.size = Pt(9)
            r_vi.font.color.rgb = cls.COLOR_MUTED

            # Source Sanskrit Box (Table with subtle background)
            src_tbl = doc.add_table(rows=1, cols=1)
            src_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
            c = src_tbl.cell(0, 0)
            shd = parse_xml(r'<w:shd {} w:fill="FAF5EF"/>'.format(nsdecls('w')))
            c._tc.get_or_add_tcPr().append(shd)
            bdr = parse_xml(r'<w:tcBorders {}><w:left w:val="single" w:sz="24" w:space="0" w:color="800020"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tcBorders>'.format(nsdecls('w')))
            c._tc.get_or_add_tcPr().append(bdr)

            p_deva = c.paragraphs[0]
            r_d = p_deva.add_run(ve.devanagari_source)
            r_d.font.name = "Nirmala UI"
            r_d.font.size = Pt(11.5)
            r_d.bold = True
            r_d.font.color.rgb = RGBColor(74, 21, 27)

            p_iast = c.add_paragraph()
            r_i = p_iast.add_run(ve.iast_transliteration)
            r_i.font.name = "Georgia"
            r_i.font.size = Pt(9.5)
            r_i.italic = True
            r_i.font.color.rgb = cls.COLOR_MUTED

            # Target Script Recitation
            if ve.target_script_transliteration and target.script_code != "Deva":
                p_rec = doc.add_paragraph()
                if target.is_rtl:
                    p_rec.alignment = WD_ALIGN_PARAGRAPH.RIGHT
                r_lbl = p_rec.add_run(f"{target.script_name} Recitation:\n")
                r_lbl.bold = True
                r_lbl.font.size = Pt(8.5)
                r_lbl.font.color.rgb = cls.COLOR_BLUE
                r_txt = p_rec.add_run(ve.target_script_transliteration)
                r_txt.font.name = target_font_name
                r_txt.font.size = Pt(11)
                r_txt.font.color.rgb = cls.COLOR_BLUE

            # Views
            # 1. Literal View
            p_lit = doc.add_paragraph()
            if target.is_rtl:
                p_lit.alignment = WD_ALIGN_PARAGRAPH.RIGHT
            r_ltitle = p_lit.add_run(f"Literal Translation ({ve.literal_status}):\n")
            r_ltitle.bold = True
            r_ltitle.font.size = Pt(8.5)
            r_ltitle.font.color.rgb = cls.COLOR_DARK
            if ve.literal_translation:
                r_lcontent = p_lit.add_run(ve.literal_translation)
                r_lcontent.font.name = target_font_name
                r_lcontent.font.size = Pt(10)
            else:
                r_lmissing = p_lit.add_run("Pending scholarly review.")
                r_lmissing.italic = True
                r_lmissing.font.size = Pt(9)
                r_lmissing.font.color.rgb = cls.COLOR_MUTED

            # 2. Tatparya View
            p_tat = doc.add_paragraph()
            if target.is_rtl:
                p_tat.alignment = WD_ALIGN_PARAGRAPH.RIGHT
            r_ttitle = p_tat.add_run(f"Traditional Tātparya ({ve.tatparya_status}):\n")
            r_ttitle.bold = True
            r_ttitle.font.size = Pt(8.5)
            r_ttitle.font.color.rgb = cls.COLOR_DARK
            if ve.tatparya_translation:
                r_tcontent = p_tat.add_run(ve.tatparya_translation)
                r_tcontent.font.name = target_font_name
                r_tcontent.font.size = Pt(10)
            else:
                r_tmissing = p_tat.add_run("Pending commentary collation.")
                r_tmissing.italic = True
                r_tmissing.font.size = Pt(9)
                r_tmissing.font.color.rgb = cls.COLOR_MUTED

            # 3. Bhavartha View
            if ve.bhavartha_translation:
                p_bhav = doc.add_paragraph()
                if target.is_rtl:
                    p_bhav.alignment = WD_ALIGN_PARAGRAPH.RIGHT
                r_btitle = p_bhav.add_run(f"Devotional Bhavartha ({ve.bhavartha_status}):\n")
                r_btitle.bold = True
                r_btitle.font.size = Pt(8.5)
                r_btitle.font.color.rgb = cls.COLOR_DARK
                r_bcontent = p_bhav.add_run(ve.bhavartha_translation)
                r_bcontent.font.name = target_font_name
                r_bcontent.font.size = Pt(10)

            # Divider line
            doc.add_paragraph("—" * 35)

        # 5. Colophon & Disclaimer
        p_foot = doc.add_paragraph()
        p_foot.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_f1 = p_foot.add_run(f"Vedic Heritage Platform Digital Publication Edition\n")
        r_f1.bold = True
        r_f1.font.size = Pt(9)
        r_f2 = p_foot.add_run(f"{gov.disclaimer}\nGenerated: {document.generated_at.strftime('%Y-%m-%d %H:%M UTC')}")
        r_f2.font.size = Pt(8)
        r_f2.font.color.rgb = cls.COLOR_MUTED

        doc.save(output_path)
        logger.info("DOCX publication successfully generated at: %s", output_path)
        return output_path
