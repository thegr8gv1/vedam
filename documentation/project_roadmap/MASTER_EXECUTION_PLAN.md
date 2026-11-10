# Vedam — Master Execution Plan & Feature Roadmap

**Status:** Living Canonical Roadmap Document  
**Repository:** `C:\Vedam`  
**Current Phase:** Phase 22D (DivyaDishi: Offline Magnetic Declination, True-Heading Correction & Approximate Sacred Alignment - COMPLETED)  
**Target Milestone:** DivyaDishi Sacred Orientation & Live Directional Navigation

---

## 1. Roadmap Architecture & Execution Trajectory

The Vedam platform unites authentic Vedic scripture preservation, multilingual scholarly governance, and deeply immersive daily devotional practice.

### Phase Trajectory Summary:
- **Phase 1 – Phase 11F:** Core repository architecture, multilingual database, 22-language translation governance engine, scholarly workbench, API gateway, and strict Section 8 human-review barriers.
- **Phase 12A – Phase 20E:** Audio vault ingestion, device notification reminders, offline audio streaming, and verified multiplatform mobile runtime.
- **Phase 21A:** Daily Japa Practice Experience (Mantra selection, traditional repetition targets 11/21/54/108/1008, manual & audio bead counting, resumable progress).
- **Phase 21B:** Guided Sadhana Practice Flow (multi-step morning/evening routine integrating Japa, Dhyana, Prarthana, and Sankalpa).
- **Phase 21C:** Structured Step-by-Step Puja Guides (Shodashopachara 16-upachara worship flows, source attribution, offline guides).
- **Phase 21D:** Vrat, Upavasa & Religious Observance Tracking (Ekadashi, Pradosham, Sankashti, fasting guidelines, sankalpa tracking).
- **Phase 21E:** Scripture Learning, Verse-by-Verse Study & Content Trust (Devanagari, IAST transliteration, word-by-word padartha, authentic audio pronunciation).
- **Phase 21F:** Devotional Audio Library & Practice Integration (Offline bundled library, audio controls, background playback).
- **Phase 21G:** Audio Integrity, Cross-Feature Validation & Product Roadmap Readiness (Audio vault reconciliation, tokenized anti-double-counting completion integrity, DivyaDishi roadmap formulation).
- **Phase 21H:** Phase 21G Regression Evidence Audit & DivyaDishi Temple Directory Planning (Test suite regression audit, ear-approved vs bundled track provenance audit, provisional 20-temple seed dataset integration).
- **Phase 21I:** Vedic Sankalpa Generator, Recitation Guide & DivyaDishi Roadmap Refinement (Daily & situational Sankalpa builder integrating live Panchangam, devotee lineage, Devanagari/IAST recitation, and DivyaDishi origin/reference accuracy guidelines).
- **Phase 21J:** Sankalpa Correctness, Transparency & Regression Hardening (Audited Sanskrit grammar, Gotra defaulting, audio-sankalpa synergy).
- **Phase 21K:** Sankalpa Default Safety, Privacy Terminology & Backend Test Debt (Refined Gotra lineage options, zero-cloud privacy transparency, backend test stabilization).
- **Phase 21L:** Daily Devotional Flow Orchestrator & Sequence Hub (Nitya Sadhana Dashboard, multi-practice sequencing, on-device journal tracking).
- **Phase 21L.1:** Nitya Sadhana Closure Audit & Completion Hardening (Verified completion locks, DST-safe date math, strict Panchangam recommendation provenance).
- **Phase 22A (Completed):** DivyaDishi Foundation: Temple Directory, Coordinate Integrity & Sacred Direction Architecture (20-temple provisional directory with explicit unverified status, pure geodetic bearing calculation engine, approximate city origin selection, browsing UI, and zero sensor dependencies).
- **Phase 22B (Completed):** DivyaDishi: Temple Coordinate Verification, Origin Provenance & Direction Terminology Audit (ASI/endowment provenance audit, compound center reclassification, 13 canonical origins with ±15 km uncertainty disclosures, scriptural Dikpala terminology alignment).
- **Phase 22C (Completed):** DivyaDishi: Opt-In Live Compass, Heading Quality & Sensor Lifecycle (Foreground-only, opt-in sensor activation, native Android rotation vector with accelerometer+magnetometer fallback, Magnetic vs True North separation, serene 8-cardinal dial).
- **Phase 22D (Completed):** DivyaDishi: Offline Magnetic Declination, True-Heading Correction & Approximate Sacred Alignment (Pure Dart NOAA WMM-2025/2020 spherical harmonic engine, True Heading normalization, shortest signed turn angle guidance, provisional coordinate safeguard with explicit user opt-in and dual uncertainty disclosures).
- **Phase 23 (Upcoming):** Pre-Beta Hardening, UI Polish & Build Packaging (Consolidates essential compass visual polish without blocking; versioned installable beta artifacts).
- **Phase 24:** Core Devotional Text Scholar Review & Certification (Human Acceptance Track A — Real Sanskrit scholars certify core launch texts in database).
- **Phase 25:** Devotee Usability & Accessibility Testing (Human Acceptance Track B — Everyday devotees usability evaluation).
- **Phase 26:** Physical Multi-Device Technical Beta & Field Testing (Human Acceptance Track C — Real Android hardware and browser matrix).
- **Phase 27:** Beta Defect Triage, Remediation & Regression Closure (Human Acceptance Track D — 0 P0/P1 defects; concludes human testing).
- **Phase 28:** Production Release, Infrastructure & Launch Approval (Concludes Version 1.0 Development).

