# Source Audit Report: SRC-002 (Drik Panchang – Vedic Mantras)
**Audit Date:** 2026-11-04  
**Auditor:** Principal Software Architect & Data Researcher  
**Target URL:** `https://www.drikpanchang.com/vedic-mantra/mantra-collection.html`  
**Evaluation Status:** **RED** (Automated collection, API extraction, or commercial replication is strictly prohibited; limited to manual comparative verification of public-domain verse numbers)

---

## 1. Executive Summary & Identity
- **Platform Name:** Drik Panchang
- **Parent Entity:** Adarsh Mobile Applications LLP (Offices in Mathura, UP and Bengaluru, Karnataka, India).
- **Primary Domain:** `https://www.drikpanchang.com/`
- **Core Mission:** Premier Hindu astronomical calendar, Panchangam, festival, and Vedic ritual portal.
- **Hosted Infrastructure:** Custom server cluster (`Server: DrikPanchang`, `Via: 1.1 google`), HTTP/3 enabled, active Cloudflare/Google protection.

---

## 2. Technical Inspection

### 2.1 Architecture & Content Delivery
- **Rendering Mechanism:** Server-rendered dynamic pages with aggressive session tracking, personalized cookie states (`drik-school-name=purnimanta`, `drik-ayanamsha-type=chitra-paksha`, etc.), and strict caching headers (`cache-control: no-store, no-cache`).
- **URL Routing Strategy:** Hierarchical static-like URLs under `/vedic-mantra/` (e.g., `/vedic-mantra/gods/lord-shiva/shiva-mantras.html`).
- **AJAX & Internal APIs:** Core dynamic functions and calculations use `/ajax/` and `/dp-api/`, both strictly firewalled.
- **Languages Offered:**
  - Interface: English and Hindi (`?lang=hi`).
  - Texts: Devanagari Sanskrit with English transliteration, English translation, and ritual instructions.
- **Available Formats:** HTML web pages. No downloadable PDFs or open bulk data dumps.
- **Feeds / APIs:** No authorized public API exists. Commercial APIs are marketed privately by Adarsh Mobile Applications LLP.

### 2.2 Sitemap & robots.txt Analysis
- **robots.txt (`https://www.drikpanchang.com/robots.txt`):**
  ```text
  User-agent: *
  Disallow: /ajax/
  Disallow: /dp-api/
  User-agent: cohere-ai
  Disallow: /
  User-agent: YouBot
  Disallow: /
  User-agent: SeekportBot
  Disallow: /
  User-agent: CCBot
  Disallow: /
  User-agent: Bytespider
  Disallow: /
  User-agent: Baiduspider
  Disallow: /
  Sitemap: https://www.drikpanchang.com/drik-sitemap.xml
  ```
- **Observations:**
  - Sitemaps list ~2,828 key URLs.
  - Core API endpoints (`/ajax/` and `/dp-api/`) are explicitly disallowed.
  - Aggressive bot blocking targeting data harvesters and AI training crawlers.

### 2.3 Content Volume & Organization
- **Scope in `/vedic-mantra/`:**
  - ~28 deity-specific mantra collections (Ganesha, Shiva, Vishnu, Rama, Krishna, Durga, Lakshmi, Saraswati, Surya, Kubera, etc.).
  - Vedic Suktams and Samhita selections (Rudram Namakam/Chamakam, Purusha Suktam, Sri Suktam).
  - Ritual Vidhi mantras (Panchamrita Snanam, Shodashopachara mantras).
  - Yantras and deity diagrams.

---

## 3. Copyright, Licensing & Permissions Assessment

### 3.1 Terms of Service & Intellectual Property
- **Copyright Assertion:**
  - Prominent site-wide legal notice: *"All Images and data - Copyrights Ⓒ www.drikpanchang.com. Drik Panchang and the Panditji Logo are registered trademarks of Adarsh Mobile Applications LLP."*
- **Terms & Legal Posture:**
  - Operated as a commercial proprietary software service.
  - Panchang calculations, Muhurta algorithms, festival rules, and website text formatting are actively defended proprietary assets.
- **Public Domain vs. Site Proprietary Boundary:**
  - *Public Domain:* Ancient Rigvedic, Yajurvedic, and Atharvavedic mantras in the Vedic Sanskrit original are public domain.
  - *Proprietary IP:* Drik Panchang’s English translations, explanations of significance, ritual arrangement, custom imagery, and calculation engines are copyrighted property of Adarsh Mobile Applications LLP.
- **Commercial Reuse / Bulk Extraction:**
  - Commercial reuse of content or scraping of pages is expressly forbidden without a commercial licensing contract.

### 3.2 Permission Status Assignment
**Status: RED**
- **Justification:** Automated scraping, bot access to internal endpoints, and republishing of Drik Panchang's textual layouts or translations violate their explicit copyright claims and legal terms.
- **Action Required:**
  1. **Strictly DO NOT build scrapers** or automated harvesters targeting Drik Panchang.
  2. Use Drik Panchang strictly as an external human benchmark to cross-verify festival dates and traditional mantra recensions manually in a standard browser.
  3. When implementing Vedic calendar algorithms in Phase 10, implement standard astronomical ephemeris libraries (Swiss Ephemeris / PyEphem) from first principles rather than copying Drik Panchang's output.

---

## 4. Content Analysis & Text Structure

- **Original Sanskrit:** Available in clear Devanagari with Vedic accents for Vedic mantras.
- **Transliteration:** English Roman transliteration provided.
- **Translations:** Concise English meanings and significance notes accompany each mantra.
- **Attributions:** Rishi, Chandas, and Devata are occasionally noted for major Vedic suktas.
- **Audio / Video:** Minimal inline audio; primarily text and imagery.

---

## 5. Technical Collection Recommendation

- **Scraping Allowed?** No. Disallowed by legal policy and architectural controls.
- **Permitted Role in Project:** Secondary manual reference for verifying traditional verse counts and comparing Vedic accent placements against authoritative printed Samhitas.
