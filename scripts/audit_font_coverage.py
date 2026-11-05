"""
Vedic Heritage Platform — Phase 11D Font Coverage & Licensing Audit
Audits Windows font files (Nirmala.ttc, tahoma.ttf, calibri.ttf, arial.ttf, georgia.ttf)
inspecting font collections, subfont indices, script coverage, licenses, and embedding rights.
"""

from pathlib import Path
import os
import sys

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

import fitz  # PyMuPDF has built-in font inspection tools via Font/FreeType
from automation.exporters.typography import MultilingualTypographyEngine

FONTS_DIR = Path(r"C:\Windows\Fonts")


def audit_fonts():
    print("=================================================================")
    print("PHASE 11D AUDIT: Font Coverage & Licensing Matrix")
    print("=================================================================")

    target_fonts = [
        ("Nirmala.ttc", "TrueType Collection (TTC)", [0, 1]),
        ("tahoma.ttf", "TrueType Font (TTF)", None),
        ("calibri.ttf", "TrueType Font (TTF)", None),
        ("arial.ttf", "TrueType Font (TTF)", None),
        ("georgia.ttf", "TrueType Font (TTF)", None),
    ]

    font_audit_records = []

    for fname, ftype, indices in target_fonts:
        fpath = FONTS_DIR / fname
        exists = fpath.exists()
        size_bytes = fpath.stat().st_size if exists else 0
        print(f"\nFont: {fname}")
        print(f"  Path:       {fpath}")
        print(f"  Type:       {ftype}")
        print(f"  Exists:     {exists} ({size_bytes:,} bytes)")

        if not exists:
            font_audit_records.append({
                "font_file": fname,
                "exists": False,
            })
            continue

        # Inspect subfonts if TTC
        if indices is not None:
            for idx in indices:
                try:
                    f = fitz.Font(fontfile=str(fpath), fontindex=idx)
                    print(f"  Subfont [{idx}]: Name='{f.name}', Flags={f.flags}, Glyph count={f.glyph_count}")
                except Exception as e:
                    print(f"  Subfont [{idx}]: Error reading index {idx}: {e}")
        else:
            try:
                f = fitz.Font(fontfile=str(fpath))
                print(f"  Standalone: Name='{f.name}', Flags={f.flags}, Glyph count={f.glyph_count}")
            except Exception as e:
                print(f"  Standalone: Error reading font: {e}")

    # -----------------------------------------------------------------------
    # Script to Font Mapping & Legal Licensing Matrix
    # -----------------------------------------------------------------------
    print("\n--- Script-to-Font Legal Licensing & Redistribution Ledger ---")
    profiles = MultilingualTypographyEngine.FONT_PROFILES
    script_matrix = []

    for sc, prof in profiles.items():
        print(f"\nScript: {sc} ({prof.family_name})")
        print(f"  ReportLab Regular: {prof.reportlab_regular}")
        print(f"  Windows Files:     {prof.windows_file_names}")
        print(f"  License:           {prof.license}")
        print(f"  Embedding Rights:  {prof.embedding_rights}")
        print(f"  Shaping Engine:    {prof.shaping_engine}")
        print(f"  Limitations:       {prof.known_limitations}")

        # Legal Analysis:
        # Microsoft Windows fonts (Nirmala UI, Tahoma, Calibri, Arial, Georgia) are licensed
        # for use ON Windows OS. They are NOT redistributable or freely bundleable into Linux Docker
        # containers or EPUB archives!
        # For EPUB and Web/HTML, SIL Open Font License (OFL) fonts like Google Noto Sans or Charis SIL
        # must be used when distributing files to end users.
        is_ms_proprietary = "Microsoft" in prof.license

        record = {
            "script_code": sc,
            "family_name": prof.family_name,
            "reportlab_font": prof.reportlab_regular,
            "windows_files": list(prof.windows_file_names),
            "css_stack": prof.css_stack,
            "word_font": prof.word_font_name,
            "license": prof.license,
            "embedding_rights": prof.embedding_rights,
            "is_microsoft_proprietary": is_ms_proprietary,
            "open_source_alternative": "Google Noto Sans " + sc if sc != "Latn" else "Charis SIL / Gentium",
            "cross_platform_risk": (
                "High: Font is proprietary to Windows. Linux CI/CD or server environments will fail to find "
                f"{prof.windows_file_names[0]} unless Google Noto packages (fonts-noto) are installed."
                if is_ms_proprietary else "Low"
            ),
        }
        script_matrix.append(record)

    out_json = Path("exports/audit_evidence/phase11d_audit/font_licensing_matrix.json")
    out_json.parent.mkdir(parents=True, exist_ok=True)
    import json
    out_json.write_text(json.dumps(script_matrix, indent=2), encoding="utf-8")
    print(f"\nFont matrix saved to: {out_json.resolve()}")


if __name__ == "__main__":
    audit_fonts()