---

## 2. DivyaDishi (Divine Direction) Architecture

### Status: `CORE ARCHITECTURE COMPLETED (PHASES 22A–22D IMPLEMENTED)`

> [!IMPORTANT]
> **Planning & Architectural Specification Only**: No magnetometer, GPS, sensor, location permission, bearing calculation, or temple rendering code is implemented during Phase 21H. Implementation will commence in an upcoming dedicated phase after sensor calibration research and battery-efficiency profiling are completed.

---

### Section A: Smart Temple Direction & Alignment
- **Concept:** Devotees worldwide seek to orient themselves toward sacred kshetras (temple sanctums) during daily prayer, Japa, and Sandhyavandanam. DivyaDishi provides real-time celestial and geographic bearing toward consecrated deities and sanctums.
- **Geographic Calculations:**
  - Great-circle forward azimuth calculation using the Haversine / spherical law of cosines formula:
    $$\theta = \text{atan2}(\sin(\Delta\lambda)\cos(\phi_2), \cos(\phi_1)\sin(\phi_2) - \sin(\phi_1)\cos(\phi_2)\cos(\Delta\lambda))$$
  - Real-time bearing compensation using device magnetometer and accelerometer sensor fusion.
  - Smooth low-pass filtering and magnetic declination correction based on World Magnetic Model (WMM) epochs to ensure jitter-free needle alignment with true sanctum direction.
- **Visual Sanctum Alignment:**
  - Sacred Mandala compass rose with customizable deity icons.
  - Dynamic visual haptic feedback when the devotee's physical orientation aligns within $\pm 3^\circ$ of the sacred sanctum (*Darshan Abhimukha*).

---

### Section B: Indian Temple Directory & Sacred Geography
- **Canonical Coverage Target:** A verified offline directory of major sacred pilgrimage centers (*Maha Kshetras*):
  - **12 Jyotirlingas:** Somnath, Mallikarjuna, Mahakaleshwar, Omkareshwar, Kedarnath, Bhimashankar, Kashi Vishwanath, Trimbakeshwar, Baidyanath, Nageshwar, Ramanathaswamy (Rameswaram), Grishneshwar.
  - **108 Divya Desams:** Srirangam, Tirumala Venkateswara, Kanchipuram Varadharaja, Badrinath, Dwarka, Ahobilam, Muktinath, and pan-Indian kshetras.
  - **51 Shakti Peethas:** Kamakhya, Kalighat, Vaishno Devi, Chamundeshwari, Meenakshi Amman, Kanchi Kamakshi, and related pithas.
  - **Pancha Bhoota Sthalas:** Chidambaram (Akasha), Kalahasti (Vayu), Tiruvannamalai (Agni), Tiruvanaikaval (Jala), Kanchipuram (Prithvi).
- **Metadata Attributes:**
  - Precise geographic latitude and longitude coordinates of the Moola Virat (sanctum sanctorum).
  - Presiding Deity (*Moola Nayaka / Nayaki*), Sthala Vriksha, Pushkarini (holy water body), and architectural orientation (East-facing vs West-facing sanctums).
  - Authentic scriptural Sthala Purana citations and historical lineage.

---

### Section C: Temple-Specific Devotional Experience
- **Daily Darshan & Aarti Rhythm:**
  - Temple time zone synchronized daily routine (Suprabhatam, Viswaroopa Darshan, Madhyahna Pooja, Sayarakshai, Ekantha Seva).
