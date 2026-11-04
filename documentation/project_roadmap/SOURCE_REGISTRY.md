# Vedic Heritage Platform — Content Source Registry
**Last Updated:** Current Session  
**Status:** Living Document (Updated whenever new websites, libraries, or datasets are introduced)

---

## 📌 Purpose & Dynamic Intake Policy

This registry tracks all potential, candidate, and approved sources of Vedic mantras, stotras, suktams, puja vidhis, and devotional texts. 

Whenever the user provides a new website, book, digital library, or API:
1. **Assign a unique Source ID** (`SRC-xxx`).
2. **Conduct the 4-Point Intake Check**:
   - *Technical Architecture*: Static HTML, Client-rendered SPA, PDF, or API.
   - *Legal & Permissions*: robots.txt, Terms of Service, copyright statement, public-domain boundary.
   - *Language & Script Scope*: Devanagari, Telugu, Tamil, Kannada, Roman IAST, etc.
   - *Text Quality & Provenance*: Traditional attributions, commentary presence, accents.
3. **Log the findings** in this table.
4. **Link to the deep-dive research file** in `documentation/source_research/SRC-xxx_<name>.md`.

---

## 🗂️ Master Source Inventory

| Source ID | Source Name | Base / Entry URL | Content Types | Primary Scripts / Languages | Legal & Robots Status | Inspection Status | Ingestion Priority | Notes & Provenance |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **SRC-001** | **Vaidika Vignanam** | `https://vignanam.org/` | Stotras, Suktams, Sahasranamas, Mantras, Ashtakams, Puja Vidhi | Sanskrit, Telugu, Hindi, Tamil, Kannada, Bengali, Gujarati, Malayalam, Odia, English | Pending Assessment (Step 1-3) | In Progress | High | Comprehensive multilingual script switcher; extensive categorization by deity and scripture. |
| **SRC-002** | **Drik Panchang** | `https://www.drikpanchang.com/vedic-mantra/` | Vedic Mantras, Samhitas, Suktams, Deity Mantras, Puja rituals | Sanskrit (Devanagari, IAST), Hindi, English | Pending Assessment (Step 1-3) | In Progress | High | Astronomical and ritual reference site. Known for rigorous Vedic accentuation and puja steps. |
| **SRC-003** | **Stotrams.com** | `https://stotrams.com/` | Stotras, Ashtottara Shatanamavali, Sahasranama, Chalisa, Kavacham | Devanagari, English (IAST), Regional transliterations | Pending Assessment (Step 1-3) | In Progress | Medium | Structured stotram library organized by deity; clean verse structures. |
| **SRC-004** | **Temples.bio** | `https://www.temples.bio/stotrams` | Stotrams, Temple prayers, Ashtakams, regional hymns | Multilingual Indic scripts | Pending Assessment (Step 1-3) | In Progress | Medium | Temple-associated devotional literature and popular stotrams. |
| **SRC-005+** | *User-Supplied Sources* | *To be appended on input* | *TBD* | *TBD* | *Pending* | *Queued* | *TBD* | *Dynamic queue for incoming sources.* |

---

## 🏛️ Additional Trustworthy Repositories Under Discovery
These public-domain, academic, and government repositories are queued for evaluation:
- **GRETIL (Göttingen Register of Electronic Texts in Indian Languages)**: Scholarly public-domain e-texts of classical Sanskrit literature, Vedas, and Puranas.
- **Sanskrit Documents (sanskritdocuments.org)**: Large non-profit volunteer repository of authentic stotras, mantras, and scriptures with public domain/CC licensing history.
- **Muktabodha Indological Research Institute**: Digitized manuscripts and core Tantric, Agamic, and Vedic texts with scholarly cataloging.
- **Digital Library of India / Internet Archive Public Vedic Collections**: Historical printed editions for cross-verification of conflicting verses.

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
- **Robots.txt Summary**: [Disallow rules, crawl-delay]
- **Copyright Statement**: [Public domain underlying text vs. site proprietary layout]
- **Recommended Extraction Approach**: [Official Export / API / Single-worker Parser / Manual Curation]
- **Verification Priority**: [Pilot / High / Medium / Low]
```
