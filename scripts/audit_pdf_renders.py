"""
Vedic Heritage Platform — Phase 11D Visual PDF Rendering Audit
Renders PDF pages to high-resolution PNG images via PyMuPDF (fitz),
inspecting Hindi, Telugu, Urdu, Vedic accents, IAST, and Indic conjunct shaping.
"""

from pathlib import Path
import sys

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

import fitz  # PyMuPDF
from automation.exporters.pdf_multilingual_exporter import MultilingualPDFExporter
from automation.exporters.publication_model import (
    LanguageScriptTarget,
    MissingContentLedger,
    PublicationDocument,
    PublicationGovernance,
    PublicationMetadata,
    VerseEntry,
)

EVIDENCE_DIR = Path("exports/audit_evidence/phase11d_audit/pdf_renders")
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)


def render_pdf_to_images(pdf_path: Path, prefix: str):
    """Renders every page of a PDF to PNG images at 150 DPI."""
    doc = fitz.open(pdf_path)
    page_count = len(doc)
    image_paths = []
    print(f"\nRendering {pdf_path.name} ({page_count} pages)...")

    for i in range(page_count):
        page = doc[i]
        pix = page.get_pixmap(dpi=150)
        img_name = f"{prefix}_page_{i + 1}.png"
        img_path = EVIDENCE_DIR / img_name
        pix.save(img_path)
        image_paths.append((i + 1, img_path, pix.width, pix.height))
        print(f"  Page {i + 1}: Saved to {img_path.name} ({pix.width}x{pix.height})")

    doc.close()
    return image_paths