- **Associated Liturgical Audio & Stotrams:**
  - Linking temples to their authentic traditional compositions:
    - Tirumala $\rightarrow$ *Venkateswara Suprabhatam*, *Govinda Namavali*.
    - Kashi Vishwanath $\rightarrow$ *Kashi Vishwanathashtakam*, *Shiva Tandava Stotram*.
    - Madurai Meenakshi $\rightarrow$ *Meenakshi Pancharatnam*.
    - Rameswaram $\rightarrow$ *Ramanatha Ashtakam*.
- **Live / Archival Audio Chants:**
  - Structured step-by-step mental pilgrimage (*Manasa Teertha Yatra*) allowing devotees unable to travel physically to perform sacred orientation and mental circumambulation (*Pradakshina*).

---

### Section D: Personalized Worship & Sankalpa Integration
- **Ishta Devata & Kula Devata Selection:**
  - Devotees configure their family deity or personal spiritual focus, setting default alignment on app launch.
- **Sankalpa Spatial Context:**
  - Integration with the Vedam Sankalpa generator: automatically deriving Desa (region), Kshetra (nearest sacred river/temple), and orientation for Vedic sankalpa recitation.
- **Special Tithi & Festival Synchrony:**
  - Dynamic prompts when a temple's Brahmotsavam, Kalyanotsavam, or annual Maha Shivaratri / Vaikuntha Ekadashi occurs.

---

### Section E: Technical Research Before Implementation
Before writing production mobile code, the following architectural prerequisites must be validated:
1. **Sensor Availability & Permissions:**
   - Graceful fallback for devices lacking hardware magnetometers (accelerometer/gyroscope only, or manual compass card).
   - Strict privacy-preserving location access: location used solely for on-device bearing calculation; zero GPS coordinates transmitted over network.
   - Offline manual city/coordinate selection for privacy-conscious devotees or offline usage.
2. **Sensor Fusion & Battery Conservation:**
   - Throttle sensor listener sample rate to normal UI refresh rates (15–30 Hz) with auto-pause when screen dims or app enters background.
   - Low-pass Kalman filter or exponential moving average (EMA) to prevent compass oscillation near magnetic anomalies.
3. **True North vs Magnetic North:**
   - Calculation of magnetic declination angle using NOAA / WMM algorithm so orientation points accurately to geographic coordinates rather than magnetic drift.
4. **Coordinate Accuracy Verification:**
   - Rigorous independent audit of all GPS coordinates against official Devasthanam and Survey of India geo-benchmarks.

---

### Section F: Initial Featured Temple — Tirumala Tirupati Devasthanams (Lord Venkateswara)
The pilot implementation for DivyaDishi will focus on the sacred abode of Kaliyuga Varada, Lord Sri Venkateswara at Tirumala:
- **Sanctum Coordinates:** $13.6833^\circ\text{ N}, 79.3472^\circ\text{ E}$ (Ananda Nilayam Vimana, Tirumala).
- **Sanctum Orientation:** Moola Virat faces East (*Poorva Abhimukha*).
- **Liturgical Audio Suite:**
  - *Sri Venkateswara Suprabhatam* (Kausalya Supraja Rama...)
  - *Sri Venkateswara Stotram*
  - *Sri Venkateswara Prapatti*
  - *Sri Venkateswara Mangalasasanam*
  - *Govinda Namavali*

---

## 3. DivyaDishi — Initial 20-Temple Directory (Provisional Research Dataset)

### Status: `PLANNED — NOT YET IMPLEMENTED`

> [!CAUTION]
> **Provisional Seed Research Data Notice**: The coordinates listed below represent user-supplied research data for DivyaDishi roadmap formulation. They have **NOT** yet undergone formal geospatial or survey verification. All entries are explicitly classified with `coordinate_status: USER_SUPPLIED_UNVERIFIED`. They must not be described as official, authoritative, surveyed, or verified.

### Proposed Directory Data Schema:
```
id,temple_name,city,state_country,latitude,longitude,coordinate_status,source_notes
```

