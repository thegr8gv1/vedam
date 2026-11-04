"""
Vedic Heritage Platform — Professional Word Document Exporter
Generates publication-quality typeset manuscripts (.docx) using python-docx
with verse boundaries, Indic typography, and provenance footers.
"""

from pathlib import Path
from typing import Optional
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Inches, Pt, RGBColor

from automation.rights.engine import RightsProvenanceEngine
from database.models import ReleaseStatus, Text, VerseType


class WordExporter:
    """Exports structured sacred literature into publication-grade Word documents."""

    COLOR_PRIMARY = RGBColor(139, 30, 11)   # Vedic Maroon (#8B1E0B)
    COLOR_SECONDARY = RGBColor(30, 58, 138) # Deep Navy (#1E3A8A)
    COLOR_MUTED = RGBColor(107, 114, 128)   # Slate Gray (#6B7280)
    COLOR_DARK = RGBColor(17, 24, 39)       # Near Black

    @classmethod
    def export_text_bundle(
        cls,
        text: Text,
        output_path: str,
        include_transliteration: bool = True,
        include_translations: bool = True,
        target_channel: str = "scholarly_review",
    ) -> str:
        """
        Generate a beautifully styled Word manuscript (.docx) for the given Text.
        """
        # Rights Gatekeeping
        RightsProvenanceEngine.assert_export_clearance(text.rights, target_channel)

        doc = Document()

        # Set page margins (1 inch all around)
        for section in doc.sections:
            section.top_margin = Inches(1.0)
            section.bottom_margin = Inches(1.0)
            section.left_margin = Inches(1.0)
            section.right_margin = Inches(1.0)

        # 1. Header / Invocation
        cls._add_title_block(doc, text)

        # 2. Metadata Capsule
        cls._add_metadata_table(doc, text)

        # 3. Verses Body
        cls._add_verses_body(doc, text, include_transliteration, include_translations)

        # 4. Rights & Provenance Colophon
        cls._add_provenance_colophon(doc, text)

        out_file = Path(output_path)
        out_file.parent.mkdir(parents=True, exist_ok=True)
        doc.save(str(out_file))
        return str(out_file)

    @classmethod
    def _add_title_block(cls, doc: Document, text: Text) -> None:
        p_om = doc.add_paragraph()
        p_om.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run_om = p_om.add_run("॥ ॐ श्रीपरमात्मने नमः ॥")
        run_om.font.name = "Nirmala UI"
        run_om.font.size = Pt(13)
        run_om.font.bold = True
        run_om.font.color.rgb = cls.COLOR_PRIMARY
        p_om.paragraph_format.space_after = Pt(6)

        # Devanagari Title
        p_dev = doc.add_paragraph()
        p_dev.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run_dev = p_dev.add_run(f"॥ {text.devanagari_title} ॥")
        run_dev.font.name = "Nirmala UI"
        run_dev.font.size = Pt(22)
        run_dev.font.bold = True
        run_dev.font.color.rgb = cls.COLOR_PRIMARY
        p_dev.paragraph_format.space_after = Pt(2)

        # Canonical English Title
        p_en = doc.add_paragraph()
        p_en.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run_en = p_en.add_run(text.canonical_title)
        run_en.font.name = "Calibri"
        run_en.font.size = Pt(15)
        run_en.font.bold = True
        run_en.font.color.rgb = cls.COLOR_SECONDARY
        p_en.paragraph_format.space_after = Pt(14)

    @classmethod
    def _add_metadata_table(cls, doc: Document, text: Text) -> None:
        tbl = doc.add_table(rows=2, cols=3)
        tbl.alignment = WD_ALIGN_PARAGRAPH.CENTER
        tbl.autofit = False

        cells = tbl.rows[0].cells
        cells[0].text = f"Deity: {text.deity.name if text.deity else 'Traditional'}"
        cells[1].text = f"Category: {text.primary_category.name if text.primary_category else 'Stotra'}"
        cells[2].text = f"Composer: {text.composer or 'Traditional'}"

        cells2 = tbl.rows[1].cells
        cells2[0].text = f"Metre: {text.chandas or 'Anushtubh'}"
        cells2[1].text = f"Scripture: {text.source_scripture or 'Classical Liturgy'}"
        cells2[2].text = f"Content ID: {text.content_id}"

        # Style cells
        for row in tbl.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(2)
                    p.paragraph_format.space_after = Pt(2)
                    for r in p.runs:
                        r.font.name = "Calibri"
                        r.font.size = Pt(9.5)
                        r.font.color.rgb = cls.COLOR_MUTED

        p_space = doc.add_paragraph()
        p_space.paragraph_format.space_after = Pt(14)

    @classmethod
    def _add_verses_body(
        cls,
        doc: Document,
        text: Text,
        include_transliteration: bool,
        include_translations: bool,
    ) -> None:
        for verse in text.verses:
            # Verse Heading / Label
            p_label = doc.add_paragraph()
            run_lbl = p_label.add_run(f"Verse {verse.verse_number} — {verse.verse_type.value}")
            run_lbl.font.name = "Calibri"
            run_lbl.font.size = Pt(9)
            run_lbl.font.bold = True
            run_lbl.font.color.rgb = cls.COLOR_MUTED
            p_label.paragraph_format.space_before = Pt(10)
            p_label.paragraph_format.space_after = Pt(2)

            # Devanagari Verse Text
            p_dev = doc.add_paragraph()
            p_dev.alignment = WD_ALIGN_PARAGRAPH.CENTER
            run_dev = p_dev.add_run(verse.devanagari_text)
            run_dev.font.name = "Nirmala UI"
            run_dev.font.size = Pt(14)
            run_dev.font.bold = True
            run_dev.font.color.rgb = cls.COLOR_DARK
            p_dev.paragraph_format.space_after = Pt(3)

            # Roman IAST Transliteration
            if include_transliteration and verse.iast_text:
                p_iast = doc.add_paragraph()
                p_iast.alignment = WD_ALIGN_PARAGRAPH.CENTER
                run_iast = p_iast.add_run(verse.iast_text)
                run_iast.font.name = "Calibri"
                run_iast.font.size = Pt(11)
                run_iast.font.italic = True
                run_iast.font.color.rgb = cls.COLOR_SECONDARY
                p_iast.paragraph_format.space_after = Pt(4)

            # English Translation (Bhavartha)
            if include_translations:
                en_trans = next((t.translated_text for t in verse.translations if t.target_language == "en"), None)
                if en_trans:
                    p_trans = doc.add_paragraph()
                    run_tag = p_trans.add_run("Meaning: ")
                    run_tag.font.bold = True
                    run_tag.font.size = Pt(10)
                    run_tag.font.color.rgb = cls.COLOR_PRIMARY
                    run_val = p_trans.add_run(en_trans)
                    run_val.font.size = Pt(10)
                    run_val.font.color.rgb = cls.COLOR_DARK
                    p_trans.paragraph_format.space_after = Pt(8)

            # Subtle Divider between stanzas
            p_div = doc.add_paragraph()
            p_div.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_div = p_div.add_run("❖   ❖   ❖")
            r_div.font.size = Pt(8)
            r_div.font.color.rgb = cls.COLOR_MUTED
            p_div.paragraph_format.space_after = Pt(6)

    @classmethod
    def _add_provenance_colophon(cls, doc: Document, text: Text) -> None:
        p_break = doc.add_paragraph()
        p_break.paragraph_format.space_before = Pt(16)

        p_col = doc.add_paragraph()
        r_head = p_col.add_run("Rights, Provenance & Scholarly Citation\n")
        r_head.font.bold = True
        r_head.font.size = Pt(10.5)
        r_head.font.color.rgb = cls.COLOR_PRIMARY

        rights = text.rights
        if rights:
            col_lines = [
                f"• Canonical Content ID: {text.content_id} | UUID: {text.uuid}",
                f"• Primary Source: {rights.primary_source} | Edition: {rights.specific_edition or 'Standard Traditional'}",
                f"• License: {rights.license_type} | Release Status: {rights.release_status.value}",
                f"• Commercial Clearance: {'Approved' if rights.commercial_reuse_permitted else 'Restricted / Scholarly Review Only'}",
                f"• Required Attribution: {rights.attribution_text or 'Vedic Heritage Digital Library'}",
                f"• Integrity Verification Hash (SHA-256): {text.content_hash}",
            ]
            for line in col_lines:
                r_line = p_col.add_run(line + "\n")
                r_line.font.size = Pt(8.5)
                r_line.font.color.rgb = cls.COLOR_MUTED
