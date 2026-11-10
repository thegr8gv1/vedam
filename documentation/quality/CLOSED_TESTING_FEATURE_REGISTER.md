# VEDAM CLOSED TESTING FEATURE REGISTER
## Complete Inventory & Verification Catalog for Screens, Controls, Presets & Settings

**Document ID:** VEDAM-REG-FEAT-001  
**Version:** 1.0.0-RC  
**Date:** 2026-11-10  
**Target Application:** Vedam (Mobile & Web)  
**Package ID:** `org.vedam.vedam_app`  
**Execution Lead:** Product Owner / Principal Reviewer  
**Status:** READY FOR OWNER TESTING  

---

## 1. Feature Inventory Overview & Structure

This register catalogs every user-accessible screen, control, modal, slider, preset, toggle, and setting across the 12 core functional domains of Vedam.

### Functional Domains:
1. **Shell & Navigation:** 5 Primary Tabs, Sacred App Bar, Theme Switching
2. **Home Dashboard:** Welcome Header, Daily Routine, Panchangam Preview, Vrat Card
3. **Scripture Library:** Search, Filters, Detail, Verse Reader, Verse Learning, Bookmarks
4. **Chanting & Japa:** 7 Traditional Presets + Custom, Visual Mala, Taps, Volume Buttons, Haptics
5. **Devotional Audio:** 455 Chants Catalog, Player Screen, Scrubber, Loops, Speeds, Background Service
6. **Guided Puja:** 6 Shodashopachara Guides, Preparation Checklist, 16 Steps, Timers
7. **Daily Sadhana & Orchestrator:** Sequence Editor, Multi-Practice Execution, Journal
8. **Vedic Sankalpa Generator:** Gotra Picker, Shakha, Astrological Auto-Fill, Audio Guide
9. **Panchangam Astronomical Engine:** Tithi, Nakshatra, Rahu Kalam, 13 Cities, Offline Math
10. **Festivals & Vrat Tracking:** Festival Calendar, Vrat Observances, Reminders, Alarms
11. **DivyaDishi Sacred Direction:** 20 Temples, Geodesic Bearing, Compass Dial, WMM Declination
12. **Settings, Personalization & Offline:** Languages, Scripts, Theme, Storage Reset, Privacy

---

## 2. Granular Feature Test Catalog

### Legend:
- **Status:** `[NOT_TESTED]`, `[PASS]`, `[FAIL]`, `[BLOCKED]`

---

### Domain 1: Shell & Primary Navigation

| Test ID | Control / Screen | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-NAV-01** | Bottom Navigation Bar | Tap sequentially on: 1. Home, 2. Library, 3. Sadhana, 4. Favorites, 5. Settings. | Bottom navigation bar switches screens instantly without lag; active tab icon highlights in gold. | — | `NOT_TESTED` |
| **TC-FEAT-NAV-02** | Sacred App Bar | 1. Observe Sacred App Bar on top of screen.<br>2. Tap theme toggle or settings icon. | Displays golden temple motif, app title "Vedam", and clean action icons. | — | `NOT_TESTED` |
| **TC-FEAT-NAV-03** | Back Navigation & State | 1. Navigate from Home -> Library -> Scripture Detail -> Verse Reader.<br>2. Press Android system back button repeatedly. | Pops through navigation stack smoothly, returning to Home without state loss. | — | `NOT_TESTED` |

---

### Domain 2: Home Dashboard (`HomeScreen`)

| Test ID | Widget / Card | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-HOME-01** | Devotional Welcome Header | 1. Open app at morning, afternoon, and evening.<br>2. Observe greeting text. | Shows contextual traditional greetings: "Suprabhatam" (Morning), "Subha Madhyahnam" (Afternoon), "Subha Sandhya" (Evening). | — | `NOT_TESTED` |
| **TC-FEAT-HOME-02** | Daily Verse Card | 1. Tap on Daily Verse Card on Home screen. | Displays inspirational daily verse; tapping opens Verse Reader directly to that verse. | — | `NOT_TESTED` |
| **TC-FEAT-HOME-03** | Daily Routine Card | 1. Observe Daily Routine progress bar.<br>2. Tap "Start Routine". | Launches Morning / Evening Sadhana orchestrator flow. Progress bar updates upon step completion. | — | `NOT_TESTED` |
| **TC-FEAT-HOME-04** | Japa Quick Card | 1. Inspect Japa quick card.<br>2. Tap "Quick Chant". | Opens Japa Practice screen with the user's primary daily mantra pre-selected. | — | `NOT_TESTED` |
| **TC-FEAT-HOME-05** | Panchangam Preview Card | 1. Observe Tithi, Nakshatra, and Rahu Kalam snippet.<br>2. Tap card. | Displays today's astrological data; tapping opens full Panchangam Screen. | — | `NOT_TESTED` |
| **TC-FEAT-HOME-06** | Upcoming Vrat Card | 1. Observe upcoming fasting date.<br>2. Tap card. | Displays next sacred observance (e.g. Ekadashi / Pradosham) and days remaining. Tapping opens Vrat Calendar. | — | `NOT_TESTED` |