### Initial 20-Temple Research Dataset:
| ID | Temple Name | City / Region | State / Country | Latitude | Longitude | Coordinate Status | Source Notes |
|:---|:---|:---|:---|:---:|:---:|:---|:---|
| 1 | Tirumala Venkateswara Swamy Temple | Tirumala, Tirupati | Andhra Pradesh, India | 13.6833 | 79.3472 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 2 | Kashi Vishwanath Temple | Varanasi | Uttar Pradesh, India | 25.3109 | 83.0107 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 3 | Jagannath Temple | Puri | Odisha, India | 19.8047 | 85.8183 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 4 | Vaishno Devi Temple / Bhawan | Katra | Jammu & Kashmir, India | 33.0299 | 74.9482 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 5 | Badrinath Temple | Badrinath | Uttarakhand, India | 30.7433 | 79.4938 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 6 | Kedarnath Temple | Kedarnath | Uttarakhand, India | 30.7352 | 79.0669 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 7 | Somnath Temple | Prabhas Patan | Gujarat, India | 20.8880 | 70.4013 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 8 | Dwarkadhish Temple | Dwarka | Gujarat, India | 22.2376 | 68.9678 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 9 | Ramanathaswamy Temple | Rameswaram | Tamil Nadu, India | 9.2881 | 79.3174 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 10 | Mahakaleshwar Jyotirlinga | Ujjain | Madhya Pradesh, India | 23.1828 | 75.7683 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 11 | Meenakshi Amman Temple | Madurai | Tamil Nadu, India | 9.9195 | 78.1193 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 12 | Ram Janmabhoomi Temple | Ayodhya | Uttar Pradesh, India | 26.7939 | 82.1966 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 13 | Krishna Janmabhoomi Temple | Mathura | Uttar Pradesh, India | 27.5050 | 77.6737 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 14 | Ranganathaswamy Temple | Srirangam | Tamil Nadu, India | 10.8625 | 78.6897 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 15 | Brihadeeswarar Temple | Thanjavur | Tamil Nadu, India | 10.7831 | 79.1325 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 16 | Kamakhya Temple | Guwahati | Assam, India | 26.1664 | 91.7054 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 17 | Sree Padmanabhaswamy Temple | Thiruvananthapuram | Kerala, India | 8.4827 | 76.9436 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 18 | Pashupatinath Temple | Kathmandu | Nepal | 27.7105 | 85.3487 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 19 | Janaki Mandir | Janakpur | Nepal | 26.7304 | 85.9257 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |
| 20 | Muktinath Temple | Mustang, Gandaki Province | Nepal | 28.8167 | 83.8717 | USER_SUPPLIED_UNVERIFIED | Coordinates supplied by user for DivyaDishi planning; independent verification pending. |

---

### Coordinate Verification Plan (Future Implementation Gate)
Before any provisional coordinate is promoted to verified status (`VERIFIED_SANCTUM_COORDINATES` or `VERIFIED_ENTRANCE_COORDINATES`), a formal seven-step verification protocol must be executed:

1. **Reference Point Specification & Identity (Entrance vs Center vs Sanctum):**
   - Explicitly document whether the coordinate represents the primary accessible entrance/gateway (e.g., Rajagopuram, Mahadwara), the temple compound center, or the inner sanctum (*Garbhagriha* / Moola Virat).
   - Prefer an independently verified accessible designated entrance or public gateway when inner sanctum coordinates are unavailable or uncertain.
   - Tag each entry with its specific reference point classification: `ENTRANCE_GATEWAY`, `COMPOUND_CENTER`, or `INNER_SANCTUM`.
   - Preserve metadata for every coordinate: reference point classification, attribution source URL/authority, verification date, and confidence level (`PROVISIONAL`, `COMMUNITY_VERIFIED`, `AUTHORITY_VERIFIED`).
2. **Authority & Benchmark Cross-Referencing:** Cross-reference coordinates against official temple devasthanams, state tourism/archaeological departments, and Survey of India / national geospatial benchmark data.
3. **Settlement vs Sanctum Disambiguation:**
   - **Vaishno Devi Bhawan vs Katra Town:** The sacred Bhawan sits high in the Trikuta Mountains, approximately 13 km by foot from Katra base town ($32.99^\circ\text{ N}, 74.93^\circ\text{ E}$). The sanctum coordinate must point to the Holy Cave Bhawan ($33.0299^\circ\text{ N}, 74.9482^\circ\text{ E}$), not Katra town center.
   - **Badrinath & Kedarnath:** High-altitude Himalayan shrines must point to the actual temple structure, strictly distinguishing it from helipads, trek starting points, or surrounding settlement clusters.
   - **Muktinath Temple vs Mustang District:** Mustang is an extensive Himalayan region (3,570 km²). The coordinates must pin the sacred 108 water sprouts (*Muktidhara*) and temple compound at Ranipauwa/Chumig Gyatsa, not the general district center (Jomsom).
   - **Large Temple Complexes:** Massive enclosures like Srirangam (156 acres, 7 concentric prakaras) and Rameswaram produce divergent readings depending on whether an entrance Rajagopuram or the inner sanctum is pinned. Pinned coordinates must strictly identify the Garbhagriha or clearly label the reference point as the Rajagopuram entrance.
