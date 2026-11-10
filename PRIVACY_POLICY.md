# Privacy Policy for Vedam

**Last Updated:** November 10, 2026  
**Application Name:** Vedam  
**Developer / Publisher:** thegr8gv1  
**Repository:** [https://github.com/thegr8gv1/Vedam](https://github.com/thegr8gv1/Vedam)  
**Public Policy URL:** [https://thegr8gv1.github.io/Vedam/privacy-policy.html](https://thegr8gv1.github.io/Vedam/privacy-policy.html)  

---

## 1. Introduction & Core Philosophy

Vedam is a sacred Vedic scripture, devotional chanting, and personal sadhana application designed with a strict **privacy-first, offline-autonomous architecture**. 

We believe that spiritual practice, prayer, japa meditation, and scripture study are deeply personal and sacred. Therefore, Vedam is engineered so that **your devotional data never leaves your device**.

> **The Vedam Privacy Guarantee:**
> - Zero tracking or telemetry.
> - Zero user accounts, registration, or logins.
> - Zero transmission of practice data, japa counts, gotra lineage, or reflections to any remote server.
> - Zero third-party analytics, advertising, or data collection SDKs.
> - The Android release build does **NOT** request or contain the `android.permission.INTERNET` permission.

---

## 2. Information We Do NOT Collect

Vedam does **not** collect, store, transmit, or share any personal data:
- **No Personal Identifiable Information (PII):** We do not collect names, email addresses, phone numbers, postal addresses, or government IDs.
- **No Device Identifiers or Telemetry:** We do not collect IMEI numbers, MAC addresses, Android Advertising IDs (AAID), IP addresses, or hardware fingerprints.
- **No Financial Data:** Vedam is completely free. We do not process payments, credit cards, or in-app purchases.
- **No Location Tracking:** Vedam does not access your physical GPS coordinates. DivyaDishi temple alignment utilizes only approximate city origins explicitly chosen by you.

---

## 3. How Your Devotional Data is Handled (On-Device Storage)

All features in Vedam operate strictly on your local device:

1. **Japa Mala Chanting Counter:**
   - Your repetition counts, daily totals, streaks, and target milestones are stored exclusively on your device using Android `SharedPreferences` (or local browser storage on Web).
2. **Nitya Sadhana & Daily Routines:**
   - Customized sequences and completion records persist strictly in local device key-value storage.
3. **Vedic Sankalpa Generator:**
   - Any personal lineage options you enter (e.g., Gotra, Veda Shakha, Name) are used solely in temporary memory to generate the Sanskrit recitation text on your screen. They are never transmitted over any network.
4. **Devotional Journal & Bookmarks:**
   - Bookmarked verses and personal reflections remain private on your device.
5. **DivyaDishi Sacred Orientation:**
   - Live compass orientation samples device rotation sensors in the foreground only. Geodesic bearings are calculated locally on your processor using offline NOAA World Magnetic Model (WMM) spherical harmonics.

---

## 4. Device Permissions & Why They Are Needed

The packaged Vedam Android release build requests only the minimum operating system permissions required for local devotional utility:

| Permission | Purpose | Network Access? |
| :--- | :--- | :---: |
| `android.permission.FOREGROUND_SERVICE` | Enables continuous audio playback when you lock your device or switch to another app during Japa. | **No** |
| `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Required on Android 14+ to identify background audio playback as active devotional chanting. | **No** |
| `android.permission.POST_NOTIFICATIONS` | Displays media playback controls (Play, Pause, Stop) in the notification drawer and local prayer alerts. | **No** |
| `android.permission.SCHEDULE_EXACT_ALARM` | Ensures local Vrat, Ekadashi, and Sandhya reminders fire accurately at your scheduled time. | **No** |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Re-registers your scheduled prayer reminders locally after your device restarts. | **No** |
| `android.permission.VIBRATE` | Provides subtle, tactile haptic feedback as you advance beads on the virtual Japa Mala. | **No** |
| `android.permission.WAKE_LOCK` | Prevents the CPU from sleeping while an audio chant or Japa session is actively playing. | **No** |

> **Note on Internet Permission:**  
> The `android.permission.INTERNET` permission is **completely omitted** from the release APK and Android App Bundle manifests. The application is mathematically incapable of opening outbound internet sockets.

---

## 5. Third-Party Libraries & Services

- **Zero Advertising Networks:** Vedam contains no ads (no Google AdMob, Unity, Meta, or third-party ad networks).
- **Zero Analytics SDKs:** Vedam contains no Google Analytics, Firebase, Mixpanel, Segment, or tracking pixels.
- **Zero Crashlytics / Error Reporting:** No diagnostic data or stack traces are transmitted over the network.
- **Bundled Fonts & Audio:** All Indic typography and 31 core devotional audio recordings are bundled locally inside the application binary; no external CDNs are contacted at runtime.

---

## 6. Children's Privacy (COPPA / GDPR-K Compliance)

Vedam contains authentic scriptural, educational, and devotional content suitable for users of all ages. Because Vedam does not collect any personal information whatsoever, it fully complies with the Children's Online Privacy Protection Act (COPPA), the General Data Protection Regulation (GDPR), and related child privacy frameworks worldwide.

---

## 7. Data Retention & User Control

You retain 100% control over all data generated within Vedam:
- **In-App Reset:** You can clear your Japa counts, Sadhana history, and preferences at any time via **Settings -> Reset Practice History**.
- **System Wipe / Uninstallation:** Clearing the app data in Android OS Settings (`Settings -> Apps -> Vedam -> Clear Storage`), or uninstalling the application, permanently erases all on-device data immediately.

---

## 8. Changes to This Privacy Policy

If this Privacy Policy is updated, the revised policy will be committed directly to our public GitHub repository and updated at our public GitHub Pages URL. Because Vedam does not collect user contact information, we encourage users to review the policy on GitHub periodically.

---

## 9. Contact & Governance

If you have questions, feedback, or verification inquiries regarding Vedam's privacy architecture, please contact us:

- **Repository Issues / Discussions:** [https://github.com/thegr8gv1/Vedam/issues](https://github.com/thegr8gv1/Vedam/issues)
- **Developer GitHub:** [https://github.com/thegr8gv1](https://github.com/thegr8gv1)
- **Email:** `101169446+thegr8gv1@users.noreply.github.com`
