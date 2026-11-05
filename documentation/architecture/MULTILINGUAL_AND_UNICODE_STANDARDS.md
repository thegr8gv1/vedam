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

## 3. Vedic Swaras, Unicode Encoding & Recension Conventions

Vedic texts (Rigveda, Yajurveda, Samaveda, Atharvaveda, and associated Suktas) contain sacred liturgical accents that govern pitch, inflection, and recitation cadence.

### Standard Unicode Encoding & Philological Conventions:
1. **`U+0952` (`॒`) — DEVANAGARI STRESS SIGN ANUDATTA:**
   - Visual glyph: Combining horizontal line below the accented syllable.
   - Recension practice: Represents the lower tone (*anudatta*) across both Shakala Rigveda and Taittiriya Krishna Yajurveda traditions.
   - Example: In `सु॒गन्धिं॑`, the syllable `ग` carries the anudatta underline.
2. **`U+0951` (`॑`) — DEVANAGARI STRESS SIGN UDATTA [Unicode Name] / SVARITA [Vedic Usage]:**
   - Visual glyph: Combining vertical stroke above the accented syllable.
   - Unicode Standard Note: Historically designated `DEVANAGARI STRESS SIGN UDATTA` in Unicode 1.0, with the official Unicode annotation: *"= svarita; mostly used for svarita, with anudatta below (U+0952)"*.
   - Recension practice: In standard printed critical editions of the Shakala Rigveda (Max Müller, VSM) and Taittiriya Aranyaka / Samhita (Anandashrama), this stroke marks the *svarita* (rising/falling pitch). In these recensions, *udatta* (high pitch) is traditionally left unmarked between anudatta and svarita.
   - Example: In `त्र्य॑म्बकं`, the syllable `त्र्य` carries the vertical svarita tick above.
3. **`U+0954` (`॓`) — DEVANAGARI ACUTE ACCENT:**
   - Used where explicit marking of high pitch (*udatta*) is required in specialized grammatical treaties.
4. **`U+1CDA` (`᳚`) — VEDIC TONE DOUBLE SVARITA:**
   - Double vertical stroke above used in Taittiriya and Samaveda chant notations for extended / prolonged svarita (*dirgha svarita*).

> [!WARNING]
> **Recension Distinction:**
> The complete traditional chanting realization (*svara-uccāraṇa*) cannot be inferred solely from a Unicode character code point. Oral performance varies fundamentally between Shakala Rigvedic tradition, Taittiriya Krishna Yajurvedic tradition, and Madhyandina Shukla Yajurvedic tradition. Our digital library preserves source edition graphemes without reconstructing or altering historical typographical conventions.

### Normalization Guardrails:
When cleaning or normalizing text in `automation/cleaners/`:
- **Never strip Unicode combining characters** in ranges `U+0951` to `U+0954` or `U+1CD0` to `U+1CF6`.
- Stripping swaras alters the sacred phonetic vibration and textual authenticity of Vedic mantras.
- For non-Vedic classical stotras (e.g., Ganesha Pancharatnam, Shiva Tandava, Kanakadhara, Mahishasura Mardini), swara diacritics are absent; poetic meter (*Chandas*) governs the rhythm.