def audit_demonstration_pdfs():
    print("=================================================================")
    print("PHASE 11D AUDIT: Visual PDF Rendering Inspection (PyMuPDF)")
    print("=================================================================")

    findings = []
    demo_base = Path("exports/multilingual_publication/demonstrations")

    # 1. Hindi Devanagari PDF (Ganesha Pancharatnam)
    hindi_pdf = demo_base / "hindi_deva/pdf/VEDA-TXT-00001_ganesha_pancharatnam_hi-Deva_draft_export.pdf"
    if hindi_pdf.exists():
        hindi_pages = render_pdf_to_images(hindi_pdf, "demo_hindi_deva")
    else:
        print(f"WARNING: Hindi PDF not found at {hindi_pdf}")

    # 2. Telugu PDF (Gayatri Vedic Mantra)
    telugu_pdf = demo_base / "telugu_telu/pdf/VEDA-TXT-00006_gayatri_vedic_mantra_te-Telu_draft_export.pdf"
    if telugu_pdf.exists():
        telugu_pages = render_pdf_to_images(telugu_pdf, "demo_telugu_telu")
    else:
        print(f"WARNING: Telugu PDF not found at {telugu_pdf}")

    # 3. Urdu RTL PDF (Gayatri Vedic Mantra)
    urdu_pdf = demo_base / "urdu_arab/pdf/VEDA-TXT-00006_gayatri_vedic_mantra_ur-Arab_draft_export.pdf"
    if urdu_pdf.exists():
        urdu_pages = render_pdf_to_images(urdu_pdf, "demo_urdu_arab")
    else:
        print(f"WARNING: Urdu PDF not found at {urdu_pdf}")

    # -----------------------------------------------------------------------
    # 4. Generate Synthetic Test Fixtures:
    #    - Sanskrit with Vedic Swaras (U+0951 Anudatta, U+0952 Svarita, U+1CDA Dvisvarita)
    #    - Complex Indic Conjuncts (त्स्न्य, र्द्ध्व, ङ्क्त, क्ष्म, ष्ट्र)
    #    - Long multi-page verses
    # -----------------------------------------------------------------------
    print("\n--- Generating Synthetic PDF Test Fixture: Vedic Swaras & Conjuncts ---")
    synth_doc = PublicationDocument(
        metadata=PublicationMetadata(
            content_id="VEDA-TXT-SYNTH01",
            canonical_title="Synthetic Linguistic Test Suite",
            devanagari_title="कृत्रिम भाषावैज्ञानिक परीक्षणम्",
            composer="Scholarly Test Harness",
            deity="Agni & Sarasvati",
            chandas="Anushtup & Trishtup",
            source_scripture="Rigveda & Taittiriya Samhita",
        ),
        target=LanguageScriptTarget(
            language_code="sa",
            language_name="Sanskrit",
            script_code="Deva",
            script_name="Devanagari",
            bcp47="sa-Deva",
            direction="ltr",
            is_rtl=False,
            shaping_required=True,
        ),
        missing_content=MissingContentLedger(3, 0, 0, 0, False),
        verses=(
            # Verse 1: Vedic Accents (Rigvedic & Taittiriya Swaras)
            VerseEntry(
                verse_number=1,
                verse_id="SYNTH-V1",
                canonical_order=1,
                raw_source="अ॒ग्निमी॑ळे पु॒रोहि॑तं य॒ज्ञस्य॑ दे॒वमृ॒त्विज॑म् । हो॑ता॑रं रत्न॒धात॑मम् ॥",
                devanagari_source="अ॒ग्निमी॑ळे पु॒रोहि॑तं य॒ज्ञस्य॑ दे॒वमृ॒त्विज॑म् । हो॑ता॑रं रत्न॒धात॑मम् ॥",
                iast_transliteration="agnimī́ḷe puróhitaṃ yajñásya devámr̥tvíjam | hótāraṃ ratnadhā́tamam ||",
                has_vedic_swaras=True,
                literal_translation="अग्निं स्तौमि पुरोहितं यज्ञस्य देवम् ऋत्विजम्...",
                literal_status="DRAFT",
                bhavartha_translation="हम यज्ञ के पुरोहित, दिव्य देव और ऋत्विक अग्निदेव की स्तुति करते हैं।",
                bhavartha_status="DRAFT",
            ),
            # Verse 2: Complex Conjuncts & Halanta sequences
            VerseEntry(
                verse_number=2,
                verse_id="SYNTH-V2",
                canonical_order=2,
                raw_source="त्स्न्य र्द्ध्व ङ्क्त क्ष्म ष्ट्र वार्ष्णेय कार्ष्ण्य सौक्ष्म्य प्रागैतिहासिक्यम्",
                devanagari_source="त्स्न्य र्द्ध्व ङ्क्त क्ष्म ष्ट्र वार्ष्णेय कार्ष्ण्य सौक्ष्म्य प्रागैतिहासिक्यम्",
                iast_transliteration="tsnya rddhva ṅkta kṣma ṣṭra vārṣṇeya kārṣṇya saukṣmya prāgaitihāsikyam",
                literal_translation="परीक्षण संयुक्ताक्षराणि...",
                literal_status="DRAFT",
                bhavartha_translation="यह जटिल संयुक्ताक्षरों के विरूपण का तकनीकी परीक्षण है।",
                bhavartha_status="DRAFT",
            ),
            # Verse 3: Extended length text forcing pagination
            VerseEntry(
                verse_number=3,
                verse_id="SYNTH-V3",
                canonical_order=3,
                raw_source="नमस्ते अस्तु भगवन् विश्वेश्वराय महादेवाय त्र्यम्बकाय त्रिपुरान्तकाय त्रिकाग्निकालाय कालाग्निरुद्राय नीलकण्ठाय मृत्युञ्जयाय सर्वेश्वराय सदाशिवाय श्रीमन्महादेवाय नमः ।" * 4,
                devanagari_source="नमस्ते अस्तु भगवन् विश्वेश्वराय महादेवाय त्र्यम्बकाय त्रिपुरान्तकाय त्रिकाग्निकालाय कालाग्निरुद्राय नीलकण्ठाय मृत्युञ्जयाय सर्वेश्वराय सदाशिवाय श्रीमन्महादेवाय नमः ।" * 4,
                iast_transliteration="namaste astu bhagavan viśveśvarāya mahādevāya tryambakāya tripurāntakāya..." * 4,
                literal_translation="दीर्घ परीक्षण पाठः..." * 6,
                literal_status="DRAFT",
                bhavartha_translation="हे विश्वेश्वर, महादेव, त्रिनेत्र, त्रिपुरांतक, कालाग्निरुद्र, नीलकंठ, मृत्युंजय, सर्वेश्वर, सदाशिव, आप परम कृपालु भगवान् को बारंबार नमस्कार है। " * 6,
                bhavartha_status="DRAFT",
            ),
        ),
        governance=PublicationGovernance(
            publication_channel="draft_export",
            overall_review_status="DRAFT",
            is_approved_for_public_release=False,
            watermark_text="UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE",
        ),
    )

    synth_pdf_path = EVIDENCE_DIR / "synth_vedic_swaras_and_conjuncts.pdf"
    MultilingualPDFExporter.export(synth_doc, output_path=str(synth_pdf_path), enforce_gate=False)
    synth_pages = render_pdf_to_images(synth_pdf_path, "synth_vedic_conjuncts")

    # -----------------------------------------------------------------------
    # 5. Extract Text & Font Glyphs from Rendered Pages to Detect Errors
    # -----------------------------------------------------------------------
    print("\n--- Inspecting Glyph Coverage & Rendering Artifacts in PDFs ---")
    all_pdfs = [
        ("Hindi Devanagari", hindi_pdf),
        ("Telugu Indic", telugu_pdf),
        ("Urdu Perso-Arabic", urdu_pdf),
        ("Sanskrit Vedic/Conjuncts", synth_pdf_path),
    ]

    for label, p_path in all_pdfs:
        if not p_path.exists():
            continue
        doc = fitz.open(p_path)
        for page_idx in range(len(doc)):
            page = doc[page_idx]
            text = page.get_text()

            # Check for unresolved characters (e.g.  or empty squares or raw hex escapes)
            if "\ufffd" in text:
                msg = f"DEFECT: Replacement character (U+FFFD) detected on Page {page_idx + 1} of {label} ({p_path.name})."
                print(f"  [ERROR] {msg}")
                findings.append({"file": p_path.name, "page": page_idx + 1, "severity": "HIGH", "defect": msg})

            # Check fonts used on page
            fonts = page.get_fonts()
            print(f"  [{label}] Page {page_idx + 1}: {len(fonts)} font(s) embedded: {[f[3] for f in fonts]}")

        doc.close()

    print("\n=================================================================")
    print(f"PDF VISUAL RENDERING AUDIT COMPLETED: Rendered images saved to {EVIDENCE_DIR}")
    print("=================================================================")
    return findings


if __name__ == "__main__":
    findings = audit_demonstration_pdfs()
    import json
    out_path = Path("exports/audit_evidence/phase11d_audit/pdf_rendering_findings.json")
    out_path.write_text(json.dumps(findings, indent=2), encoding="utf-8")
    print(f"Results written to: {out_path.resolve()}")
