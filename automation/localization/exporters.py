"""
Vedic Heritage Platform — Multilingual Publication Exporter
Generates multilingual Excel, Word, and JSON publication artifacts
incorporating Sanskrit, Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Gujarati, Malayalam, Odia, and English.
"""

from datetime import datetime, timezone
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Inches, Pt, RGBColor
import openpyxl
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

from database.models import Text, TranslationType, Verse


class MultilingualPublicationExporter:
    """Produces multi-language comparative manuscripts across Excel, Word, and JSON."""

    EXPORT_DIRS = {
        "excel": "exports/multilingual/excel",
        "word": "exports/multilingual/word",
        "json": "exports/multilingual/json",
    }

    # Royal Styling
    MAROON_HEADER = PatternFill(start_color="800020", end_color="800020", fill_type="solid")
    GOLD_ACCENT = PatternFill(start_color="D4AF37", end_color="D4AF37", fill_type="solid")
    ZEBRA_TINT = PatternFill(start_color="F9FAFB", end_color="F9FAFB", fill_type="solid")

    HEADER_FONT = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    TITLE_FONT = Font(name="Georgia", size=14, bold=True, color="800020")
    REGULAR_FONT = Font(name="Calibri", size=10, color="1F2937")
    INDIC_FONT = Font(name="Nirmala UI", size=10, color="111827")
    DEVANAGARI_BOLD = Font(name="Nirmala UI", size=11, bold=True, color="800020")

    BORDER_THIN = Border(
        left=Side(style="thin", color="E5E7EB"),
        right=Side(style="thin", color="E5E7EB"),
        top=Side(style="thin", color="E5E7EB"),
        bottom=Side(style="thin", color="E5E7EB"),
    )

    @classmethod
    def ensure_directories(cls) -> None:
        for p in cls.EXPORT_DIRS.values():
            Path(p).mkdir(parents=True, exist_ok=True)

    @classmethod
    def export_all_formats(cls, text: Text) -> Dict[str, str]:
        cls.ensure_directories()
        slug = text.canonical_title.lower().replace(" ", "_").replace("-", "_")
        base = f"{text.content_id}_{slug}_multilingual"

        xlsx_path = os.path.join(cls.EXPORT_DIRS["excel"], f"{base}.xlsx")
        docx_path = os.path.join(cls.EXPORT_DIRS["word"], f"{base}.docx")
        json_path = os.path.join(cls.EXPORT_DIRS["json"], f"{base}.json")

        cls.export_excel(text, xlsx_path)
        cls.export_word(text, docx_path)
        cls.export_json(text, json_path)

        return {
            "excel": xlsx_path,
            "word": docx_path,
            "json": json_path,
        }

    @classmethod
    def export_excel(cls, text: Text, output_path: str) -> str:
        wb = openpyxl.Workbook()
        wb.remove(wb.active)  # Remove default sheet

        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)

        # 1. Comparative All-Languages Sheet
        ws_comp = wb.create_sheet(title="Comparative All-Languages")
        ws_comp.sheet_view.showGridLines = True
        ws_comp.merge_cells("A1:M1")
        ws_comp["A1"] = f"{text.canonical_title} — Multilingual Comparative Matrix (10 Languages + IAST)"
        ws_comp["A1"].font = cls.TITLE_FONT

        headers = [
            "Verse #",
            "Original Awadhi (अवधी)" if text.content_id == "VEDA-TXT-00008" else "Original Sanskrit",
            "IAST (Roman)",
            "Hindi (हिन्दी)",
            "Telugu (తెలుగు)",
            "Tamil (தமிழ்)",
            "Kannada (ಕನ್ನಡ)",
            "Marathi (मराठी)",
            "Bengali (বাংলা)",
            "Gujarati (ગુજરાતી)",
            "Malayalam (മലയാളം)",
            "Odia (ଓଡ଼ିଆ)",
            "English (Bhavartha)",
        ]
        ws_comp.append([])
        ws_comp.append(headers)

        num_cols = len(headers)
        for col_idx in range(1, num_cols + 1):
            cell = ws_comp.cell(row=3, column=col_idx)
            cell.fill = cls.MAROON_HEADER
            cell.font = cls.HEADER_FONT
            cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

        row = 4
        for v in sorted_verses:
            trans_by_lang = {t.target_language: t.translated_text for t in v.translations}
            ws_comp.cell(row=row, column=1, value=v.verse_number).alignment = Alignment(horizontal="center", vertical="top")
            ws_comp.cell(row=row, column=2, value=v.devanagari_text).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=3, value=v.iast_text or "").font = cls.REGULAR_FONT
            ws_comp.cell(row=row, column=4, value=trans_by_lang.get("hi", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=5, value=trans_by_lang.get("te", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=6, value=trans_by_lang.get("ta", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=7, value=trans_by_lang.get("kn", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=8, value=trans_by_lang.get("mr", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=9, value=trans_by_lang.get("bn", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=10, value=trans_by_lang.get("gu", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=11, value=trans_by_lang.get("ml", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=12, value=trans_by_lang.get("or", "")).font = cls.INDIC_FONT
            ws_comp.cell(row=row, column=13, value=trans_by_lang.get("en", "")).font = cls.REGULAR_FONT

            for c in range(1, num_cols + 1):
                ws_comp.cell(row=row, column=c).border = cls.BORDER_THIN
                ws_comp.cell(row=row, column=c).alignment = Alignment(wrap_text=True, vertical="top")
                if row % 2 == 1:
                    ws_comp.cell(row=row, column=c).fill = cls.ZEBRA_TINT
            row += 1

        # Auto-fit columns
        widths = {1: 10, 2: 38, 3: 35, 4: 40, 5: 40, 6: 40, 7: 40, 8: 40, 9: 40, 10: 40, 11: 40, 12: 40, 13: 45}
        for col_idx, w in widths.items():
            ws_comp.column_dimensions[get_column_letter(col_idx)].width = w

        wb.save(output_path)
        return output_path

    @classmethod
    def export_word(cls, text: Text, output_path: str) -> str:
        doc = Document()

        # Title
        p_title = doc.add_paragraph()
        p_title.paragraph_format.space_after = Pt(4)
        run_title = p_title.add_run(f"॥ {text.devanagari_title} ॥\n{text.canonical_title}")
        run_title.font.name = "Nirmala UI"
        run_title.font.size = Pt(18)
        run_title.font.bold = True
        run_title.font.color.rgb = RGBColor(128, 0, 32)

        p_sub = doc.add_paragraph(
            f"Multilingual Scholarly Edition — {'Awadhi' if text.content_id == 'VEDA-TXT-00008' else 'Sanskrit'}, Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Gujarati, Malayalam, Odia, and English"
        )
        p_sub.runs[0].font.name = "Georgia"
        p_sub.runs[0].font.size = Pt(11)
        p_sub.runs[0].font.italic = True
        doc.add_paragraph()

        # Sri Venkateswara Suprabhatam Table of Contents
        if text.content_id == "VEDA-TXT-00013":
            p_toc_head = doc.add_paragraph()
            p_toc_head.paragraph_format.space_after = Pt(2)
            r_th = p_toc_head.add_run("Canonical Four-Section Liturgical Architecture (Tirumala Canon):")
            r_th.font.name = "Georgia"
            r_th.font.size = Pt(11.5)
            r_th.font.bold = True
            r_th.font.color.rgb = RGBColor(128, 0, 32)

            sections_info = [
                ("Section 1: श्रीवेङ्कटेशसुप्रभातम् (Suprabhatam)", "Verses 1–29", "Awakening of the Lord & Vishvarupa Darshana"),
                ("Section 2: श्रीवेङ्कटेशस्तोत्रम् (Stotram)", "Verses 30–40", "Eulogy of Transcendent Form, Krishna & Rama Identity"),
                ("Section 3: श्रीवेङ्कटेशप्रपत्तिः (Prapatti)", "Verses 41–56", "Purushakara & Absolute Sharanagati at Lotus Feet"),
                ("Section 4: श्रीवेङ्कटेशमङ्गलाशासनम् (Mangalasasanam)", "Verses 57–70", "Auspicious Benediction wishing eternal victory"),
            ]
            tbl_toc = doc.add_table(rows=len(sections_info) + 1, cols=3)
            tbl_toc.autofit = False
            tbl_toc.columns[0].width = Inches(3.2)
            tbl_toc.columns[1].width = Inches(1.1)
            tbl_toc.columns[2].width = Inches(2.7)

            hdr_cells = tbl_toc.rows[0].cells
            for idx, title in enumerate(["Canonical Section", "Verse Range", "Liturgical & Theological Role"]):
                r = hdr_cells[idx].paragraphs[0].add_run(title)
                r.font.bold = True
                r.font.size = Pt(9.5)
                r.font.color.rgb = RGBColor(128, 0, 32)

            for s_idx, (sec_title, v_range, role) in enumerate(sections_info):
                row_cells = tbl_toc.rows[s_idx + 1].cells
                row_cells[0].paragraphs[0].add_run(sec_title).font.size = Pt(9)
                row_cells[1].paragraphs[0].add_run(v_range).font.size = Pt(9)
                row_cells[2].paragraphs[0].add_run(role).font.size = Pt(9)
            doc.add_paragraph()

        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)
        current_section = None

        for v in sorted_verses:
            # Section header insertion for Suprabhatam
            if text.content_id == "VEDA-TXT-00013":
                sec_banner = None
                if v.verse_number == 1:
                    sec_banner = "॥ प्रथमः भागः — श्रीवेङ्कटेशसुप्रभातम् (श्लोकाः १–२९) ॥\nSection 1: Sri Venkateswara Suprabhatam (Awakening of the Lord)"
                elif v.verse_number == 30:
                    sec_banner = "॥ द्वितीयः भागः — श्रीवेङ्कटेशस्तोत्रम् (श्लोकाः १–११ / ३०–४०) ॥\nSection 2: Sri Venkateswara Stotram (Eulogy of Divine Glories)"
                elif v.verse_number == 41:
                    sec_banner = "॥ तृतीयः भागः — श्रीवेङ्कटेशप्रपत्तिः (श्लोकाः १–१६ / ४१–५६) ॥\nSection 3: Sri Venkateswara Prapatti (Solemn Surrender at Lotus Feet)"
                elif v.verse_number == 57:
                    sec_banner = "॥ चतुर्थः भागः — श्रीवेङ्कटेशमङ्गलाशासनम् (श्लोकाः १–१४ / ५७–७०) ॥\nSection 4: Sri Venkateswara Mangalasasanam (Auspicious Benediction)"

                if sec_banner:
                    doc.add_paragraph()
                    p_sb = doc.add_paragraph()
                    r_sb = p_sb.add_run(sec_banner)
                    r_sb.font.name = "Nirmala UI"
                    r_sb.font.size = Pt(13)
                    r_sb.font.bold = True
                    r_sb.font.color.rgb = RGBColor(128, 0, 32)
                    doc.add_paragraph()

            # Verse header
            p_vnum = doc.add_paragraph()
            if text.content_id == "VEDA-TXT-00008":
                if v.verse_number == 1:
                    v_title = "❖ प्रारम्भिक दोहा १ / Opening Doha 1"
                elif v.verse_number == 2:
                    v_title = "❖ प्रारम्भिक दोहा २ / Opening Doha 2"
                elif v.verse_number == 43:
                    v_title = "❖ समापन दोहा / Concluding Doha"
                else:
                    v_title = f"❖ चौपाई {v.verse_number - 2} / Chaupai {v.verse_number - 2} (Verse {v.verse_number})"
            elif text.content_id == "VEDA-TXT-00013":
                if v.verse_number <= 29:
                    v_title = f"❖ सुप्रभात श्लोकः {v.verse_number} / Suprabhatam Sloka {v.verse_number}"
                elif v.verse_number <= 40:
                    v_title = f"❖ स्तोत्र श्लोकः {v.verse_number - 29} (Verse {v.verse_number}) / Stotram Sloka {v.verse_number - 29}"
                elif v.verse_number <= 56:
                    v_title = f"❖ प्रपत्ति श्लोकः {v.verse_number - 40} (Verse {v.verse_number}) / Prapatti Sloka {v.verse_number - 40}"
                else:
                    v_title = f"❖ मङ्गलाशासन श्लोकः {v.verse_number - 56} (Verse {v.verse_number}) / Mangalasasanam Sloka {v.verse_number - 56}"
            else:
                v_title = f"❖ श्लोकः {v.verse_number} / Verse {v.verse_number}"

            r_vnum = p_vnum.add_run(v_title)
            r_vnum.font.bold = True
            r_vnum.font.size = Pt(11)
            r_vnum.font.color.rgb = RGBColor(128, 0, 32)

            # Table for verse renderings
            orig_label = "Original Awadhi (अवधी)" if text.content_id == "VEDA-TXT-00008" else "Original Sanskrit"
            labels_data = [
                (orig_label, v.devanagari_text, "Nirmala UI", True),
                ("IAST (Roman)", v.iast_text or "", "Calibri", False),
            ]
            trans_map = {t.target_language: t.translated_text for t in v.translations}
            lang_items = [
                ("Hindi (हिन्दी)", trans_map.get("hi", ""), "Nirmala UI", False),
                ("Telugu (తెలుగు)", trans_map.get("te", ""), "Nirmala UI", False),
                ("Tamil (தமிழ்)", trans_map.get("ta", ""), "Nirmala UI", False),
                ("Kannada (ಕನ್ನಡ)", trans_map.get("kn", ""), "Nirmala UI", False),
                ("Marathi (मराठी)", trans_map.get("mr", ""), "Nirmala UI", False),
                ("Bengali (বাংলা)", trans_map.get("bn", ""), "Nirmala UI", False),
                ("Gujarati (ગુજરાતી)", trans_map.get("gu", ""), "Nirmala UI", False),
                ("Malayalam (മലയാളം)", trans_map.get("ml", ""), "Nirmala UI", False),
                ("Odia (ଓଡ଼ିଆ)", trans_map.get("or", ""), "Nirmala UI", False),
                ("English (Bhavartha)", trans_map.get("en", ""), "Calibri", False),
            ]
            labels_data.extend(lang_items)

            tbl = doc.add_table(rows=len(labels_data), cols=2)
            tbl.autofit = False
            tbl.columns[0].width = Inches(1.8)
            tbl.columns[1].width = Inches(5.0)

            for idx, (label, val, font_name, is_bold) in enumerate(labels_data):
                cell_lbl = tbl.cell(idx, 0)
                cell_val = tbl.cell(idx, 1)

                r_l = cell_lbl.paragraphs[0].add_run(label)
                r_l.font.bold = True
                r_l.font.size = Pt(9.5)
                r_l.font.color.rgb = RGBColor(80, 80, 80)

                r_v = cell_val.paragraphs[0].add_run(val)
                r_v.font.name = font_name
                r_v.font.size = Pt(10)
                r_v.font.bold = is_bold

            doc.add_paragraph()

        doc.save(output_path)
        return output_path

    @classmethod
    def export_json(cls, text: Text, output_path: str) -> str:
        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)
        payload = {
            "content_id": text.content_id,
            "canonical_title": text.canonical_title,
            "devanagari_title": text.devanagari_title,
            "composer": text.composer,
            "source_scripture": text.source_scripture,
            "verse_count": len(sorted_verses),
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "supported_languages": ["sa", "hi", "te", "ta", "kn", "mr", "bn", "gu", "ml", "or", "en"],
            "verses": [
                {
                    "verse_number": v.verse_number,
                    "verse_type": v.verse_type.value,
                    "original_sanskrit": v.devanagari_text,
                    "iast": v.iast_text,
                    "transliterations": {t.target_script: t.script_text for t in v.transliterations},
                    "translations": {
                        t.target_language: {
                            "type": t.translation_type.value,
                            "text": t.translated_text,
                            "translator": t.translator,
                            "review_status": t.review_status.value,
                        }
                        for t in v.translations
                    },
                }
                for v in sorted_verses
            ],
        }

        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)

        return output_path
