"""
Panchangam Calculation Engine for Vedam.
Computes the five primary limbs (Pancha Anga) — Vara, Tithi, Nakshatra, Yoga, Karana —
along with exact transition times, Dina-mana (daylight interval), Rahu Kalam,
Yamagandam, Gulika Kalam, Abhijit Muhurat, Brahma Muhurta, and liturgical observances.
"""

from datetime import date, datetime, timedelta, timezone
from typing import List, Optional, Tuple
import zoneinfo

from backend.panchangam.models import (
    AyanamsaType,
    CalculationConventions,
    DailyPanchangamResponse,
    Observance,
    PanchaAngaElement,
    PanchangamLocation,
    SunMoonEvents,
    TimePeriod,
)
from backend.panchangam.astronomy_service import AstronomyEngineAdapter


# --- TRADITIONAL CANONICAL DICTIONARIES ---

TITHI_NAMES = [
    ("Shukla Pratipada", "शुक्ल प्रतिपदा", "Agni", "Beginnings, self-study, and prayer"),
    ("Shukla Dwitiya", "शुक्ल द्वितीया", "Brahma", "Architecture, foundations, and growth"),
    ("Shukla Tritiya", "शुक्ल तृतीया", "Gauri", "Devotion, beauty, and auspicious ceremonies"),
    ("Shukla Chaturthi", "शुक्ल चतुर्थी", "Ganesha", "Remover of obstacles, Ganesha aradhana"),
    ("Shukla Panchami", "शुक्ल पञ्चमी", "Sarpa Devatas", "Wisdom, knowledge, and healing"),
    ("Shukla Shashthi", "शुक्ल षष्ठी", "Kartikeya (Skanda)", "Courage, discipline, and triumph over negativity"),
    ("Shukla Saptami", "शुक्ल सप्तमी", "Surya", "Health, radiance, and Surya upasana"),
    ("Shukla Ashtami", "शुक्ल अष्टमी", "Durga", "Strength, courage, and spiritual endurance"),
    ("Shukla Navami", "शुक्ल नवमी", "Saraswati", "Spiritual wisdom, dharma, and Ramachandra puja"),
    ("Shukla Dashami", "शुक्ल दशमी", "Yama / Dharma", "Righteousness, triumph, and auspicious ventures"),
    ("Shukla Ekadashi", "शुक्ल एकादशी", "Vishnu", "Sacred Vishnu fasting, Japa, and spiritual awakening"),
    ("Shukla Dvadashi", "शुक्ल द्वादशी", "Vishnu", "Charity, breaking Ekadashi fast, Harivasara"),
    ("Shukla Trayodashi", "शुक्ल त्रयोदशी", "Shiva / Kamadeva", "Pradosha Shiva worship, peace, and purification"),
    ("Shukla Chaturdashi", "शुक्ल चतुर्दशी", "Shiva", "Intense spiritual contemplation and cleansing"),
    ("Purnima", "पूर्णिमा", "Chandra / Satyanarayana", "Full moon, fullness of mind, Satyanarayana vrata"),
    # Krishna Paksha
    ("Krishna Pratipada", "कृष्ण प्रतिपदा", "Agni", "Introspection, calm reflection, and study"),
    ("Krishna Dwitiya", "कृष्ण द्वितीया", "Brahma", "Inner peace, service, and devotion"),
    ("Krishna Tritiya", "कृष्ण तृतीया", "Gauri", "Quiet contemplation and patience"),
    ("Krishna Chaturthi", "कृष्ण चतुर्थी", "Ganesha", "Sankashti Ganesha contemplation"),
    ("Krishna Panchami", "कृष्ण पञ्चमी", "Sarpa Devatas", "Spiritual grounding and mental balance"),
    ("Krishna Shashthi", "कृष्ण षष्ठी", "Kartikeya", "Steadfast discipline and mindfulness"),
    ("Krishna Saptami", "कृष्ण सप्तमी", "Surya", "Spiritual vitality and prayer"),
    ("Krishna Ashtami", "कृष्ण अष्टमी", "Shiva / Kala Bhairava", "Bhairava puja, overcoming inner fear"),
    ("Krishna Navami", "कृष्ण नवमी", "Durga", "Protection, discernment, and inward focus"),
    ("Krishna Dashami", "कृष्ण दशमी", "Yama / Dharma", "Gratitude and moral steadfastness"),
    ("Krishna Ekadashi", "कृष्ण एकादशी", "Vishnu", "Sacred fasting, deep meditation, and surrender"),
    ("Krishna Dvadashi", "कृष्ण द्वादशी", "Vishnu", "Parana, dana, and quiet contemplation"),
    ("Krishna Trayodashi", "कृष्ण त्रयोदशी", "Shiva", "Masa Shivaratri & Krishna Pradosham worship"),
    ("Krishna Chaturdashi", "कृष्ण चतुर्दशी", "Shiva / Rudra", "Intense Shiva dhyana, dissolution of ego"),
    ("Amavasya", "अमावास्या", "Pitris", "New moon, ancestral remembrance, quiet stillness"),
]