4. **Audit Trail Documentation:** Record the verification source URL, retrieval date, methodology, and verification sign-off for each entry.
5. **Precision & Ambiguity Logging:** Record coordinate precision down to 4 decimal places ($\sim 11\text{ m}$ resolution) and log any ambiguity.
6. **Origin Accuracy Limitations (GPS vs City/Region Selector):**
   - Explicitly document that device GPS and manually selected city/region represent different accuracy tiers.
   - When a manual city or regional centroid is used, it acts as an *approximate origin*; the bearing UI must clearly disclose this limitation (e.g., "Approximate direction based on city location").
   - Location permissions remain 100% optional; manual city selection is always available as a zero-permission alternative.
7. **Scholarly / Human Review Gate:** Require independent human reviewer sign-off before status promotion.

---

### Future Directory Expansion Strategy
The initial 20 temples serve as a seed research set. The production DivyaDishi directory will systematically expand to:
- **12 Jyotirlingas:** Complete coverage across all 12 holy shrines of Lord Shiva.
- **108 Divya Desams:** All 108 Vishnu kshetras sung by the Alvars (105 in India, 1 in Nepal - Muktinath, 2 celestial - Tirupparkadal & Paramapadam represented via Manasa Pooja).
- **51 Shakti Peethas:** Complete sacred geography of the Devi traditions across India, Nepal, Bangladesh, and Sri Lanka.
- **Pancha Bhoota Sthalas:** The 5 elemental manifestations of Lord Shiva in South India.
- **Regional & Heritage Pilgrimage Centers:** Major kshetras across all Indian states and neighboring Himalayan pilgrim routes.
- **Manasa Teertha Yatra:** Mental circumambulation for elderly devotees, hospital patients, or devotees unable to travel physically.

---

## 4. DivyaDishi Implementation Boundaries & Devotional Invariants

- **Geographic Orientation vs Spiritual Merit:** Directional alignment is purely a physical, geographic measurement to assist devotional focus. It is never presented as a metric of spiritual merit, purity, or religious correctness.
- **Optional & Privacy-Preserving Origin Hierarchy:** Location permissions must remain 100% optional. The app must function fully without location permissions by providing an offline city/region selector. GPS coordinates are processed exclusively on-device in volatile memory and never logged, transmitted, or retained.
- **Origin Accuracy Transparency:** The system explicitly distinguishes high-precision GPS origins from manual city/region selections. Manual city selection is treated as an approximate origin, and the UI will clearly indicate this limitation to the devotee.
- **Reference Point Rigor:** Pinned coordinates must specify their reference point type (`ENTRANCE_GATEWAY`, `COMPOUND_CENTER`, or `INNER_SANCTUM`). In public or disputed shrines, an accessible designated entrance is preferred over speculative sanctum pinning.
- **Zero Sensor / GPS Code in Phase 21I:** Phase 21I focuses on the core user-facing Vedic Sankalpa Generator and recitation guide. No sensor, compass, GPS, bearing calculation, or navigation UI code is introduced.
- **Zero Production Database Changes:** No alterations, migrations, or tables added to `database/vedam.db`.
- **Zero Translation Status Bypass:** All 3,070 translations strictly preserved in `DRAFT` status; 0 approved.
- **Section 8 Governance:** Human-review requirements remain strictly intact.

---

## 5. Phase 21L: Daily Devotional Flow Orchestrator & Sequence Hub (COMPLETED)

### Overview
Phase 21L establishes a calm, unified daily devotional practice experience (`NityaSadhanaDashboard`) connecting Vedam's existing Sankalpa Generator, Japa Practice, Guided Puja, Devotional Audio Library, Vrat Observance, and Scripture Study features into customizable morning, evening, and custom sequences.

### Key Capabilities Delivered
1. **Customizable Practice Sequences:**
   - Pre-seeded with authentic Morning Sadhana (*Prātaḥ Sankalpa*, *Daily Ganesha Puja*, *Gayatri Mahamantra Japa*, *Scripture Study*) and Evening Sadhana (*Evening Chanting*, *Shiva/Mrityunjaya Japa*, *Silent Gratitude*).
   - Full user step management: enable/disable, toggle optional vs required, reorder via `ReorderableListView`, custom duration estimates, add/remove steps.
