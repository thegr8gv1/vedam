# Multilingual Localization & Unicode Standards
**Version:** 1.0.0  
**Status:** Approved Standard  
**Scope:** 22 Eighth Schedule Indian Languages + Sanskrit + English  

---

## 1. Supported Languages & Language Tiers

The platform is designed to preserve, transliterate, and translate texts across 24 languages:

| Tier | Language | Script Family | Primary Role |
| :--- | :--- | :--- | :--- |
| **Source** | **Sanskrit (`sa`)** | Devanagari, Grantha, IAST | Primary Sacred Source Language |
| **Pilot 1** | **Telugu (`te`)** | Telugu script | Classical South Indian Recitations & Keerthanas |
| **Pilot 1** | **Hindi (`hi`)** | Devanagari | Broad National Devotional Reach |
| **Pilot 1** | **Tamil (`ta`)** | Tamil script / Grantha | Ancient Dravidian Devotional Hymns & Divya Prabandham |
| **Pilot 1** | **Kannada (`kn`)** | Kannada script | Dasa Sahitya & Karnataka Vedic Traditions |
| **Global** | **English (`en`)** | Latin / Roman IAST | Global Interface, Academic Commentary, Translations |
| **Scheduled** | **Bengali (`bn`)** | Eastern Nagari | Shakta Hymns & Gaudiya Vaishnava Literature |
| **Scheduled** | **Gujarati (`gu`)** | Gujarati script | Pushtimarg & Western Indian Bhakti Literature |
| **Scheduled** | **Malayalam (`ml`)** | Malayalam script | Kerala Tantra & Vedic Recitation Traditions |
| **Scheduled** | **Marathi (`mr`)** | Devanagari | Varkari Tradition, Abhangs & Granthas |
| **Scheduled** | **Odia (`or`)** | Odia script | Jagannath Traditions & Utkala Devotional Poetry |
| **Scheduled** | **Assamese (`as`)** | Eastern Nagari | Kamakhya & Vaishnavite Literature |
| **Scheduled** | **Punjabi (`pa`)** | Gurmukhi | Sanatan & regional hymns |
| **Scheduled** | **Kashmiri (`ks`)** | Sharada / Devanagari | Kashmir Shaivism & Shaivite Stutis |
| **Scheduled** | **Maithili (`mai`)** | Tirhuta / Devanagari | Mithila Sakta & Vaishnava traditions |
| **Scheduled** | **Konkani (`kok`)** | Devanagari / Roman | Coastal Devotional Liturgies |
| **Scheduled** | **Nepali (`ne`)** | Devanagari | Pashupatinath Traditions |
| **Scheduled** | **Sindhi (`sd`)** | Devanagari / Arabic | Jhulelal traditions |
| **Scheduled** | **Dogri (`doi`)** | Devanagari | Duggar regional traditions |
| **Scheduled** | **Manipuri (`mni`)** | Meitei Mayek / Bengali | Manipuri Vaishnavism |
| **Scheduled** | **Bodo (`brx`)** | Devanagari | Bathou traditions |
| **Scheduled** | **Santali (`sat`)** | Ol Chiki | Tribal spiritual heritage |
| **Scheduled** | **Urdu (`ur`)** | Nastaliq / Perso-Arabic | Cultural interface |

---

## 2. Critical Demarcation: Script Conversion vs. Translation

> [!IMPORTANT]
> **Strict Semantic Boundary:**
> Under no circumstances must script transliteration be confused with translation:
> - **Transliteration (Script Conversion):** A purely mechanical, lossless phonetic mapping of letters from one alphabet to another (e.g. Devanagari `शिव` $\rightarrow$ Telugu `శివ` $\rightarrow$ Tamil `ஶிவ` $\rightarrow$ Roman `Śiva`). The language remains Sanskrit.
> - **Literal Translation:** Word-for-word grammatical equivalent in the target language.
> - **Bhavartha (Interpretive Meaning):** Devotional, contextual meaning explaining the spiritual purport.
> - **Padachheda & Anvaya:** Dissection of Sanskrit compound words (*samasa*) and prose rearrangement of poetic meter.
> - **Tatparya:** Deep philosophical commentary citing classical Darshanas (Advaita, Vishishtadvaita, Dvaita).

---

## 3. Vedic Swaras & Unicode Combining Characters

Vedic texts (Rigveda, Yajurveda, Samaveda, Atharvaveda, and associated Suktas) contain sacred musical accents that indicate tone and cadence:

### Standard Unicode Encoding:
1. **Anudatta (Grave / Lower Tone):** Combining low line below the syllable — `U+0952` (`॒`).
   - Example: `सु॒गन्धिं॑` (Anudatta on `ग`).
2. **Svarita (Acute / Rising Tone):** Combining vertical line above the syllable — `U+0951` (`॑`).
   - Example: `त्र्य॑म्बकं` (Svarita on `त्र्य`).
3. **Udatta (High Tone):** Usually unmarked in Madhyandina / Shakala traditions, or marked with `U+0954`.
4. **Dirgha Svarita:** Double acute combining mark — `U+1CDA`.

### Normalization Guardrails:
When cleaning or normalizing text in `automation/cleaners/`:
- **Never strip Unicode combining characters** in ranges `U+0951` to `U+0954` or `U+1CD0` to `U+1CF6`.
- Stripping swaras alters the sacred phonetic vibration of Vedic mantras.
- For non-Vedic classical stotras (e.g., Ganesha Pancharatnam, Shiva Tandava), swaras are absent; poetic meter (*Chandas*) governs the rhythm.