NAKSHATRA_NAMES = [
    ("Ashwini", "अश्विनी", "Ashwini Kumaras", "Swiftness, rejuvenation, healing"),
    ("Bharani", "भरणी", "Yama", "Transformation, moral discipline, restraint"),
    ("Krittika", "कृत्तिका", "Agni", "Spiritual purification, courage, clarity"),
    ("Rohini", "रोहिणी", "Brahma / Prajapati", "Creative growth, fertility, devotion"),
    ("Mrigashirsha", "मृगशीर्षा", "Soma / Chandra", "Spiritual quest, gentleness, curiosity"),
    ("Ardra", "आर्द्रा", "Rudra", "Cleansing storms, tears of devotion, spiritual breakthrough"),
    ("Punarvasu", "पुनर्वसु", "Aditi", "Renewal of spiritual light, homecoming, goodness"),
    ("Pushya", "पुष्य", "Brihaspati", "Most auspicious star for spiritual sadhana and learning"),
    ("Ashlesha", "आश्लेषा", "Sarpas", "Deep intuition, esoteric wisdom, kundalini focus"),
    ("Magha", "मघा", "Pitris", "Ancestral heritage, dignity, sacred traditions"),
    ("Purva Phalguni", "पूर्व फाल्गुनी", "Bhaga", "Loving devotion, spiritual joy, celebration"),
    ("Uttara Phalguni", "उत्तर फाल्गुनी", "Aryaman", "Noble friendship, patron of vows and dharma"),
    ("Hasta", "हस्त", "Savitr", "Healing touch, craftsmanship, prayerful action"),
    ("Chitra", "चित्रा", "Tvashtar (Vishvakarma)", "Beauty, architectural grace, spiritual radiance"),
    ("Swati", "स्वाती", "Vayu", "Spiritual independence, freedom, subtle life breath"),
    ("Vishakha", "विशाखा", "Indra-Agni", "Single-minded focus, triumph of purpose"),
    ("Anuradha", "अनुराधा", "Mitra", "Devoted fellowship, bhakti, Radha consciousness"),
    ("Jyeshtha", "ज्येष्ठा", "Indra", "Spiritual seniority, courage in duty"),
    ("Mula", "मूल", "Nirriti", "Root causes, spiritual unlearning, foundational truth"),
    ("Purva Ashadha", "पूर्वाषाढा", "Apas (Sacred Waters)", "Inherent invincibility, purifying waters"),
    ("Uttara Ashadha", "उत्तराषाढा", "Vishvedevas", "Universal virtue, enduring righteousness"),
    ("Shravana", "श्रवण", "Vishnu", "Sacred listening, Shruti contemplation, Vishnu seva"),
    ("Dhanishta", "धनिष्ठा", "Ashta Vasus", "Divine music, wealth of spirit, rhythmic devotion"),
    ("Shatabhisha", "शतभिषा", "Varuna", "Hundred healers, cosmic order, contemplative solitude"),
    ("Purva Bhadrapada", "पूर्वभाद्रपदा", "Aja Ekapada", "Ascetic tapasya, spiritual passion"),
    ("Uttara Bhadrapada", "उत्तरभाद्रपदा", "Ahirbudhnya", "Deep wisdom, meditative stillness, kundalini peace"),
    ("Revati", "रेवती", "Pushan", "Gentle guidance, safe journeys, final spiritual completion"),
]

