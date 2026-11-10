# VEDAM CLOSED TESTING CONTENT REGISTER
## Complete Inventory & Verification Catalog for Scriptures, Mantras, Pujas & Sacred Metadata

**Document ID:** VEDAM-REG-CNT-001  
**Version:** 1.0.0-RC  
**Date:** 2026-11-10  
**Target Application:** Vedam (Mobile & Web)  
**Package ID:** `org.vedam.vedam_app`  
**Execution Lead:** Product Owner / Principal Reviewer  
**Status:** READY FOR OWNER TESTING  

---

## 1. Content Inventory Overview & Summary

This register contains the exhaustive inventory of all sacred texts, verses, mantras, audio associations, puja rituals, and temple metadata currently incorporated in the Vedam application and reconciled against `database/vedam.db` (SHA-256: `0B3500F36434217D...`) and `mobile_app/lib/data/fixtures/`.

### Summary Totals:
- **Canonical Scripture Compositions:** 20 Texts
- **Total Individual Verses:** 310 Verses
- **Vedic Compositions with Svaras:** 4 Texts (Gayatri, Mahamrityunjaya, Purusha Suktam, Durga Suktam)
- **Supported Transliteration Scripts:** Devanagari, IAST, Telugu, Tamil, Kannada, Malayalam
- **Draft Translation Languages:** 10 Regional Languages (English, Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Gujarati, Malayalam, Odia)
- **Master Devotional Mantras Catalog:** 455 Chants across 7 Deity Collections
- **Bundled Offline Master Audio Tracks:** 31 High-Resolution `.mp3` Files
- **Structured Shodashopachara Puja Guides:** 6 Daily Worship Liturgies
- **Pre-Configured Daily Sadhana Plans:** 3 Multi-Step Spiritual Routines
- **Sacred Temple Directory Records:** 20 Ancient Shrines with Geodetic Coordinates

---

## 2. Track A1: Canonical Scripture Compositions & Verses (20 Texts / 310 Verses)

### Legend:
- **Status:** `[NOT_TESTED]`, `[PASS]`, `[FAIL]`, `[BLOCKED]`

---

### [TXT-01] VEDA-TXT-00001: Ganesha Pancharatnam (गणेशपञ्चरत्नम्)
- **Composer:** Adi Shankaracharya | **Meter:** Vasantatilaka / Anushtubh | **Source:** Advaita Smartha Stotra Samgraha | **Verses:** 6

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT01-01** | V1 | Devanagari & Meter | 1. Open Library -> Stotras -> Ganesha Pancharatnam.<br>2. Select Verse 1.<br>3. Inspect Devanagari text and meter label. | Devanagari text renders `मुदाकरात्तमोदकं...` without font clipping. Meter displayed as `Vasantatilaka`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT01-02** | V1 | IAST Transliteration | 1. In Verse Reader, toggle IAST script.<br>2. Inspect diacritics. | Displays `mudākarāttamōdakaṁ sadā vimuktisādhakaṁ...` with macron over `ā` and `ō`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT01-03** | V1 | Indic Transliteration | 1. Open Script Selector.<br>2. Switch sequentially to Telugu, Tamil, Kannada, Malayalam. | Script renders accurately: Telugu (`ముదాకరాత్త...`), Tamil (`முதாகராத்த...`), Kannada (`ಮುದಾಕರಾತ್ತ...`), Malayalam (`മുദാകരാത്ത...`). No tofu boxes. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT01-04** | V1 | English & Hindi Meaning| 1. Scroll down to Translation card.<br>2. Inspect English draft.<br>3. Switch language to Hindi. | English draft begins: *"I bow to that Vinayaka who joyfully holds a sweet modaka..."*. Hindi renders faithful meaning. Clearly labeled `DRAFT`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT01-05** | V2-V5 | Core Stotra Flow | 1. Tap Next Verse sequentially for Verses 2, 3, 4, and 5.<br>2. Verify verse numbering and continuity. | V2 (`नतेतरातिभीकरं...`), V3 (`विहव्यराजदारकं...`), V4 (`अकिञ्चनार्तिमार्जनं...`), V5 (`नितान्तकान्तदन्तकान्ति...`) render seamlessly. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT01-06** | V6 | Phalasruti Verse | 1. Navigate to Verse 6.<br>2. Verify Phalasruti meter and meaning. | V6 (`समाहिताय चेतसा...`) renders in Anushtubh meter. States the spiritual benefit of daily dawn recitation. | — | `NOT_TESTED` | — |

---

### [TXT-02] VEDA-TXT-00002: Shiva Tandava Stotram (शिवताण्डवस्तोत्रम्)
- **Composer:** Lankadhipati Ravana | **Meter:** Panchachamara (16 syllables) | **Source:** Traditional Shaiva Purana Canon | **Verses:** 16

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT02-01** | V1 | Devanagari & Rhythm | 1. Open Shiva Tandava Stotram.<br>2. Read Verse 1. | Displays `जटाटवीगलज्जलप्रवाहपावितस्थले...`. All conjuncts (`ट्ठ`, `ङ्ग्`, `म्ब्`) render crisply without overlapping glyphs. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT02-02** | V1 | Word-by-Word Padartha | 1. In Verse Reader, tap on "Word Breakdown" tab. | Displays structured Padartha breakdown (e.g., `जटा-अटवी-गलत्-जल-प्रवाह-पावित-स्थले`) with grammatical parsing. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT02-03** | V2-V15| Tandava Stanzas | 1. Advance through verses 2 to 15.<br>2. Verify transliterations in Tamil and Telugu. | Renders famous lines: V2 (`जटाकटाहसंभ्रम...`), V3 (`धराधरेन्द्रनन्दिनी...`), V4 (`सहस्रलोचनप्रभृत्यशेष...`), V5 (`जटाभुजङ्गपिङ्गल...`). | — | `NOT_TESTED` | — |
| **TC-CNT-TXT02-04** | V16| Phalasruti Completion | 1. Navigate to final Verse 16. | Displays `इमं हि नित्यमेवमुक्तमुत्तमोत्तमं स्तवं...`. Confirms completeness of 16-verse hymn. | — | `NOT_TESTED` | — |