2. **Resumable Step-by-Step Flow Runner:**
   - Active session persistence across app restarts and navigation interruptions.
   - Distinctive progress bar, current step details, direct integration launching dedicated tools (Sankalpa modal, Guided Puja screen, Japa screen, Audio player, Scripture learner, Vrat calendar).
   - Dedicated quiet reflection / contemplation timer right on screen.
   - Pause, save, skip optional steps, or conclude early.
   - Concludes with sacred closing peace invocation (*Om Shanti Shanti Shanti*).
3. **Strict Zero Autoplay Invariant:**
   - Audio tracks and Japa counting beads never autoplay upon entering practice steps; playback commands require explicit devotee interaction.
4. **Private On-Device Journal & Non-Inflationary Streak Tracking:**
   - 100% private, on-device SharedPreferences storage.
   - Pure timezone-safe streak calculator enforcing single-day multi-session non-inflation (multiple practices on one day count as exactly 1 practice day).
   - "Clear Journal History" with confirmation alert, preserving independent Japa/Puja/Vrat records.
5. **Conservative Contextual Panchangam Recommendations:**
   - Sourced from verified daily astronomical coordinates (Vara/Tithi/Observances).
   - Transparent provenance tagging (`Live Calculation` vs `Offline Approximation`).
   - Non-mandatory, gentle suggestions with 1-tap dismissal persisting for the remainder of the calendar day.
6. **Multiplatform Verification:**
   - 471 tests passing (100% pass rate) with 0 failures.
   - 0 `flutter analyze` issues.
   - Android Debug APK, Android Release APK (68.7 MB, well below 100MB limit, SHA-256 `251E4DBC3CD28A825A75B135B0215BC9D6A769A923E15C2E344B2FA8F2DCCF98`), Web Release build.
   - Production database completely untouched: SHA-256 `0B3500F36434217D0E35B1B3F0BB1E12C4598B406177D11979E1FC2A46B7AB97`, size 20,455,424 bytes, Alembic `e3a7b1c9f2d5`, exactly 3,070 `DRAFT` translations, 0 approved, 0 human reviewers.

---

## 6. Phase 22A: DivyaDishi Foundation — Temple Directory, Coordinate Integrity & Sacred Direction Architecture (COMPLETED)

Phase 22A establishes the foundational geodetic coordinate architecture and directory browsing experience for DivyaDishi:
- **Provisional Sacred Temple Dataset:** Initial 20 user-researched temples accurately modeled with geodetic coordinates, point types (`innerSanctum`, `compoundCenter`), and transparent `userSuppliedUnverified` verification status.
- **Pure Geodetic Calculation Engine:** Standalone, platform-independent great-circle forward azimuth formula with strict $[0.0, 360.0)^\circ$ normalization, antimeridian date-line crossing logic, Haversine geodesic distance, and sub-meter / identical coordinate detection.
- **Two-Tier Origin Architecture (Tier 1 Implemented):** Purely offline, zero-permission approximate city origin selection with 13 canonical spiritual cities (Varanasi, Delhi, Mumbai, Bengaluru, Chennai, Kolkata, Hyderabad, Tirupati, Ayodhya, Ujjain, Madurai, Haridwar, Kathmandu).
- **Presentation & Browsing UI:** Comprehensive Temple Directory Screen with live search (name, deity, city, state, country, alternate names), country filter chips, tradition filter dropdown, prominent provisional coordinate warnings, and detail modal with great-circle bearing previews.
- **Devotional Hub Integration:** Direct portal card embedded in `SadhanaScreen` for convenient devotee access.
- **Verification Gates:**
  - 534 tests passing across full Flutter test suite (42 Phase 22A-specific tests).
  - 0 `flutter analyze` issues.
  - Multiplatform verified: Web release build succeeded, Android release APK built at 68.9 MB (< 100 MB budget).
  - Zero production database mutations: SHA-256 `0B3500F36434217D0E35B1B3F0BB1E12C4598B406177D11979E1FC2A46B7AB97` strictly verified.

---

## 7. Phase 22B: DivyaDishi — Temple Coordinate Verification, Origin Provenance & Direction Terminology Audit (COMPLETED)