YOGA_NAMES = [
    ("Vishkambha", "विष्कम्भ", "Overcoming obstacles"),
    ("Priti", "प्रीति", "Affection and love"),
    ("Ayushman", "आयुष्मान्", "Longevity and vibrant health"),
    ("Saubhagya", "सौभाग्य", "Auspicious fortune and well-being"),
    ("Shobhana", "शोभन", "Radiant grace and elegance"),
    ("Atiganda", "अतिगण्ड", "Caution advised in material undertakings"),
    ("Sukarma", "सुकर्मा", "Noble and virtuous deeds"),
    ("Dhriti", "धृति", "Fortitude, patience, and resolve"),
    ("Shula", "शूल", "Sharp discipline; focus on prayer"),
    ("Ganda", "गण्ड", "Inner cleansing and watchfulness"),
    ("Vriddhi", "वृद्धि", "Prosperity and spiritual expansion"),
    ("Dhruva", "ध्रुव", "Steadfastness and eternal truth"),
    ("Vyaghata", "व्याघात", "Overcoming spiritual adversaries"),
    ("Harshana", "हर्षण", "Joyous celebration and cheer"),
    ("Vajra", "वज्र", "Indomitable strength and resolve"),
    ("Siddhi", "सिद्धि", "Spiritual accomplishment and success"),
    ("Vyatipata", "व्यतीपात", "Quietude, introspective meditation"),
    ("Variyan", "वरीयान्", "Distinguished noble excellence"),
    ("Parigha", "परिघ", "Protective boundary and endurance"),
    ("Shiva", "शिव", "Auspiciousness, peace, and grace"),
    ("Siddha", "सिद्ध", "Spiritual attainment and focus"),
    ("Sadhya", "साध्य", "Fulfillment of spiritual duties"),
    ("Shubha", "शुभ", "Pure, radiant auspiciousness"),
    ("Shukla", "शुक्ल", "Luminous clarity and virtue"),
    ("Brahma", "ब्रह्म", "Divine oneness and profound peace"),
    ("Aindra (Indra)", "ऐन्द्र", "Leadership, nobility, and dharma"),
    ("Vaidhriti", "वैधृति", "Solemn restraint and silent dhyana"),
]

VARA_NAMES = [
    ("Ravivara", "रविवार (Sunday)", "Surya", "Sun", "Devotion to Surya, vitality, and illumination"),
    ("Somavara", "सोमवार (Monday)", "Chandra / Shiva", "Moon", "Devotion to Lord Shiva and Chandra, peace of mind"),
    ("Mangalavara", "मङ्गलवार (Tuesday)", "Mangala / Hanuman / Subrahmanya", "Mars", "Strength, courage, Hanuman Chalisa"),
    ("Budhavara", "बुधवार (Wednesday)", "Budha / Vishnu", "Mercury", "Intellect, learning, Vishnu Sahasranama"),
    ("Guruvara", "गुरुवार (Thursday)", "Brihaspati / Dakshinamurthy", "Jupiter", "Guru worship, scriptural study, spiritual wisdom"),
    ("Shukravara", "शुक्रवार (Friday)", "Shukra / Mahalakshmi", "Venus", "Devotion to Divine Mother Lakshmi, harmony"),
    ("Shanivara", "शनिवार (Saturday)", "Shani / Hanuman", "Saturn", "Discipline, charity, overcoming hardship"),
]

# 11 Karanas: 4 fixed (Shakuni, Chatushpada, Naga, Kimstughna) + 7 repeating
FIXED_KARANAS = {
    0: ("Kimstughna", "किंस्तुघ्न", "Auspicious beginnings and spiritual vows"),
    57: ("Shakuni", "शकुनि", "Watchful discernment and prayer"),
    58: ("Chatushpada", "चतुष्पाद", "Charity to animals, cow protection"),
    59: ("Naga", "नाग", "Subtle energy contemplation, inner grounding"),
}

REPEATING_KARANAS = [
    ("Bava", "बव", "Noble and auspicious acts"),
    ("Balava", "बालव", "Spiritual growth, humility"),
    ("Kaulava", "कौलव", "Social friendship, harmony"),
    ("Taitila", "तैतिल", "Steady progress, diligence"),
    ("Gara", "गर", "Patience and agricultural care"),
    ("Vanija", "वणिज", "Fair dealing, honest commerce"),
    ("Vishti (Bhadra)", "विष्टि (भद्रा)", "Inward prayer and restraint; avoid new worldly ventures"),
]