---

### [TXT-03] VEDA-TXT-00003: Aditya Hrudayam (आदित्यहृदयम्)
- **Composer:** Brahmarshi Agastya | **Meter:** Anushtubh | **Source:** Valmiki Ramayana, Yuddha Kanda, Sarga 105 | **Verses:** 31

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT03-01** | V1-V2 | Narrative Prologue | 1. Open Aditya Hrudayam.<br>2. Read verses 1 and 2. | V1: `ततो युद्धपरिश्रान्तं समरे चिन्तया स्थितम्...`. V2: `दैवतैश्च समागम्य...`. Agastya approaching Rama on the battlefield. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT03-02** | V3-V15| Upadesha & Solar Names | 1. Step through verses 3 to 15.<br>2. Toggle Kannada and Malayalam. | V3: `राम राम महाबाहो शृणु गुह्यं सनातनम्...`. Verses 4–15 describe the glory and cosmic identity of Surya. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT03-03** | V16-V25| Namavali Stanzas | 1. Step through verses 16 to 25. | V16 starts the famous salutations: `नमः पूर्वाय गिरये पश्चिमायाद्रये नमः...`. Correct formatting for repeated `नमः` invocations. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT03-04** | V26-V31| Epilogue & Victory | 1. Read verses 26 to 31. | V31: `अथ रुचिरपतिर्मुदा युक्तः...`. Rama dispels his fatigue, picks up his bow, and resolves to vanquish Ravana. | — | `NOT_TESTED` | — |

---

### [TXT-04] VEDA-TXT-00004: Madhurashtakam (मधुराष्टकम्)
- **Composer:** Mahaprabhu Vallabhacharya | **Meter:** Anushtubh / Totaka variation | **Source:** Pushtimarga Canon | **Verses:** 9

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT04-01** | V1-V8 | Sweetness Stanzas | 1. Open Madhurashtakam.<br>2. Step through verses 1 to 8. | V1: `अधरं मधुरं वदनं मधुरं नयनं मधुरं हसितं मधुरम्... मधुरधिपतेरखिलं मधुरम्`. Refrain `मधुरधिपतेरखिलं मधुरम्` terminates each stanza. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT04-02** | V9 | Phalasruti | 1. Navigate to Verse 9. | Verse 9 provides traditional benediction of contemplating Krishna's divine sweetness. | — | `NOT_TESTED` | — |

---

### [TXT-05] VEDA-TXT-00005: Mahamrityunjaya Vedic Mantra (महामृत्युञ्जयमन्त्रः)
- **Rishi:** Vasistha / Markandeya | **Meter:** Vedic Anushtubh / Trishtubh | **Source:** Rigveda 7.59.12; Shukla Yajurveda 3.60 | **Verses:** 1

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT05-01** | V1 | Vedic Svaras (Devanagari)| 1. Open Mahamrityunjaya Mantra.<br>2. Inspect accent marks above and below characters. | Displays `ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।\nउ॒र्वा॒रु॒कमि॑व॒ बन्ध॑नान्मृ॒त्योर्मु॑क्षीय॒ माऽमृता॑त् ॥`. Svaras render cleanly without vertical truncation. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT05-02** | V1 | IAST Accents | 1. Toggle IAST transliteration. | Displays: `oṁ trya॑mbakaṁ yajāmahe su॒gandhiṁ॑ puṣṭi॒vardha॑nam...` with acute and grave/horizontal accent diacritics. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT05-03** | V1 | Audio Linkage & Japa | 1. Tap Chanting / Japa button.<br>2. Audio plays `assets/audio/bundled/maha_mrityunjaya_mantra.mp3`. | Audio plays clear pronunciation matching Vedic svaras. Bead increments upon loop completion. | — | `NOT_TESTED` | — |

---

### [TXT-06] VEDA-TXT-00006: Gayatri Vedic Mantra (सावित्रीगायत्रीमन्त्रः)
- **Rishi:** Brahmarshi Vishvamitra | **Meter:** Nicrid Gayatri (24 syllables: 8-8-8) | **Source:** Rigveda 3.62.10; Shukla Yajurveda 36.3 | **Verses:** 1

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT06-01** | V1 | Vedic Svaras (Devanagari)| 1. Open Gayatri Mantra in Scripture Reader.<br>2. Inspect text display. | Displays: `ॐ भूर्भुव॒स्स॒वः॑ । तत्स॑वि॒तुर्वरे॑ण्यं॒ भर्गो॑ दे॒वस्य॑ धीमहि । धियो॒ यो नः॑ प्रचो॒दया॑त् ॥`. Svara marks aligned above and below respective aksharas. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT06-02** | V1 | Indic Scripts | 1. Switch script to Telugu, Tamil, Kannada, Malayalam. | Transliterations render faithfully with regional Indic characters. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT06-03** | V1 | Audio Playback & Japa | 1. Start audio playback.<br>2. Listen to full recording. | High-quality chanting of Gayatri Mantra plays via `assets/audio/bundled/gayatri_mantra.mp3`. | — | `NOT_TESTED` | — |

