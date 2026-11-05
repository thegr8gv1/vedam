# ADMINISTRATIVE CREDENTIAL VERIFICATION CHECKLIST
**Phase**: Phase 9 Editorial Governance  
**Document Reference**: `VEDAM-ADM-CHECKLIST-2026-V1`  
**Audience**: Editorial Board Administrators & Compliance Officers  

---

## 1. Identity & Authenticity Verification

| Verification Step | Verification Criteria | Verified? | Verification Notes & Document Reference |
| :--- | :--- | :---: | :--- |
| **1.1 Living Identity** | Government-issued photo ID verified; scholar verified as a living person (not an AI alias or synthetic persona). | [ ] | Document Type / State: ____________ |
| **1.2 Academic / Traditional Lineage** | Degree certificate (PhD / Acharya / Vidwan) or Matha Patrika / Sampradaya Diksha certificate verified. | [ ] | Issuing Authority: ____________ |
| **1.3 Institutional Record** | Faculty page, departmental listing, or university registry checked. | [ ] | Directory URL / Reference: ____________ |
| **1.4 Direct Contact Confirmation** | Verification via official institutional email domain (or verified telephone interview for traditional Acharyas). | [ ] | Verification Date: ____________ |
| **1.5 Privacy Masking** | Contact details moved to private administrative vault; public profile sanitized. | [ ] | Masked in `ReviewerProfilePublicRead`. |

---

## 2. Discipline Competency Authorization Matrix

Before granting role permissions, verify specific criteria for the applicant's requested role:

### A. Vedic Recension Specialist (`VEDIC_RECENSION`)
- [ ] Certified oral recitation fluency with accurate Vedic Swaras (Udatta, Anudatta, Svarita).
- [ ] Verified Shakha recension awareness (Rigveda Shakala, Yajurveda Madhyandina / Taittiriya, etc.).
- [ ] Familiarity with classical Samhita bhashyas (Sayana, Bhatta Bhaskara).
- *Restriction*: **Does NOT grant authority to approve classical vernacular or regional translations.**

### B. Sanskrit Grammar Specialist (`SANSKRIT_GRAMMAR`)
- [ ] Mastery of Paninian Ashtadhyayi, Kashika, and Siddhanta Kaumudi.
- [ ] Ability to parse complex Sandhi, Subanta/Tinganta forms, and Samasa compounds.
- [ ] Verified peer-reviewed publications or traditional Vyakarana title.
- *Restriction*: **Does NOT grant authority to approve Awadhi metrics or regional language syntax.**

### C. Awadhi Specialist (`AWADHI_SPECIALIST`)
- [ ] Demonstrated expertise in early modern vernacular Awadhi morphology and metrics.
- [ ] Familiarity with Tulsidas manuscript traditions and regional phonetic variations.
- [ ] Capability to scan 16-matra Chaupai and 13+11-matra Doha.
- *Restriction*: **Does NOT grant authority to certify Vedic recension accents.**

### D. Regional Translators (`*_TRANSLATOR`)
- [ ] Native-level mother-tongue fluency in the target language (Telugu, Tamil, Kannada, Malayalam, Hindi, Marathi, Bengali, Gujarati, Odia).
- [ ] Proven track record in literary or philosophical translation from Sanskrit.
- [ ] Deep comprehension of traditional devotional terminology.
- *Restriction*: **Authorized strictly for their specific language code (e.g. `te`, `ta`, etc.).**

---

## 3. Administrative Sign-Off Procedure

1. Admin creates verification dossier and computes document SHA-256 hash.
2. Admin executes `ReviewerOnboardingService.verify_credentials()`:
   - Sets `is_human_verified = True`.
   - Sets `account_category = 'REAL_HUMAN_SCHOLAR'`.
   - Records `verification_doc_hash` and `verification_authority`.
3. Verification logged to immutable `auth_audit_logs` table.
4. Editorial Board Director counter-signs verification ledger.
