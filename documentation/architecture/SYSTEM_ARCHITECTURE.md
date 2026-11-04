# Vedic Heritage Platform — System Architecture & Modular Design
**Version:** 2.0.0  
**Status:** Approved Architectural Specification (Phase 2 Authorization)  

---

## 1. High-Level Architectural Overview

The platform is designed as an enterprise-grade, asynchronous, modular data processing and knowledge distribution ecosystem. It cleanly separates:
- **Acquisition & Ingestion**: Dual-track (Track A: Partnership; Track B: Independent Public Domain).
- **Core Persistence**: Multi-version relational schema supporting multi-edition provenance, version history, media assets, and granular rights grants.
- **Compliance & Rights**: Mandatory Content Rights & Provenance Engine with a Jurisdiction-Aware Copyright Assessment Framework.
- **Export & Delivery**: Typeset Word manuscripts, structured Excel datasets, and mobile JSON bundles.

```mermaid
flowchart TD
    subgraph Acquisition ["1. Acquisition Tier"]
        TA["Track A: Partner Data Handoffs"]
        TB["Track B: Public Domain Primary Sources"]
    end

    subgraph Automation ["2. Python Automation Pipeline (automation/)"]
        P0["connectors/base.py<br>(Rate limits, Retry, Dry-run)"]
        P1["identity/generator.py<br>(VEDA-TXT IDs, Hashes)"]
        P2["cleaners/unicode_preserver.py<br>(Unicode NFC, Swara Preserver)"]
        P3["parsers/<br>(verse_splitter.py, metadata_extractor.py)"]
        P4["classifiers/<br>(text_classifier.py)"]
        P5["validators/<br>(completeness_checker.py)"]
        P6["duplicate_detection/<br>(SHA-256 & Levenshtein)"]
        P7["rights/jurisdiction.py<br>(Jurisdiction Rights Engine)"]
        P8["pipeline/<br>(queue.py, checkpoint.py, logger.py)"]
    end

    subgraph DataStorage ["3. Relational Persistence Tier (database/)"]
        DB[(SQLite Dev / PostgreSQL Prod)]
        T_SRC["sources & source_editions"]
        T_TXT["texts & text_versions"]
        T_VRS["verses & transliterations"]
        T_TRN["translations"]
        T_RGT["content_rights & rights_grants"]
        T_MDA["media_assets"]
        T_LOG["verification_audit_logs"]
    end

    subgraph ExportTier ["4. Publication & Distribution Tier (exports/)"]
        EX_XLS["excel_exporter.py<br>(Multi-tab Styled .xlsx)"]
        EX_DOC["word_exporter.py<br>(Typeset .docx Manuscripts)"]
        EX_JSN["json_exporter.py<br>(Mobile App Bundles)"]
    end

    Acquisition --> P0 --> P1 --> P2 --> P3 --> P4 --> P5 --> P6 --> P7 --> P8
    P8 --> DataStorage
    DataStorage --> P7
    P7 --> ExportTier
```

---

## 2. Python Module Architecture

```text
automation/
├── connectors/
│   └── base.py                 # Abstract Source Connector with rate limits, retries, dry-run, and permission verification
├── identity/
│   └── generator.py            # Canonical Content ID (VEDA-TXT-XXXXX), Verse ID, and SHA-256 hash generation
├── cleaners/
│   └── unicode_preserver.py    # Unicode NFC normalizer, Vedic Swara analyzer, and multi-script transliteration engine
├── parsers/
│   ├── verse_splitter.py       # Verse and stanza demarcation (Sanskrit stotras, Awadhi dohas & chaupais)
│   └── metadata_extractor.py   # Liturgical metadata extractor (Rishi, Chandas, Devata, Viniyoga)
├── classifiers/
│   └── text_classifier.py      # Category classifier, Awadhi/Sanskrit language detector, and deity identifier
├── validators/
│   └── completeness_checker.py # Missing verse, duplicate number, and truncation detector
├── duplicate_detection/
│   └── engine.py               # Exact SHA-256 and RapidFuzz fuzzy recension similarity scoring
├── rights/
│   ├── engine.py               # Mandatory Content Rights & Provenance Engine gatekeeper
│   └── jurisdiction.py         # Multi-jurisdiction copyright evaluation framework (IN, US, EU, GB, GLOBAL)
├── pipeline/
│   ├── queue.py                # End-to-end ingestion orchestrator (normalization -> splitting -> validation -> DB)
│   ├── checkpoint.py           # Resumable job state engine saving progress to disk
│   └── logger.py               # Structured JSON and console audit logging
├── exporters/
│   ├── excel_exporter.py       # OpenPyXL multi-tab styled workbooks
│   ├── word_exporter.py        # Python-docx typeset printable manuscripts
│   └── json_exporter.py        # Mobile-app-ready JSON serializer
└── pilot/
    └── seed_pilot_data.py      # Seed script for the 8 authorized candidate compositions
```
