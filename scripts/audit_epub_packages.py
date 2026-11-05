"""
Vedic Heritage Platform — Phase 11D EPUB 3 Structural & Standards Compliance Audit
Performs rigorous structural, XML, and EPUB 3 packaging audits on all demonstration EPUBs.
"""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import zipfile

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

DEMO_DIR = Path("exports/multilingual_publication/demonstrations")


def audit_single_epub(epub_path: Path, expected_dir: str):
    print(f"\n=======================================================")
    print(f"Auditing EPUB: {epub_path.name}")
    print(f"Path: {epub_path}")
    print(f"=======================================================")

    results = {
        "file": epub_path.name,
        "is_valid": True,
        "errors": [],
        "warnings": [],
        "details": {},
    }

    if not epub_path.exists():
        results["is_valid"] = False
        results["errors"].append(f"File not found: {epub_path}")
        return results

    try:
        zf = zipfile.ZipFile(epub_path, "r")
    except Exception as e:
        results["is_valid"] = False
        results["errors"].append(f"Invalid ZIP archive: {e}")
        return results

    namelist = zf.namelist()
    results["details"]["total_entries"] = len(namelist)
    results["details"]["entries"] = namelist

    # 1. First entry must be mimetype
    if not namelist or namelist[0] != "mimetype":
        results["is_valid"] = False
        results["errors"].append(f"First entry in archive is '{namelist[0] if namelist else 'EMPTY'}', expected 'mimetype'.")
    else:
        info = zf.getinfo("mimetype")
        if info.compress_type != zipfile.ZIP_STORED:
            results["is_valid"] = False
            results["errors"].append(f"Mimetype entry compress_type is {info.compress_type}, expected ZIP_STORED (0).")
        mimetype_content = zf.read("mimetype")
        if mimetype_content != b"application/epub+zip":
            results["is_valid"] = False
            results["errors"].append(f"Mimetype content is {mimetype_content}, expected b'application/epub+zip'.")
        if len(info.extra) > 0:
            results["warnings"].append(f"Mimetype entry contains extra field of length {len(info.extra)}.")

    # 2. Check META-INF/container.xml
    if "META-INF/container.xml" not in namelist:
        results["is_valid"] = False
        results["errors"].append("Missing META-INF/container.xml.")
    else:
        try:
            c_xml = zf.read("META-INF/container.xml")
            c_root = ET.fromstring(c_xml)
            # Find rootfile
            ns = {"c": "urn:oasis:names:tc:opendocument:xmlns:container"}
            rootfile = c_root.find(".//c:rootfile", ns)
            if rootfile is None:
                rootfile = c_root.find(".//rootfile")
            if rootfile is None:
                results["is_valid"] = False
                results["errors"].append("No rootfile element found in container.xml.")
            else:
                opf_path = rootfile.attrib.get("full-path")
                media_type = rootfile.attrib.get("media-type")
                results["details"]["opf_path"] = opf_path
                results["details"]["opf_media_type"] = media_type
                if media_type != "application/oebps-package+xml":
                    results["warnings"].append(f"Unexpected OPF media-type: {media_type}")
        except Exception as e:
            results["is_valid"] = False
            results["errors"].append(f"Malformed META-INF/container.xml: {e}")

    # 3. Check OEBPS/content.opf
    opf_file = results["details"].get("opf_path", "OEBPS/content.opf")
    if opf_file not in namelist:
        results["is_valid"] = False
        results["errors"].append(f"OPF file '{opf_file}' referenced in container.xml does not exist in archive.")
    else:
        try:
            opf_xml = zf.read(opf_file)
            opf_root = ET.fromstring(opf_xml)
            results["details"]["opf_version"] = opf_root.attrib.get("version")

            # Check manifest items
            manifest_items = {}
            for item in opf_root.findall(".//{http://www.idpf.org/2007/opf}item"):
                item_id = item.attrib.get("id")
                href = item.attrib.get("href")
                mtype = item.attrib.get("media-type")
                props = item.attrib.get("properties", "")
                manifest_items[item_id] = (href, mtype, props)

            results["details"]["manifest_count"] = len(manifest_items)

            # Check if all manifest hrefs exist in zip
            for item_id, (href, mtype, props) in manifest_items.items():
                expected_zip_path = f"OEBPS/{href}" if not href.startswith("OEBPS/") else href
                if expected_zip_path not in namelist:
                    results["is_valid"] = False
                    results["errors"].append(f"Manifest item '{item_id}' href '{href}' not found at '{expected_zip_path}'.")

            # Check spine
            spine_elem = opf_root.find(".//{http://www.idpf.org/2007/opf}spine")
            if spine_elem is None:
                results["is_valid"] = False
                results["errors"].append("Missing spine element in OPF.")
            else:
                prog_dir = spine_elem.attrib.get("page-progression-direction", "ltr")
                results["details"]["page_progression_direction"] = prog_dir
                if prog_dir != expected_dir:
                    results["is_valid"] = False
                    results["errors"].append(f"Spine page-progression-direction is '{prog_dir}', expected '{expected_dir}'.")

        except Exception as e:
            results["is_valid"] = False
            results["errors"].append(f"Malformed OPF: {e}")

    # 4. Check OEBPS/nav.xhtml
    if "OEBPS/nav.xhtml" not in namelist:
        results["is_valid"] = False
        results["errors"].append("Missing OEBPS/nav.xhtml.")
    else:
        try:
            nav_xml = zf.read("OEBPS/nav.xhtml")
            nav_root = ET.fromstring(nav_xml)
            results["details"]["nav_lang"] = nav_root.attrib.get("lang") or nav_root.attrib.get("{http://www.w3.org/XML/1998/namespace}lang")
            results["details"]["nav_dir"] = nav_root.attrib.get("dir")
        except Exception as e:
            results["is_valid"] = False
            results["errors"].append(f"Malformed OEBPS/nav.xhtml XML: {e}")

    # 5. Check all XHTML files
    xhtml_files = [n for n in namelist if n.endswith(".xhtml") or n.endswith(".html")]
    for xf in xhtml_files:
        try:
            content = zf.read(xf)
            ET.fromstring(content)
        except Exception as e:
            results["is_valid"] = False
            results["errors"].append(f"Malformed XHTML in {xf}: {e}")

    zf.close()

    print(f"Audit Result: {'PASSED' if results['is_valid'] else 'FAILED'}")
    print(f"Errors ({len(results['errors'])}):   {results['errors']}")
    print(f"Warnings ({len(results['warnings'])}): {results['warnings']}")
    print(f"Details: {results['details']}")
    return results


def main():
    print("=================================================================")
    print("PHASE 11D AUDIT: EPUB 3 Packaging & Standards Compliance")
    print("=================================================================")

    all_audits = []

    epubs = [
        (DEMO_DIR / "hindi_deva/epub/VEDA-TXT-00001_ganesha_pancharatnam_hi-Deva_draft_export.epub", "ltr"),
        (DEMO_DIR / "telugu_telu/epub/VEDA-TXT-00006_gayatri_vedic_mantra_te-Telu_draft_export.epub", "ltr"),
        (DEMO_DIR / "urdu_arab/epub/VEDA-TXT-00006_gayatri_vedic_mantra_ur-Arab_draft_export.epub", "rtl"),
    ]

    for p, exp_dir in epubs:
        res = audit_single_epub(p, exp_dir)
        all_audits.append(res)

    out_file = Path("exports/audit_evidence/phase11d_audit/epub_audit_findings.json")
    out_file.parent.mkdir(parents=True, exist_ok=True)
    import json
    out_file.write_text(json.dumps(all_audits, indent=2), encoding="utf-8")
    print(f"\nAll EPUB audit results saved to: {out_file.resolve()}")


if __name__ == "__main__":
    main()
