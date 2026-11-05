"""
Vedic Heritage Platform — Phase 11D Publication Package Demonstrations
Generates complete 4-format publication packages (HTML, PDF, DOCX, EPUB) for:
1. Indic Devanagari text: Shri Shiv Tandava Stotram in Hindi (hi-Deva)
2. Indic South Indian text: Gayatri Mantra in Telugu (te-Telu)
3. Perso-Arabic RTL text: Gayatri Mantra in Urdu (ur-Arab)
All generated strictly under channel 'draft_export' with non-bypassable DRAFT watermarks.
"""

from pathlib import Path
import sqlite3
import sys

# Ensure repository root in path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from automation.exporters.multilingual_publication_orchestrator import (
    MultilingualPublicationOrchestrator,
)
from database.connection import get_db_session

DEMO_DIR = Path("exports/multilingual_publication/demonstrations")


def main():
    print("=================================================================")
    print("Vedic Heritage Platform — Generating Phase 11D Demonstrations")
    print("=================================================================")

    DEMO_DIR.mkdir(parents=True, exist_ok=True)

    with get_db_session() as session:
        # Package 1: Devanagari Hindi (VEDA-TXT-00001)
        print("\n--- [Package 1] Generating Hindi (hi-Deva) Publication Package ---")
        manifest_hi = MultilingualPublicationOrchestrator.export_text_from_database(
            session=session,
            text_id_or_content_id="VEDA-TXT-00001",
            target_language="hi",
            target_script="Deva",
            publication_channel="draft_export",
            formats=["html", "pdf", "docx", "epub"],
            output_dir=DEMO_DIR / "hindi_deva",
        )
        print(f"Content: {manifest_hi.canonical_title} [{manifest_hi.target_bcp47}]")
        print(f"Gate Verdict: {manifest_hi.gate_verdict}")
        for fmt, art in manifest_hi.artifacts.items():
            print(f"  [{fmt.upper()}] {art.file_path} ({art.file_size_bytes:,} bytes, sha256: {art.sha256_hash[:16]}...)")

        # Package 2: Non-Devanagari Telugu (VEDA-TXT-00006)
        print("\n--- [Package 2] Generating Telugu (te-Telu) Publication Package ---")
        manifest_te = MultilingualPublicationOrchestrator.export_text_from_database(
            session=session,
            text_id_or_content_id="VEDA-TXT-00006",
            target_language="te",
            target_script="Telu",
            publication_channel="draft_export",
            formats=["html", "pdf", "docx", "epub"],
            output_dir=DEMO_DIR / "telugu_telu",
        )
        print(f"Content: {manifest_te.canonical_title} [{manifest_te.target_bcp47}]")
        print(f"Gate Verdict: {manifest_te.gate_verdict}")
        for fmt, art in manifest_te.artifacts.items():
            print(f"  [{fmt.upper()}] {art.file_path} ({art.file_size_bytes:,} bytes, sha256: {art.sha256_hash[:16]}...)")

        # Package 3: RTL Perso-Arabic Urdu (VEDA-TXT-00006)
        print("\n--- [Package 3] Generating Urdu (ur-Arab) RTL Publication Package ---")
        manifest_ur = MultilingualPublicationOrchestrator.export_text_from_database(
            session=session,
            text_id_or_content_id="VEDA-TXT-00006",
            target_language="ur",
            target_script="Arab",
            publication_channel="draft_export",
            formats=["html", "pdf", "docx", "epub"],
            output_dir=DEMO_DIR / "urdu_arab",
        )
        print(f"Content: {manifest_ur.canonical_title} [{manifest_ur.target_bcp47}]")
        print(f"Gate Verdict: {manifest_ur.gate_verdict}")
        for fmt, art in manifest_ur.artifacts.items():
            print(f"  [{fmt.upper()}] {art.file_path} ({art.file_size_bytes:,} bytes, sha256: {art.sha256_hash[:16]}...)")

    print("\n=================================================================")
    print("ALL THREE DEMONSTRATION PUBLICATION PACKAGES GENERATED CLEANLY!")
    print("=================================================================")


if __name__ == "__main__":
    main()
