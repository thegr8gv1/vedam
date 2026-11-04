# Source Audit Report: SRC-004 (Temples.bio – Stotrams)
**Audit Date:** 2026-11-04  
**Auditor:** Principal Software Architect & Data Researcher  
**Target URL:** `https://www.temples.bio/stotrams`  
**Evaluation Status:** **RED** (Automated collection, derivative generation, and commercial reuse are strictly forbidden without written permission; content catalog is minimal and commercially tied)

---

## 1. Executive Summary & Identity
- **Platform Name:** Temples.bio
- **Primary Domain:** `https://www.temples.bio/`
- **Core Business Model:** Commercial pilgrimage, temple darshan, hotel bookings, and paid puja reservation portal (e.g., Karthika Masam Rudrabhishekam bookings, TTD tours).
- **Hosted Infrastructure:** Apache 2.4.58 on Ubuntu (`Server: Apache/2.4.58 (Ubuntu)`), PHP session backend (`PHPSESSID`), dynamic MySQL/Laravel architecture.

---

## 2. Technical Inspection

### 2.1 Architecture & Content Delivery
- **Technology Stack:** PHP-driven dynamic backend with jQuery, OwlCarousel, and intl-tel-input for customer bookings.
- **URL Routing Strategy:** Clean URL routing:
  - Landing: `https://www.temples.bio/stotrams`
  - Deity Chalisas & Stotrams: `/deities/<deity>/<slug>` (e.g., `/deities/hanuman/chalisa`, `/deities/shiva/shiva-tandava-stotram`).
- **Available Languages & Scripts:**
  - Primarily English, Hindi, and Telugu.
  - Basic script toggles embedded on individual stotra pages.
- **Available Formats:**
  - Web pages (HTML).
  - Promotes downloadable PDFs (`/public/uploads/...pdf`) as lead-generation mechanisms.
  - Audio clips embedded with simple HTML5 players.
- **Feeds & APIs:** No public API. Backend APIs are strictly internal for booking operations.

### 2.2 Sitemap & robots.txt Analysis
- **robots.txt (`https://www.temples.bio/robots.txt`):**
  - Allows search bots and select AI crawlers on root (`Allow: /`).
  - Disallows internal administrative and database paths (`/admin/`, `/database/`, `/config/`, `/storage/`, `/vendor/`).
- **Sitemap (`https://www.temples.bio/sitemap.xml`):**
  - Contains **1,924 total URLs**, but the vast majority (~1,850+) are commercial temple directories, city guides, puja booking forms, and hotel packages.
  - Stotrams and chalisas constitute only a small fraction (~18 to 25 items).

### 2.3 Content Volume & Organization
- **Total Devotional Texts:** Very limited collection (~18–25 popular hymns).
  - Popular Chalisas: Hanuman Chalisa, Shiva Chalisa, Durga Chalisa, Ganesh Chalisa, Ram Chalisa, Shani Chalisa, Krishna Chalisa.
  - Popular Stotrams: Shiva Tandava Stotram, Dakshinamurthy Stotram, Ashta Lakshmi Stotram.
- **Lack of Scholarly Depth:** Texts are formatted primarily as consumer-facing devotional blogs rather than critical scholarly editions.

---

## 3. Copyright, Licensing & Permissions Assessment

### 3.1 Terms & Conditions Policy Analysis (`https://www.temples.bio/terms-and-conditions`)
The site’s legal terms are standard commercial terms of service:

> *"Intellectual Property: The Service and its original content, features, and functionality are owned by Temples.bio and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not reproduce, distribute, modify, or create derivative works from any content on our Service without our express written permission."*

- **Commercial Intent:** Temples.bio uses stotrams as SEO landing pages to drive traffic to its commercial puja and temple tour booking services.
- **Public Domain vs. Site Proprietary Boundary:**
  - The hymns are traditional (Tulsidas's Hanuman Chalisa, Ravana's Shiva Tandava).
  - However, Temples.bio expressly claims copyright over the presentation, website content, translations, and derivative assets, forbidding any copying or reproduction without written permission.

### 3.2 Permission Status Assignment
**Status: RED**
- **Justification:**
  - Automated collection is prohibited by terms of service.
  - Republication or derivative creation without written permission is explicitly prohibited.
  - The content volume is minuscule (~20 texts) and provides no unique scholarly or manuscript value over established academic repositories.
- **Action Required:**
  1. **Do not scrape or ingest content from Temples.bio.**
  2. Drop Temples.bio as an ingestion target for the automated pipeline.
  3. Focus resources on high-volume, authentic repositories (e.g. Vignanam, Stotrams.com, SanskritDocuments, GRETIL).

---

## 4. Content Analysis & Text Structure

- **Original Sanskrit:** Mixed quality; often modern Devanagari transliteration with occasional typo vulnerabilities.
- **Transliteration:** Basic Roman English.
- **Translations:** Simplified English meanings aimed at casual readers rather than scholars.
- **Attributions:** Mention traditional authors where commonly known (e.g., Tulsidas).

---

## 5. Technical Collection Recommendation

- **Scraping Allowed?** No.
- **Recommendation:** Exclude from active scraper development. It does not justify legal overhead or permission requests given its minimal catalog size and commercial restrictions.