---

### [TXT-07] VEDA-TXT-00007: Sri Suktam (श्री सूक्तम्)
- **Rishi:** Ananda, Kardama, Chiklita | **Meter:** Anushtubh / Trishtubh | **Source:** Rigveda Khilani 5.87 | **Verses:** 16

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT07-01** | V1 | Vedic Svaras & Invocation| 1. Open Sri Suktam.<br>2. Read Verse 1. | Displays: `हिर॑ण्यवर्णां॒ हरि॑णीं सु॒वर्ण॑रज॒तस्र॑जाम् । च॒न्द्रां हि॒रण्म॑यीं ल॒क्ष्मीं जात॑वेदो म॒ आव॑ह ॥` with accurate Vedic Svara markings. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT07-02** | V2-V16| Complete Liturgy | 1. Step through verses 2 to 16.<br>2. Verify Padartha and translations. | All 16 verses display in proper traditional order, concluding with `महालक्ष्म्यै च विद्महे विष्णुपत्नी च धीमहि...`. | — | `NOT_TESTED` | — |

---

### [TXT-08] VEDA-TXT-00008: Hanuman Chalisa (हनुमान चालीसा)
- **Composer:** Goswami Tulsidas | **Meter:** Doha & Chaupai (Awadhi) | **Source:** Awadhi Bhakti Canon | **Verses:** 43

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT08-01** | V1-V2 | Opening Dohas | 1. Open Hanuman Chalisa.<br>2. Read verses 1 and 2. | V1: `श्रीगुरु चरन सरोज रज...`. V2: `बुद्धिहीन तनु जानिके...`. Both opening Dohas render in authentic Awadhi orthography. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT08-02** | V3-V42| 40 Chaupais | 1. Progress through verses 3 to 42.<br>2. Verify Awadhi conjuncts (`नहिं`, `कहुँ`, `रघुबर`). | All 40 Chaupais display in correct sequence, from `जय हनुमान ज्ञान गुन सागर` through `जो सत बार पाठ कर कोई`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT08-03** | V43 | Closing Doha | 1. Navigate to Verse 43. | Displays closing Doha: `पवनतनय संकट हरन, मंगल मूरति रूप । राम लखन सीता सहित, हृदय बसहु सुर भूप ॥`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT08-04** | All | Audio Synchronization | 1. Play bundled Hanuman Chalisa audio (`hanuman_chalisa.mp3`). | Full recitation plays smoothly in foreground and background notification. | — | `NOT_TESTED` | — |

---

### [TXT-09] VEDA-TXT-00009: Test Shiva Stuti 1
- **Status in DB:** DRAFT / Test Record | **Verses:** 1

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT09-01** | V1 | Test Fixture Isolation | 1. Verify display in test filter or developer mode. | Record is marked as a test fixture. Does not pollute main devotee devotional catalog. | — | `NOT_TESTED` | — |

---

### [TXT-10] VEDA-TXT-00010: Mahalakshmi Ashtakam (महालक्ष्म्यष्टकम्)
- **Source:** Padma Purana, Uttara Khanda | **Meter:** Anushtubh | **Verses:** 10

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT10-01** | V1 | Namastestu Mahamaye | 1. Open Mahalakshmi Ashtakam.<br>2. Inspect Verse 1. | Displays: `नमस्तेऽस्तु महामाये श्रीपीठे सुरपूजिते । शङ्खचक्रगदाहस्ते महालक्ष्मि नमोऽस्तु ते ॥`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT10-02** | V2-V8 | Eight Stanzas of Hymn | 1. Step through verses 2 to 8. | Verses 2–8 render the eight classical stanzas honoring Mahalakshmi. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT10-03** | V9-V10| Phalasruti | 1. Read verses 9 and 10. | Phalasruti stanzas detailing benefits of reciting once, twice, or thrice daily render cleanly. | — | `NOT_TESTED` | — |

---

### [TXT-11] VEDA-TXT-00011: Lingashtakam (लिङ्गाष्टकम्)
- **Source:** Linga Purana / Shaiva Agama | **Meter:** Anushtubh | **Verses:** 9

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT11-01** | V1 | Brahma Murari Surarchita | 1. Open Lingashtakam.<br>2. Inspect Verse 1. | Displays: `ब्रह्ममुरारिसुरार्चितलिङ्गं निर्मलभासितशोभितलिङ्गम् । जन्मजदुःखविनाशकलिङ्गं तत् प्रणमामि सदाशिवलिङ्गम् ॥`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT11-02** | V2-V9 | Complete Lingashtakam | 1. Step through verses 2 to 8.<br>2. Inspect verse 9 (Phalasruti). | All 8 stanzas followed by the Phalasruti verse (`लिङ्गाष्टकमिदं पुण्यं...`) render in sequence. | — | `NOT_TESTED` | — |

---

