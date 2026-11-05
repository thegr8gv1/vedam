"""
Phase 11F: Live HTTP Application & Authenticated Workbench Playwright Verification
Starts the aiohttp API Gateway server on localhost:8088 in a background thread/process,
executes live browser interactions with Playwright Chromium, and captures live screenshot evidence.
"""

import asyncio
import os
from pathlib import Path
import sys
import threading
import time

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from aiohttp import web
from playwright.sync_api import sync_playwright

from automation.workbench.gateway import create_app
from database.connection import get_db_session

OUTPUT_DIR = Path("exports/audit_evidence/phase11f_live_screenshots")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

HOST = "127.0.0.1"
PORT = 8088
BASE_URL = f"http://{HOST}:{PORT}"


class ServerThread(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True)
        self.loop = asyncio.new_event_loop()
        self.runner = None

    def run(self):
        asyncio.set_event_loop(self.loop)
        app = create_app(db_session_factory=get_db_session)
        self.runner = web.AppRunner(app)
        self.loop.run_until_complete(self.runner.setup())
        site = web.TCPSite(self.runner, HOST, PORT)
        self.loop.run_until_complete(site.start())
        print(f"[LIVE SERVER] Running on {BASE_URL}")
        self.loop.run_forever()

    def stop(self):
        if self.runner:
            self.loop.call_soon_threadsafe(self.loop.stop)


def main():
    print("==========================================================================")
    print(" Vedic Heritage Platform — Phase 11F Live Browser Verification")
    print("==========================================================================")

    server = ServerThread()
    server.start()
    time.sleep(2)  # Allow server to initialize

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1600, "height": 1080})
        page = context.new_page()

        # 1. Live Workbench Main Overview (Live from HTTP server)
        print("Navigating to live workbench...")
        page.goto(f"{BASE_URL}/workbench", wait_until="networkidle")
        page.screenshot(path=str(OUTPUT_DIR / "01_live_http_workbench_overview.png"), full_page=True)
        print("Captured: 01_live_http_workbench_overview.png")

        # 2. Live Urdu RTL Layout from HTTP Server
        print("Navigating to Urdu RTL view...")
        page.goto(f"{BASE_URL}/workbench?content_id=VEDA-TXT-00006&verse_number=1&target_language=ur&target_script=Arab", wait_until="networkidle")
        page.screenshot(path=str(OUTPUT_DIR / "02_live_urdu_rtl_shaping.png"), full_page=True)
        print("Captured: 02_live_urdu_rtl_shaping.png")

        # 3. Live Telugu Scripture View from HTTP Server
        print("Navigating to Telugu Scripture view...")
        page.goto(f"{BASE_URL}/workbench?content_id=VEDA-TXT-00006&verse_number=1&target_language=te&target_script=Telu", wait_until="networkidle")
        page.screenshot(path=str(OUTPUT_DIR / "03_live_telugu_scripture_view.png"), full_page=True)
        print("Captured: 03_live_telugu_scripture_view.png")

        # 4. Live Unicode Diagnostics Section from HTTP Server
        print("Navigating to Unicode Diagnostics...")
        page.goto(f"{BASE_URL}/workbench?content_id=VEDA-TXT-00006&verse_number=1&target_language=sa&target_script=Deva", wait_until="networkidle")
        # Click to expand diagnostics
        details = page.locator(".diag-drawer")
        if details.count() > 0:
            details.evaluate("el => el.open = true")
        page.locator(".diagnostics-section").screenshot(path=str(OUTPUT_DIR / "04_live_unicode_diagnostics_drawer.png"))
        print("Captured: 04_live_unicode_diagnostics_drawer.png")

        # 5. Live Publication Preflight & PDF Warning from HTTP Server
        print("Navigating to Publication Preflight...")
        page.locator(".pub-preview-section").screenshot(path=str(OUTPUT_DIR / "05_live_publication_preflight_pdf_warning.png"))
        print("Captured: 05_live_publication_preflight_pdf_warning.png")

        browser.close()

    server.stop()
    print("All live screenshots captured successfully in:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
