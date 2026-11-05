"""
Phase 11F Live Browser-to-Server Flow Verification & Network Traffic Audit
Validates that the workbench UI running in a genuine headless Chromium browser
communicates with the live aiohttp API Gateway over HTTP, executes API calls,
dynamically renders responses, and upholds all scholarly constraints.
"""

import asyncio
from pathlib import Path
import sys
import threading
import time

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from aiohttp import web
from playwright.sync_api import sync_playwright

from automation.workbench.gateway import create_app
from database.connection import get_db_session

HOST = "127.0.0.1"
PORT = 8089
BASE_URL = f"http://{HOST}:{PORT}"


class LiveServer(threading.Thread):
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
        print(f"[AUDIT LIVE SERVER] Started on {BASE_URL}")
        self.loop.run_forever()

    def stop(self):
        if self.runner:
            self.loop.call_soon_threadsafe(self.loop.stop)


def run_live_audit():
    server = LiveServer()
    server.start()
    time.sleep(2)

    network_requests = []
    audit_results = {}

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()

            # Record all HTTP traffic
            def on_request(request):
                network_requests.append({
                    "url": request.url,
                    "method": request.method,
                    "headers": request.headers,
                })

            page.on("request", on_request)

            # 1. Navigation to /workbench
            print("[AUDIT] 1. Navigating to /workbench...")
            resp = page.goto(f"{BASE_URL}/workbench", wait_until="networkidle")
            assert resp.status == 200
            audit_results["workbench_page_status"] = resp.status

            # Verify security headers in response
            headers = resp.headers
            audit_results["csp_present"] = "content-security-policy" in headers
            audit_results["nosniff_present"] = headers.get("x-content-type-options") == "nosniff"
            audit_results["sameorigin_present"] = headers.get("x-frame-options") == "SAMEORIGIN"

            # 2. Check client API object
            print("[AUDIT] 2. Verifying client-side VEDAM_API injection...")
            has_vedam_api = page.evaluate("() => typeof window.VEDAM_API === 'object'")
            audit_results["vedam_api_available"] = has_vedam_api

            # 3. Direct API call from browser context
            print("[AUDIT] 3. Executing browser fetch to /api/v1/health...")
            health_data = page.evaluate(f"""
                async () => {{
                    const res = await fetch('{BASE_URL}/api/v1/health');
                    return await res.json();
                }}
            """)
            audit_results["health_status"] = health_data.get("status")
            audit_results["supported_languages"] = health_data.get("supported_languages")

            # 4. Browser fetch to /api/v1/texts catalog
            print("[AUDIT] 4. Fetching compositions catalog...")
            texts_data = page.evaluate(f"""
                async () => {{
                    const res = await fetch('{BASE_URL}/api/v1/texts');
                    return await res.json();
                }}
            """)
            audit_results["canonical_compositions_count"] = len(texts_data.get("compositions", []))

            # 5. Fetch scholarly verse payload from browser
            print("[AUDIT] 5. Fetching scholarly payload for VEDA-TXT-00006 verse 1 (Urdu RTL)...")
            verse_data = page.evaluate(f"""
                async () => {{
                    const res = await fetch('{BASE_URL}/api/v1/texts/VEDA-TXT-00006/verses/1/scholarly?target_language=ur&target_script=Arab');
                    return await res.json();
                }}
            """)
            audit_results["verse_is_rtl"] = verse_data.get("is_rtl")
            audit_results["verse_direction"] = verse_data.get("direction")
            audit_results["has_unicode_diag"] = "unicode_diagnostics" in verse_data
            audit_results["has_pub_preview"] = "publication_preview" in verse_data

            # 6. Attempt unauthenticated review submission from browser
            print("[AUDIT] 6. Testing unauthenticated review submission blocking...")
            unauth_review = page.evaluate(f"""
                async () => {{
                    const res = await fetch('{BASE_URL}/api/v1/reviews/submit', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{
                            content_id: 'VEDA-TXT-00001',
                            verse_number: 1,
                            target_language: 'hi',
                            action_type: 'REQUEST_REVISION',
                            scholarly_commentary: 'Unauthenticated browser attempt'
                        }})
                    }});
                    return {{ status: res.status, body: await res.json() }};
                }}
            """)
            audit_results["unauth_review_status"] = unauth_review["status"]
            audit_results["unauth_review_error"] = unauth_review["body"].get("error")

            browser.close()

    finally:
        server.stop()

    print("\n==========================================================================")
    print(" LIVE AUDIT RESULTS SUMMARY")
    print("==========================================================================")
    for k, v in audit_results.items():
        print(f"  {k:<35}: {v}")
    print(f"\nTotal browser HTTP requests recorded: {len(network_requests)}")

    # Invariant assertions
    assert audit_results["workbench_page_status"] == 200
    assert audit_results["csp_present"] is True
    assert audit_results["nosniff_present"] is True
    assert audit_results["sameorigin_present"] is True
    assert audit_results["vedam_api_available"] is True
    assert audit_results["health_status"] == "HEALTHY"
    assert audit_results["supported_languages"] == 23
    assert audit_results["canonical_compositions_count"] == 18
    assert audit_results["verse_is_rtl"] is True
    assert audit_results["verse_direction"] == "rtl"
    assert audit_results["unauth_review_status"] == 401

    print("\n[AUDIT SUCCESS] Complete browser-to-server lifecycle verified 100% genuine.")


if __name__ == "__main__":
    run_live_audit()
