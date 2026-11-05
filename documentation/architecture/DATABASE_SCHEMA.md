# Vedic Heritage Platform — Database Architecture & Schema Specification
**Version:** 2.0.0  
**Status:** Approved Specification (Phase 2 Authorization)  
**ORM Implementation:** SQLAlchemy 2.0 (`database/models.py`)  
**Validation Schemas:** Pydantic V2 (`database/schemas.py`)  

---

## 1. Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    SOURCES ||--o{ SOURCE_EDITIONS : publishes
    SOURCES ||--o{ CONTENT_RIGHTS : provides
    CATEGORIES ||--o{ CATEGORIES : "parent / subcategory"
    CATEGORIES ||--o{ TEXTS : classifies
    DEITIES ||--o{ TEXTS : dedicated_to
    TEXTS ||--o{ SOURCE_EDITIONS : based_on
    TEXTS ||--o{ TEXT_VERSIONS : preserves
    TEXTS ||--o{ VERSES : contains
    TEXTS ||--|| CONTENT_RIGHTS : governed_by
    TEXTS ||--o{ RIGHTS_GRANTS : cleared_by
    TEXTS ||--o{ MEDIA_ASSETS : accompanied_by
    TEXTS ||--o{ VERIFICATION_AUDIT_LOGS : audits
    TEXTS ||--o{ DUPLICATE_CANDIDATES : compares
    VERSES ||--o{ TRANSLITERATIONS : rendered_in
    VERSES ||--o{ TRANSLATIONS : translated_into
    VERSES ||--o{ TRANSLATION_VIEWS : expressed_in
    TRANSLATIONS ||--o{ TRANSLATION_VIEWS : decomposes_into
    CONTRIBUTORS ||--o{ TRANSLATIONS : translates
    CONTRIBUTORS ||--o{ TRANSLATIONS : reviews

    TEXTS {
        int id PK
        string content_id UK "e.g. VEDA-TXT-00001"
        string uuid UK
        string canonical_title
        string devanagari_title
        string raw_source_script
        text raw_source_text "Immutable"
        text canonical_scholarly_text
        int deity_id FK
        int primary_category_id FK
        string original_language "sa, awa"
        string composer
        string rishi
        string chandas
        string devata
        string content_hash "SHA-256"
        int verse_count
    }

    SOURCE_EDITIONS {
        int id PK
        int text_id FK
        int source_id FK
        string edition_title
        string publisher
        string editor_name
        int publication_year
        string isbn_or_call_number
        boolean is_primary_critical_edition
    }

    RIGHTS_GRANTS {
        int id PK
        int text_id FK
        string ip_layer "COMPOSITION, EDITION, TRANSLATION, AUDIO"
        string jurisdiction "IN, US, EU, GB, GLOBAL"
        string license_type
        boolean commercial_reuse_authorized
        string contract_reference
        boolean is_legally_approved
        string legal_reviewer
        string status "GREEN, AMBER, RED"
    }

    MEDIA_ASSETS {
        int id PK
        int text_id FK
        string media_type "AUDIO_CHANT, JAPA_LOOP, VIDEO_LONG"
        string title
        string file_path
        float duration_seconds
        int repetition_count "108"
        string license_type
        boolean commercial_release_cleared
    }

    CONTENT_RIGHTS {
        int id PK
        int text_id FK, UK
        string original_author_attribution
        string primary_source
        string specific_edition
        string license_type "PUBLIC_DOMAIN, PARTNER"
        boolean commercial_reuse_permitted
        string territory_restriction "GLOBAL, IN"
        boolean is_legally_approved
        string legal_reviewer
        string release_status "GREEN, AMBER, RED"
    }

    VERSES {
        int id PK
        int text_id FK
        string verse_id UK "e.g. VEDA-TXT-00001-V001"
        int verse_number
        string verse_type "VERSE, DOHA, MANTRA"
        text raw_source_text
        text devanagari_text
        text iast_text
        boolean vedic_accents_present
        json vedic_accent_annotations
    }

    TRANSLITERATIONS {
        int id PK
        int verse_id FK
        string target_script "telugu, tamil, kannada, malayalam"
        text script_text
        boolean is_lossless
    }

    TRANSLATIONS {
        int id PK
        int verse_id FK
        string target_language "en, hi, te, ta, kn"
        string translation_type "BHAVARTHA, PADACHHEDA"
        text translated_text
        json word_by_word_json
        string review_status "DRAFT, APPROVED"
    }

    TRANSLATION_VIEWS {
        int id PK
        string view_id UK "e.g. VIEW-TR-00001-BHAVARTHA-v1"
        int translation_id FK
        int verse_id FK
        string target_language "en, hi, te, ta, kn, mr, bn, gu, ml, or"
        string view_type "BHAVARTHA, LITERAL, TATPARYA"
        text view_text
        int version "1"
        string source_reference
        string translator_provenance
        string review_status "DRAFT, SCHOLAR_REVIEWED, APPROVED"
        string reviewer
        string reviewer_affiliation
        datetime reviewed_at
        text approval_notes
        json approval_history_json
    }
```
