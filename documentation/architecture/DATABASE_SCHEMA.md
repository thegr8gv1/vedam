# Vedic Heritage Platform — Database Architecture & Schema Specification
**Version:** 1.0.0  
**Status:** Approved Specification (Phase 1, Step 6)  
**ORM Implementation:** SQLAlchemy 2.0 (`database/models.py`)  
**Validation Schemas:** Pydantic V2 (`database/schemas.py`)  

---

## 1. Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    SOURCES ||--o{ CONTENT_RIGHTS : provides
    CATEGORIES ||--o{ CATEGORIES : "parent / subcategory"
    CATEGORIES ||--o{ TEXTS : classifies
    DEITIES ||--o{ TEXTS : dedicated_to
    TEXTS ||--o{ TEXT_VERSIONS : preserves
    TEXTS ||--o{ VERSES : contains
    TEXTS ||--|| CONTENT_RIGHTS : governed_by
    TEXTS ||--o{ VERIFICATION_AUDIT_LOGS : audits
    TEXTS ||--o{ DUPLICATE_CANDIDATES : compares
    VERSES ||--o{ TRANSLITERATIONS : rendered_in
    VERSES ||--o{ TRANSLATIONS : translated_into

    SOURCES {
        int id PK
        string source_code UK
        string name
        string base_url
        string acquisition_track
        string contact_email
    }

    CATEGORIES {
        int id PK
        string slug UK
        string name
        int parent_id FK
    }

    DEITIES {
        int id PK
        string slug UK
        string name
        string sanskrit_name
    }

    TEXTS {
        int id PK
        string content_id UK
        string uuid UK
        string canonical_title
        string devanagari_title
        int deity_id FK
        int primary_category_id FK
        string composer
        string rishi
        string chandas
        string content_hash
        int verse_count
    }

    TEXT_VERSIONS {
        int id PK
        int text_id FK
        string version_type
        int version_number
        text full_text
    }

    VERSES {
        int id PK
        int text_id FK
        string verse_id UK
        int verse_number
        string verse_type
        text devanagari_text
        text iast_text
        boolean vedic_accents_present
        string meter
    }

    TRANSLITERATIONS {
        int id PK
        int verse_id FK
        string target_script
        text script_text
        boolean is_lossless
    }

    TRANSLATIONS {
        int id PK
        int verse_id FK
        string target_language
        string translation_type
        text translated_text
        json word_by_word_json
        string review_status
    }

    CONTENT_RIGHTS {
        int id PK
        int text_id FK, UK
        int source_id FK
        string original_author_attribution
        string primary_source
        string specific_edition
        string license_type
        boolean commercial_reuse_permitted
        boolean translation_permitted
        string release_status
    }

    VERIFICATION_AUDIT_LOGS {
        int id PK
        int text_id FK
        string action
        text previous_value
        text new_value
        string performed_by
        datetime timestamp
    }

    DUPLICATE_CANDIDATES {
        int id PK
        int text_id_a FK
        int text_id_b FK
        float similarity_score
        string comparison_method
        string status
    }
```

---

## 2. Table Specifications & Cardinalities

### 2.1 `texts` (Master Sacred Text Entity)
- **Primary Key:** `id` (Integer autoincrement).
- **Unique Indexes:** `content_id` (`VEDA-TXT-XXXXX`), `uuid` (UUIDv4).
- **Secondary Indexes:** `canonical_title`, `content_hash`, `primary_category_id`, `deity_id`.
- **Purpose:** Acts as the single immutable anchor for all versions, verses, translations, and downstream publication handoffs.

### 2.2 `verses` (Granular Stanza Entity)
- **Primary Key:** `id` (Integer autoincrement).
- **Unique Index:** `verse_id` (`VEDA-TXT-XXXXX-VXXX`).
- **Composite Index:** `(text_id, verse_number)`.
- **Fields:**
  - `devanagari_text`: Canonical Sanskrit text in UTF-8.
  - `vedic_accents_present`: Flag indicating presence of combining characters (U+0951 Svarita, U+0952 Anudatta).
  - `verse_type`: `INVOCATION`, `VERSE`, `DOHA`, `CHAUPAI`, `MANTRA`, `PHALASRUTI`, `COLOPHON`.

### 2.3 `transliterations` (Multi-Script Projections)
- **Foreign Key:** `verse_id` references `verses.id` (ON DELETE CASCADE).
- **Unique Constraint:** `(verse_id, target_script)`.
- **Supported Scripts:** Telugu, Tamil, Kannada, Malayalam, Bengali, Gujarati, Odia, Assamese, Punjabi, Devanagari, Roman IAST.

### 2.4 `translations` (Multilingual Interpretations & Padachheda)
- **Foreign Key:** `verse_id` references `verses.id` (ON DELETE CASCADE).
- **Unique Constraint:** `(verse_id, target_language, translation_type)`.
- **Fields:**
  - `translation_type`: `LITERAL`, `BHAVARTHA`, `PADACHHEDA`, `TATPARYA`.
  - `word_by_word_json`: Structured array of grammatical tokens: `[{"word": "...", "padachheda": "...", "meaning": "..."}]`.
  - `review_status`: `DRAFT`, `SCHOLAR_REVIEWED`, `APPROVED`.

### 2.5 `content_rights` (Rights & Provenance Enforcement)
- **Foreign Key:** `text_id` references `texts.id` (1-to-1 relationship, UNIQUE).
- **Foreign Key:** `source_id` references `sources.id`.
- **Release Status Enum:**
  - `GREEN`: Approved for commercial publishing and public mobile distribution.
  - `AMBER`: Pending legal verification or partner contract signature.
  - `RED`: Prohibited for commercial publication.

---

## 3. Database Migration Strategy (Alembic)

- For development, SQLite (`database/vedam.db`) provides instant zero-dependency testing.
- For production, Alembic handles transactional DDL migrations against PostgreSQL.
- Migration scripts will reside in `database/migrations/versions/`.
