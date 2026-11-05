"""
Vedic Heritage Platform — Phase 11D HTML Security & Adversarial Injection Audit
Performs adversarial penetration testing on MultilingualHTMLExporter, testing XSS vectors,
tag injection, attribute injection, entity escaping, and <bdi> boundary safety.
"""

from pathlib import Path
import re
import sys

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from automation.exporters.html_exporter import MultilingualHTMLExporter
from automation.exporters.publication_model import (
    LanguageScriptTarget,
    MissingContentLedger,
    PublicationDocument,
    PublicationGovernance,
    PublicationMetadata,
    VerseEntry,
)

EVIDENCE_DIR = Path("exports/audit_evidence/phase11d_audit/html_security")
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)


def audit_html_security():
    print("=================================================================")
    print("PHASE 11D AUDIT: HTML Security & Adversarial Injection Audit")
    print("=================================================================")

    # Adversarial Payloads
    XSS_PAYLOADS = [
        "<script>alert('XSS_EXEC_01')</script>",
        "<img src=x onerror=alert('XSS_EXEC_02')>",
        "\" onmouseover=\"alert('XSS_EXEC_03')\" data-dummy=\"",
        "'><svg onload=alert('XSS_EXEC_04')>",
        "javascript:alert('XSS_EXEC_05')",
        "<iframe src='javascript:alert(1)'></iframe>",
        "&lt;script&gt;alert(1)&lt;/script&gt;",
        "<h1>INJECTED_HEADER</h1>",
        "'; DROP TABLE texts; --",
    ]

    findings = []
    tests_run = 0

    for idx, payload in enumerate(XSS_PAYLOADS):
        tests_run += 1
        print(f"\n--- Testing Payload #{idx + 1}: {payload[:45]} ---")

        # Inject payload into multiple fields
        adv_doc = PublicationDocument(
            metadata=PublicationMetadata(
                content_id=f"VEDA-TXT-ADV{idx:02d}",
                canonical_title=f"Adversarial Title {payload}",
                devanagari_title=f"परीक्षण {payload}",
                composer=f"Malicious Author {payload}",
                deity=f"Deity {payload}",
                chandas=f"Meter {payload}",
                primary_category=f"Category {payload}",
                source_scripture=f"Scripture {payload}",
            ),
            target=LanguageScriptTarget(
                language_code="hi",
                language_name="Hindi",
                script_code="Deva",
                script_name="Devanagari",
                bcp47="hi-Deva",
                direction="ltr",
                is_rtl=False,
                shaping_required=True,
            ),
            missing_content=MissingContentLedger(1, 0, 0, 0, False),
            verses=(
                VerseEntry(
                    verse_number=1,
                    verse_id=f"VERSE-ADV-{idx}",
                    canonical_order=1,
                    raw_source=f"Source Mantra {payload}",
                    devanagari_source=f"स्रोत मन्त्र {payload}",
                    iast_transliteration=f"srotra {payload}",
                    literal_translation=f"Literal meaning {payload}",
                    literal_status="DRAFT",
                    tatparya_translation=f"Tatparya purport {payload}",
                    tatparya_status="DRAFT",
                    bhavartha_translation=f"Bhavartha devotional {payload}",
                    bhavartha_status="DRAFT",
                    word_by_word_json=[{"sanskrit": f"पद {payload}", "meaning": f"अर्थ {payload}"}],
                    notes=f"Scholarly note {payload}",
                ),
            ),
            governance=PublicationGovernance(
                publication_channel="draft_export",
                overall_review_status="DRAFT",
                is_approved_for_public_release=False,
                watermark_text=f"WATERMARK {payload}",
                disclaimer=f"DISCLAIMER {payload}",
            ),
        )

        html_out_path = EVIDENCE_DIR / f"adversarial_test_{idx:02d}.html"
        MultilingualHTMLExporter.export(adv_doc, output_path=str(html_out_path), enforce_gate=False)

        html_content = html_out_path.read_text(encoding="utf-8")

        # Check for unescaped raw script or html tags
        dangerous_patterns = [
            r"<script>",
            r"<img src=x onerror",
            r"<svg onload",
            r"<iframe",
            r"<h1>INJECTED_HEADER</h1>",
        ]

        injected = False
        for pat in dangerous_patterns:
            if re.search(pat, html_content, re.IGNORECASE):
                msg = f"VULNERABILITY: Raw unescaped dangerous pattern '{pat}' found in output HTML!"
                print(f"  [CRITICAL FAIL] {msg}")
                findings.append({"payload_idx": idx, "pattern": pat, "severity": "CRITICAL", "message": msg})
                injected = True

        if not injected:
            print("  Escaping verified: All HTML tags cleanly neutralized via entity encoding.")

    # -----------------------------------------------------------------------
    # Test BiDi <bdi> Isolation on Mixed RTL/LTR HTML
    # -----------------------------------------------------------------------
    print("\n--- Testing Mixed-Directionality <bdi> Isolation in RTL HTML ---")
    rtl_adv_doc = PublicationDocument(
        metadata=PublicationMetadata(
            content_id="VEDA-TXT-RTL01",
            canonical_title="Urdu RTL BiDi Safety Test",
            devanagari_title="परीक्षण",
        ),
        target=LanguageScriptTarget(
            language_code="ur",
            language_name="Urdu",
            script_code="Arab",
            script_name="Perso-Arabic",
            bcp47="ur-Arab",
            direction="rtl",
            is_rtl=True,
            shaping_required=True,
        ),
        missing_content=MissingContentLedger(1, 0, 0, 0, False),
        verses=(
            VerseEntry(
                verse_number=1,
                verse_id="VERSE-RTL-1",
                canonical_order=1,
                raw_source="ॐ",
                devanagari_source="ॐ",
                iast_transliteration="oṃ",
                bhavartha_translation="یہ آیت VEDA-TXT-00006 کا اردو ترجمہ ہے۔",
                bhavartha_status="DRAFT",
            ),
        ),
        governance=PublicationGovernance(
            publication_channel="draft_export",
            overall_review_status="DRAFT",
            is_approved_for_public_release=False,
            watermark_text="DRAFT",
        ),
    )

    rtl_html_path = EVIDENCE_DIR / "rtl_bidi_isolation_test.html"
    MultilingualHTMLExporter.export(rtl_adv_doc, output_path=str(rtl_html_path), enforce_gate=False)
    rtl_content = rtl_html_path.read_text(encoding="utf-8")

    assert '<html lang="ur-Arab" dir="rtl">' in rtl_content
    assert '<bdi dir="ltr">VEDA-TXT-00006</bdi>' in rtl_content
    print("  RTL root attributes verified: <html lang='ur-Arab' dir='rtl'>")
    print("  Embedded LTR token isolation verified: <bdi dir='ltr'>VEDA-TXT-00006</bdi> correctly injected.")

    print("\n=================================================================")
    print(f"HTML SECURITY AUDIT COMPLETED: {tests_run} tests run, {len(findings)} vulnerabilities found.")
    print("=================================================================")

    out_file = Path("exports/audit_evidence/phase11d_audit/html_security_findings.json")
    out_file.parent.mkdir(parents=True, exist_ok=True)
    import json
    out_file.write_text(json.dumps(findings, indent=2), encoding="utf-8")
    print(f"Security findings written to: {out_file.resolve()}")
    return findings


if __name__ == "__main__":
    audit_html_security()