---

### Domain 3: Scripture Library & Reading Experience

| Test ID | Feature / Control | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-LIB-01** | Scripture Search Bar | 1. Open Library tab.<br>2. Enter "Shiva" in search bar.<br>3. Clear and enter "हनुमान". | Filters results instantaneously by English canonical title and Devanagari script. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-02** | Category Filter Pills | 1. Tap on "Stotra", "Suktam", "Mantra", "All Categories". | List filters dynamically, displaying only scriptures matching the selected category. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-03** | Deity Filter Pills | 1. Tap on "Ganesha", "Shiva", "Vishnu", "Devi", "Surya". | Displays only scriptures addressed to the selected deity. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-04** | Scripture Detail Screen | 1. Tap on "Purusha Suktam".<br>2. Inspect author, meter, verse count, and verse list. | Header displays Rishi Narayana, Anushtubh meter, 16 verses. Verse list shows first line previews. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-05** | Verse Reader Navigation | 1. In Verse Reader, tap "Next Verse" ($\to$) and "Previous Verse" ($\leftarrow$).<br>2. Swipe left and right. | Transitions smoothly between verses; verse counter updates (e.g. "Verse 3 of 16"). | — | `NOT_TESTED` |
| **TC-FEAT-LIB-06** | Script Selection Modal | 1. In Verse Reader, tap Script icon.<br>2. Select "Telugu", then "Tamil", then "Devanagari". | Text immediately transforms into chosen script with accurate Unicode character shaping. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-07** | Font Scaling Slider | 1. Open Reading Preferences.<br>2. Drag font scale slider from 0.8x to 2.0x. | Text dynamically resizes smoothly without overlapping lines or breaking container boundaries. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-08** | Transliteration Toggle | 1. Toggle "Show Transliteration" on/off. | Transliteration card collapses/expands smoothly. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-09** | Translation Toggle | 1. Toggle "Show Translation" on/off. | Translation card collapses/expands smoothly. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-10** | Word Breakdown (Padartha)| 1. Open a text with Padartha (e.g. Shiva Tandava).<br>2. Tap "Word Breakdown" tab. | Shows individual Sanskrit words, grammatical case/number/root, and English/Hindi meaning. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-11** | Bookmark Toggle | 1. Tap Bookmark icon on Verse 5.<br>2. Navigate to Favorites tab -> Bookmarks. | Verse appears in Bookmarks list; tapping it navigates directly back to Verse 5. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-12** | Verse Note Dialog | 1. Tap Note icon on verse.<br>2. Enter personal reflection text and save.<br>3. Revisit verse. | Note persists in local storage; note badge displays on verse card. | — | `NOT_TESTED` |
| **TC-FEAT-LIB-13** | Verse Learning Screen | 1. In Scripture Detail, tap "Study / Memorize".<br>2. Tap "Hide Sanskrit" and "Reveal on Tap". | Text conceals aksharas; tapping reveals them for interactive memorization practice. | — | `NOT_TESTED` |

---

### Domain 4: Chanting & Japa Practice (All 7 Presets + Custom)

