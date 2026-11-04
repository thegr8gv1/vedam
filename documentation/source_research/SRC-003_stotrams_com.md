# Source Audit Report: SRC-003 (Stotrams.com)
**Audit Date:** 2026-11-04  
**Auditor:** Principal Software Architect & Data Researcher  
**Target URL:** `https://stotrams.com/`  
**Evaluation Status:** **AMBER** (Sanskrit texts are explicitly recognized as Public Domain; automated wholesale downloading is restricted; written permission requested for translations and bulk access)

---

## 1. Executive Summary & Identity
- **Platform Name:** Stotrams
- **Primary Domain:** `https://stotrams.com/`
- **Core Mission:** A clean, modern, advertisement-free digital reading library of Sanskrit and regional devotional literature with word-by-word meanings and multi-script transliteration.
- **Hosted Infrastructure:** Modern Jamstack architecture built on **Astro** static site generator, deployed via Cloudflare Pages / Workers (`Server: cloudflare`, `cfCacheStatus: DYNAMIC`).

---

## 2. Technical Inspection

### 2.1 Architecture & Content Delivery
- **Technology Stack:** Built with Astro (`_astro/SiteSearch...js`), server-side rendered / statically pre-rendered with zero bloated client JavaScript.
- **URL Structure:** Clean, human-readable slug hierarchy:
  - Stotras: `https://stotrams.com/stotra/<slug>` (e.g., `/stotra/shiva-tandavastotram1`)
  - Collections: `https://stotrams.com/collection/<deity-or-category>` (e.g., `/collection/shiva`, `/collection/veda`)
  - Forms: `/forms/aarti`, `/forms/chalisa`, `/forms/ashtakam`, `/forms/kavacham`, `/forms/sahasranama`, `/forms/namavali`
- **Languages & Scripts:**
  - 10 Scripts supported via rule-based lossless phonetic conversion: Devanagari, Telugu, Tamil, Kannada, Malayalam, Bengali, Gujarati, Odia, Assamese, and Roman IAST.
  - Regional devotional hymns in Hindi, Marathi, Gujarati, Tamil, and Telugu.
- **Available Formats:** Clean HTML. No PDF bloat.
- **APIs & Feeds:** No public API, but sitemaps provide an exhaustive index of all 31,355 pages.

### 2.2 Sitemap & robots.txt Analysis
- **robots.txt (`https://stotrams.com/robots.txt`):**
  ```text
  # Stotrams.com — deliberately open to all crawlers, including AI search,
  # user-fetch, and training bots. Goal: maximum discoverability and citation...
  User-agent: *
  Allow: /
  Disallow: /cdn-cgi/
  Disallow: /preview/
  ```
- **Sitemap Index (`https://stotrams.com/sitemap-index.xml`):**
  - Contains 8 sub-sitemaps (`sitemap-0.xml` to `sitemap-7.xml`).
  - Total indexed URLs: **31,355 URLs** covering all individual stotras, script variations, and deity collections.

---

## 3. Copyright, Licensing & Permissions Assessment

### 3.1 Terms of Use Policy Analysis (`https://stotrams.com/terms`)
Stotrams.com provides an exemplary, legally transparent model for traditional devotional literature:

> *"The Sanskrit itself is in the public domain and no one, including us, has any business claiming it. Read these texts, recite them, print them, put them on a lectern, send them to your family, use them in a class or a satsang. That's what they're here for and none of it needs our permission."*

However, their terms draw clear lines regarding editorial additions and bulk operations:

1. **Editorial & Translation Layer:**
   > *"A layer of work sits on top of the source texts: the English meanings, the word-by-word notes, the descriptions, the categorisation, and the way the library is arranged. That layer took a long time and is ours, along with the site's design, name and artwork. If you'd like to reuse it — in a book, an app, a video, another site — write to us. We generally say yes, we ask for a credit and a link..."*
2. **Bulk Scraping Restriction:**
   > *"Automated bulk downloading of the site, or reproducing the collection as a whole, isn't on. Not because the texts are precious property, but because a scraped copy goes stale the moment we correct something... If you have a use that genuinely needs bulk access, ask; there's usually a better way to do it and we'd rather help than find out afterwards."*

### 3.2 Permission Status Assignment
**Status: AMBER**
- **Justification:**
  - Ancient Sanskrit original verses: **GREEN (Public Domain)**.
  - English translations, word-by-word notes, and taxonomy: **AMBER (Requires written permission / credit)**.
  - Wholesale automated scraping: **AMBER / RESTRICTED (Explicitly requested by authors to ask first for bulk access)**.
- **Action Required:**
  1. Do not launch automated scrapers against stotrams.com.
  2. Reach out via their contact form (`stotrams.com/contact`) stating the research and preservation goals of this project, requesting permission or official data sharing for their word-by-word structural layout.
  3. Where Sanskrit verses are studied, verify against scholarly printed editions (e.g. Gita Press, Motilal Banarsidass, Ramakrishna Math).

---

## 4. Content Analysis & Text Structure

- **Original Sanskrit:** Impeccable Devanagari with proper Sandhi and verse numbering.
- **Transliteration:** Real-time client/server multi-script transliteration across 10 scripts.
- **Word-by-Word Analysis (Padachheda & Anvaya):** High quality! Every compound word is dissected with grammatical components (e.g., `जटाटवी (jaṭāṭavī) = forest of matted locks [jaṭā: matted locks | aṭavī: forest]`).
- **Translations:** Clear, modern English interpretations accompanying every verse.
- **Traditional Attributions:** Clearly indicates composer (e.g., Ravana for Shiva Tandava, Adi Shankaracharya for Kanakadhara/Bhaja Govindam, Tulsidas for Hanuman Chalisa).

---

## 5. Technical Collection Recommendation

- **Recommended Strategy:** Partnership / Ingestion Request.
- Contact the creator to request approved scholarly data export or bulk collaboration.
- This source serves as an architectural gold standard for how our platform should structure its own word-by-word database and multi-script transliteration engine in Phases 3 and 6.
