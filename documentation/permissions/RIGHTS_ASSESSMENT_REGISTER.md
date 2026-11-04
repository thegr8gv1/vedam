# Vedic Heritage Platform — Rights Assessment Register
**Version:** 3.0.0  
**Last Updated:** 2026-11-04  
**Scope:** Formal copyright evaluation ledger across legal jurisdictions (India, US, EU/UK, Global) and IP layers.

---

## 1. Compliance Matrix & Jurisdiction Rules

| Jurisdiction | Governing Statute | Public Domain Threshold | Platform Clearance Standard |
| :--- | :--- | :--- | :--- |
| **India (`IN`)** | Indian Copyright Act, 1957 (Sec. 22) | Life of author + 60 calendar years; anonymous/government works 60 yrs from publication. | Historical print editions published before 1964 with author deceased >60 yrs are verified public domain. |
| **United States (`US`)** | US Copyright Act, Title 17 | Works published before January 1, 1930 are in the public domain. | Editions published in or before 1929 are cleared for commercial distribution in US territory. |
| **European Union / UK (`EU`/`GB`)** | Directive 2006/116/EC / UK CDPA 1988 | Life of author/editor + 70 calendar years. | Requires author/editor death date prior to 1954 for complete clearance. |
| **Global Composite (`GLOBAL`)** | Multi-jurisdiction clearance | Must satisfy all applicable target territory thresholds simultaneously. | Requires both pre-1930 publication and author/editor deceased >70 years. |

---

## 2. Master Rights Assessment Ledger

| Content ID | Canonical Title | Composition Status | Specific Printed Edition | Publication Year | Publisher / Editor | Legal Reviewer | Jurisdictional Clearance | Publication Status | Notes |
| :--- | :--- | :---: | :--- | :---: | :--- | :--- | :---: | :---: | :--- |
| `TX-GAY-MAN-006` | Gayatri Vedic Mantra | Universal PD | Vaidika Samsodhana Mandala / Max Müller | 1890 | Oxford / Poona | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | Pre-1930 print; Vedic text is timeless. Approved for commercial app & export. |
| `TX-SHI-MAN-005` | Mahamrityunjaya Mantra | Universal PD | Vaidika Samsodhana Mandala | 1890 | VSM Poona | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | Rigvedic Rik. Universal public domain across all jurisdictions. |
| `TX-LAK-SUK-007` | Sri Suktam | Universal PD | J. Scheftelowitz Khilani Edition | 1906 | Breslau | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1906 print. Scheftelowitz deceased 1934 (>90 yrs). Cleared globally. |
| `TX-GAN-STO-001` | Ganesha Pancharatnam | Universal PD | Vani Vilas Press Complete Works | 1910 | Srirangam | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1910 print; Shankaracharya (c. 8th Century). Cleared globally. |
| `TX-SHI-STO-002` | Shiva Tandava Stotram | Universal PD | Nirnaya Sagar Press (Brihat Stotra) | 1912 | NSP Bombay | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1912 print; Ravana attribution. Cleared globally. |
| `TX-SUR-STO-003` | Aditya Hrudayam | Universal PD | Nirnaya Sagar Press (Valmiki Ramayana) | 1902 | NSP Bombay | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1902 print; Valmiki Itihasa. Cleared globally. |
| `TX-KRI-STO-004` | Madhurashtakam | Universal PD | Nirnaya Sagar Press | 1912 | NSP Bombay | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1912 print; Vallabhacharya (c. 1500). Cleared globally. |
| `TX-HAN-CHA-008` | Hanuman Chalisa | Universal PD | Munshi Nawal Kishore Press | 1874 | Nawal Kishore Lucknow | Platform Legal Counsel | `IN`, `US`, `EU`, `GLOBAL` | **GREEN** | 1874 print; Tulsidas (c. 1575). Classified as Awadhi (`awa`). Cleared globally. |

---

## 3. Human Legal Review Certification Protocol

Under the **Jurisdiction-Aware Rights Engine**, no record may transition from `AMBER` to `GREEN` without a permanent audit record signed by an authorized legal reviewer:

```python
# Mandatory legal sign-off requirement
assert rights_grant.legal_reviewer is not None, "Human legal sign-off mandatory for commercial release"
assert rights_grant.is_legally_approved is True, "Explicit legal sign-off flag required"
```

Any modern proprietary digital edition (such as commercial apps, modern copyright-claimed websites, or modern translations) remains marked **`RED`** or **`AMBER`** until explicit written licensing contracts are executed.
