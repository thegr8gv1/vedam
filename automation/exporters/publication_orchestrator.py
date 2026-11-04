"""
Vedic Heritage Platform — Central Publication Orchestrator
Coordinates multi-format publication exports (Excel 11-sheet, Word typeset manuscripts, and Indic PDF)
for all verified pilot texts through the publication quality gate.
"""

from datetime import datetime, timezone
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from automation.exporters.excel_publication_exporter import ExcelPublicationExporter
from automation.exporters.pdf_publication_exporter import PDFPublicationExporter
from automation.exporters.word_publication_exporter import WordPublicationExporter
from automation.validators.publication_gate import PublicationPreflightGate
from database.connection import get_db_session
from database.models import Text

logger = logging.getLogger("vedam.automation.publication_orchestrator")


class PublicationOrchestrator:
    """Central orchestrator for producing verified publication bundles across all formats."""

    EXPORT_DIRS = {
        "excel": "exports/excel",
        "word": "exports/word",
        "pdf": "exports/pdf",
    }

    @classmethod
    def ensure_export_directories(cls) -> None:
        for p in cls.EXPORT_DIRS.values():
            Path(p).mkdir(parents=True, exist_ok=True)

    @classmethod
    def publish_text(cls, text: Text, formats: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Publishes a single master text across requested formats (default: all).
        Enforces pre-flight publication gatekeeper.
        """
        cls.ensure_export_directories()
        formats = formats or ["excel", "word", "pdf"]

        # 1. Gatekeeper Assertion
        PublicationPreflightGate.assert_can_publish(text)

        slug = text.canonical_title.lower().replace(" ", "_").replace("-", "_")
        filename_base = f"{text.content_id}_{slug}"

        artifacts = {}

        # Excel Export
        if "excel" in formats:
            xlsx_path = os.path.join(cls.EXPORT_DIRS["excel"], f"{filename_base}.xlsx")
            ExcelPublicationExporter.export_publication_workbook(text, xlsx_path, enforce_gates=False)
            artifacts["excel"] = {
                "path": xlsx_path,
                "size_bytes": os.path.getsize(xlsx_path),
                "sheets": 11,
            }

        # Word Export
        if "word" in formats:
            docx_path = os.path.join(cls.EXPORT_DIRS["word"], f"{filename_base}.docx")
            WordPublicationExporter.export_publication_manuscript(text, docx_path, enforce_gates=False)
            artifacts["word"] = {
                "path": docx_path,
                "size_bytes": os.path.getsize(docx_path),
            }

        # PDF Export
        if "pdf" in formats:
            pdf_path = os.path.join(cls.EXPORT_DIRS["pdf"], f"{filename_base}.pdf")
            PDFPublicationExporter.export_publication_pdf(text, pdf_path, enforce_gates=False)
            artifacts["pdf"] = {
                "path": pdf_path,
                "size_bytes": os.path.getsize(pdf_path),
            }

        return {
            "content_id": text.content_id,
            "title": text.canonical_title,
            "verse_count": text.verse_count,
            "artifacts": artifacts,
            "published_at": datetime.now(timezone.utc).isoformat(),
        }

    @classmethod
    def publish_all_verified_pilots(cls, session) -> Dict[str, Any]:
        """Publishes all 8 verified pilot compositions across Excel, Word, and PDF."""
        pilot_ids = [
            "VEDA-TXT-00001",  # Ganesha Pancharatnam
            "VEDA-TXT-00002",  # Shiva Tandava Stotram
            "VEDA-TXT-00003",  # Aditya Hrudayam
            "VEDA-TXT-00004",  # Madhurashtakam
            "VEDA-TXT-00005",  # Mahamrityunjaya Mantra
            "VEDA-TXT-00006",  # Gayatri Mantra
            "VEDA-TXT-00007",  # Sri Suktam
            "VEDA-TXT-00008",  # Hanuman Chalisa
        ]

        results = {}
        for cid in pilot_ids:
            t = session.query(Text).filter_by(content_id=cid).first()
            if not t:
                continue
            res = cls.publish_text(t)
            results[cid] = res

        return results


if __name__ == "__main__":
    with get_db_session() as session:
        pub_report = PublicationOrchestrator.publish_all_verified_pilots(session)
        print("Publication Orchestration Complete:")
        for cid, info in pub_report.items():
            print(f"- {cid} ({info['title']}): {len(info['artifacts'])} formats generated")
            for fmt, det in info["artifacts"].items():
                print(f"    [{fmt.upper()}] {det['path']} ({det['size_bytes']} bytes)")