Phase 22B establishes rigorous evidence and cultural transparency for temple coordinates and sacred direction calculations before live compass implementation:
- **Individual 20-Temple Research Ledger:** Audited all 20 temples individually against official temple trusts, Archaeological Survey of India (ASI), state religious endowments boards, and government gazetteers. Reclassified all 20 records to `pendingVerification` with honest physical point type `compoundCenter` (due to absence of subterranean Garbhagriha cadastral geodetic benchmark certificates).
- **Coordinate Refinement & Historical Audit Trail:** Refined `TEMPLE-0012` (Ram Janmabhoomi) to the consecrated sanctum complex (`26.7956, 82.1943`) from the general town entrance coordinate (`26.7939, 82.1966`), preserving the original coordinate in `originalCoordinate` for full audit traceability.
- **Enhanced Data Models:** Extended `Temple` with `sourceUrl`, `corroborationSources`, `originalCoordinate`, `hasCoordinateChanged`, and robust `fromString` parsers for all 4 `CoordinatePointType` (`innerSanctum`, `compoundCenter`, `entranceGateway`, `unknown`) and 4 `CoordinateVerificationStatus` values.
- **Sacred Origin Provenance:** Documented administrative gazetteer sources and explicit $\pm 15$ km municipal centroid uncertainty radius across all 13 canonical cities in `SacredOrigin`.
- **Sanskrit Dishā & Ashta Dikpala Scriptural Traditions:** Audited 8 cardinal/ordinal compass points against *Brihat Samhita*, *Manasara*, *Mayamata*, and Vedic literature; incorporated textual variants (e.g. North: Puranic Kubera / Vedic Soma; Northeast: Ishana / Shiva-Rudra; Southwest: Nirrti / Rakshasa) and qualified bearing as a devotional orientation aid, not a mandatory ritual injunction.
- **UI Transparency Upgrades:** Enhanced `TempleDirectoryScreen` with `PENDING` tags and point type badges; expanded `TempleDetailModal` with full provenance ledger, source URLs, original vs refined coordinates, and explicit geodetic transparency disclaimers.
- **Verification Gates:**
  - 545 tests passing with 100% pass rate (53 DivyaDishi tests).
  - 0 `flutter analyze` issues across entire mobile workspace.
  - Multiplatform verified: Android Debug APK, Android Release APK (69.0 MB, well within 100 MB ceiling), Web Release build.
  - Production database `database/vedam.db` completely untouched: SHA-256 `0B3500F36434217D0E35B1B3F0BB1E12C4598B406177D11979E1FC2A46B7AB97` strictly verified.

---

## 8. Phase 22C: DivyaDishi — Opt-In Live Compass, Heading Quality & Sensor Lifecycle (COMPLETED)

Phase 22C establishes an optional, privacy-first, foreground-only live compass experience:
- **Foreground-Only Sensor Lifecycle:** Completely opt-in activation via explicit "Start Live Compass" and "Stop Compass" controls. Sensor streams automatically pause when backgrounded and tear down immediately on sheet disposal. Zero background tracking, zero GPS, zero network telemetry.
- **Native Android Platform Channel:** Implemented `EventChannel('org.vedam.vedam_app/compass')` in `MainActivity.kt` utilizing `Sensor.TYPE_ROTATION_VECTOR` with fallback to `Sensor.TYPE_ACCELEROMETER` + `Sensor.TYPE_MAGNETIC_FIELD`. Zero additional third-party dependencies added to `pubspec.yaml`.
- **True North vs Magnetic North Separation:** Strictly enforces the invariant that Magnetic headings are never directly compared to Great-Circle True North temple bearings without verified declination. When heading reference is `MAGNETIC`, turn-angle alignment is withheld with a clear educational notice explaining the difference.
- **Heading Domain Model:** Implemented `HeadingReading`, `HeadingReference`, `HeadingAccuracy`, and `HeadingSensorState` supporting strict $[0.0, 360.0)^\circ$ degree normalization, safe rejection of non-finite/null inputs, and staleness detection.
- **Devotional Compass Presentation:** Delivered `LiveCompassSheet` featuring a calm 8-cardinal dial visualizer, digital readout, reference and accuracy badges, magnetic interference guidance, target temple metadata (retaining `PENDING` coordinate badges), and devotional orientation disclaimers.
- **Verification Gates:**
  - 567 tests passing with 100% pass rate (22 Phase 22C tests; 75 DivyaDishi tests).
  - 0 `flutter analyze` issues.
  - Multiplatform verified: Android Debug APK, Android Release APK (69.1 MB, < 100 MB ceiling), Web Release build.
  - Production database `database/vedam.db` completely untouched: SHA-256 `0B3500F36434217D0E35B1B3F0BB1E12C4598B406177D11979E1FC2A46B7AB97` strictly verified.

---

## 9. Phase 22D: DivyaDishi — Offline Magnetic Declination, True-Heading Correction & Approximate Sacred Alignment (COMPLETED)