### [TXT-12] VEDA-TXT-00012: Sankata Nashana Ganesha Stotram (सङ्कटनाशनगणेशस्तोत्रम्)
- **Source:** Narada Purana | **Meter:** Anushtubh | **Verses:** 8

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT12-01** | V1-V5 | Twelve Names of Ganesha | 1. Open Sankata Nashana Ganesha Stotram.<br>2. Step through verses 1 to 5. | Displays opening salutation (`प्रणम्य शिरसा देवं...`) followed by the 12 sacred names: Vakratunda, Ekadanta, Krishna Pingaksha, Gajavaktra, Lambodara, Vikata, Vighnaraja, Dhumravarna, Bhalachandra, Vinayaka, Ganapati, Gajanana. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT12-02** | V6-V8 | Phalasruti & Obstacle Removal | 1. Read verses 6, 7, and 8. | Verses state the fruit of recitation: wisdom, wealth, sons, and ultimate liberation from all obstacles. | — | `NOT_TESTED` | — |

---

### [TXT-13] VEDA-TXT-00013: Venkateswara Suprabhatam (श्रीवेङ्कटेश्वरसुप्रभातम्)
- **Composer:** Prativadi Bhayankaram Anna | **Meter:** Vasantatilaka / Malini | **Source:** Tirumala Liturgy | **Verses:** 70

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT13-01** | V1 | Kausalya Supraja Rama | 1. Open Venkateswara Suprabhatam.<br>2. Read Verse 1. | Displays: `कौसल्या सुप्रजा राम पूर्वा सन्ध्या प्रवर्तते । उत्तिष्ठ नरशार्दूल कर्तव्यं दैवनिह्निकम् ॥`. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT13-02** | V1-V29| Suprabhatam Proper | 1. Step through verses 1 to 29. | All 29 morning awakening verses render in proper sequence. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT13-03** | V30-V40| Stotram Section | 1. Step through verses 30 to 40. | 11-verse Stotram section beginning with `कमलाकुचचूचुककुङ्कुमतो...` renders seamlessly. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT13-04** | V41-V56| Prapatti Section | 1. Step through verses 41 to 56. | 16-verse Prapatti (surrender) section beginning with `ईशानां जगतोऽस्य वेङ्कटपतेर्विष्णोः परां प्रेयसीम्...` renders cleanly. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT13-05** | V57-V70| Mangalashasanam | 1. Step through verses 57 to 70. | 14-verse Mangalashasanam concluding with `श्रियः कान्ताय कल्याणनिधये निधयेऽर्थिनाम्...` renders completely. | — | `NOT_TESTED` | — |

---

### [TXT-14] VEDA-TXT-00014: Purusha Suktam (पुरुषसूक्तम्)
- **Rishi:** Rishi Narayana | **Meter:** Anushtubh (1-15) / Trishtubh (16) | **Source:** Rigveda Samhita 10.90 | **Verses:** 16

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT14-01** | V1 | Thousand Heads Cosmic Vision | 1. Open Purusha Suktam.<br>2. Inspect Verse 1 with Svaras. | Displays: `सहस्र॑शीर्षा पुरु॑षः सहस्रा॒क्षः स॒हस्र॑पात् । स भूमिं॑ वि॒श्वतो॑ वृ॒त्वात्य॑तिष्ठद्दशाङ्गु॒लम् ॥` with exact Vedic accents. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT14-02** | V2-V15| Cosmic Sacrifice & Creation | 1. Step through verses 2 to 15.<br>2. Inspect Padartha in Telugu and Tamil. | Verses describe the cosmic Purusha, sacrifice, manifestation of Vedas, seasons, and beings. Svaras on every line. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT14-03** | V16| Yajnena Yajnam Ayajanta | 1. Navigate to final Verse 16.<br>2. Verify meter transition to Trishtubh. | Displays: `य॒ज्ञेन॑ य॒ज्ञम॑यजन्त दे॒वास्तानि॒ धर्मा॑णि प्रथ॒मान्या॑सन्...`. Confirms meter shift and auspicious culmination. | — | `NOT_TESTED` | — |

---

### [TXT-15] VEDA-TXT-00015: Durga Suktam (दुर्गासूक्तम्)
- **Source:** Taittiriya Aranyaka 10.1-2 (Mahanarayana Upanishad) | **Meter:** Trishtubh | **Verses:** 7

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT15-01** | V1 | Jatavedase Sunavama | 1. Open Durga Suktam.<br>2. Inspect Verse 1. | Displays: `जा॒तवे॑दसे सुनवाम॒ सोम॑मरातीय॒तो निद॑हाति॒ वेदः॑ । स नः॑ पर्ष॒दति॑ दु॒र्गाणि॒ विश्वा॑ ना॒वेव॒ सिन्धुं॑ दुरि॒तात्य॒ग्निः ॥` with high-resolution Svaras. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT15-02** | V2-V7 | Protection Across Fire | 1. Step through verses 2 to 7. | Complete 7-verse Taittiriya Suktam invocations to Agni-Durga for ferry-like safe crossing across perils. | — | `NOT_TESTED` | — |

---

