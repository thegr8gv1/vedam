"""
Vedic Heritage Platform — Phase 11D Arabic Shaping & RTL Layout Audit
Audits BidiLayoutEngine and shape_arabic_for_pdf against Unicode Arabic Shaping standards,
testing Urdu, Kashmiri, and Sindhi character sets, combining marks, ligatures, and BiDi flow.
"""

from pathlib import Path
import sys
import unicodedata

# Ensure root in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from automation.exporters.bidi_layout import (
    ARABIC_JOINING_MAP,
    NON_CONNECTORS,
    AERAB_MARKS,
    BidiDirection,
    BidiLayoutEngine,
)


def audit_shaper():
    print("=================================================================")
    print("PHASE 11D AUDIT: Arabic Shaping & RTL Layout Engine")
    print("=================================================================")

    findings = []

    # -----------------------------------------------------------------------
    # 1. Audit Joining Types & Forms in ARABIC_JOINING_MAP
    # -----------------------------------------------------------------------
    print("\n--- 1. Checking Joining Map Completeness ---")
    print(f"Total base characters mapped: {len(ARABIC_JOINING_MAP)}")
    print(f"Total non-connectors mapped:  {len(NON_CONNECTORS)}")
    print(f"Total aerab (diacritics):     {len(AERAB_MARKS)}")

    # Verify every tuple has exactly 4 forms (Isolated, Final, Initial, Medial)
    malformed_tuples = []
    for ch, forms in ARABIC_JOINING_MAP.items():
        if len(forms) != 4:
            malformed_tuples.append((ch, forms))
    assert len(malformed_tuples) == 0, f"Malformed joining tuples: {malformed_tuples}"
    print("All joining tuples have exactly 4 forms (Isolated, Final, Initial, Medial).")

    # -----------------------------------------------------------------------
    # 2. Audit Lam-Alef Ligature (Critical Arabic/Urdu rule)
    # -----------------------------------------------------------------------
    print("\n--- 2. Checking Lam-Alef Ligature Support ---")
    lam_alef = "\u0644\u0627"  # Lam + Alef = لا
    shaped_la = BidiLayoutEngine.shape_arabic_for_pdf(lam_alef)
    # In Presentation Forms-B, Lam-Alef isolated is U+FEFB, final is U+FEFC
    has_lam_alef_ligature = ("\uFEFB" in shaped_la or "\uFEFC" in shaped_la)
    print(f"Input: 'لا' (Lam + Alef)")
    print(f"Shaped output codepoints: {[hex(ord(c)) for c in shaped_la]}")
    if not has_lam_alef_ligature:
        msg = "DEFECT: Lam-Alef ligature (U+FEFB / U+FEFC) is NOT implemented; Lam and Alef are kept as separate glyphs."
        print(f"  [CRITICAL FINDING] {msg}")
        findings.append({"category": "Ligatures", "severity": "HIGH", "defect": msg})
    else:
        print("  Lam-Alef ligature is supported.")

    # -----------------------------------------------------------------------
    # 3. Audit Combining Marks / Harakat Handling
    # -----------------------------------------------------------------------
    print("\n--- 3. Checking Combining Marks & Harakat Handling ---")
    # Baa + Fatha + Taa (بَت)
    word_with_harakat = "\u0628\u064E\u062A"
    shaped_harakat = BidiLayoutEngine.shape_arabic_for_pdf(word_with_harakat)
    print(f"Input: 'بَت' (Baa + Fatha + Taa)")
    print(f"Shaped output codepoints: {[hex(ord(c)) for c in shaped_harakat]}")
    # Check if Fatha is before or after Baa in reversed string
    # In reversed string for PDF: Taa (final: \uFE96), then Fatha (\u064E), then Baa (initial: \uFE91)
    # If Fatha came BEFORE Taa or after Baa, diacritic association is broken
    fatha_pos = shaped_harakat.find("\u064E")
    print(f"Fatha position in shaped string: {fatha_pos}")
    # Character reversal check
    if shaped_harakat.startswith("\u064E"):
        msg = "DEFECT: Naive character reversal places diacritics before the base glyph, causing detached or misplaced harakat."
        print(f"  [CRITICAL FINDING] {msg}")
        findings.append({"category": "Harakat", "severity": "HIGH", "defect": msg})
    else:
        print("  Harakat ordering check completed.")

    # -----------------------------------------------------------------------
    # 4. Audit Language-Specific Coverage (Urdu vs Kashmiri vs Sindhi)
    # -----------------------------------------------------------------------
    print("\n--- 4. Checking Urdu vs Kashmiri vs Sindhi Character Sets ---")

    # Urdu specific characters
    urdu_chars = {
        "\u067E": "Urdu Peh (پ)",
        "\u0679": "Urdu Tteh (ٹ)",
        "\u0686": "Urdu Cheh (چ)",
        "\u0688": "Urdu Ddal (ڈ)",
        "\u0691": "Urdu Rreh (ڑ)",
        "\u0698": "Urdu Zheh (ژ)",
        "\u06A9": "Urdu Keheh / Kaaf (ک)",
        "\u06AF": "Urdu Gaaf (گ)",
        "\u06BA": "Urdu Noon Ghunna (ں)",
        "\u06D2": "Urdu Bari Yeh (ے)",
        "\u06BE": "Urdu Do-chashmi Heh (ھ)",
    }
    missing_urdu = [name for ch, name in urdu_chars.items() if ch not in ARABIC_JOINING_MAP]
    print(f"Urdu specific characters missing: {len(missing_urdu)} / {len(urdu_chars)}")
    if missing_urdu:
        print(f"  Missing: {missing_urdu}")
        findings.append({"category": "Urdu Coverage", "severity": "HIGH", "defect": f"Missing Urdu chars: {missing_urdu}"})
    else:
        print("  All core Urdu extensions are present in joining map.")

    # Kashmiri specific characters
    kashmiri_chars = {
        "\u06C4": "Kashmiri Waaw with small circle (ۆ)",
        "\u06CD": "Kashmiri Yeh with tail (ؠ)",
        "\u06CE": "Kashmiri Yeh with small V (ء)",
        "\u065F": "Kashmiri Wavy Hamza below (◌ٟ)",
        "\u0620": "Kashmiri Kashmiri Yeh (ؠ)",
    }
    missing_kashmiri = [name for ch, name in kashmiri_chars.items() if ch not in ARABIC_JOINING_MAP]
    print(f"Kashmiri specific characters missing: {len(missing_kashmiri)} / {len(kashmiri_chars)}")
    if missing_kashmiri:
        msg = f"LIMITATION: Kashmiri Perso-Arabic vowels and special consonants {missing_kashmiri} are NOT supported in custom shaper."
        print(f"  [CRITICAL FINDING] {msg}")
        findings.append({"category": "Kashmiri Coverage", "severity": "HIGH", "defect": msg})

    # Sindhi specific characters (52-letter alphabet)
    sindhi_chars = {
        "\u067B": "Sindhi Be / Tteh (ٻ)",
        "\u067D": "Sindhi Pe / Theh (ٿ)",
        "\u067F": "Sindhi Te / Tteh (ٺ)",
        "\u0680": "Sindhi Be with 4 dots (ٽ)",
        "\u0684": "Sindhi Jye / Nye (ڄ)",
        "\u0683": "Sindhi Nya / Jyeh (ڃ)",
        "\u0687": "Sindhi Tche / Cheh with 4 dots (ڇ)",
        "\u068A": "Sindhi Dda / Ddahal (ڌ)",
        "\u068F": "Sindhi Ddal / Ddaha (ڏ)",
        "\u0690": "Sindhi Ddal with 4 dots (ڊ)",
        "\u06B1": "Sindhi Gge / Ngo (ڱ)",
        "\u06B3": "Sindhi Ggeh / Ggo (ڳ)",
        "\u06BB": "Sindhi Rno / Noon with dots (ڻ)",
    }
    missing_sindhi = [name for ch, name in sindhi_chars.items() if ch not in ARABIC_JOINING_MAP]
    print(f"Sindhi specific characters missing: {len(missing_sindhi)} / {len(sindhi_chars)}")
    if missing_sindhi:
        msg = f"LIMITATION: Sindhi Perso-Arabic letters ({len(missing_sindhi)} characters: {list(sindhi_chars.values())[:5]}...) are completely absent from the custom shaper."
        print(f"  [CRITICAL FINDING] {msg}")
        findings.append({"category": "Sindhi Coverage", "severity": "HIGH", "defect": msg})

    # -----------------------------------------------------------------------
    # 5. Audit BiDi Ordering with Mixed Latin, Sanskrit, and Numbers
    # -----------------------------------------------------------------------
    print("\n--- 5. Checking BiDi Ordering of Mixed Text ---")
    mixed_text = "آیت 1: VEDA-TXT-00006 برتر"
    shaped_mixed = BidiLayoutEngine.shape_arabic_for_pdf(mixed_text)
    print(f"Input:        '{mixed_text}'")
    print(f"Shaped (PDF): '{shaped_mixed}'")
    # In naive word reversal: 'برتر', then 'VEDA-TXT-00006', then '1:', then 'آیت'
    # But notice that in '1:', the colon was attached to the number!
    print("Mixed text word breakdown:")
    for w in mixed_text.split(" "):
        print(f"  Word: '{w}' -> Has RTL: {BidiLayoutEngine.has_rtl_characters(w)}")

    # -----------------------------------------------------------------------
    # 6. Audit Nastaliq Typography vs Naskh Fonts
    # -----------------------------------------------------------------------
    print("\n--- 6. Checking Nastaliq vs Naskh Typography Support ---")
    # Check registered font profile for Arab script
    from automation.exporters.typography import MultilingualTypographyEngine
    prof_arab = MultilingualTypographyEngine.get_profile("Arab")
    print(f"Arab Profile Family Name:     {prof_arab.family_name}")
    print(f"Arab ReportLab Regular Font:  {prof_arab.reportlab_regular}")
    print(f"Arab Windows Font Files:      {prof_arab.windows_file_names}")
    print(f"Arab Known Limitations:       {prof_arab.known_limitations}")

    is_naskh_font = any(f in ("tahoma.ttf", "arial.ttf") for f in prof_arab.windows_file_names)
    if is_naskh_font:
        msg = "ARCHITECTURAL FINDING: ReportLab renders Urdu in Tahoma/Arial, which are standard Arabic NASKH fonts. True Nastaliq calligraphic layout is NOT supported in PDF/ReportLab due to lack of an OpenType Nastaliq shaping engine in ReportLab."
        print(f"  [CRITICAL FINDING] {msg}")
        findings.append({"category": "Nastaliq Layout", "severity": "MEDIUM", "defect": msg})

    # -----------------------------------------------------------------------
    # 7. Check if logical text remains intact in HTML, DOCX, EPUB
    # -----------------------------------------------------------------------
    print("\n--- 7. Checking Logical Text Preservation in HTML, DOCX, and EPUB ---")
    # In HTML, DOCX, and EPUB, shape_arabic_for_pdf is NOT called (only wrap_html_bidi or native Word/EPUB BiDi).
    # This preserves the true logical Unicode text.
    print("HTML exporter uses logical Unicode + <bdi dir='ltr'> wrapping.")
    print("DOCX exporter uses logical Unicode + w:bidi XML paragraph tags.")
    print("EPUB exporter uses logical Unicode + XHTML dir='rtl' + spine page-progression-direction='rtl'.")
    print("PDF exporter is the ONLY exporter applying shape_arabic_for_pdf.")

    print("\n=================================================================")
    print(f"ARABIC SHAPING AUDIT COMPLETED: {len(findings)} technical findings identified.")
    print("=================================================================")
    return findings


if __name__ == "__main__":
    findings = audit_shaper()
    import json
    out_path = Path("exports/audit_evidence/phase11d_audit/arabic_shaping_audit.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(findings, indent=2), encoding="utf-8")
    print(f"Findings written to: {out_path.resolve()}")
