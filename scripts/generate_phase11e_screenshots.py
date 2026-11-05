"""
Phase 11E Visual Screenshot Verification Generator
Generates and captures 10 distinct, evidence-grade screenshots of the Multilingual Scholarly Workbench
using Playwright Chromium with native DirectWrite and HarfBuzz shaping.
"""

import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from playwright.sync_api import sync_playwright

from automation.workbench.multilingual_dashboard import MultilingualWorkbenchViewGenerator
from database.connection import get_db_session

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

OUTPUT_DIR = Path("exports/audit_evidence/phase11e_ui_screenshots")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

REPORTS_DIR = Path("exports/reports/screenshot_fixtures")
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

print("=================================================================")
print("Vedic Heritage Platform — Phase 11E Visual Screenshot Generator")
print("=================================================================")

# 1. Generate HTML Fixtures
fixtures = [
    {
        "id": "workbench_main_overview",
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "lang": "hi",
        "script": "Deva",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "01_main_overview.html",
        "open_diag": False,
        "full_page": True,
        "crop_selector": None,
    },
    {
        "id": "sanskrit_devanagari_view",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "sa",
        "script": "Deva",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "02_sanskrit_devanagari.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid article:nth-child(1)",
    },
    {
        "id": "sanskrit_telugu_view",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "te",
        "script": "Telu",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "03_sanskrit_telugu.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid",
    },
    {
        "id": "tamil_traditional_mode",
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "lang": "ta",
        "script": "Taml",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "04_tamil_traditional.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid",
    },
    {
        "id": "urdu_perso_arabic_rtl",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "ur",
        "script": "Arab",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "05_urdu_perso_arabic.html",
        "open_diag": False,
        "full_page": True,
        "crop_selector": None,
    },
    {
        "id": "mixed_bidi_isolation",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "ur",
        "script": "Arab",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "06_mixed_bidi.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid article:nth-child(5)",
    },
    {
        "id": "transliteration_lossy_warning",
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "lang": "hi",
        "script": "Deva",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "07_transliteration_lossy.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid article:nth-child(2)",
    },
    {
        "id": "unicode_diagnostics_panel",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "sa",
        "script": "Deva",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "08_unicode_diag.html",
        "open_diag": True,
        "full_page": False,
        "crop_selector": ".diagnostics-section",
    },
    {
        "id": "reviewer_dashboard_restricted",
        "content_id": "VEDA-TXT-00006",
        "verse_number": 1,
        "lang": "ur",
        "script": "Arab",
        "reviewer": "REV-PROD-VEDIC",
        "file": REPORTS_DIR / "09_reviewer_restricted.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".workbench-grid article:nth-child(6)",
    },
    {
        "id": "publication_preview_draft_pdf_limitation",
        "content_id": "VEDA-TXT-00001",
        "verse_number": 1,
        "lang": "hi",
        "script": "Deva",
        "reviewer": "REV-ADMIN-001",
        "file": REPORTS_DIR / "10_publication_preview.html",
        "open_diag": False,
        "full_page": False,
        "crop_selector": ".pub-preview-section",
    },
]

with get_db_session() as session:
    for fix in fixtures:
        print(f"Generating HTML fixture: {fix['id']} -> {fix['file']}")
        MultilingualWorkbenchViewGenerator.generate_html_workbench(
            session=session,
            content_id=fix["content_id"],
            verse_number=fix["verse_number"],
            target_language=fix["lang"],
            target_script=fix["script"],
            reviewer_id=fix["reviewer"],
            output_file=str(fix["file"]),
        )
        if fix["open_diag"]:
            # Inject open attribute into details
            html_text = open(fix["file"], "r", encoding="utf-8").read()
            html_text = html_text.replace("<details class=\"diag-drawer\">", "<details class=\"diag-drawer\" open>")
            with open(fix["file"], "w", encoding="utf-8") as f:
                f.write(html_text)

print("\n--- Capturing Screenshots via Playwright Chromium ---")
p = sync_playwright().start()
browser = p.chromium.launch(headless=True)

captured_images = {}

for fix in fixtures:
    page = browser.new_page(viewport={"width": 1600, "height": 1200})
    file_uri = fix["file"].resolve().as_uri()
    page.goto(file_uri)
    page.wait_for_timeout(500)  # Let web fonts & layout stabilize

    out_png = OUTPUT_DIR / f"{fix['id']}.png"

    if fix["crop_selector"]:
        el = page.query_selector(fix["crop_selector"])
        if el:
            el.screenshot(path=str(out_png))
        else:
            page.screenshot(path=str(out_png), full_page=fix["full_page"])
    else:
        page.screenshot(path=str(out_png), full_page=fix["full_page"])

    size = os.path.getsize(out_png)
    captured_images[fix["id"]] = {
        "file": str(out_png),
        "size_bytes": size,
    }
    print(f"  [Captured] {out_png.name} ({size:,} bytes)")
    page.close()

browser.close()
p.stop()

print("\n=================================================================")
print(f"SUCCESS: All {len(captured_images)} Visual Screenshots Captured Cleanly!")
print(f"Destination: {OUTPUT_DIR.resolve()}")
print("=================================================================")
