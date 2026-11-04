# Vedic Heritage Platform — Content Source Registry
**Last Updated:** 2026-11-04  
**Status:** Living Document (Updated whenever new websites, libraries, or datasets are introduced)

---

## 📌 Master Source Inventory (Audited)

| Source ID | Source Name | Base / Entry URL | Content Scope | Primary Scripts & Languages | Tech Stack | Sitemaps & Volume | Legal & Permission Status | Recommendation & Next Steps |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **SRC-001** | **Vaidika Vignanam** | `https://vignanam.org/` | Stotras, Suktams, Sahasranamas, Mantras, Ashtakams, Keerthanas | 18 Indic scripts (Devanagari, Telugu, Tamil, Kannada, Malayalam, Odia, Bengali, Gujarati, etc.) + IAST English | S3 + CloudFront (Static pre-rendered HTML) | 2,720 links on front page; ~800–1,200 unique texts | **AMBER** | Terms claim database rights and prohibit app cloning/translations. robots.txt has `Crawl-delay: 10` and blocks AI bots. **Do not scrape wholesale.** Use as manual benchmark; seek written collaboration via `contact@vignanam.org`. |
| **SRC-002** | **Drik Panchang** | `https://www.drikpanchang.com/vedic-mantra/` | Vedic Mantras, Samhita hymns, Suktams, Deity collections, Puja rituals, Panchang calculations | Devanagari, English IAST, Hindi | Custom Server + Google Edge CDN (Dynamic session tracking) | 2,828 URLs in sitemap; ~28 deity mantra categories | **RED** | Commercial entity (Adarsh Mobile Applications LLP). Prohibits accessing `/dp-api/`, blocks AI bots, claims full copyright. **Automated scraping is prohibited.** Manual benchmark only. |
| **SRC-003** | **Stotrams.com** | `https://stotrams.com/` | Stotras, Ashtottara Shatanamavali, Sahasranama, Chalisa, Kavacham, Suktam | 10 Scripts (Devanagari, Telugu, Tamil, Kannada, Malayalam, Bengali, Gujarati, Odia, Assamese, IAST) + Word-by-Word notes | Astro Jamstack + Cloudflare Pages (Fast static HTML) | 31,355 indexed URLs across 8 sub-sitemaps | **AMBER** | Acknowledges ancient Sanskrit as Public Domain. However, Terms explicitly state: *"Automated bulk downloading of the site, or reproducing the collection as a whole, isn't on... ask us first."* **Do not scrape without permission.** Reach out for formal collaboration. |
| **SRC-004** | **Temples.bio** | `https://www.temples.bio/stotrams` | Chalisas and popular Stotrams | English, Hindi, Telugu | Apache 2.4 + PHP + MySQL | ~1,924 total URLs in sitemap, but only ~18–25 devotional texts (rest are hotel/tour bookings) | **RED** | Commercial puja/hotel booking business. Forbids copying, reproduction, or derivative works without written permission. Minimal catalog. **Exclude from scraper pipeline.** |
| **SRC-005+** | *Dynamic Queue* | *To be appended on input* | *TBD* | *TBD* | *TBD* | *TBD* | *Pending Audit* | *Intake queue for user-supplied sources.* |

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
- **Assigned Status**: [GREEN / AMBER / RED]
```