### [TXT-16] VEDA-TXT-00016: Narayana Suktam (नारायणसूक्तम्)
- **Source:** Taittiriya Aranyaka 10.13 | **Meter:** Anushtubh / Trishtubh | **Verses:** 12

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT16-01** | V1 | Sahasra Shirsham Devam | 1. Open Narayana Suktam.<br>2. Inspect Verse 1. | Displays: `स॒ह॒स्र॒शी॑र्षं दे॒वं॒ वि॒श्वाक्षं॑ वि॒श्वश॑म्भुवम् । विश्वं॑ ना॒राय॑णं दे॒व॒म॒क्षरं॑ पparamam पदम् ॥` with accurate Svara markings. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT16-02** | V2-V12| Heart Lotus Contemplation | 1. Step through verses 2 to 12. | Verses 6–12 describe the Dahara Akasha (lotus of the heart) and the golden flame of Narayana. | — | `NOT_TESTED` | — |

---

### [TXT-17] VEDA-TXT-00017: Surya Ashtakam (सूर्याष्टकम्)
- **Source:** Samba Purana | **Meter:** Anushtubh | **Verses:** 10

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT17-01** | V1-V8 | Eight Solar Stanzas | 1. Open Surya Ashtakam.<br>2. Step through verses 1 to 8. | V1 starts: `आदिदेव नमस्तुभ्यं प्रसीद मम भास्कर...`. All 8 stanzas invoke Surya's healing and illuminating rays. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT17-02** | V9-V10| Phalasruti Benediction | 1. Read verses 9 and 10. | Phalasruti verses guaranteeing relief from poverty, illness, and ignorance. | — | `NOT_TESTED` | — |

---

### [TXT-18] VEDA-TXT-00018: Kanakadhara Stotram (कनकधारास्तोत्रम्)
- **Composer:** Adi Shankaracharya | **Meter:** Vasantatilaka / Malini | **Source:** Advaita Stotra Samgraha | **Verses:** 21

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT18-01** | V1 | Angam Hareh Pulaka | 1. Open Kanakadhara Stotram.<br>2. Read Verse 1. | Displays: `अङ्गं हरेः पुलकभूषणमाश्रयन्ती भृङ्गाङ्गनेव मुकुलाभरणं तमालम्...`. Intricate Sanskrit compounds render cleanly. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT18-02** | V2-V21| Golden Shower of Grace | 1. Step through verses 2 to 21. | Full 21-verse hymn commemorating the golden amla offering and Lakshmi's deluge of grace. | — | `NOT_TESTED` | — |

---

### [TXT-19] VEDA-TXT-00019: Mahishasura Mardini Stotram (महिषासुरमर्दिनिस्तोत्रम्)
- **Meter:** Totaka / Shardulavikridita variation | **Source:** Shakta Canon | **Verses:** 21

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT19-01** | V1 | Ayi Giri Nandini | 1. Open Mahishasura Mardini Stotram.<br>2. Inspect Verse 1. | Displays: `अयि गिरिनन्दिनि नन्दितमेदिनि विश्वविनोदिनि नन्दसुते गिरिवरविन्ध्यशिरोऽधिनिवासिनि विष्णुविलासिनि जिष्णुनुते...`. Refrain `जय जय हे महिषासुरमर्दिनि रम्यकपर्दिनि शैलसुते` terminates stanza. | — | `NOT_TESTED` | — |
| **TC-CNT-TXT19-02** | V2-V21| Rhythmic Majesty | 1. Step through verses 2 to 21.<br>2. Verify rapid-meter phonetic layout. | Dynamic, alliterative Sanskrit compounds format smoothly across diverse device widths without jarring wraps. | — | `NOT_TESTED` | — |

---

### [TXT-99] VEDA-TXT-00099: Aditya Hrudayam Sample
- **Status in DB:** DRAFT / Sample Record | **Verses:** 2

| Test ID | Verse | Content Category | Exact Test Steps | Expected Result | Actual Result | Status | Defect / Evidence |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| **TC-CNT-TXT99-01** | V1-V2 | Sample Record Isolation | 1. Verify record is isolated as a pilot test item. | Functions as a 2-verse sample without conflicting with canonical 31-verse `VEDA-TXT-00003`. | — | `NOT_TESTED` | — |

---

## 3. Track A2: Bundled Devotional Audio Library (31 Master Tracks)

Each bundled audio recording must be auditioned on an actual device for fidelity, continuous looping, background playback, and bead counting synchronization:

| Test ID | Mantra ID | Title | Deity | Bundled Asset Path | Expected Behavior | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-CNT-AUD-01** | `VEDA-MTR-0005` | Aditya | Surya | `assets/audio/bundled/aditya.mp3` | Clear audio, zero crackle, loops seamlessly. | — | `NOT_TESTED` |
| **TC-CNT-AUD-02** | `VEDA-MTR-0069` | Surya | Surya | `assets/audio/bundled/surya.mp3` | Chanting audio plays smoothly in player screen. | — | `NOT_TESTED` |
| **TC-CNT-AUD-03** | `VEDA-MTR-0105` | Gangadhara | Shiva | `assets/audio/bundled/gangadhara.mp3` | Plays and pauses instantaneously. | — | `NOT_TESTED` |
| **TC-CNT-AUD-04** | `VEDA-MTR-0135` | Sadashiva | Shiva | `assets/audio/bundled/sadashiva.mp3` | Resumes playback accurately after pause. | — | `NOT_TESTED` |
| **TC-CNT-AUD-05** | `VEDA-MTR-0167` | Achyuta | Venkateswara | `assets/audio/bundled/achyuta.mp3` | Loop counter increments upon each track end. | — | `NOT_TESTED` |
| **TC-CNT-AUD-06** | `VEDA-MTR-0222` | Seshadrinilaya | Venkateswara | `assets/audio/bundled/seshadrinilaya.mp3` | Notification shows track title and deity. | — | `NOT_TESTED` |
| **TC-CNT-AUD-07** | `VEDA-MTR-0231` | Srinivasa | Venkateswara | `assets/audio/bundled/srinivasa.mp3` | Background playback continues with screen off. | — | `NOT_TESTED` |
| **TC-CNT-AUD-08** | `VEDA-MTR-0268` | Lakshmi | Lakshmi Devi | `assets/audio/bundled/lakshmi.mp3` | High-fidelity recording without clipping. | — | `NOT_TESTED` |
| **TC-CNT-AUD-09** | `VEDA-MTR-0300` | Varalakshmi | Lakshmi Devi | `assets/audio/bundled/varalakshmi.mp3` | Seek bar responds smoothly to scrubbing. | — | `NOT_TESTED` |
| **TC-CNT-AUD-10** | `VEDA-MTR-0324` | Kalagni Bhairava | Bhairava | `assets/audio/bundled/kalagni_bhairava.mp3` | Speed adjustment (0.75x–1.5x) preserves pitch. | — | `NOT_TESTED` |
| **TC-CNT-AUD-11** | `VEDA-MTR-0338` | Martanda Bhairava | Bhairava | `assets/audio/bundled/martanda_bhairava.mp3` | Audio ducking on phone interruptions. | — | `NOT_TESTED` |
| **TC-CNT-AUD-12** | `VEDA-MTR-0342` | Neelakantha Bhairava| Bhairava | `assets/audio/bundled/neelakantha_bhairava.mp3` | Smooth transition when user taps next. | — | `NOT_TESTED` |
| **TC-CNT-AUD-13** | `VEDA-MTR-0373` | Maa Bhairavi | Maha Vidyas | `assets/audio/bundled/maa_bhairavi.mp3` | Clean acoustic quality on speaker & headphones. | — | `NOT_TESTED` |
| **TC-CNT-AUD-14** | `VEDA-MTR-0374` | Maa Bhuvaneshwari | Maha Vidyas | `assets/audio/bundled/maa_bhuvaneshwari.mp3` | Audio buffer loads instantaneously offline. | — | `NOT_TESTED` |
| **TC-CNT-AUD-15** | `VEDA-MTR-0376` | Maa Tara | Maha Vidyas | `assets/audio/bundled/maa_tara.mp3` | Japa Mala integration increments on completion. | — | `NOT_TESTED` |
| **TC-CNT-AUD-16** | `VEDA-MTR-0378` | Achyutam Keshavam | Krishna | `assets/audio/bundled/achyutam_keshavam.mp3` | Melodic devotional playback with zero artifacts.| — | `NOT_TESTED` |
| **TC-CNT-AUD-17** | `VEDA-MTR-0384` | Asato Ma Sad Gamaya| Vedic | `assets/audio/bundled/asato_ma_sad_gamaya_pavamana_mantra.mp3`| Upanishadic chant plays with peaceful tone. | — | `NOT_TESTED` |
| **TC-CNT-AUD-18** | `VEDA-MTR-0392` | Durga Gayatri | Durga | `assets/audio/bundled/durga_gayatri.mp3` | Svara alignment with Sanskrit pronunciation. | — | `NOT_TESTED` |
| **TC-CNT-AUD-19** | `VEDA-MTR-0399` | Gayatri Mantra | Gayatri | `assets/audio/bundled/gayatri_mantra.mp3` | Reverent chanting of Savitri Gayatri. | — | `NOT_TESTED` |
| **TC-CNT-AUD-20** | `VEDA-MTR-0401` | Hanuman Chalisa | Hanuman | `assets/audio/bundled/hanuman_chalisa.mp3` | Full 43-verse Awadhi recitation plays. | — | `NOT_TESTED` |
| **TC-CNT-AUD-21** | `VEDA-MTR-0403` | Hare Krishna | Krishna | `assets/audio/bundled/hare_krishna_maha_mantra.mp3` | Maha Mantra rhythm supports 108 Japa cycle. | — | `NOT_TESTED` |
| **TC-CNT-AUD-22** | `VEDA-MTR-0413` | Maha Mrityunjaya | Shiva | `assets/audio/bundled/maha_mrityunjaya_mantra.mp3`| Classical Vedic recitation with svaras. | — | `NOT_TESTED` |
| **TC-CNT-AUD-23** | `VEDA-MTR-0415` | Mahalakshmi Gayatri | Lakshmi | `assets/audio/bundled/mahalakshmi_gayatri.mp3`| Auspicious Gayatri chant with clear clarity. | — | `NOT_TESTED` |
| **TC-CNT-AUD-24** | `VEDA-MTR-0416` | Manojavam Maruta | Hanuman | `assets/audio/bundled/manojavam_mantra.mp3` | Traditional sloka recitation plays cleanly. | — | `NOT_TESTED` |
| **TC-CNT-AUD-25** | `VEDA-MTR-0429` | Om Namah Shivaya | Shiva | `assets/audio/bundled/om_namah_shivaya.mp3` | Panchakshari mantra loops smoothly for Japa. | — | `NOT_TESTED` |
| **TC-CNT-AUD-26** | `VEDA-MTR-0438` | Rama Taraka Mantra | Rama | `assets/audio/bundled/rama_taraka_mantra.mp3` | Chanting of "Shri Rama Jaya Rama" plays. | — | `NOT_TESTED` |
| **TC-CNT-AUD-27** | `VEDA-MTR-0445` | Shri Rama Jaya Rama | Rama | `assets/audio/bundled/shri_rama_jaya_rama_jaya_jaya_rama.mp3`| Taraka mantra with rhythmic cadence. | — | `NOT_TESTED` |
| **TC-CNT-AUD-28** | `VEDA-MTR-0446` | Shuklambaradharam | Ganesha | `assets/audio/bundled/shuklambaradharam.mp3` | Invocatory prayer plays prior to puja. | — | `NOT_TESTED` |
| **TC-CNT-AUD-29** | `VEDA-MTR-0448` | So Hum | Vedic | `assets/audio/bundled/so_hum.mp3` | Meditative breath sound chant. | — | `NOT_TESTED` |
| **TC-CNT-AUD-30** | `VEDA-MTR-0452` | Surya Gayatri | Surya | `assets/audio/bundled/surya_gayatri.mp3` | Solar Gayatri chant with uplifting meter. | — | `NOT_TESTED` |
| **TC-CNT-AUD-31** | `VEDA-MTR-0454` | Vakratunda Mahakaya | Ganesha | `assets/audio/bundled/vakratunda_mahakaya.mp3` | Classical prayer to remover of all hurdles. | — | `NOT_TESTED` |

