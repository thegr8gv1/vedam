"""
Pydantic data models for the Vedam Astronomical Panchangam Engine.
Represents coordinates, traditional Pancha Anga elements, auspicious/inauspicious
muhurtas, astronomical events, calculation metadata, and API contracts.
"""

from datetime import date, datetime, time
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class AyanamsaType(str, Enum):
    LAHIRI = "lahiri"  # Chitra Paksha (Government of India standard)
    RAMAN = "raman"
    KRISHNAMURTI = "krishnamurti"
    SAYANA = "sayana"  # Tropical (0 ayanamsa)


class Paksha(str, Enum):
    SHUKLA = "Shukla Paksha"
    KRISHNA = "Krishna Paksha"


class PanchangamLocation(BaseModel):
    name: str = Field(..., description="Human-readable city or temple name")
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude in decimal degrees (-90 to +90)")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude in decimal degrees (-180 to +180)")
    timezone: str = Field(..., description="IANA timezone string, e.g., 'Asia/Kolkata', 'America/New_York'")
    altitude_meters: float = Field(default=0.0, description="Elevation above sea level in meters")

    @field_validator("latitude")
    @classmethod
    def validate_latitude(cls, v: float) -> float:
        if v < -90.0 or v > 90.0:
            raise ValueError("Latitude must be between -90 and +90 degrees.")
        return v

    @field_validator("longitude")
    @classmethod
    def validate_longitude(cls, v: float) -> float:
        if v < -180.0 or v > 180.0:
            raise ValueError("Longitude must be between -180 and +180 degrees.")
        return v


class PanchaAngaElement(BaseModel):
    number: int = Field(..., description="1-based traditional index")
    name: str = Field(..., description="English romanized name")
    sanskrit_name: str = Field(..., description="Devanagari Sanskrit name")
    start_time: Optional[datetime] = Field(None, description="Local start time if within calculation window")
    end_time: Optional[datetime] = Field(None, description="Local end time of this element")
    end_time_formatted: Optional[str] = Field(None, description="Formatted local time string (e.g. '04:15 PM')")
    meaning: str = Field(..., description="Spiritual and astrological significance")
    presiding_deity: Optional[str] = Field(None, description="Traditional ruling deity or planetary lord")


class TimePeriod(BaseModel):
    name: str = Field(..., description="Period name (e.g., 'Rahu Kalam', 'Abhijit Muhurat')")
    sanskrit_name: str = Field(..., description="Devanagari name")
    start_time: datetime = Field(..., description="Local start timestamp")
    end_time: datetime = Field(..., description="Local end timestamp")
    formatted: str = Field(..., description="Formatted string (e.g., '01:19 PM - 02:46 PM')")
    is_auspicious: bool = Field(..., description="True if auspicious, False if inauspicious/varjyam")
    description: str = Field(..., description="Traditional significance and recommended spiritual practice")


class SunMoonEvents(BaseModel):
    sunrise: Optional[datetime] = Field(None, description="Local sunrise timestamp")
    sunrise_formatted: str = Field(..., description="Formatted local sunrise (e.g. '06:03 AM')")
    sunset: Optional[datetime] = Field(None, description="Local sunset timestamp")
    sunset_formatted: str = Field(..., description="Formatted local sunset (e.g. '05:41 PM')")
    day_length_hours: float = Field(..., description="Day length in decimal hours")
    day_length_formatted: str = Field(..., description="Day length formatted (e.g. '11h 37m')")
    solar_noon: Optional[datetime] = Field(None, description="Local solar noon / Madhyahna")
    moonrise: Optional[datetime] = Field(None, description="Local moonrise timestamp where available")
    moonrise_formatted: Optional[str] = Field(None, description="Formatted local moonrise")
    moonset: Optional[datetime] = Field(None, description="Local moonset timestamp where available")
    moonset_formatted: Optional[str] = Field(None, description="Formatted local moonset")
    moon_illumination_percent: float = Field(..., description="Percentage of visible lunar disc (0-100%)")


