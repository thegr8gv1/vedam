"""
Vedic Heritage Platform — Phase 11D DOCX Packaging & OOXML Audit
Audits Microsoft Word manuscripts (.docx) as OOXML ZIP packages, inspecting
relationships, document XML, bidi paragraph/run tags, font tags, and table layout.
"""

from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

DEMO_DIR = Path("exports/multilingual_publication/demonstrations")


def audit_single_docx(docx_path: Path, is_rtl: bool):
    print(f"\n=======================================================")
    print(f"Auditing DOCX: {docx_path.name}")
    print(f"Path: {docx_path}")
    print(f"=======================================================")

    results = {
        "file": docx_path.name,
        "is_valid": True,
        "errors": [],
        "warnings": [],
        "details": {},
    }

    if not docx_path.exists():
        results["is_valid"] = False
        results["errors"].append(f"File not found: {docx_path}")
        return results

    try:
        zf = zipfile.ZipFile(docx_path, "r")
    except Exception as e:
        results["is_valid"] = False
        results["errors"].append(f"Invalid ZIP archive: {e}")
        return results

    namelist = zf.namelist()
    results["details"]["entries"] = namelist

    # 1. Mandatory OOXML parts
    mandatory_parts = ["[Content_Types].xml", "_rels/.rels", "word/document.xml"]
    for part in mandatory_parts:
        if part not in namelist:
            results["is_valid"] = False
            results["errors"].append(f"Missing mandatory OOXML part: {part}")

    # 2. Inspect word/document.xml
    try:
        doc_xml = zf.read("word/document.xml")
        root = ET.fromstring(doc_xml)
        results["details"]["doc_xml_size"] = len(doc_xml)

        w_ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

        # Check paragraphs and tables
        paragraphs = root.findall(".//w:p", w_ns)
        tables = root.findall(".//w:tbl", w_ns)
        results["details"]["paragraph_count"] = len(paragraphs)
        results["details"]["table_count"] = len(tables)

        # Check BiDi tags if RTL
        if is_rtl:
            # Look for <w:bidi/> or <w:jc w:val="right"/> or <w:rtl/>
            bidi_paragraphs = root.findall(".//w:pPr/w:bidi", w_ns)
            right_aligned = root.findall(".//w:pPr/w:jc[@w:val='right']", w_ns)
            rtl_runs = root.findall(".//w:rPr/w:rtl", w_ns)
            results["details"]["bidi_paragraphs"] = len(bidi_paragraphs)
            results["details"]["right_aligned_paragraphs"] = len(right_aligned)
            results["details"]["rtl_runs"] = len(rtl_runs)
            print(f"  RTL Features: {len(right_aligned)} right-aligned, {len(bidi_paragraphs)} w:bidi paragraphs, {len(rtl_runs)} w:rtl runs.")

            if len(right_aligned) == 0:
                results["warnings"].append("No right-aligned paragraphs found in RTL document.")
            if len(bidi_paragraphs) == 0 and len(rtl_runs) == 0:
                results["warnings"].append(
                    "NOTICE: Document uses paragraph alignment (WD_ALIGN_PARAGRAPH.RIGHT), but explicit <w:bidi/> or <w:rtl/> run tags are omitted in python-docx output."
                )

        # Check font references
        r_fonts = root.findall(".//w:rPr/w:rFonts", w_ns)
        fonts_found = set()
        for rf in r_fonts:
            for attr_name in ("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}ascii",
                              "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}hAnsi",
                              "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}cs"):
                val = rf.attrib.get(attr_name)
                if val:
                    fonts_found.add(val)
        results["details"]["fonts_referenced"] = list(fonts_found)
        print(f"  Fonts referenced: {results['details']['fonts_referenced']}")

    except Exception as e:
        results["is_valid"] = False
        results["errors"].append(f"Malformed word/document.xml: {e}")

    zf.close()

    print(f"Audit Result: {'PASSED' if results['is_valid'] else 'FAILED'}")
    print(f"Errors ({len(results['errors'])}):   {results['errors']}")
    print(f"Warnings ({len(results['warnings'])}): {results['warnings']}")
    return results


def check_office_availability():
    """Checks if MS Word or LibreOffice exists on the machine for headless rendering."""
    print("\n--- Checking MS Word / LibreOffice Availability for Document Conversion ---")
    soffice_path = shutil.which("soffice") or shutil.which("libreoffice")
    winword_path = shutil.which("winword")

    # Check common Windows paths for winword
    common_word_paths = [
        Path(r"C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"),
        Path(r"C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE"),
        Path(r"C:\Program Files\Microsoft Office\Office16\WINWORD.EXE"),
    ]
    for p in common_word_paths:
        if p.exists():
            winword_path = str(p)
            break

    print(f"LibreOffice (soffice): {soffice_path or 'NOT INSTALLED'}")
    print(f"Microsoft Word:        {winword_path or 'NOT INSTALLED'}")
    return soffice_path, winword_path


def main():
    print("=================================================================")
    print("PHASE 11D AUDIT: DOCX Packaging & OOXML Structure")
    print("=================================================================")

    check_office_availability()

    all_audits = []
    docx_files = [
        (DEMO_DIR / "hindi_deva/docx/VEDA-TXT-00001_ganesha_pancharatnam_hi-Deva_draft_export.docx", False),
        (DEMO_DIR / "telugu_telu/docx/VEDA-TXT-00006_gayatri_vedic_mantra_te-Telu_draft_export.docx", False),
        (DEMO_DIR / "urdu_arab/docx/VEDA-TXT-00006_gayatri_vedic_mantra_ur-Arab_draft_export.docx", True),
    ]

    for p, is_rtl in docx_files:
        res = audit_single_docx(p, is_rtl)
        all_audits.append(res)

    out_file = Path("exports/audit_evidence/phase11d_audit/docx_audit_findings.json")
    out_file.parent.mkdir(parents=True, exist_ok=True)
    import json
    out_file.write_text(json.dumps(all_audits, indent=2), encoding="utf-8")
    print(f"\nAll DOCX audit results saved to: {out_file.resolve()}")


if __name__ == "__main__":
    main()
