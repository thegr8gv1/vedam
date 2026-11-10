# Vedam — Master Execution Plan & Feature Roadmap

**Status:** Living Canonical Roadmap Document  
**Repository:** `C:\Vedam`  
**Current Phase:** Phase 21G (Audio Integrity, Cross-Feature Validation & Product Roadmap Readiness)  
**Target Milestone:** Devotional Practice Expansion & Spatial Devotional Orientation

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
- **Phase 21G (Current):** Audio Integrity, Cross-Feature Validation & Product Roadmap Readiness (Audio vault reconciliation, tokenized anti-double-counting completion integrity, DivyaDishi roadmap formulation).

---

## 2. Planned Feature Specification: DivyaDishi — Divine Direction

### Status: `PLANNED — NOT YET IMPLEMENTED`

> [!IMPORTANT]
> **Planning & Architectural Specification Only**: No magnetometer, GPS, sensor, or temple rendering code is implemented during Phase 21G. Implementation will commence in an upcoming dedicated phase after sensor calibration research and battery-efficiency profiling are completed.

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
- **Canonical Coverage:** A verified offline directory of major sacred pilgrimage centers (*Maha Kshetras*):
  - **12 Jyotirlingas:** Somnath, Mallikarjuna, Mahakaleshwar, Omkareshwar, Kedarnath, Bhimashankar, Kashi Vishwanath, Trimbakeshwar, Baidyanath, Nageshwar, Ramanathaswamy (Rameswaram), Grishneshwar.
  - **108 Divya Desams:** Starting with Srirangam, Tirumala Venkateswara, Kanchipuram Varadharaja, Badrinath, Dwarka, and Ahobilam.
  - **51 Shakti Peethas:** Kamakhya, Kalighat, Vaishno Devi, Chamundeshwari, Meenakshi Amman, and Kanchi Kamakshi.
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
- **Devotional Interaction Flow:**
  1. Devotee opens DivyaDishi $\rightarrow$ Sacred Ananda Nilayam compass dial rotates to indicate direct line of sight to Tirumala.
  2. Compass indicates distance (in km and nautical miles) and relative bearing.
  3. Devotee physically turns to face Tirumala $\rightarrow$ screen glows golden with haptic confirmation.
  4. One-touch initiation of Sri Venkateswara Suprabhatam or 108 Govinda Namavali Japa session aligned toward the Lord.

---

## 3. Governance and Invariant Declarations

- **Zero Database Changes:** No alterations to `database/vedam.db`.
- **Zero Translation Status Bypass:** All 3,070 translations strictly preserved in DRAFT state.
- **Section 8 Human-Review Guardrails:** All human-review and reviewer-profile invariants preserved.
- **Mobile Bundle Ceiling:** Any future assets for DivyaDishi must respect the $<100\text{ MB}$ release APK ceiling.
