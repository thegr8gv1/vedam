"""
Vedic Heritage Platform — Print-Ready Multilingual PDF Publication Exporter
Part D.6: Generates high-resolution, archival PDF manuscripts using ReportLab
with Unicode font embedding (Nirmala UI, Calibri, Tahoma), running headers/footers,
RTL Arabic-script layout, and non-bypassable DRAFT watermarking.
"""

from datetime import datetime, timezone
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    HRFlowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from automation.exporters.bidi_layout import BidiLayoutEngine
from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import PublicationDocument
from automation.exporters.typography import MultilingualTypographyEngine

logger = logging.getLogger("vedam.automation.exporters.pdf_multilingual_exporter")


class WatermarkedNumberedCanvas(canvas.Canvas):
    """
    Two-pass canvas calculating total pages, drawing running headers/footers,
    and rendering diagonal DRAFT watermark across all pages when unapproved.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []
        self.doc_title = "Vedic Heritage Digital Library"
        self.content_id = ""
        self.watermark_text = None

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_decorations(self, total_pages: int):
        self.saveState()

        # 1. Draw Diagonal Watermark if present
        if self.watermark_text:
            self.saveState()
            self.setFont("Helvetica-Bold", 36)
            self.setFillColor(colors.HexColor("#FEE2E2"), alpha=0.35)  # Soft red tint
            self.translate(letter[0] / 2.0, letter[1] / 2.0)
            self.rotate(45)
            self.drawCentredString(0, 0, self.watermark_text)
            self.restoreState()

        # Skip headers/footers on page 1 (cover / title page)
        if self._pageNumber > 1:
            # Running Header
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#6B7280"))
            self.drawString(0.5 * inch, 10.5 * inch, f"{self.doc_title} ({self.content_id})")
            self.setStrokeColor(colors.HexColor("#E5E7EB"))
            self.setLineWidth(0.5)
            self.line(0.5 * inch, 10.42 * inch, 8.0 * inch, 10.42 * inch)

            # Running Footer
            self.line(0.5 * inch, 0.65 * inch, 8.0 * inch, 0.65 * inch)
            self.drawString(0.5 * inch, 0.5 * inch, "Vedic Heritage Platform — Digital Scholarly Edition")
            page_str = f"Page {self._pageNumber} of {total_pages}"
            self.drawRightString(8.0 * inch, 0.5 * inch, page_str)

        self.restoreState()


class MultilingualPDFExporter:
    """
    Renders publication-grade PDF documents across Indian scripts, Latin IAST, and RTL Arabic.
    """

    DEFAULT_OUTPUT_DIR = "exports/multilingual_publication/pdf"

    @classmethod
    def export(
        cls,
        document: PublicationDocument,
        output_path: Optional[str] = None,
        enforce_gate: bool = True,
    ) -> str:
        """
        Exports a PublicationDocument to a print-ready PDF file.
        Returns the absolute path of the generated PDF artifact.
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
            fname = f"{document.metadata.content_id}_{slug}_{document.target.bcp47}_{document.governance.publication_channel}.pdf"
            output_path = str(out_dir / fname)
        else:
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)

        # Register Fonts
        MultilingualTypographyEngine.register_pdf_fonts()

        # Build Flowables
        doc = SimpleDocTemplate(
            output_path,
            pagesize=letter,
            leftMargin=0.5 * inch,
            rightMargin=0.5 * inch,
            topMargin=0.6 * inch,
            bottomMargin=0.6 * inch,
        )

        flowables = cls._build_flowables(document)

        def make_canvas(*args, **kwargs):
            c = WatermarkedNumberedCanvas(*args, **kwargs)
            c.doc_title = document.metadata.canonical_title
            c.content_id = document.metadata.content_id
            c.watermark_text = "UNREVIEWED DRAFT" if document.governance.watermark_text else None
            return c

        doc.build(flowables, canvasmaker=make_canvas)

        logger.info("PDF publication successfully generated at: %s", output_path)
        return output_path

    @classmethod
    def _build_flowables(cls, document: PublicationDocument) -> List[Any]:
        styles = getSampleStyleSheet()
        target = document.target
        meta = document.metadata
        gov = document.governance
        missing = document.missing_content

        target_font = MultilingualTypographyEngine.get_reportlab_font_name(target.script_code)
        target_font_bold = MultilingualTypographyEngine.get_reportlab_font_name(target.script_code, bold=True)
        indic_font = "NirmalaUI"
        indic_font_bold = "NirmalaUI-Bold"
        iast_font = "IAST-Regular"

        # Styles
        title_deva_style = ParagraphStyle(
            "DevaTitle",
            parent=styles["Normal"],
            fontName=indic_font_bold,
            fontSize=18,
            leading=24,
            textColor=colors.HexColor("#800020"),  # Maroon
            alignment=1,  # Centered
            spaceAfter=6,
        )
        title_eng_style = ParagraphStyle(
            "EngTitle",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=14,
            leading=18,
            textColor=colors.HexColor("#1F2937"),
            alignment=1,
            spaceAfter=12,
        )
        verse_num_style = ParagraphStyle(
            "VerseNum",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=12,
            textColor=colors.HexColor("#800020"),
        )
        verse_id_style = ParagraphStyle(
            "VerseId",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=8,
            leading=10,
            textColor=colors.HexColor("#6B7280"),
            alignment=2,  # Right-aligned
        )
        source_deva_style = ParagraphStyle(
            "SourceDeva",
            parent=styles["Normal"],
            fontName=indic_font,
            fontSize=11,
            leading=16,
            textColor=colors.HexColor("#4A151B"),
            spaceAfter=4,
        )
        source_iast_style = ParagraphStyle(
            "SourceIast",
            parent=styles["Normal"],
            fontName=iast_font,
            fontSize=9,
            leading=13,
            textColor=colors.HexColor("#4B5563"),
            fontStyle="italic",
            spaceAfter=6,
        )
        recitation_style = ParagraphStyle(
            "RecitationStyle",
            parent=styles["Normal"],
            fontName=target_font,
            fontSize=10.5,
            leading=15,
            textColor=colors.HexColor("#1E3A8A"),
            alignment=2 if target.is_rtl else 0,
            spaceAfter=6,
        )
        view_label_style = ParagraphStyle(
            "ViewLabel",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8,
            leading=10,
            textColor=colors.HexColor("#374151"),
            spaceBefore=4,
            spaceAfter=2,
        )
        view_text_style = ParagraphStyle(
            "ViewText",
            parent=styles["Normal"],
            fontName=target_font,
            fontSize=9.5,
            leading=14,
            textColor=colors.HexColor("#111827"),
            alignment=2 if target.is_rtl else 0,
            spaceAfter=4,
        )
        missing_text_style = ParagraphStyle(
            "MissingText",
            parent=styles["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor("#9CA3AF"),
            spaceAfter=4,
        )
        banner_text_style = ParagraphStyle(
            "BannerText",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#92400E"),
            alignment=1,
        )

        flowables: List[Any] = []

        # Draft Banner
        if gov.watermark_text:
            banner_data = [[Paragraph(f"&#9888; NOTICE: {gov.watermark_text}", banner_text_style)]]
            banner_table = Table(banner_data, colWidths=[7.5 * inch])
            banner_table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FEF3C7")),
                ("BORDER", (0, 0), (-1, -1), 1, colors.HexColor("#F59E0B")),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]))
            flowables.append(banner_table)
            flowables.append(Spacer(1, 10))

        # Title Block
        flowables.append(Paragraph(meta.devanagari_title, title_deva_style))
        flowables.append(Paragraph(f"{meta.canonical_title} — {target.language_name} Edition ({target.script_name})", title_eng_style))

        # Metadata Table
        meta_rows = [
            ["Content ID:", meta.content_id, "Target Language:", f"{target.language_name} ({target.bcp47})"],
            ["Category:", meta.primary_category, "Directionality:", f"{target.direction.upper()} ({'RTL' if target.is_rtl else 'LTR'})"],
            ["Review Status:", gov.overall_review_status, "Edition Channel:", gov.publication_channel],
        ]
        if meta.deity or meta.rishi:
            meta_rows.append(["Deity:", meta.deity or "—", "Rishi / Composer:", meta.rishi or meta.composer or "—"])

        meta_table = Table(meta_rows, colWidths=[1.3 * inch, 2.45 * inch, 1.3 * inch, 2.45 * inch])
        meta_table.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
            ("FONTSIZE", (0, 0), (-1, -1), 8),
            ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#374151")),
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F9FAFB")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#E5E7EB")),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ]))
        flowables.append(meta_table)
        flowables.append(Spacer(1, 14))

        # Legacy gap note
        if missing.is_legacy_gap_affected:
            gap_data = [[Paragraph(
                f"<b>Editorial Notice:</b> Contains {missing.missing_literal_count} missing literal views and "
                f"{missing.missing_tatparya_count} missing traditional tatparya views (legacy 747 gap queue).",
                banner_text_style
            )]]
            gap_table = Table(gap_data, colWidths=[7.5 * inch])
            gap_table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FFFBEB")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#FCD34D")),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]))
            flowables.append(gap_table)
            flowables.append(Spacer(1, 10))

        flowables.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#800020"), spaceAfter=14))

        # Verses
        for ve in document.verses:
            verse_elements: List[Any] = []

            # Verse Header Bar
            v_head_data = [
                [Paragraph(f"Verse {ve.verse_number}", verse_num_style), Paragraph(ve.verse_id, verse_id_style)]
            ]
            v_head_table = Table(v_head_data, colWidths=[3.75 * inch, 3.75 * inch])
            v_head_table.setStyle(TableStyle([
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
            ]))
            verse_elements.append(v_head_table)

            # Source Sanskrit Box
            src_elements = [
                Paragraph(ve.devanagari_source, source_deva_style),
                Paragraph(ve.iast_transliteration, source_iast_style),
            ]
            src_table = Table([[src_elements]], colWidths=[7.5 * inch])
            src_table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FAF5EF")),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("LINELEFT", (0, 0), (-1, -1), 3, colors.HexColor("#800020")),
            ]))
            verse_elements.append(src_table)
            verse_elements.append(Spacer(1, 6))

            # Recitation in target script
            if ve.target_script_transliteration and target.script_code != "Deva":
                rec_text = ve.target_script_transliteration
                if target.is_rtl:
                    rec_text = BidiLayoutEngine.shape_arabic_for_pdf(rec_text)
                verse_elements.append(Paragraph(f"<b>{target.script_name} Recitation:</b>", view_label_style))
                verse_elements.append(Paragraph(rec_text, recitation_style))

            # Views
            if ve.literal_translation:
                lit_t = ve.literal_translation
                if target.is_rtl:
                    lit_t = BidiLayoutEngine.shape_arabic_for_pdf(lit_t)
                verse_elements.append(Paragraph(f"<b>Literal Translation ({ve.literal_status}):</b>", view_label_style))
                verse_elements.append(Paragraph(lit_t, view_text_style))
            else:
                verse_elements.append(Paragraph("<i>Literal Translation: Pending scholarly review.</i>", missing_text_style))

            if ve.tatparya_translation:
                tat_t = ve.tatparya_translation
                if target.is_rtl:
                    tat_t = BidiLayoutEngine.shape_arabic_for_pdf(tat_t)
                verse_elements.append(Paragraph(f"<b>Traditional Tātparya ({ve.tatparya_status}):</b>", view_label_style))
                verse_elements.append(Paragraph(tat_t, view_text_style))
            else:
                verse_elements.append(Paragraph("<i>Traditional Tātparya: Pending commentary collation.</i>", missing_text_style))

            if ve.bhavartha_translation:
                bhav_t = ve.bhavartha_translation
                if target.is_rtl:
                    bhav_t = BidiLayoutEngine.shape_arabic_for_pdf(bhav_t)
                verse_elements.append(Paragraph(f"<b>Devotional Bhavartha ({ve.bhavartha_status}):</b>", view_label_style))
                verse_elements.append(Paragraph(bhav_t, view_text_style))

            verse_elements.append(Spacer(1, 10))
            verse_elements.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#E5E7EB"), spaceAfter=10))

            flowables.append(KeepTogether(verse_elements))

        return flowables
