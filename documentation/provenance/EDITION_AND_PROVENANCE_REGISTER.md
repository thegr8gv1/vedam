# Vedic Heritage Platform — Edition and Provenance Register
**Version:** 4.0.0  
**Last Updated:** 2026-11-04  
**Scope:** Exhaustive layer-by-layer provenance, critical edition mapping, and full-text verification register for all 8 pilot compositions.

---

## 1. The Seven-Layer IP and Provenance Framework

To prevent copyright confusion, unauthorized copying of modern editorial work, or loss of textual authenticity, every ingested composition must demarcate the seven distinct intellectual property and provenance layers:

```mermaid
flowchart TD
    L1["Layer 1: Underlying Traditional Composition<br>(Public Domain - Ancient/Timeless)"] --> L2["Layer 2: Original Historical Source<br>(Samhita / Aranyaka / Itihasa / Purana)"]
    L2 --> L3["Layer 3: Specific Historical Printed Critical Edition<br>(Physical Print >60 yrs post-mortem; Public Domain)"]
    L3 --> L4["Layer 4: Modern Digital Transcription<br>(Keystroke/OCR input - audit database rights)"]
    L4 --> L5["Layer 5: Phonetic Multi-Script Transliteration<br>(Platform-generated algorithmically via sanscript)"]
    L5 --> L6["Layer 6: Target Language Translation<br>(Original platform commission / human scholarly translation)"]
    L6 --> L7["Layer 7: Editorial Commentary & Liturgical Notes<br>(Original scholarly platform compilation)"]
```

---

## 2. Provenance Audit Matrix for Verified Pilot Compositions

| Content ID | Canonical Title | Primary Deity | Attributed Composer | Poetic Metre (Chandas) | Verified Verses | Primary Critical Printed Edition | Publication Year | Archive Reference | Legal Rights Status | Text Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`VEDA-TXT-00001`** | Ganesha Pancharatnam | Ganesha | Adi Shankaracharya (c. 788–820 CE) | Vasantatilaka / Anushtubh | **6** | *Complete Works of Sri Sankaracharya*, Vol. 11, Vani Vilas Press (Srirangam) | 1910 | `archive.org/details/brihatstotraratn00khem` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00002`** | Shiva Tandava Stotram | Shiva | Traditional attribution to Ravana | Panchachamara | **16** | *Brihat Stotra Ratnakara*, Nirnaya Sagar Press (Bombay) | 1912 | `archive.org/details/BrihatStotraRatnakaraNSP1912` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00003`** | Aditya Hrudayam | Surya | Maharishi Valmiki / Sage Agastya | Anushtubh (Epic 32-syllable) | **31** | *Valmiki Ramayana with Tilaka Commentary*, Nirnaya Sagar Press (Bombay) | 1902 | `archive.org/details/ValmikiRamayanaNirnayaSagar1902` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00004`** | Madhurashtakam | Krishna | Jagadguru Vallabhacharya (1479–1531 CE) | Totaka | **9** | *Brihat Stotra Ratnakara*, Nirnaya Sagar Press (Bombay) | 1912 | `archive.org/details/brihatstotraratn00khem` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00005`** | Mahamrityunjaya Vedic Mantra | Shiva | Rishi Maitravaruni Vasishtha / Markandeya | Trishtubh (4x11) | **1** | *Rigveda Samhita with Sayana Bhashya*, Vaidika Samsodhana Mandala (Poona) | 1933 | `archive.org/details/RigVedaSamhitaVSM` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00006`** | Gayatri Vedic Mantra | Savita / Surya | Brahmarshi Vishvamitra (Gathina) | Nicrid Gayatri (24 syllables) | **1** | *Rig-Veda-Sanhita*, F. Max Müller, Oxford University Press / VSM | 1890 | `archive.org/details/RigVedaWithSayanaBhashyaPoona` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00007`** | Sri Suktam | Devi / Lakshmi | Rishis Ananda, Chiklita, Kardama, Sri | Anushtubh & Trishtubh | **16** | *Die Apokryphen des Rgveda (Khilani)*, Dr. J. Scheftelowitz (Breslau) & VSM Poona (1946) | 1906 | `archive.org/details/RigVedaKhilaniScheftelowitz` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |
| **`VEDA-TXT-00008`** | Hanuman Chalisa | Hanuman | Goswami Tulsidas (c. 1532–1623 CE) | Awadhi Doha & Chaupai | **43** | *Shri Hanuman Chalisa Lithograph*, Munshi Nawal Kishore Press (Lucknow) | 1874 | `archive.org/details/HanumanChalisaNawalKishore1874` | `GREEN_CLEARED` | `VERIFIED_FULL_TEXT` |

---

## 3. Detailed Verification Dossiers for Pilot Compositions

Detailed philological reports for each composition are maintained under `documentation/quality/`:
- `documentation/quality/VERIFICATION_GANESHA_PANCHARATNAM.md`
- `documentation/quality/VERIFICATION_SHIVA_TANDAVA.md`
- `documentation/quality/VERIFICATION_ADITYA_HRUDAYAM.md`
- `documentation/quality/VERIFICATION_MADHURASHTAKAM.md`
- `documentation/quality/VERIFICATION_SRI_SUKTAM.md`
- `documentation/quality/VERIFICATION_HANUMAN_CHALISA.md`