| Test ID | Preset / Option | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-JAPA-01**| Preset 11 Repetitions | 1. Open Japa screen.<br>2. Select preset **11**.<br>3. Count 11 beads. | Target set to 11 (Ekadasha Japa). Reaching 11 triggers completion celebration dialog. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-02**| Preset 21 Repetitions | 1. Select preset **21**.<br>2. Count 21 beads. | Target set to 21 (Ekavimshati Japa). Completes successfully at bead 21. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-03**| Preset 27 Repetitions | 1. Select preset **27**.<br>2. Count 27 beads. | Target set to 27 (Quarter Mala / Nakshatra). Completes at bead 27. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-04**| Preset 54 Repetitions | 1. Select preset **54**.<br>2. Count 54 beads. | Target set to 54 (Ardha Mala). Progress ring fills exactly to 50% at 27, completes at 54. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-05**| Preset 108 Repetitions| 1. Select preset **108**.<br>2. Count 108 beads. | Target set to 108 (Purna Mala). Meru bead highlights; full mala completion recorded. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-06**| Preset 111 Repetitions| 1. Select preset **111**.<br>2. Count 111 beads. | Target set to 111 (Shubha Sankalpa). Completes at bead 111. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-07**| Preset 1008 Repetitions| 1. Select preset **1008**.<br>2. Verify target set. | Target set to 1008 (Sahasra Japa). Mala counter tracks 9 full rounds + 36 beads. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-08**| Custom Target: Valid | 1. Tap "Custom".<br>2. Enter "100" and submit. | Sets custom target to 100 repetitions without error. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-09**| Custom Target: Boundary| 1. Tap "Custom".<br>2. Enter "100000" (max bound). | Validates successfully and sets target to 100,000. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-10**| Custom Target: Rejection| 1. Enter "0", "-5", "10.5", "abc", "100001". | Each invalid entry displays clear error prompt; rejects invalid value. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-11**| Screen Tap Counting | 1. Tap anywhere inside the large circular bead target. | Each tap increments count by 1 with subtle ripple animation. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-12**| Volume Button Counting | 1. Enable Volume Key counting in settings.<br>2. Press Volume Up physical button. | Each press increments Japa counter by 1 without changing device media volume. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-13**| Haptic Feedback Toggle | 1. Enable/disable haptic toggle.<br>2. Tap counter. | Device vibrates subtly on each bead when enabled; remains silent when disabled. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-14**| Sound Bell Toggle | 1. Enable bell sound toggle.<br>2. Reach target. | Temple bell chime sounds upon mala completion. | — | `NOT_TESTED` |
| **TC-FEAT-JAPA-15**| Japa History Persistence| 1. Complete 108 Japa.<br>2. Tap "Log Practice".<br>3. Force close app and reopen.<br>4. Open Japa History modal. | Session record persists with timestamp, mantra name, 108 count, and duration. | — | `NOT_TESTED` |

---

### Domain 5: Devotional Audio Player & Mantras

| Test ID | Control / Feature | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-AUD-01** | Mantras Catalog Browsing| 1. Open Mantras screen.<br>2. Browse collections (Surya, Shiva, Venkateswara, Lakshmi, Bhairava, Maha Vidyas). | Displays 455 mantras categorized cleanly; bundled tracks marked with green badge. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-02** | Play / Pause / Resume | 1. Tap on Gayatri Mantra.<br>2. Tap Play, then Pause, then Resume. | Audio starts, pauses, and resumes instantaneously without stutter. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-03** | Scrubber / Seek Bar | 1. Drag audio seek bar to middle of track.<br>2. Release slider. | Playback jumps accurately to chosen timestamp. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-04** | Continuous Loop Mode | 1. Toggle Loop mode to "Repeat".<br>2. Let track play to the end. | Audio restarts at beginning seamlessly without gaps. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-05** | Playback Speed Selector| 1. Tap Speed button.<br>2. Select 0.75x, 1.25x, 1.5x. | Playback speed changes smoothly while preserving voice pitch. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-06** | Background Audio Playback| 1. Start audio playback.<br>2. Switch to another app or lock phone screen. | Audio continues playing uninterrupted in Android foreground service. | — | `NOT_TESTED` |
| **TC-FEAT-AUD-07** | Notification Controls | 1. Pull down Android notification shade.<br>2. Tap Pause, Play, and Close on media notification. | Controls respond immediately; closing notification stops playback cleanly. | — | `NOT_TESTED` |

---

### Domain 6: Guided Puja Liturgies

| Test ID | Guide & Step | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-PUJA-01**| Puja Overview & Prep | 1. Open Ganesha Puja Guide.<br>2. Review preparation checklist. | Displays list of required items (lamp, flowers, water, naivedya, bell) with checkboxes. | — | `NOT_TESTED` |
| **TC-FEAT-PUJA-02**| Sequential Upachara Flow| 1. Start Puja.<br>2. Step through Upacharas 1 to 16. | Each step displays Sanskrit mantra, Devanagari sloka, step description, and timer. | — | `NOT_TESTED` |
| **TC-FEAT-PUJA-03**| Step Countdown Timer | 1. On Dhyana step, observe countdown timer.<br>2. Let timer expire. | Chime sounds upon step timer completion; prompts devotee to advance to next step. | — | `NOT_TESTED` |
| **TC-FEAT-PUJA-04**| Completion Celebration | 1. Complete step 16 (Aarti / Pradakshina).<br>2. Tap "Finish Puja". | Celebratory mangalam dialog displays; logs completed puja to history. | — | `NOT_TESTED` |

