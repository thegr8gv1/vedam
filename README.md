# Vedic Heritage Digital Library & Global Spiritual Platform

A comprehensive digital platform and automation ecosystem for preserving, organizing, verifying, translating, and publishing authentic Indian Vedic, Puranic, and devotional literature across 22 Scheduled Indian languages, English, and worldwide interfaces.

---

## 🏛️ Project Vision & Purpose

This platform serves as a permanent, authentic, and scholarly digital repository of India's spiritual heritage. It powers:
- **Spiritual Text Digital Library**: High-precision Sanskrit original texts, transliterations, word-by-word meanings, and verified multilingual translations.
- **Devotional Audio & Video Automation**: Production handoffs for chanting (1, 3, 11, 21, 27, 54, 108 repetitions, Japa), Suno AI, social platforms (YouTube, Reels, Instagram, X).
- **Global Vedic Calendar & Panchangam**: Astronomical location-aware calculations (Tithi, Nakshatra, Yoga, Karana, Rahu Kalam, Yamagandam, etc.) supporting regional conventions (Amanta & Purnimanta).
- **Daily Sankalpam Generator**: Authentic location- and tradition-specific ritual Sankalpam generation.
- **Cross-Platform Mobile Application**: Flutter-based global iOS and Android app with offline chanting counter and reading modes.

---

## 📂 Living Documentation & Roadmap

To ensure no requirements are forgotten and the project can adapt gracefully as more websites, datasets, and scripts are introduced, consult:

- **[Master Execution Plan](documentation/project_roadmap/MASTER_PLAN.md)**: The canonical living roadmap detailing all 10 phases, architecture, quality gates, and current sprint status.
- **[Source Registry](documentation/project_roadmap/SOURCE_REGISTRY.md)**: The central registry tracking all input websites, digital libraries, academic repositories, and datasets with their legal rights and extraction status.
- **[Source Research](documentation/source_research/)**: Deep-dive inspection notes, robots.txt analyses, and structural audits for every candidate source.
- **[Architecture & Schemas](documentation/architecture/)**: System diagrams, database schemas, and export layout standards.

---

## 🏗️ Repository Architecture

```text
Vedam/
├── documentation/          # Roadmaps, source research, legal assessments, architectural specs
├── database/               # Schemas, SQLAlchemy models, Alembic migrations, backups
├── automation/             # Modular Python pipeline:
│   ├── source_discovery/   # Source inventory & crawler discovery
│   ├── permission_checker/ # Terms of Service & robots.txt compliance
│   ├── collectors/         # Rate-limited, resumable extractors per source
│   ├── parsers/            # HTML/text parsing into raw canonical models
│   ├── cleaners/           # Unicode normalization & whitespace normalization
│   ├── validators/         # Sanskrit grammar, meter, verse-count & diacritics checks
│   ├── duplicate_detection/# Content-hash & fuzzy duplicate recognition
│   ├── translation/        # Multi-stage localization & glossary management
│   └── exporters/          # Excel, Word, and JSON automated generation
├── data/                   # Data tiers: raw -> processed -> verified -> translations -> rejected
├── exports/                # Generated Word (.docx), Excel (.xlsx), and JSON publications
├── media/                  # Audio chanting scripts, metadata, and production handoffs
├── backend/                # FastAPI services for mobile and web apps
├── admin_dashboard/        # Scholar and editorial review portal
├── mobile_app/             # Flutter cross-platform mobile application
├── tests/                  # Pytest test suite ensuring zero silent regressions
└── logs/                   # Audit trails, scraper logs, and operation journals
```

---

## 🛡️ Core Operating Principles

1. **Accuracy Over Speed**: We do not rush. Texts are preserved with their original provenance.
2. **Never Silently Alter**: AI suggestions are stored separately as candidates; raw texts are never overwritten.
3. **Strict Copyright & Provenance Compliance**: Ancient texts are public domain; modern commentaries, translations, and site arrangements are protected. Every source is audited before extraction.
4. **Resumable & Logged Operations**: All scrapers and processors save checkpoints and handle network interruptions gracefully.
5. **Incremental Phased Progress**: Each module must be designed, documented, tested, and approved before moving to the next.
