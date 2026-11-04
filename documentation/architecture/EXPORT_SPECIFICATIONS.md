# Vedic Heritage Platform — Export Formats & Layout Specifications
**Version:** 1.0.0  
**Status:** Approved Specification (Phase 1, Step 7)  
**Implementations:**
- `automation/exporters/excel_exporter.py`
- `automation/exporters/word_exporter.py`
- `automation/exporters/json_exporter.py`

---

## 1. Professional Excel Workbook Specification (`.xlsx`)

Excel exports serve scholars, data researchers, translators, and content managers.

### 1.1 Multi-Worksheet Architecture
1. **Worksheet 1: `Overview & Metadata`**
   - Title banner in Deep Navy (`#1E3A8A`) with white text.
   - Master metadata grid: Content ID, canonical titles, deity, category, composer, rishi, chandas, scripture, verse count, SHA-256 hash, and release status badge.
2. **Worksheet 2: `Verses & Translations`**
   - Frozen header row (`A2`) for continuous scrolling.
   - Headers: `Verse ID`, `Verse #`, `Type`, `Devanagari (Original)`, `IAST Transliteration`, `Telugu Script`, `Tamil Script`, `English Meaning (Bhavartha)`, `Word-by-Word Analysis`, `Metre / Notes`.
   - Automatic column auto-fitting with maximum wrap-text boundaries.
   - Nirmala UI font for Indic scripts; Calibri for Roman typography.
3. **Worksheet 3: `Rights & Provenance`**
   - Full legal disclosure: Attribution, primary source, specific edition, license type, commercial flags, attribution text, and audit timestamps.
   - Emerald Green fill for `GREEN` status; Amber fill for `AMBER`.

---

## 2. Professional Word Document Specification (`.docx`)

Word exports provide beautiful, printable typeset manuscripts suitable for recitation, chanting study, and publishing.

### 2.1 Typographic Hierarchy
- **Margins:** Standard 1.0 inch all around.
- **Invocation Banner:** Centered `॥ ॐ श्रीपरमात्मने नमः ॥` in Vedic Maroon (`#8B1E0B`), 13pt bold Nirmala UI.
- **Devanagari Title:** Centered, 22pt bold Nirmala UI (`॥ गणेशपञ्चरत्नम् ॥`).
- **Canonical English Subtitle:** Centered, 15pt bold Calibri in Deep Navy (`#1E3A8A`).
- **Metadata Capsule:** 2-row, 3-column clean borderless table presenting Deity, Category, Composer, Metre, Scripture, and Content ID in Slate Gray (`#6B7280`).
- **Stanza Blocks:**
  - Verse label (e.g. `Verse 1 — VERSE`) in 9pt bold slate.
  - Devanagari verse: Centered, 14pt bold Nirmala UI with natural line breaks.
  - Roman IAST transliteration: Centered, 11pt italic Calibri in Deep Navy.
  - English Meaning: Justified block with bold Maroon "Meaning:" lead-in.
  - Stanza break: Centered floral ornament (`❖   ❖   ❖`).
- **Provenance Colophon:** Concluding footer detailing Content ID, primary edition citation, license, and verification hash.

---

## 3. Mobile Application JSON Specification (`.json`)

The JSON export provides the authoritative data contract powering the Flutter mobile app, offline database sync, and devotional audio pipelines.

### 3.1 JSON Schema Contract
```json
{
  "schema_version": "1.0.0",
  "content_id": "VEDA-TXT-00001",
  "uuid": "4f9d2c18-...",
  "title": {
    "canonical": "Ganesha Pancharatnam",
    "devanagari": "गणेशपञ्चरत्नम्",
    "alternatives": ["Sri Ganesha Pancharatnam"]
  },
  "taxonomy": {
    "category": "stotra",
    "category_name": "Stotra",
    "deity": "ganesha",
    "deity_name": "Lord Ganesha"
  },
  "liturgical_metadata": {
    "composer": "Adi Shankaracharya",
    "chandas": "Vasantatilaka",
    "source_scripture": "Stotra Ratnavali",
    "original_language": "sa",
    "original_script": "Devanagari"
  },
  "rights_and_provenance": {
    "release_status": "GREEN",
    "license_type": "PUBLIC_DOMAIN",
    "commercial_reuse_permitted": true,
    "primary_source": "Nirnaya Sagar Press (1912)",
    "content_hash": "e3b0c44..."
  },
  "mobile_integration": {
    "is_released_for_production": true,
    "total_verses": 6,
    "chanting_presets": [1, 3, 11, 21, 27, 54, 108],
    "supports_japa_counter": true,
    "offline_cache_priority": "HIGH"
  },
  "verses": [
    {
      "verse_id": "VEDA-TXT-00001-V001",
      "verse_number": 1,
      "verse_type": "VERSE",
      "devanagari": "मुदाकरात्तमोदकं...",
      "iast": "mudākarāttamōdakaṁ...",
      "vedic_accents_present": false,
      "meter": "Vasantatilaka",
      "transliterations": {
        "telugu": "ముదాకరాత్తమోదకం..."
      },
      "translations": [
        {
          "language": "en",
          "type": "BHAVARTHA",
          "text": "I bow to Vinayaka...",
          "word_by_word": [
            {"word": "मुदाकरात्तमोदकम्", "padachheda": "मुदा + करात्त-मोदकम्", "meaning": "joyfully holding modaka"}
          ],
          "review_status": "APPROVED"
        }
      ]
    }
  ]
}
```

---

## 4. Generated Working Prototype Artifacts

Working prototypes have been generated and validated:
- **Excel Prototype:** [`exports/excel/ganesha_pancharatnam_prototype.xlsx`](file:///c:/Vedam/exports/excel/ganesha_pancharatnam_prototype.xlsx) and [`mahamrityunjaya_prototype.xlsx`](file:///c:/Vedam/exports/excel/mahamrityunjaya_prototype.xlsx).
- **Word Prototype:** [`exports/word/ganesha_pancharatnam_prototype.docx`](file:///c:/Vedam/exports/word/ganesha_pancharatnam_prototype.docx) and [`mahamrityunjaya_prototype.docx`](file:///c:/Vedam/exports/word/mahamrityunjaya_prototype.docx).
- **JSON Prototype:** [`exports/json/ganesha_pancharatnam_prototype.json`](file:///c:/Vedam/exports/json/ganesha_pancharatnam_prototype.json) and [`mahamrityunjaya_prototype.json`](file:///c:/Vedam/exports/json/mahamrityunjaya_prototype.json).