---

### Domain 7: Daily Sadhana Flow & Orchestrator

| Test ID | Control / Feature | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-SAD-01** | Nitya Sadhana Dashboard| 1. Open Sadhana tab.<br>2. Inspect Morning Routine card. | Shows streak count, steps included (Sankalpa, Japa, Puja), and completion status. | — | `NOT_TESTED` |
| **TC-FEAT-SAD-02** | Routine Customization | 1. Tap "Customize Routine".<br>2. Drag Japa step above Puja step.<br>3. Save routine. | Steps reorder smoothly; saved order persists on relaunch. | — | `NOT_TESTED` |
| **TC-FEAT-SAD-03** | Guided Multi-Step Flow | 1. Tap "Start Morning Sadhana".<br>2. Complete Step 1 (Sankalpa).<br>3. Auto-advances to Step 2 (Gayatri Japa). | Advances sequentially through full multi-practice sequence without manual navigation. | — | `NOT_TESTED` |
| **TC-FEAT-SAD-04** | Devotional Journal Log | 1. At routine completion, enter a reflection in journal prompt.<br>2. View Journal History. | Reflection persists with date, practices completed, and streak count. | — | `NOT_TESTED` |

---

### Domain 8: Vedic Sankalpa Generator

| Test ID | Input / Selection | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-SNK-01** | Astrological Auto-Fill | 1. Open Sankalpa Generator.<br>2. Inspect astrological header fields. | Auto-populates current Samvatsara, Ayana, Ritu, Masa, Paksha, Tithi, Vasara from Panchangam. | — | `NOT_TESTED` |
| **TC-FEAT-SNK-02** | Gotra Search & Picker | 1. Tap Gotra field.<br>2. Search "Bharadwaja", select it.<br>3. Search "Unknown Gotra". | Correctly selects Bharadwaja (`भारद्वाजसगोत्रस्य`). Selecting unknown gotra defaults safely to Vishnu/Shiva/Kashyapa. | — | `NOT_TESTED` |
| **TC-FEAT-SNK-03** | Veda Shakha Selection | 1. Select "Rigveda", then "Yajurveda". | Updates recitation formula (e.g. `ऋग्वेदन्तर्गत...`, `यजुर्वेदन्तर्गत...`). | — | `NOT_TESTED` |
| **TC-FEAT-SNK-04** | Sanskrit Text Generation| 1. Tap "Generate Sankalpa".<br>2. Inspect generated Sanskrit text. | Formulates grammatically correct, individualized Sanskrit Sankalpa ready for ritual recitation. | — | `NOT_TESTED` |
| **TC-FEAT-SNK-05** | Copy / Recitation Mode | 1. Tap "Copy Text".<br>2. Tap "Read Aloud" or listen to phonetic guide. | Copies text to device clipboard; phonetic audio/recitation guide plays smoothly. | — | `NOT_TESTED` |

---

### Domain 9: Panchangam Astronomical Calculations

| Test ID | Feature / Control | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-PAN-01** | Current Day Astrological Data| 1. Open Panchangam screen.<br>2. Inspect Tithi, Nakshatra, Yoga, Karana. | Displays today's precise Panchangam elements with percentage completion and ending times. | — | `NOT_TESTED` |
| **TC-FEAT-PAN-02** | Inauspicious Muhurtas | 1. Inspect Rahu Kalam, Yamaganda, Gulika Kalam cards. | Displays exact local time intervals for today's inauspicious periods. | — | `NOT_TESTED` |
| **TC-FEAT-PAN-03** | City Origin Selector | 1. Tap Location button.<br>2. Select "Varanasi (Kashi)", then "Tirupati", then "Ujjain". | Calculations update immediately to reflect chosen city's geographical coordinates and sunrise time. | — | `NOT_TESTED` |
| **TC-FEAT-PAN-04** | Date Navigation | 1. Tap forward arrow ($\to$) to view tomorrow and next week.<br>2. Tap "Today" button. | Advances date calculations seamlessly; "Today" button snaps back to current date. | — | `NOT_TESTED` |

---

### Domain 10: Festivals & Vrat Observances