Phase 22D extends the DivyaDishi sacred compass architecture with an offline, mathematically rigorous magnetic declination correction engine:
- **Offline NOAA World Magnetic Model (WMM) Engine:** Pure Dart spherical harmonic geomagnetic field calculator supporting official NOAA/NCEI models (WMM-2025 epoch 2025.0–2030.0 and WMM-2020 epoch 2020.0–2025.0) with zero external dependencies added to `pubspec.yaml`.
- **Benchmark Mathematical Accuracy:** Validated against official NOAA/NCEI test vectors across global benchmarks (Seattle, Equator, High Latitudes, Greenwich) and pan-Indian sacred locations (Varanasi, New Delhi, Mumbai, Bengaluru, Chennai, Kolkata, Kathmandu) to $< 0.0001^\circ$.
- **True Heading Normalization:** Normalizes measured magnetic sensor headings to True Geographic North:
  $$\text{True Heading} = (\text{Magnetic Heading} + \text{Declination}) \pmod{360.0}$$
- **Signed Relative Sacred Alignment:** Shortest angular difference turn guidance $[-180.0^\circ, +180.0^\circ]$ with devotional alignment tolerance ($\pm 5.0^\circ$):
  $$\text{turnAngle} = (\text{targetBearingTrue} - \text{trueHeading} + 540.0) \pmod{360.0} - 180.0$$
- **Provisional Coordinate Safeguards:** Preserves devotional transparency by withholding direct alignment guidance by default for all 20 unverified / compound-center temples. Explicit user opt-in (`"Show Approximate Alignment Comparison"`) unlocks an **APPROXIMATE TEMPLE-COMPLEX ALIGNMENT** banner with dual uncertainty disclosures ($\pm 15$ km origin centroid and provisional temple compound centroid).
- **Zero-Permission, Privacy-First Architecture:** Zero GPS access, zero device location permissions, zero background sensor execution, zero network telemetry, and zero production database mutation.
- **Verification Gates:**
  - 589 tests passing with 100% pass rate (22 Phase 22D tests; 97 DivyaDishi tests).
  - 0 `flutter analyze` issues.
  - Multiplatform verified: Android Debug APK, Android Release APK (69.2 MB, < 100 MB budget), Web Release build.
  - Production database `database/vedam.db` completely untouched: SHA-256 `0B3500F36434217D0E35B1B3F0BB1E12C4598B406177D11979E1FC2A46B7AB97` strictly verified.

---

## 10. Reconciled Master Completion & Launch Roadmap (Phases 23–28)

Following the comprehensive audit in `VEDAM_MASTER_COMPLETION_AND_HUMAN_ACCEPTANCE_ROADMAP.md`, feature development is officially capped. The application now transitions into pre-beta hardening, human acceptance, and production release:

### Bounded Launch Sequence (Version 1.0):
1. **Phase 23 (Mandatory): Pre-Beta Hardening, UI Polish & Build Packaging**
   - Consolidates essential compass visual polish (deferring complex physics damping to v1.1).
   - Generates signed installable beta APK and Web staging builds.
2. **Phase 24 (Mandatory): Core Devotional Text Scholar Review & Certification (Track A)**
   - Onboards verified human scholars (`is_human_verified = True`) to review and approve 10 core launch texts in `database/vedam.db`.
3. **Phase 25 (Mandatory): Devotee Usability & Accessibility Testing (Track B)**
   - 25–30 real devotees across senior, householder, and youth cohorts; $\ge 90\%$ completion, SUS $\ge 85$.
4. **Phase 26 (Mandatory): Physical Multi-Device Technical Beta & Field Testing (Track C)**
   - 10+ real Android devices (flagship and budget) and browsers; sensor calibration, audio interruptions, offline durability.
5. **Phase 27 (Mandatory): Beta Defect Triage, Remediation & Regression Closure (Track D)**
   - Zero P0/P1 defects; 100% automated regression pass rate. **Concludes Human Testing.**
6. **Phase 28 (Mandatory): Production Release, Infrastructure & Launch Approval**
   - Hardened VPS deployment, cold-storage DB recovery runbook, Play Store publishing. **Concludes Version 1.0 Development.**

### Post-Launch Enhancements (Version 1.1+):
- **Phase 29:** On-Site Temple Sanctum Coordinate Ground-Truthing & Expanded 108-Temple Directory.
- **Phase 30:** Full Corpus 3,070-Translation Scholarly Certification Backlog.
- **Phase 31:** Advanced Audio Chant Pitch Analytics & Interactive Recitation Guide.