class PanchangamCalculator:
    """Calculates comprehensive Panchangam data for a given date and location."""

    def __init__(self, engine: Optional[AstronomyEngineAdapter] = None):
        self.engine = engine or AstronomyEngineAdapter()

    def calculate(
        self,
        target_date: date,
        location: PanchangamLocation,
        ayanamsa_type: AyanamsaType = AyanamsaType.LAHIRI,
    ) -> DailyPanchangamResponse:
        """
        Executes astronomical calculations for target_date at the specified location.
        """
        try:
            loc_tz = zoneinfo.ZoneInfo(location.timezone)
        except Exception:
            loc_tz = timezone.utc

        # Local civil midnight for start of day
        local_midnight = datetime(
            target_date.year, target_date.month, target_date.day, 0, 0, 0, tzinfo=loc_tz
        )

        # 1. Sunrise and Sunset calculations
        sr_utc, ss_utc, noon_utc = self.engine.get_sunrise_sunset(
            local_midnight, location.latitude, location.longitude, location.altitude_meters
        )

        # In case of polar midnight sun / polar night, provide fallback
        if sr_utc is None or ss_utc is None:
            # Fallback to nominal 06:00 - 18:00 local time for geometry failure
            sr_local = local_midnight.replace(hour=6)
            ss_local = local_midnight.replace(hour=18)
            noon_local = local_midnight.replace(hour=12)
        else:
            sr_local = sr_utc.astimezone(loc_tz)
            ss_local = ss_utc.astimezone(loc_tz)
            noon_local = noon_utc.astimezone(loc_tz) if noon_utc else (sr_local + (ss_local - sr_local) / 2)

        # Calculate exact daylight interval (Dina-mana)
        day_length = ss_local - sr_local
        day_length_hours = max(0.1, day_length.total_seconds() / 3600.0)
        dl_h = int(day_length_hours)
        dl_m = int((day_length_hours - dl_h) * 60)

        # Moonrise and Moonset
        mr_utc, ms_utc = self.engine.get_moonrise_moonset(
            local_midnight, location.latitude, location.longitude, location.altitude_meters
        )
        mr_local = mr_utc.astimezone(loc_tz) if mr_utc else None
        ms_local = ms_utc.astimezone(loc_tz) if ms_utc else None

        # Moon illumination
        illum_percent = self.engine.get_moon_illumination(sr_local.astimezone(timezone.utc))

        # Build SunMoonEvents
        sun_moon = SunMoonEvents(
            sunrise=sr_local,
            sunrise_formatted=sr_local.strftime("%I:%M %p"),
            sunset=ss_local,
            sunset_formatted=ss_local.strftime("%I:%M %p"),
            day_length_hours=round(day_length_hours, 2),
            day_length_formatted=f"{dl_h}h {dl_m}m",
            solar_noon=noon_local,
            moonrise=mr_local,
            moonrise_formatted=mr_local.strftime("%I:%M %p") if mr_local else "Not today",
            moonset=ms_local,
            moonset_formatted=ms_local.strftime("%I:%M %p") if ms_local else "Not today",
            moon_illumination_percent=illum_percent,
        )

        # 2. Reference moment: Liturgical day begins at Sunrise (Udaya-lagna convention)
        ref_utc = sr_local.astimezone(timezone.utc)
        sun_sid, moon_sid, ayanamsa_deg = self.engine.get_sidereal_coordinates(ref_utc, ayanamsa_type)
        sun_trop, _ = self.engine.get_sun_coordinates(ref_utc)
        moon_trop, _ = self.engine.get_moon_coordinates(ref_utc)

        # 3. Vara (Weekday)
        # Weekday of local civil date (Monday=0, Sunday=6 in Python)
        # We map Sunday=0, Monday=1, ... Saturday=6
        py_weekday = target_date.weekday()
        # py_weekday: Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6
        vara_idx = (py_weekday + 1) % 7  # Sun=0, Mon=1, ..., Sat=6
        v_name, v_sans, v_lord, v_graha, v_meaning = VARA_NAMES[vara_idx]
        vara = PanchaAngaElement(
            number=vara_idx + 1,
            name=v_name,
            sanskrit_name=v_sans,
            start_time=sr_local,
            end_time=sr_local + timedelta(days=1),
            end_time_formatted="Until next sunrise",
            meaning=v_meaning,
            presiding_deity=f"{v_lord} ({v_graha})",
        )

        # 4. Tithi (Lunar Day)
        # Angular elongation: (Moon_lon - Sun_lon) % 360 / 12.0
        diff_deg = (moon_trop - sun_trop) % 360.0
        tithi_float = diff_deg / 12.0
        tithi_idx = int(tithi_float)  # 0 to 29
        t_name, t_sans, t_deity, t_meaning = TITHI_NAMES[tithi_idx]

        # Calculate Tithi transition / end time
        target_tithi_angle = ((tithi_idx + 1) * 12.0) % 360.0
        tithi_end_utc = self.engine.find_boundary_transition(
            ref_utc,
            lambda dt: (self.engine.get_moon_coordinates(dt)[0] - self.engine.get_sun_coordinates(dt)[0]) % 360.0,
            target_tithi_angle,
            search_window_hours=36.0,
        )
        tithi_end_local = tithi_end_utc.astimezone(loc_tz) if tithi_end_utc else None

        tithi = PanchaAngaElement(
            number=tithi_idx + 1,
            name=t_name,
            sanskrit_name=t_sans,
            start_time=None,
            end_time=tithi_end_local,
            end_time_formatted=tithi_end_local.strftime("%I:%M %p") if tithi_end_local else "Spans entire day",
            meaning=t_meaning,
            presiding_deity=t_deity,
        )

        # Paksha
        paksha = "Shukla Paksha (Waxing)" if tithi_idx < 15 else "Krishna Paksha (Waning)"

        # 5. Nakshatra (Lunar Mansion)
        # Based on sidereal Moon longitude divided into 27 segments of 13° 20' = 13.333333°
        seg_deg = 360.0 / 27.0
        nak_float = moon_sid / seg_deg
        nak_idx = int(nak_float) % 27
        n_name, n_sans, n_deity, n_meaning = NAKSHATRA_NAMES[nak_idx]

        target_nak_angle = ((nak_idx + 1) * seg_deg) % 360.0
        nak_end_utc = self.engine.find_boundary_transition(
            ref_utc,
            lambda dt: self.engine.get_sidereal_coordinates(dt, ayanamsa_type)[1],
            target_nak_angle,
            search_window_hours=36.0,
        )
        nak_end_local = nak_end_utc.astimezone(loc_tz) if nak_end_utc else None

        nakshatra = PanchaAngaElement(
            number=nak_idx + 1,
            name=n_name,
            sanskrit_name=n_sans,
            start_time=None,
            end_time=nak_end_local,
            end_time_formatted=nak_end_local.strftime("%I:%M %p") if nak_end_local else "Spans entire day",
            meaning=n_meaning,
            presiding_deity=n_deity,
        )

        # 6. Yoga (Combined Longitudes)
        # (Sun_sid + Moon_sid) % 360 / (360/27)
        yoga_deg = (sun_sid + moon_sid) % 360.0
        yoga_idx = int(yoga_deg / seg_deg) % 27
        y_name, y_sans, y_meaning = YOGA_NAMES[yoga_idx]

        target_yoga_angle = ((yoga_idx + 1) * seg_deg) % 360.0
        yoga_end_utc = self.engine.find_boundary_transition(
            ref_utc,
            lambda dt: (
                self.engine.get_sidereal_coordinates(dt, ayanamsa_type)[0]
                + self.engine.get_sidereal_coordinates(dt, ayanamsa_type)[1]
            ) % 360.0,
            target_yoga_angle,
            search_window_hours=36.0,
        )
        yoga_end_local = yoga_end_utc.astimezone(loc_tz) if yoga_end_utc else None

        yoga = PanchaAngaElement(
            number=yoga_idx + 1,
            name=y_name,
            sanskrit_name=y_sans,
            start_time=None,
            end_time=yoga_end_local,
            end_time_formatted=yoga_end_local.strftime("%I:%M %p") if yoga_end_local else "Spans entire day",
            meaning=y_meaning,
            presiding_deity=None,
        )

        # 7. Karana (Half-Tithi)
        # 60 half-tithis in a lunar month
        karana_idx = int(diff_deg / 6.0) % 60
        if karana_idx in FIXED_KARANAS:
            k_name, k_sans, k_meaning = FIXED_KARANAS[karana_idx]
        else:
            rep_idx = (karana_idx - 1) % 7
            k_name, k_sans, k_meaning = REPEATING_KARANAS[rep_idx]

        target_karana_angle = ((karana_idx + 1) * 6.0) % 360.0
        karana_end_utc = self.engine.find_boundary_transition(
            ref_utc,
            lambda dt: (self.engine.get_moon_coordinates(dt)[0] - self.engine.get_sun_coordinates(dt)[0]) % 360.0,
            target_karana_angle,
            search_window_hours=20.0,
        )
        karana_end_local = karana_end_utc.astimezone(loc_tz) if karana_end_utc else None

        karana = PanchaAngaElement(
            number=karana_idx + 1,
            name=k_name,
            sanskrit_name=k_sans,
            start_time=None,
            end_time=karana_end_local,
            end_time_formatted=karana_end_local.strftime("%I:%M %p") if karana_end_local else "Spans entire day",
            meaning=k_meaning,
            presiding_deity=None,
        )

        # 8. Auspicious & Inauspicious Periods (8 equal parts of daylight)
        part_duration = day_length / 8.0

        # Mapping 1-based part numbers for days of week (Sun=0, Mon=1, ..., Sat=6)
        # Rahu Kalam: Sun:8, Mon:2, Tue:7, Wed:5, Thu:6, Fri:4, Sat:3
        rahu_parts = [8, 2, 7, 5, 6, 4, 3]
        # Yamagandam: Sun:5, Mon:4, Tue:3, Wed:2, Thu:1, Fri:7, Sat:6
        yama_parts = [5, 4, 3, 2, 1, 7, 6]
        # Gulika Kalam: Sun:7, Mon:6, Tue:5, Wed:4, Thu:3, Fri:2, Sat:1
        guli_parts = [7, 6, 5, 4, 3, 2, 1]

        def get_period(part_num: int, name: str, sanskrit: str, is_auspicious: bool, desc: str) -> TimePeriod:
            start = sr_local + (part_num - 1) * part_duration
            end = sr_local + part_num * part_duration
            return TimePeriod(
                name=name,
                sanskrit_name=sanskrit,
                start_time=start,
                end_time=end,
                formatted=f"{start.strftime('%I:%M %p')} - {end.strftime('%I:%M %p')}",
                is_auspicious=is_auspicious,
                description=desc,
            )

        rahu_kalam = get_period(
            rahu_parts[vara_idx], "Rahu Kalam", "राहुकाल", False,
            "Inauspicious 1/8th daylight segment governed by Rahu. Traditional ventures and auspicious journeys avoided."
        )
        yamagandam = get_period(
            yama_parts[vara_idx], "Yamagandam", "यमगण्ड", False,
            "Inauspicious segment ruled by Yama. Not recommended for commencing celebrations or new undertakings."
        )
        gulika_kalam = get_period(
            guli_parts[vara_idx], "Gulika Kalam", "गुलिक काल", True,
            "Governed by Gulika (son of Shani). Favorable for starting ongoing beneficial work, charity, and study."
        )

        # Abhijit Muhurat: 8th of 15 daylight muhurtas (day length / 15)
        muhurta_duration = day_length / 15.0
        abhijit_start = sr_local + 7 * muhurta_duration
        abhijit_end = sr_local + 8 * muhurta_duration
        is_abhijit_favorable = vara_idx != 3  # Avoided on Wednesday (Budhavara) in some traditions
        abhijit_muhurat = TimePeriod(
            name="Abhijit Muhurat",
            sanskrit_name="अभिजित् मुहूर्त",
            start_time=abhijit_start,
            end_time=abhijit_end,
            formatted=f"{abhijit_start.strftime('%I:%M %p')} - {abhijit_end.strftime('%I:%M %p')}",
            is_auspicious=is_abhijit_favorable,
            description=(
                "Highly auspicious midday muhurta consecrated to Lord Vishnu. Capable of neutralizing minor planetary flaws."
                + (" (On Wednesdays, traditional caution is exercised)." if vara_idx == 3 else "")
            ),
        )

        # Brahma Muhurta: 2 muhurtas before sunrise (48 mins each, i.e., 96 mins to 48 mins before sunrise)
        bm_start = sr_local - timedelta(minutes=96)
        bm_end = sr_local - timedelta(minutes=48)
        brahma_muhurta = TimePeriod(
            name="Brahma Muhurta",
            sanskrit_name="ब्रह्म मुहूर्त",
            start_time=bm_start,
            end_time=bm_end,
            formatted=f"{bm_start.strftime('%I:%M %p')} - {bm_end.strftime('%I:%M %p')}",
            is_auspicious=True,
            description="Sacred pre-dawn ambrosial period optimal for Japa, Pranayama, and profound Vedic contemplation.",
        )

        # 9. Liturgical Observances (Informational Guidance Safeguard)
        observances: List[Observance] = []
        if tithi_idx in (10, 25):  # Ekadashi
            ek_type = "Shukla" if tithi_idx == 10 else "Krishna"
            observances.append(
                Observance(
                    name=f"{ek_type} Ekadashi Vratam",
                    sanskrit_name=f"{'शुक्ल' if tithi_idx == 10 else 'कृष्ण'} एकादशी व्रतम्",
                    category="Ekadashi",
                    description="Sacred Vaishnava fasting day dedicated to Lord Narayana. Harivasara and nocturnal Japa observed.",
                    is_informational=True,
                    disclaimer="Calculated from Udaya Tithi. Vaishnava and Smartha traditions may differ regarding Viddha Ekadashi and Arunodaya vedha rules. Please verify with your sampradaya or local temple.",
                )
            )
        if tithi_idx in (12, 27):  # Trayodashi / Pradosham
            observances.append(
                Observance(
                    name="Pradosha Vratam",
                    sanskrit_name="प्रदोष व्रतम्",
                    category="Pradosham",
                    description="Twilight worship of Lord Shiva and Nandi Bhagavan during Trayodashi sandhyakala.",
                    is_informational=True,
                    disclaimer="Calculated for Trayodashi coinciding with evening sunset/sandhyakala. Local temple puja timings may vary.",
                )
            )
        if tithi_idx == 14:  # Purnima
            observances.append(
                Observance(
                    name="Purnima Vratam",
                    sanskrit_name="पूर्णिमा व्रतम्",
                    category="Purnima",
                    description="Full moon day observed with Sri Satyanarayana Vratha and charity.",
                    is_informational=True,
                    disclaimer="Calculated for informational guidance. Fasting or puja schedule may depend on whether Purnima touches Pradosha or sunrise.",
                )
            )
        if tithi_idx == 29:  # Amavasya
            observances.append(
                Observance(
                    name="Amavasya",
                    sanskrit_name="अमावास्या (दर्पण)",
                    category="Amavasya",
                    description="New moon day dedicated to Tarpanam, ancestral prayers, and quiet reflection.",
                    is_informational=True,
                    disclaimer="Calculated for informational reference. Tarpanam and Shraddha sankalpam conventions depend on Aparahna or Kutapa muhurta.",
                )
            )

        # 10. Conventions metadata
        deg = int(ayanamsa_deg)
        minutes = int((ayanamsa_deg - deg) * 60)
        seconds = (ayanamsa_deg - deg - minutes / 60.0) * 3600.0
        ayanamsa_formatted = f"{deg}° {minutes}' {seconds:.2f}\""

        conventions = CalculationConventions(
            ayanamsa_used=f"{ayanamsa_type.value.capitalize()} Ayanamsa (Government of India / Chitra Paksha standard)",
            ayanamsa_value_degrees=round(ayanamsa_deg, 6),
            ayanamsa_value_formatted=ayanamsa_formatted,
            ephemeris_engine="Astronomy Engine 2.1 (VSOP87 Sun / ELP2000-82 Moon)",
            coordinate_system="Geocentric apparent ecliptic coordinates",
            sunrise_convention="Topocentric center of solar disc at -50' (accounting for 34' refraction + 16' semi-diameter)",
            time_scale="Terrestrial Time (TT) to UTC via Delta-T; civil output in selected IANA timezone",
            udaya_tithi_rule="Tithi prevailing at local Suryodaya (sunrise) governs the liturgical identity of the day",
        )

        return DailyPanchangamResponse(
            calculation_timestamp_utc=datetime.now(timezone.utc),
            requested_date=target_date,
            location=location,
            vara=vara,
            sun_moon=sun_moon,
            tithi=tithi,
            nakshatra=nakshatra,
            yoga=yoga,
            karana=karana,
            paksha=paksha,
            rahu_kalam=rahu_kalam,
            yamagandam=yamagandam,
            gulika_kalam=gulika_kalam,
            abhijit_muhurat=abhijit_muhurat,
            brahma_muhurta=brahma_muhurta,
            observances=observances,
            conventions=conventions,
        )
