# Source Audit Report: SRC-001 (Vaidika Vignanam)
**Audit Date:** 2026-11-04  
**Auditor:** Principal Software Architect & Data Researcher  
**Target URL:** `https://vignanam.org/`  
**Evaluation Status:** **AMBER** (Requires written permission / authorized collaboration for automated bulk extraction; public-domain texts may be referenced manually with strict rate limits)

---

## 1. Executive Summary & Identity
- **Platform Name:** Vaidika Vignanam
- **Primary Domain:** `https://vignanam.org/`
- **Founder / Maintainer:** Srinivas Vadrevu (founded in 2006 as a blog, established as vignanam.org in 2010).
- **Core Mission:** A devotional community repository preserving spiritual and devotional literature in various Indian languages.
- **Hosted Infrastructure:** Amazon S3 with AWS CloudFront CDN edge caching (`Server: AmazonS3`, `Via: CloudFront`).

---

## 2. Technical Inspection

### 2.1 Architecture & Content Delivery
- **Rendering Mechanism:** Static HTML with client-side enhancements. Pages are pre-rendered and served directly via CloudFront CDN.
- **URL Routing Strategy:** Clean path-based language prefix routing:
  - English (IAST): `https://vignanam.org/english/<slug>.html`
  - Devanagari: `https://vignanam.org/devanagari/<slug>.html`
  - Telugu: `https://vignanam.org/telugu/<slug>.html`
  - Tamil: `https://vignanam.org/tamil/<slug>.html`
  - Kannada: `https://vignanam.org/kannada/<slug>.html`
  - Malayalam: `https://vignanam.org/malayalam/<slug>.html`
  - Gujarati: `https://vignanam.org/gujarati/<slug>.html`
  - Odia: `https://vignanam.org/odia/<slug>.html`
  - Bengali: `https://vignanam.org/bengali/<slug>.html`
  - Marathi: `https://vignanam.org/marathi/<slug>.html`
  - Assamese: `https://vignanam.org/assamese.html` / `.../<slug>.html`
  - Punjabi: `https://vignanam.org/punjabi/<slug>.html`
  - Hindi: `https://vignanam.org/hindi/<slug>.html`
  - Samskritam: `https://vignanam.org/samskritam.html`
  - Konkani, Nepali, Sinhala, Grantha: Dedicated subpaths.
- **Dynamic JavaScript:** Minimal client-side JavaScript for script switching and layout toggles. Content is fully available in raw HTML without headless browser execution.
- **Available Formats:**
  - HTML (Structured web pages).
  - PDF: Generates downloadable PDFs for individual stotras (`.pdf` links embedded).
  - Audio: Embeds third-party or native audio recitations for select stotras.
- **APIs & Feeds:** No public REST API or RSS feed provided. Mobile applications (Android and iOS) query internal endpoints.

### 2.2 Sitemap & robots.txt Analysis
- **robots.txt (`https://vignanam.org/robots.txt`):**
  ```text
  User-agent: GPTBot
  Disallow: /
  User-agent: ClaudeBot
  Disallow: /
  User-agent: anthropic-ai
  Disallow: /
  User-agent: CCBot
  Disallow: /
  User-agent: PerplexityBot
  Disallow: /
  User-agent: Bytespider
  Disallow: /
  User-agent: *
  Allow: /
  Crawl-delay: 10
  Sitemap: https://vignanam.org/sitemap.xml
  ```
- **Observations:**
  - Explicitly blocks commercial AI scraping bots (`GPTBot`, `ClaudeBot`, `anthropic-ai`, `PerplexityBot`, etc.).
  - Permits general web crawlers (`User-agent: * Allow: /`) with a strict **`Crawl-delay: 10` seconds** per request.
  - `sitemap.xml` exists at root.

### 2.3 Content Volume & Organization
- **Front Page Catalog:** Over **2,720 direct links** across category tabs, deities, and languages.
- **Estimated Unique Texts:** ~800 to 1,200 unique Vedic, Puranic, and devotional compositions, each cross-rendered in 14–18 scripts.
- **Categorization Dimensions:**
  - By Category (Nitya Parayana, Suktams, Stotras, Sahasranamas, Ashtottara Shatanamavali, Kavacham, Keerthanas).
  - By Deity (Shiva, Vishnu, Devi, Ganesha, Subrahmanya, Hanuman, Surya/Navagraha, etc.).
  - By Author/Composer (Adi Shankaracharya, Tyagaraja, Annamayya, Ramadasa).
  - By Festival (Shivaratri, Navaratri, Diwali, etc.).

---

## 3. Copyright, Licensing & Permissions Assessment

### 3.1 Terms of Service & Intellectual Property
- **Official Terms (`terms-conditions.html`):**
  - Defines the service and proprietary scope: *"The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Vaidika Vignanam."*
  - Specific prohibitions: *"You’re not allowed to copy, or modify the app, any part of the app... and you also shouldn’t try to translate the app into other languages, or make derivative versions."*
- **Public Domain vs. Site Proprietary Boundary:**
  - *Public Domain:* The ancient Sanskrit shlokas, Vedic suktams (e.g. Purusha Suktam, Sri Suktam), and classical stotras are timeless public domain texts.
  - *Proprietary IP:* The digital collation, customized Devanagari/Telugu typography with custom-marked anusvaras (`shuddha Devanagari`, `shuddha Telugu`), typographical corrections, website arrangement, and database compilation are legally asserted by Vaidika Vignanam.
- **Commercial Reuse & Derivative Works:**
  - Commercial reuse of their compiled database without permission is strictly restricted.
  - Uncontrolled bulk downloading violates their terms and intent.

### 3.2 Permission Status Assignment
**Status: AMBER**
- **Justification:** While the underlying Sanskrit hymns are in the public domain, automated wholesale scraping of vignanam.org violates their 10-second crawl-delay constraints and their explicit assertion of database rights.
- **Action Required:**
  1. Automated bulk scraping must not be performed against this website.
  2. For pilot and comparative verification, public-domain text titles can be referenced, but underlying full texts should be acquired from open academic public-domain repositories (e.g., GRETIL, SanskritDocuments) or collected only after seeking written collaboration with Srinivas Vadrevu (`contact@vignanam.org`).

---

## 4. Content Analysis & Text Structure

- **Original Sanskrit:** Available in Devanagari and phonetic IAST transliteration.
- **Vedic Accents:** Rigorously encoded for Vedic Suktas (e.g., Purusha Suktam, Rudram). Accents use standard Unicode combining characters (Anudatta `U+0952` and Svarita `U+0951`), rendering accurately in modern browsers.
- **Diacritical Precision:** Provides toggles between simplified script (e.g., simple anusvara) and orthodox orthography (*shuddha* script with Vedic accents and class nasals).
- **Attributions:** Traditional authors (e.g., Adi Shankaracharya, Veda Vyasa, Valmiki) are cataloged.
- **Translations:** Does *not* offer full verse-by-verse English or regional translations on most pages; focuses primarily on accurate multi-script chanting lyrics.

---

## 5. Technical Collection Recommendation

- **Method:** Disallowed for automated wholesale scraping.
- **Authorized Use Case:** Source for manual cross-verification of Vedic accents, traditional orthography, and script transliteration accuracy for pilot stotras.
- **Direct Outreach:** Send a formal introductory letter to `contact@vignanam.org` requesting scholarly data exchange or API access for digital heritage preservation.