class Observance(BaseModel):
    name: str = Field(..., description="Observance name (e.g., 'Rama Ekadashi', 'Pradosha Vratam')")
    sanskrit_name: str = Field(..., description="Devanagari name")
    category: str = Field(..., description="Category: 'Ekadashi', 'Vrata', 'Purnima', 'Amavasya', 'Sankranti'")
    description: str = Field(..., description="Religious and scriptural context")
    is_informational: bool = Field(default=True, description="Flag indicating observance calculation is informational rather than dogmatic")
    disclaimer: Optional[str] = Field(
        default="Calculated for reference. Specific fasting or ritual timings may vary by sampradaya (Smartha vs Vaishnava) and local temple sankalpam. Please consult your family acharya or local temple authority.",
        description="Sectarian and regional observance disclaimer"
    )


class CalculationConventions(BaseModel):
    ayanamsa_used: str = Field(..., description="Ayanamsa system applied (e.g., 'Lahiri (Chitra Paksha)')")
    ayanamsa_value_degrees: float = Field(..., description="Ayanamsa angle in decimal degrees")
    ayanamsa_value_formatted: str = Field(..., description="Ayanamsa in Deg Min Sec notation")
    ephemeris_engine: str = Field(..., description="Ephemeris engine and version (e.g., 'Astronomy Engine 2.1 (VSOP87/ELP2000-82)')")
    coordinate_system: str = Field(..., description="Geocentric apparent ecliptic coordinates for bodies")
    sunrise_convention: str = Field(..., description="Topocentric center of solar disc at -50' (accounting for 34' refraction + 16' semi-diameter)")
    time_scale: str = Field(..., description="TT (Terrestrial Time) converted to local civil timezone via UTC & delta-T")
    udaya_tithi_rule: str = Field(..., description="Tithi active at local sunrise defines the day's liturgical governance")


class DailyPanchangamResponse(BaseModel):
    status: str = Field(default="success")
    calculation_timestamp_utc: datetime = Field(..., description="UTC timestamp when calculations were executed")
    requested_date: date = Field(..., description="Target civil date")
    location: PanchangamLocation = Field(..., description="Selected location and timezone")
    
    # Astronomical Day
    vara: PanchaAngaElement = Field(..., description="Vara - Weekday and its planetary ruler")
    sun_moon: SunMoonEvents = Field(..., description="Sunrise, sunset, day length, moonrise, moonset")
    
    # 5 Primary Panchangam Elements (Pancha Anga)
    tithi: PanchaAngaElement = Field(..., description="Tithi - Lunar day based on Moon-Sun elongation")
    nakshatra: PanchaAngaElement = Field(..., description="Nakshatra - Lunar mansion based on sidereal Moon longitude")
    yoga: PanchaAngaElement = Field(..., description="Yoga - Combined solar and lunar sidereal longitudes")
    karana: PanchaAngaElement = Field(..., description="Karana - Half-tithi interval")
    paksha: str = Field(..., description="Shukla Paksha (Waxing) or Krishna Paksha (Waning)")
    
    # Auspicious & Inauspicious Timings
    rahu_kalam: TimePeriod = Field(..., description="Rahu Kalam - 1/8th daylight segment dedicated to Rahu")
    yamagandam: TimePeriod = Field(..., description="Yamagandam - 1/8th daylight segment dedicated to Yama")
    gulika_kalam: TimePeriod = Field(..., description="Gulika Kalam - 1/8th daylight segment dedicated to Gulika/Shani")
    abhijit_muhurat: Optional[TimePeriod] = Field(None, description="Abhijit Muhurat - 8th of 15 daylight muhurtas")
    brahma_muhurta: Optional[TimePeriod] = Field(None, description="Brahma Muhurta - 2 muhurtas (96 mins) before sunrise")
    
    # Observances & Festivals
    observances: List[Observance] = Field(default_factory=list, description="Verified liturgical observances for the date")
    
    # Transparency & Conventions
    conventions: CalculationConventions = Field(..., description="Exact astronomical formulas, ayanamsa, and standards")
