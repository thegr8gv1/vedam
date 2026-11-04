# Vedic Heritage Platform — Rights Assessment & Legal Clearance Register
**Version:** 7.0.0  
**Last Updated:** 2026-11-04  
**Scope:** Multidimensional rights assessment, legal counsel sign-offs, and commercial publication clearance for all 18 verified compositions (8 Pilot Compositions + 3 Batch 1 + 3 Batch 2 + 4 Batch 3 Compositions).

---

## 1. Multidimensional Rights Architecture

The platform separates legal copyright clearance from editorial and automated technical quality audits:

```
[Acquisition: VERIFIED_SOURCE]
        │
        ▼
[Textual Verification: SCHOLAR_VERIFIED] ──┐
        │                                  │
        ▼                                  ▼
[Rights Clearance: GREEN_CLEARED] ──► [Editorial Approval: APPROVED] ──► [Publication: READY_FOR_EXPORT]
        │                                  ▲
        ▼                                  │
[Translation Status: DRAFT / APPROVED] ────┘
```

**Dual-Channel Publication Governance:**
1. **Scholarly Review & Typeset Verification Channel (`scholarly_review`):**
   - Requires `AcquisitionStatus.VERIFIED_SOURCE`
   - Requires `TextualVerificationStatus.SCHOLAR_VERIFIED`
   - Requires `RightsClearanceStatus.GREEN_CLEARED` (Affirmative human legal sign-off)
   - Permits `TranslationStatus.DRAFT` (Awaiting Scholarly Panel Review) with explicit provenance notice
   - Requires `EditorialApprovalStatus.APPROVED`
   - Requires `PublicationStatus.READY_FOR_EXPORT`
2. **Commercial Public Release Channel (`commercial_release`):**
   - Strictly requires `TranslationStatus.APPROVED` or `SCHOLAR_REVIEWED` by accredited Sanskrit scholar panel before commercial distribution.

---

## 2. Rights Clearance Register for Verified Compositions

| Content ID | Canonical Title | Composition Age | Primary Edition Year | Jurisdiction | License Type | Commercial Reuse | Legal Reviewer | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`VEDA-TXT-00001`** | Ganesha Pancharatnam | c. 800 CE | 1910 (Vani Vilas) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00002`** | Shiva Tandava Stotram | Ancient | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00003`** | Aditya Hrudayam | Ancient Epic | 1902 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00004`** | Madhurashtakam | c. 1500 CE | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00005`** | Mahamrityunjaya Vedic Mantra | Vedic (Ancient) | 1890 (Max Müller) / 1933 (VSM)* | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED`* |
| **`VEDA-TXT-00006`** | Gayatri Vedic Mantra | Vedic (Ancient) | 1890 (Max Müller) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00007`** | Sri Suktam | Vedic Khilani | 1906 (Scheftelowitz) / 1946 (VSM)*| GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED`* |
| **`VEDA-TXT-00008`** | Hanuman Chalisa | c. 1575 CE | 1874 (Nawal Kishore) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00010`** | Mahalakshmi Ashtakam | Ancient Purana | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00011`** | Lingashtakam | Ancient (c. 800 CE) | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00012`** | Sankata Nashana Ganesha Stotram | Ancient Purana | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00013`** | Venkateswara Suprabhatam | c. 1400 CE | 1918 (Vavilla) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00014`** | Purusha Suktam | Vedic (Ancient) | 1890 (Max Müller) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00015`** | Durga Suktam | Vedic (Taittiriya) | 1894 (Anandashrama) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00016`** | Narayana Suktam | Vedic (Taittiriya) | 1894 (Anandashrama) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00017`** | Surya Ashtakam | Puranic (Samba) | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00018`** | Kanakadhara Stotram | c. 800 CE | 1910 (Vani Vilas) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |
| **`VEDA-TXT-00019`** | Mahishasura Mardini Stotram | Classical Stotra | 1912 (Nirnaya Sagar) | GLOBAL | `PUBLIC_DOMAIN` | **YES** | Lead Legal Counsel | `GREEN_CLEARED` |

*\* Note: Modern editorial notes from VSM 1933 and VSM 1946 are sequestered under `AMBER_RESTRICTED`; core Vedic texts are anchored to universal public domain editions (Max Müller 1890, Scheftelowitz 1906).*

---

## 3. Pre-Flight Publication Quality Gate Verification

All 11 verified compositions have been evaluated against the 15-rule publication pre-flight gate (`PublicationPreflightGate`):
- `PUB-001` TITLE_CHECK: **PASSED**
- `PUB-002` CLASSIFICATION_CHECK: **PASSED**
- `PUB-003` LANGUAGE_SCRIPT_CHECK: **PASSED**
- `PUB-004` PROVENANCE_ATTRIBUTION_CHECK: **PASSED**
- `PUB-005` CRITICAL_EDITION_CHECK: **PASSED**
- `PUB-006` RIGHTS_CLEARANCE_STATUS_CHECK: **PASSED**
- `PUB-007` LEGAL_COUNSEL_SIGNOFF_CHECK: **PASSED**
- `PUB-008` ACQUISITION_STATUS_CHECK: **PASSED**
- `PUB-009` TEXTUAL_VERIFICATION_CHECK: **PASSED**
- `PUB-010` TRANSLATION_APPROVAL_CHECK: **PASSED** (Permitted in `scholarly_review` channel; flagged for scholarly review)
- `PUB-011` EDITORIAL_APPROVAL_CHECK: **PASSED**
- `PUB-012` VERSE_COUNT_MATCH_CHECK: **PASSED**
- `PUB-013` VERSE_SEQUENCE_CONTINUITY_CHECK: **PASSED**
- `PUB-014` VEDIC_SWARA_ACCENT_CHECK: **PASSED**
- `PUB-015` CONTENT_HASH_INTEGRITY_CHECK: **PASSED**
