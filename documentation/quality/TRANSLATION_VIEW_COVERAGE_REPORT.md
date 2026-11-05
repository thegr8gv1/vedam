# Vedic Heritage Platform — Translation View Coverage & Legacy Audit Report
**Phase 7 Baseline Documentation**

**Report Date:** November 4, 2026  
**Alembic Revision:** `8a95ab32600e` (`add_translation_views_table`)  
**Database Snapshot:** `database/vedam.db`  

---

## 1. Executive Summary

This report establishes the baseline translation-view coverage across the 18 canonical compositions (307 source verses) and 10 supported languages (9 regional Indian languages + English).

The platform models translations in three granular, independently reviewable layers:
1. **Devotional Bhavartha (`BHAVARTHA`):** Devotional and poetic meaning suitable for chanting, prayer, and daily liturgical contemplation.
2. **Literal / Padachheda Dissection (`LITERAL`):** Direct word-by-word syntax rendering reflecting grammatical structure.
3. **Traditional Exegesis (`TATPARYA`):** Doctrinal and theological interpretation based on classical sampradaya commentaries (e.g., Sayanacharya, Bhatta Bhaskara, Adi Shankaracharya).

---

## 2. Global View Distribution

| Translation View Type | Total Populated Records | Review Status: DRAFT | Review Status: APPROVED | Coverage across 3,070 Translations |
| :--- | :---: | :---: | :---: | :---: |
| **Devotional Bhavartha (`BHAVARTHA`)** | **3,070** | 3,070 | 0 | **100.0%** |
| **Literal Dissection (`LITERAL`)** | **2,318** | 2,318 | 0 | **75.50%** |
| **Traditional Meaning (`TATPARYA`)** | **2,318** | 2,318 | 0 | **75.50%** |
| **TOTAL POPULATED VIEWS** | **7,706** | **7,706** | **0** | — |

---

## 3. Identification of the 752 Legacy Translation Records

A total of **752 active translation records** currently possess a dedicated `BHAVARTHA` view but do not yet have separate `LITERAL` and `TATPARYA` views in `word_by_word_json`.

These records originated from:
1. **Phase 4 & 5 Pilot English Translations (307 records):** The baseline English translations created during pilot ingestion provided comprehensive verse meaning but had not yet been parsed into separate JSON grammatical structures.
2. **Phase 6B & Early Batch 1 Regional Translations (445 records):** Localized in earlier stages focusing primarily on devotional Bhavartha.

### Composition Breakdown of the 752 Legacy Records

| Content ID | Canonical Title | Category | Total Verses | Total Translations | 3-View Records (Complete) | Legacy Records (Bhavartha Only) | Backfill Priority |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `VEDA-TXT-00001` | Ganesha Pancharatnam | Stotra | 6 | 60 | 0 | **60** (6 En + 54 Reg) | High |
| `VEDA-TXT-00002` | Shiva Tandava Stotram | Stotra | 16 | 160 | 144 | **16** (16 En) | High |
| `VEDA-TXT-00003` | Aditya Hrudayam | Itihasa Hymn | 31 | 310 | 279 | **31** (31 En) | High |
| `VEDA-TXT-00004` | Madhurashtakam | Ashtakam | 9 | 90 | 0 | **90** (9 En + 81 Reg) | Medium |
| `VEDA-TXT-00005` | Gayatri Mantra | Mantra | 1 | 10 | 0 | **10** (1 En + 9 Reg) | Critical |
| `VEDA-TXT-00006` | Mahamrityunjaya Mantra | Mantra | 1 | 10 | 0 | **10** (1 En + 9 Reg) | Critical |
| `VEDA-TXT-00007` | Sri Suktam | Suktam | 16 | 160 | 144 | **16** (16 En) | Critical |
| `VEDA-TXT-00008` | Hanuman Chalisa | Chalisa | 43 | 430 | 387 | **43** (43 En) | High |
| `VEDA-TXT-00010` | Lingashtakam | Ashtakam | 10 | 100 | 0 | **100** (10 En + 90 Reg) | Medium |
| `VEDA-TXT-00011` | Bilvashtakam | Stotra | 9 | 90 | 0 | **90** (9 En + 81 Reg) | Medium |
| `VEDA-TXT-00012` | Surya Ashtakam | Stotra | 8 | 80 | 0 | **80** (8 En + 72 Reg) | Medium |
| `VEDA-TXT-00013` | Sri Venkateswara Suprabhatam | Suprabhatam | 70 | 700 | 671 | **29** (29 En V01–V29) | High |
| `VEDA-TXT-00014` | Purusha Suktam | Suktam | 16 | 160 | 144 | **16** (16 En) | Critical |
| `VEDA-TXT-00015` | Durga Suktam | Suktam | 7 | 70 | 63 | **7** (7 En) | Critical |
| `VEDA-TXT-00016` | Narayana Suktam | Suktam | 12 | 120 | 108 | **12** (12 En) | Critical |
| `VEDA-TXT-00017` | Suryashtakam (Hymn) | Stotra | 10 | 100 | 0 | **100** (10 En + 90 Reg) | Medium |
| `VEDA-TXT-00018` | Kanakadhara Stotram | Stotra | 21 | 210 | 189 | **21** (21 En) | High |
| `VEDA-TXT-00019` | Mahishasura Mardini Stotram | Stotra | 21 | 210 | 189 | **21** (21 En) | High |
| **TOTALS** | **18 Compositions** | — | **307** | **3,070** | **2,318** | **752** | — |

---

## 4. Backfill Strategy & Safeguards

1. **No Silent Synthetic Fill:**
   Missing Literal and Traditional Meaning views are **never** invented through bulk automated runs without source research.
2. **Prioritization Tiers:**
   - **Tier 1 (Critical - Vedic Mantras & Suktams):** Gayatri Mantra, Mahamrityunjaya Mantra, Sri Suktam, Purusha Suktam, Durga Suktam, Narayana Suktam (87 legacy records).
   - **Tier 2 (High - Core Classical Devotional Compositions):** Hanuman Chalisa, Shiva Tandava Stotram, Aditya Hrudayam, Kanakadhara Stotram, Mahishasura Mardini Stotram, Venkateswara Suprabhatam, Ganesha Pancharatnam (221 legacy records).
   - **Tier 3 (Medium - Classical Ashtakams):** Lingashtakam, Bilvashtakam, Surya Ashtakam, Madhurashtakam, Suryashtakam (444 legacy records).
3. **Independent View Review Governance:**
   When backfilling views, each generated view carries `ReviewStatus.DRAFT`. A human scholar can independently review and approve the `LITERAL` view without requiring the `TATPARYA` view to be simultaneously approved.