| Test ID | Control / Feature | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-VRT-01** | Monthly Festival Calendar| 1. Open Festivals screen.<br>2. Swipe across calendar months. | Calendar displays upcoming festivals with color-coded deity dots and descriptions. | — | `NOT_TESTED` |
| **TC-FEAT-VRT-02** | Festival Detail Screen | 1. Tap on "Maha Shivaratri".<br>2. Inspect rituals, fasting rules, and auspicious times. | Displays detailed historical context, puja Vidhi, and vrat rules. | — | `NOT_TESTED` |
| **TC-FEAT-VRT-03** | Vrat Observance Tracking| 1. Open Vrat Calendar.<br>2. Tap "Observe Ekadashi".<br>3. Toggle "Sankalpa Taken". | Records personal observance; badge reflects active vrat on Home screen. | — | `NOT_TESTED` |
| **TC-FEAT-VRT-04** | Reminders & Notifications| 1. Open Reminders Settings.<br>2. Set notification for "Evening Aarti at 6:30 PM".<br>3. Verify alarm schedule. | Schedules exact alarm via Android `AlarmManager`. Fires at 6:30 PM with peaceful notification. | — | `NOT_TESTED` |

---

### Domain 11: DivyaDishi Sacred Direction & Live Compass

| Test ID | Feature / Control | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-DIVYA-01**| 20 Temples Directory | 1. Open DivyaDishi screen.<br>2. Browse 20 sacred temples.<br>3. Inspect distance and bearing. | Lists all 20 temples with great-circle bearing and distance calculated from selected origin. | — | `NOT_TESTED` |
| **TC-FEAT-DIVYA-02**| Origin Selection Modal | 1. Tap "Select Origin".<br>2. Choose "Hyderabad" or "Delhi". | Updates origin coordinates; displays explicit $\pm 15\text{ km}$ approximate origin disclosure. | — | `NOT_TESTED` |
| **TC-FEAT-DIVYA-03**| Live Compass Activation | 1. Tap "Align to Kashi Vishwanath".<br>2. Live compass bottom sheet opens. | Compass sensor activates in foreground only; rotating device rotates needle toward North. | — | `NOT_TESTED` |
| **TC-FEAT-DIVYA-04**| True North & Declination | 1. Toggle "Correct for True North" switch on/off. | Needle adjusts by local magnetic declination angle calculated via offline NOAA WMM-2025 engine. | — | `NOT_TESTED` |
| **TC-FEAT-DIVYA-05**| Turn Angle Guidance | 1. Observe directional guidance text. | Displays clear guidance: e.g. "Turn 42° East to face Kashi Vishwanath Temple". Needle aligns to golden notch. | — | `NOT_TESTED` |
| **TC-FEAT-DIVYA-06**| Sensor Quality Badge | 1. Observe sensor badge in top-right of sheet. | Displays "High Accuracy", "Medium", or "Calibrate Compass (Figure-8)". | — | `NOT_TESTED` |

---

### Domain 12: Settings, Personalization & Offline Resilience

| Test ID | Setting / State | Exact Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-FEAT-SET-01** | App Language Switcher | 1. Open Settings.<br>2. Switch language to Hindi, then Telugu, then English. | Entire UI localized into chosen language immediately. | — | `NOT_TESTED` |
| **TC-FEAT-SET-02** | Theme Selection | 1. Switch theme between "Light", "Dark", and "System". | Backgrounds, cards, and typography transition smoothly between golden light and midnight dark modes. | — | `NOT_TESTED` |
| **TC-FEAT-SET-03** | Audio Cache Reset | 1. Tap "Clear Audio Cache".<br>2. Confirm dialog. | Purges downloaded audio cache; bundled asset tracks remain intact. | — | `NOT_TESTED` |
| **TC-FEAT-SET-04** | Data Reset Confirmation | 1. Tap "Reset Practice History".<br>2. Dialog prompts for explicit confirmation. | Cancelling preserves data; confirming wipes practice logs cleanly without database corruption. | — | `NOT_TESTED` |
| **TC-FEAT-SET-05** | About & Privacy Screen | 1. Tap "Privacy & About".<br>2. Read disclosures. | Confirms version `1.0.0+1`, zero remote tracking, 100% on-device storage guarantee. | — | `NOT_TESTED` |
| **TC-FEAT-SET-06** | 100% Offline Resilience| 1. Enable Airplane Mode on device.<br>2. Launch app.<br>3. Traverse all tabs, play audio, count Japa, compute Panchangam. | App functions 100% autonomously without network errors, crashes, or spinning loaders. | — | `NOT_TESTED` |

---
*Vedam Feature Register Certified by Quality Assurance Group*