---

## 4. Track A3: Structured Shodashopachara Puja Guides (6 Guides)

| Test ID | Guide ID | Title | Deity | Key Verification Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-CNT-PUJA-01** | `guide_ganesh_puja` | Daily Ganesha Pancha Upachara | Ganesha | Traversal of Dhyana, Avahana, Asana, Padya, Arghya, Achamaniya, Snana, Vastra, Yajnopavita, Gandha, Pushpa, Dhupa, Dipa, Naivedya, Tambula, Aarti. | All 16 upacharas display correct Sanskrit mantras and instructions. | — | `NOT_TESTED` |
| **TC-CNT-PUJA-02** | `guide_shiva_puja` | Daily Shiva Pancha Upachara | Shiva | Traversal of Bilva patra offering, Bhasma dharana, Rudra dhyana, and Linga abhisheka. | Accurate Shaiva liturgical steps and completion persistence. | — | `NOT_TESTED` |
| **TC-CNT-PUJA-03** | `guide_vishnu_puja` | Daily Vishnu Pancha Upachara | Vishnu | Traversal of Tulasi leaf offerings, Shankha-Chakra dhyana, and Panchamrita snana. | Authentic Vaishnava ritual sequence displayed. | — | `NOT_TESTED` |
| **TC-CNT-PUJA-04** | `guide_lakshmi_puja` | Daily Mahalakshmi Prarthana | Lakshmi | Traversal of lotus flower offerings, Kumkuma archana, and Sri Suktam recitation. | Complete Lakshmi puja flow with devotional reverence. | — | `NOT_TESTED` |
| **TC-CNT-PUJA-05** | `guide_morning_prayer`| Prātah Smaraṇam | Universal | Dawn contemplation prayer steps: waking up, viewing palms (Karaagre Vasate Lakshmi), Bhoomi Vandana. | Morning prayer guide leads user through auspicious start of day. | — | `NOT_TESTED` |
| **TC-CNT-PUJA-06** | `guide_evening_prayer`| Sandhyā Dīpa Prārthanā | Universal | Dusk lamp-lighting steps: lighting ghee lamp, Subham Karoti Kalyanam, silent meditation. | Evening lamp-lighting liturgy guides devotee calmly. | — | `NOT_TESTED` |

---

## 5. Track A4: Daily Sadhana Plans (3 Plans)

| Test ID | Plan ID | Title | Composition Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-CNT-SAD-01** | `sadhana_pratah_smriti` | Prātah Nitya Sadhana | Sankalpa $\to$ Dhyana $\to$ Gayatri Japa (108) $\to$ Aditya Hrudayam. | Multi-step sequence advances seamlessly; preserves completed status in journal. | — | `NOT_TESTED` |
| **TC-CNT-SAD-02** | `sadhana_sandhya_dhyana`| Sandhyā Dhyāna Sadhana | Dipa Puja $\to$ Shiva Dhyana $\to$ Mahamrityunjaya Japa (54) $\to$ Shanti Mantra. | Evening routine guides transition from active day to serene night practice. | — | `NOT_TESTED` |
| **TC-CNT-SAD-03** | `sadhana_ganesh_aradhana`| Ganesha Sankata Nashana | Ganesha Puja $\to$ Stotram recitation $\to$ Vakratunda Japa (108) $\to$ Aarti. | Dedicated practice flow for Tuesday / Sankashti observance. | — | `NOT_TESTED` |

---

## 6. Track A5: Sacred Temple Directory (DivyaDishi — 20 Temples)

