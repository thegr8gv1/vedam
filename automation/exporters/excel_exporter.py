"""
Vedic Heritage Platform — Professional Excel Exporter
Generates multi-worksheet formatted Excel workbooks using openpyxl with
proper Indic Unicode support, frozen headers, and rights provenance tracking.
"""

from pathlib import Path
from typing import Any, Dict, List, Optional
import openpyxl
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

from automation.rights.engine import RightsProvenanceEngine
from database.models import ReleaseStatus, Text


class ExcelExporter:
    """Exports structured sacred literature datasets to professional Excel (.xlsx) workbooks."""

    HEADER_FILL = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")  # Navy Blue
    ACCENT_FILL = PatternFill(start_color="F59E0B", end_color="F59E0B", fill_type="solid")  # Amber
    GREEN_FILL = PatternFill(start_color="10B981", end_color="10B981", fill_type="solid")   # Emerald Green
    HEADER_FONT = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    TITLE_FONT = Font(name="Calibri", size=14, bold=True, color="1E3A8A")
    REGULAR_FONT = Font(name="Calibri", size=10)
    DEVANAGARI_FONT = Font(name="Nirmala UI", size=11)
    BORDER_THIN = Border(
        left=Side(style="thin", color="D1D5DB"),
        right=Side(style="thin", color="D1D5DB"),
        top=Side(style="thin", color="D1D5DB"),
        bottom=Side(style="thin", color="D1D5DB"),
    )

    @classmethod
    def export_text_bundle(cls, text: Text, output_path: str, target_channel: str = "scholarly_review") -> str:
        """
        Export a single master text with all verses, transliterations, translations,
        and legal provenance into an Excel workbook.
        """
        # Verify rights gatekeeping
        RightsProvenanceEngine.assert_export_clearance(text.rights, target_channel)

        wb = openpyxl.Workbook()
        # Remove default sheet
        default_sheet = wb.active
        wb.remove(default_sheet)

        # 1. Sheet: Master Overview
        cls._create_overview_sheet(wb, text)

        # 2. Sheet: Verses & Translations
        cls._create_verses_sheet(wb, text)

        # 3. Sheet: Rights & Provenance
        cls._create_rights_sheet(wb, text)

        # Save workbook
        out_file = Path(output_path)
        out_file.parent.mkdir(parents=True, exist_ok=True)
        wb.save(str(out_file))
        return str(out_file)

    @classmethod
    def _create_overview_sheet(cls, wb: openpyxl.Workbook, text: Text) -> None:
        ws = wb.create_sheet(title="Overview & Metadata")
        ws.views.sheetView[0].showGridLines = True

        ws["A1"] = "Vedic Heritage Digital Library — Master Text Record"
        ws["A1"].font = cls.TITLE_FONT
        ws.merge_cells("A1:D1")

        metadata_rows = [
            ("Content ID", text.content_id),
            ("Canonical English Title", text.canonical_title),
            ("Devanagari Title", text.devanagari_title),
            ("Deity", text.deity.name if text.deity else "N/A"),
            ("Primary Category", text.primary_category.name if text.primary_category else "N/A"),
            ("Language / Script", f"{text.original_language} ({text.original_script})"),
            ("Composer / Attribution", text.composer or "Traditional / Ancient"),
            ("Rishi (Seer)", text.rishi or "N/A"),
            ("Chandas (Metre)", text.chandas or "N/A"),
            ("Devata", text.devata or "N/A"),
            ("Source Scripture", text.source_scripture or "N/A"),
            ("Associated Festival", text.associated_festival or "N/A"),
            ("Traditional Usage", text.traditional_usage or "N/A"),
            ("Total Verses", text.verse_count),
            ("Content SHA-256 Hash", text.content_hash),
            ("Universal UUID", text.uuid),
            ("Release Status", text.rights.release_status.value if text.rights else "UNAUDITED"),
        ]

        row_idx = 3
        for label, val in metadata_rows:
            ws.cell(row=row_idx, column=1, value=label).font = Font(name="Calibri", size=10, bold=True)
            cell_val = ws.cell(row=row_idx, column=2, value=str(val))
            cell_val.font = cls.DEVANAGARI_FONT if label == "Devanagari Title" else cls.REGULAR_FONT
            if label == "ReleaseStatus":
                cell_val.font = Font(name="Calibri", size=10, bold=True, color="10B981" if val == "GREEN" else "EF4444")
            row_idx += 1

        cls._autofit_columns(ws)

    @classmethod
    def _create_verses_sheet(cls, wb: openpyxl.Workbook, text: Text) -> None:
        ws = wb.create_sheet(title="Verses & Translations")
        ws.views.sheetView[0].showGridLines = True
        ws.freeze_panes = "A2"

        headers = [
            "Verse ID",
            "Verse #",
            "Type",
            "Devanagari (Original)",
            "IAST Transliteration",
            "Telugu Script",
            "Tamil Script",
            "English Meaning (Bhavartha)",
            "Word-by-Word Analysis",
            "Metre / Notes",
        ]

        for col_idx, h in enumerate(headers, start=1):
            cell = ws.cell(row=1, column=col_idx, value=h)
            cell.font = cls.HEADER_FONT
            cell.fill = cls.HEADER_FILL
            cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

        for row_idx, verse in enumerate(text.verses, start=2):
            # Locate Telugu and Tamil transliterations if present
            te_text = next((t.script_text for t in verse.transliterations if t.target_script == "telugu"), "")
            ta_text = next((t.script_text for t in verse.transliterations if t.target_script == "tamil"), "")
            
            # Locate English Bhavartha and word-by-word
            en_trans = next((t.translated_text for t in verse.translations if t.target_language == "en"), "")
            wbw_trans = next((str(t.word_by_word_json) for t in verse.translations if t.word_by_word_json), "")

            row_data = [
                verse.verse_id,
                verse.verse_number,
                verse.verse_type.value,
                verse.devanagari_text,
                verse.iast_text or "",
                te_text,
                ta_text,
                en_trans,
                wbw_trans,
                f"{verse.meter or ''} {verse.notes or ''}".strip(),
            ]

            for col_idx, val in enumerate(row_data, start=1):
                cell = ws.cell(row=row_idx, column=col_idx, value=val)
                cell.font = cls.DEVANAGARI_FONT if col_idx in {4, 6, 7} else cls.REGULAR_FONT
                cell.border = cls.BORDER_THIN
                cell.alignment = Alignment(vertical="top", wrap_text=True)

        cls._autofit_columns(ws, max_width=45)

    @classmethod
    def _create_rights_sheet(cls, wb: openpyxl.Workbook, text: Text) -> None:
        ws = wb.create_sheet(title="Rights & Provenance")
        ws.views.sheetView[0].showGridLines = True

        ws["A1"] = "Mandatory Content Rights, Licensing & Provenance Audit"
        ws["A1"].font = cls.TITLE_FONT
        ws.merge_cells("A1:C1")

        rights = text.rights
        if not rights:
            ws["A3"] = "WARNING: No ContentRights record linked to this text."
            ws["A3"].font = Font(name="Calibri", size=11, bold=True, color="EF4444")
            return

        rights_data = [
            ("Release Status", rights.release_status.value),
            ("Original Composition Attribution", rights.original_composition_attribution),
            ("Primary Source", rights.primary_source),
            ("Specific Edition", rights.specific_edition or "N/A"),
            ("Publication Date", rights.edition_publication_date or "N/A"),
            ("Transcription Contributor", rights.transcription_contributor or "N/A"),
            ("Source URL", rights.source_url or "N/A"),
            ("Copyright Owner", rights.copyright_owner or "Public Domain / Traditional"),
            ("License Type", rights.license_type),
            ("License URL", rights.license_url or "N/A"),
            ("Commercial Reuse Permitted", "YES" if rights.commercial_reuse_permitted else "NO"),
            ("Translation Permitted", "YES" if rights.translation_permitted else "NO"),
            ("Derivative Work Permitted", "YES" if rights.derivative_work_permitted else "NO"),
            ("Distribution Permitted", "YES" if rights.distribution_permitted else "NO"),
            ("Attribution Required", "YES" if rights.attribution_required else "NO"),
            ("Required Attribution Text", rights.attribution_text or "N/A"),
            ("Written Permission Reference", rights.written_permission_reference or "N/A"),
            ("Review Date", rights.review_date.strftime("%Y-%m-%d %H:%M:%S UTC") if rights.review_date else "N/A"),
            ("Supporting Evidence", rights.supporting_evidence or "N/A"),
        ]

        row_idx = 3
        for label, val in rights_data:
            ws.cell(row=row_idx, column=1, value=label).font = Font(name="Calibri", size=10, bold=True)
            cell_val = ws.cell(row=row_idx, column=2, value=val)
            cell_val.font = cls.REGULAR_FONT
            if label == "Release Status":
                cell_val.font = Font(name="Calibri", size=12, bold=True, color="FFFFFF")
                cell_val.fill = cls.GREEN_FILL if val == "GREEN" else cls.ACCENT_FILL
            row_idx += 1

        cls._autofit_columns(ws, max_width=60)

    @staticmethod
    def _autofit_columns(ws: openpyxl.worksheet.worksheet.Worksheet, max_width: int = 50) -> None:
        for col in ws.columns:
            max_len = 0
            col_letter = get_column_letter(col[0].column)
            for cell in col:
                val = str(cell.value or "")
                if len(val) > max_len:
                    max_len = len(val)
            adjusted_width = min(max(max_len + 3, 12), max_width)
            ws.column_dimensions[col_letter].width = adjusted_width
