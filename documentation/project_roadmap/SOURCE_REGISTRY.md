# Vedic Heritage Platform — Content Source Registry
**Last Updated:** 2026-11-04  
**Status:** Living Document (Updated whenever new websites, libraries, or datasets are introduced)

---

## 📌 Master Source Inventory

| Source ID | Source Name | Base / Entry URL | Content Scope | Primary Scripts & Languages | Tech Stack | Acquisition Track | Status | Notes & Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| **SRC-001** | **Vaidika Vignanam** | `https://vignanam.org/` | Stotras, Suktams, Sahasranamas, Mantras, Ashtakams, Keerthanas | 18 Indic scripts + IAST English | S3 + CloudFront (Static) | **Track A** | **AMBER** | Terms claim database rights; robots.txt has 10s crawl delay. **Do not scrape.** Formal partnership letter prepared (`documentation/permissions/PARTNERSHIP_OUTREACH_VIGNANAM.md`). |
| **SRC-002** | **Drik Panchang** | `https://www.drikpanchang.com/vedic-mantra/` | Vedic Mantras, Samhitas, Suktams, Panchang calculations | Devanagari, English IAST, Hindi | Custom Server + Google Edge | Benchmark | **RED** | Commercial entity (Adarsh Mobile Applications LLP). Full copyright asserted. **Automated scraping is prohibited.** Manual cross-check reference only. |
| **SRC-003** | **Stotrams.com** | `https://stotrams.com/` | Stotras, Ashtottara Shatanamavali, Sahasranama, Chalisa, Kavacham | 10 Scripts + Word-by-Word notes | Astro Jamstack + Cloudflare Pages | **Track A** | **AMBER** | Acknowledges Sanskrit as public domain; requests to ask for bulk access. **Do not scrape.** Formal partnership letter prepared (`documentation/permissions/PARTNERSHIP_OUTREACH_STOTRAMS.md`). |
| **SRC-004** | **Temples.bio** | `https://www.temples.bio/stotrams` | Chalisas and popular Stotrams | English, Hindi, Telugu | Apache 2.4 + PHP + MySQL | Excluded | **RED** | Commercial puja/hotel booking business. Strictly forbids copying without written permission. Minimal catalog. **Excluded from pipeline.** |
| **SRC-IND-001** | **Historical Public Domain Printed Editions** | `https://archive.org/details/digitallibraryindia` | Vedic Samhitas, Critical Editions, Stotra Ratnavali, Sayana Bhashya | Devanagari, Grantha | Scanned Critical Editions & Archives | **Track B** | **GREEN** | Verified out-of-copyright historical editions published >60 years ago (Nirnaya Sagar Press 1912, Vaidika Samsodhana Mandala 1890, Venkateshwara Steam Press 1908). Cleared for commercial platform release. |
| **SRC-IND-002+** | *Scholarly Repositories (GRETIL, Muktabodha)* | Academic URLs | Manuscript variants, meter, paleography | Devanagari, Roman IAST | Academic E-Texts | **Track B Reference** | **AMBER** | Reference only. Used for scholarly cross-checking; do not assume commercial reusability without specific edition audit. |

---

## 📝 New Source Intake Form Template

When adding a new source, copy and paste this section:

```markdown
### Source ID: SRC-[Number]
- **Name**: [Platform / Website Name]
- **Entry URL**: [URL]
- **Date Added**: [YYYY-MM-DD]
- **Offered Content**: [Mantras / Stotras / Puja / Suktam / etc.]
- **Available Languages/Scripts**: [Devanagari / IAST / Regional]
- **Technical Characteristics**: [Static / SPA / Dynamic / REST API]
- **Acquisition Track**: [Track A: Partner / Track B: Independent Public Domain]
- **Robots.txt Summary**: [Disallow rules, crawl-delay]
- **Copyright Statement**: [Public domain underlying text vs. site proprietary layout]
- **Recommended Extraction Approach**: [Official Export / API / Single-worker Parser / Manual Curation]
- **Verification Priority**: [Pilot / High / Medium / Low]
- **Assigned Status**: [GREEN / AMBER / RED]
```