| Test ID | Temple ID | Name & Compound Center | Geodetic Coordinates | Uncertainty | Direction Terminology | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-CNT-TMP-01** | `TEMPLE-0001` | Tirumala Venkateswara Swamy | $13.6833^\circ\text{ N}, 79.3472^\circ\text{ E}$ | $\pm 50\text{ m}$ (Compound) | Dakshina / Agneya | Great circle bearing calculated accurately. | `NOT_TESTED` |
| **TC-CNT-TMP-02** | `TEMPLE-0002` | Kashi Vishwanath Temple | $25.3109^\circ\text{ N}, 83.0107^\circ\text{ E}$ | $\pm 50\text{ m}$ (Compound) | Uttara / Ishanya | Temple card displays holy Ganga / Kashi context. | `NOT_TESTED` |
| **TC-CNT-TMP-03** | `TEMPLE-0003` | Jagannath Temple (Puri) | $19.8049^\circ\text{ N}, 85.8179^\circ\text{ E}$ | $\pm 50\text{ m}$ (Compound) | Purva / Agneya | Accurate great-circle initial bearing computed. | `NOT_TESTED` |
| **TC-CNT-TMP-04** | `TEMPLE-0004` | Vaishno Devi Temple / Bhawan | $33.0308^\circ\text{ N}, 74.9490^\circ\text{ E}$ | $\pm 100\text{ m}$ (Trikuta) | Uttara | Altitude and mountain shrine metadata displayed. | `NOT_TESTED` |
| **TC-CNT-TMP-05** | `TEMPLE-0005` | Badrinath Temple | $30.7447^\circ\text{ N}, 79.4912^\circ\text{ E}$ | $\pm 50\text{ m}$ (Garhwal) | Uttara | Alaknanda valley shrine details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-06** | `TEMPLE-0006` | Kedarnath Temple | $30.7352^\circ\text{ N}, 79.0669^\circ\text{ E}$ | $\pm 50\text{ m}$ (Jyotirlinga) | Uttara | Mandakini Jyotirlinga details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-07** | `TEMPLE-0007` | Somnath Temple | $20.8880^\circ\text{ N}, 70.4012^\circ\text{ E}$ | $\pm 50\text{ m}$ (Prabhas Patan)| Pratichi / Vayavya | First Jyotirlinga coast details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-08** | `TEMPLE-0008` | Dwarkadhish Temple | $22.2376^\circ\text{ N}, 68.9678^\circ\text{ E}$ | $\pm 50\text{ m}$ (Jagat Mandir)| Pratichi | Western Char Dham details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-09** | `TEMPLE-0009` | Ramanathaswamy Temple | $9.2881^\circ\text{ N}, 79.3174^\circ\text{ E}$ | $\pm 50\text{ m}$ (Rameswaram) | Dakshina | Southern Jyotirlinga corridors details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-10** | `TEMPLE-0010` | Mahakaleshwar Jyotirlinga | $23.1827^\circ\text{ N}, 75.7682^\circ\text{ E}$ | $\pm 50\text{ m}$ (Ujjain) | Madhya / Pratichi | Ancient prime meridian city details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-11** | `TEMPLE-0011` | Meenakshi Amman Temple | $9.9195^\circ\text{ N}, 78.1193^\circ\text{ E}$ | $\pm 50\text{ m}$ (Madurai) | Dakshina | Pandya sacred architecture details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-12** | `TEMPLE-0012` | Ram Janmabhoomi Temple | $26.7956^\circ\text{ N}, 82.1943^\circ\text{ E}$ | $\pm 50\text{ m}$ (Ayodhya) | Purva / Uttara | Sarayu sacred birthplace details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-13** | `TEMPLE-0013` | Krishna Janmabhoomi Temple | $27.5050^\circ\text{ N}, 77.6698^\circ\text{ E}$ | $\pm 50\text{ m}$ (Mathura) | Uttara / Pratichi | Braj mandala sacred center details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-14** | `TEMPLE-0014` | Ranganathaswamy Temple | $10.8624^\circ\text{ N}, 78.6901^\circ\text{ E}$ | $\pm 50\text{ m}$ (Srirangam) | Dakshina | Island Kaveri 7-enclosure details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-15** | `TEMPLE-0015` | Brihadeeswarar Temple | $10.7828^\circ\text{ N}, 79.1318^\circ\text{ E}$ | $\pm 50\text{ m}$ (Thanjavur) | Dakshina | Chola monumental Vimana details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-16** | `TEMPLE-0016` | Kamakhya Temple | $26.1664^\circ\text{ N}, 91.7056^\circ\text{ E}$ | $\pm 50\text{ m}$ (Nilachal) | Purva / Ishanya | Premier Shakti Peetha details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-17** | `TEMPLE-0017` | Sree Padmanabhaswamy Temple | $8.4828^\circ\text{ N}, 76.9436^\circ\text{ E}$ | $\pm 50\text{ m}$ (Trivandrum) | Dakshina | Anantha Shayana sanctum details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-18** | `TEMPLE-0018` | Pashupatinath Temple | $27.7104^\circ\text{ N}, 85.3487^\circ\text{ E}$ | $\pm 50\text{ m}$ (Kathmandu) | Uttara | Bagmati international shrine details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-19** | `TEMPLE-0019` | Janaki Mandir | $26.7303^\circ\text{ N}, 85.9261^\circ\text{ E}$ | $\pm 50\text{ m}$ (Janakpur) | Purva / Uttara | Mithila Sita heritage details verified. | `NOT_TESTED` |
| **TC-CNT-TMP-20** | `TEMPLE-0020` | Muktinath Temple | $28.8168^\circ\text{ N}, 83.8715^\circ\text{ E}$ | $\pm 100\text{ m}$ (Chumig Gyatsa)| Uttara | High Himalayan Shaligrama details verified. | `NOT_TESTED` |

---
*Vedam Content Register Certified by Quality Assurance Group*
