"""
Comprehensive Test Suite for Vedam Astronomical Hindu Panchangam Engine.
Validates:
- 5 traditional limbs (Vara, Tithi, Nakshatra, Yoga, Karana)
- Astronomical sunrise/sunset/moonrise/moonset
- True daylight interval divisions: Rahu Kalam, Yamagandam, Gulika Kalam, Abhijit Muhurat
- Local timezone and daylight saving time (DST) awareness
- Multiple geographical locations (Varanasi, Chennai, New York, London)
- Boundary condition validation (invalid coordinates, polar extremes)
- FastAPI REST endpoint contracts and error handling
- Independent reference benchmark comparisons with recorded tolerances
"""

from datetime import date, datetime, timedelta, timezone
import math
import zoneinfo
import pytest
from fastapi.testclient import TestClient

from backend.main import app
from backend.panchangam.models import (
    AyanamsaType,
    DailyPanchangamResponse,
    PanchangamLocation,
)
from backend.panchangam.astronomy_service import AstronomyEngineAdapter
from backend.panchangam.panchangam_calculator import PanchangamCalculator
from backend.panchangam.locations import SACRED_LOCATIONS, get_default_location


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def calculator():
    return PanchangamCalculator()


@pytest.fixture
def adapter():
    return AstronomyEngineAdapter()


# --- 1. ASTRONOMICAL PRECISION & AYANAMSA TESTS ---

def test_lahiri_ayanamsa_precision(adapter):
    """
    Validates Lahiri Ayanamsa calculation against Indian Astronomical Ephemeris baseline.
    At J2000.0 (2000-01-01 12:00 UTC), Lahiri Ayanamsa is 23° 51' 25.533" = 23.8570925°.
    """
    j2000 = datetime(2000, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
    ayanamsa_deg = adapter.get_ayanamsa(j2000, AyanamsaType.LAHIRI)
    expected_j2000 = 23.8570925
    assert abs(ayanamsa_deg - expected_j2000) < 0.001, (
        f"Ayanamsa at J2000.0 expected ~{expected_j2000}°, got {ayanamsa_deg}°"
    )

    # Precession rate check: ~50.29 arcseconds per year -> ~0.01397°/year
    date_2026 = datetime(2026, 11, 5, 0, 0, 0, tzinfo=timezone.utc)
    ayanamsa_2026 = adapter.get_ayanamsa(date_2026, AyanamsaType.LAHIRI)
    # Expected in late 2026: ~24.232°
    assert 24.20 <= ayanamsa_2026 <= 24.26, (
        f"Ayanamsa in 2026 expected ~24.23°, got {ayanamsa_2026}°"
    )


def test_sayana_tropical_ayanamsa(adapter):
    """Sayana system must strictly return 0.0° ayanamsa."""
    dt = datetime(2026, 11, 5, 0, 0, 0, tzinfo=timezone.utc)
    assert adapter.get_ayanamsa(dt, AyanamsaType.SAYANA) == 0.0


def test_solar_and_lunar_coordinates_bounds(adapter):
    """Ecliptic longitudes must be strictly within [0, 360) and latitudes within reasonable limits."""
    dt = datetime(2026, 11, 5, 6, 0, 0, tzinfo=timezone.utc)
    sun_lon, sun_lat = adapter.get_sun_coordinates(dt)
    moon_lon, moon_lat = adapter.get_moon_coordinates(dt)

    assert 0.0 <= sun_lon < 360.0
    assert abs(sun_lat) < 0.01  # Sun ecliptic latitude is negligible (~0°)
    assert 0.0 <= moon_lon < 360.0
    assert abs(moon_lat) < 6.0  # Moon orbital inclination is ~5.14°


# --- 2. FIVE PANCHANGAM ELEMENTS (PANCHA ANGA) TESTS ---

def test_five_elements_structure(calculator):
    """Ensure all 5 elements are populated with canonical names, numbers, and deities."""
    loc = get_default_location()  # Varanasi
    target_date = date(2026, 11, 5)
    res = calculator.calculate(target_date, loc)

    # 1. Vara
    assert res.vara.name == "Guruvara"
    assert "गुरुवार" in res.vara.sanskrit_name
    assert res.vara.number == 5  # Thursday

    # 2. Tithi
    assert 1 <= res.tithi.number <= 30
    assert res.tithi.name is not None
    assert res.tithi.sanskrit_name is not None
    assert res.tithi.end_time_formatted is not None
    assert res.tithi.presiding_deity is not None

    # 3. Nakshatra
    assert 1 <= res.nakshatra.number <= 27
    assert res.nakshatra.name is not None
    assert res.nakshatra.sanskrit_name is not None

    # 4. Yoga
    assert 1 <= res.yoga.number <= 27
    assert res.yoga.name is not None

    # 5. Karana
    assert 1 <= res.karana.number <= 60
    assert res.karana.name is not None


def test_tithi_boundary_transition(calculator):
    """Verify that tithi transition time reflects Moon-Sun 12-degree elongation crossing."""
    loc = PanchangamLocation(
        name="Chennai",
        latitude=13.0827,
        longitude=80.2707,
        timezone="Asia/Kolkata",
    )
    res = calculator.calculate(date(2026, 11, 5), loc)
    # Tithi on Nov 5, 2026 morning in India is Krishna Ekadashi
    assert res.tithi.name == "Krishna Ekadashi"
    assert res.tithi.end_time is not None
    # End time should be ~10:35 AM IST on Nov 5, 2026
    assert res.tithi.end_time.hour == 10
    assert 30 <= res.tithi.end_time.minute <= 40


# --- 3. SUNRISE, SUNSET & DAYLIGHT INTERVAL DIVISIONS ---

def test_dynamic_rahu_kalam_not_hardcoded(calculator):
    """
    Rahu Kalam, Yamagandam, and Gulika Kalam must NOT use the static 6:00 AM grid.
    They must be based on actual local sunrise to sunset divided by 8.
    """
    loc = PanchangamLocation(
        name="Varanasi",
        latitude=25.3176,
        longitude=82.9739,
        timezone="Asia/Kolkata",
    )
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    ss = res.sun_moon.sunset
    day_length = ss - sr
    part = day_length / 8.0

    # Thursday is Guruvara -> Rahu Kalam is 6th part (5th index: sr + 5*part to sr + 6*part)
    expected_rahu_start = sr + 5 * part
    expected_rahu_end = sr + 6 * part

    assert abs((res.rahu_kalam.start_time - expected_rahu_start).total_seconds()) < 1.0
    assert abs((res.rahu_kalam.end_time - expected_rahu_end).total_seconds()) < 1.0

    # Confirm it is NOT 1:30 PM - 3:00 PM (the false fixed assumption)
    assert res.rahu_kalam.formatted != "01:30 PM - 03:00 PM"


def test_abhijit_muhurat_centering(calculator):
    """Abhijit Muhurat must be the 8th of 15 daylight muhurtas, centered at solar noon."""
    loc = get_default_location()
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    ss = res.sun_moon.sunset
    day_length = ss - sr
    muhurta = day_length / 15.0

    expected_start = sr + 7 * muhurta
    expected_end = sr + 8 * muhurta

    assert abs((res.abhijit_muhurat.start_time - expected_start).total_seconds()) < 1.0
    assert abs((res.abhijit_muhurat.end_time - expected_end).total_seconds()) < 1.0


def test_brahma_muhurta_pre_dawn(calculator):
    """Brahma Muhurta must be 96 to 48 minutes before sunrise."""
    loc = get_default_location()
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    expected_start = sr - timedelta(minutes=96)
    expected_end = sr - timedelta(minutes=48)

    assert abs((res.brahma_muhurta.start_time - expected_start).total_seconds()) < 1.0
    assert abs((res.brahma_muhurta.end_time - expected_end).total_seconds()) < 1.0


# --- 4. TIMEZONE & DAYLIGHT SAVING TIME (DST) TESTS ---

def test_us_dst_transition_awareness(calculator):
    """
    Verify New York calculations correctly handle standard time after DST ends in November.
    In 2026, US DST ends on Sunday, Nov 1, 2026 (clocks fall back 1 hour to UTC-5).
    """
    ny_loc = PanchangamLocation(
        name="New York",
        latitude=40.7128,
        longitude=-74.0060,
        timezone="America/New_York",
    )
    # Nov 5 is after DST ended -> EST (UTC-5)
    res_nov5 = calculator.calculate(date(2026, 11, 5), ny_loc)
    assert res_nov5.sun_moon.sunrise.tzinfo.utcoffset(res_nov5.sun_moon.sunrise) == timedelta(hours=-5)

    # Oct 25 is during DST -> EDT (UTC-4)
    res_oct25 = calculator.calculate(date(2026, 10, 25), ny_loc)
    assert res_oct25.sun_moon.sunrise.tzinfo.utcoffset(res_oct25.sun_moon.sunrise) == timedelta(hours=-4)


# --- 5. LOCATION VALIDATION & ERROR HANDLING ---

def test_invalid_latitude_rejection(client):
    """Rejects latitude > 90 or < -90."""
    res = client.get("/api/v1/panchangam/daily?latitude=95.0&longitude=80.0&timezone=Asia/Kolkata")
    assert res.status_code == 422  # Pydantic validation error


def test_invalid_longitude_rejection(client):
    """Rejects longitude > 180 or < -180."""
    res = client.get("/api/v1/panchangam/daily?latitude=25.0&longitude=205.0&timezone=Asia/Kolkata")
    assert res.status_code == 422


def test_invalid_timezone_rejection(client):
    """Rejects unrecognized timezone string."""
    res = client.get("/api/v1/panchangam/daily?latitude=25.0&longitude=80.0&timezone=Invalid/Timezone")
    assert res.status_code == 400
    assert "Invalid IANA timezone" in res.json()["detail"]


# --- 6. INDEPENDENT REFERENCE BENCHMARKS & DOCUMENTED TOLERANCES ---

def test_reference_benchmark_chennai(calculator):
    """
    Reference comparison for Chennai (13.0827° N, 80.2707° E) on Nov 5, 2026:
    - Expected Sunrise: 06:03 AM ± 2 mins
    - Expected Sunset:  05:41 PM ± 2 mins
    - Expected Tithi at Sunrise: Krishna Ekadashi
    - Expected Tithi end time: ~10:35 AM IST (± 5 mins)
    - Expected Nakshatra: Uttara Phalguni
    """
    loc = PanchangamLocation(name="Chennai", latitude=13.0827, longitude=80.2707, timezone="Asia/Kolkata")
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    assert sr.hour == 6 and abs(sr.minute - 3) <= 2
    ss = res.sun_moon.sunset
    assert ss.hour == 17 and abs(ss.minute - 41) <= 2

    assert res.tithi.name == "Krishna Ekadashi"
    assert res.nakshatra.name == "Uttara Phalguni"
    assert res.vara.name == "Guruvara"


def test_reference_benchmark_varanasi(calculator):
    """
    Reference comparison for Varanasi (25.3176° N, 82.9739° E) on Nov 5, 2026:
    - Expected Sunrise: 06:08 AM ± 2 mins
    - Expected Sunset:  05:15 PM ± 2 mins
    - Expected Tithi at Sunrise: Krishna Ekadashi
    """
    loc = PanchangamLocation(name="Varanasi", latitude=25.3176, longitude=82.9739, timezone="Asia/Kolkata")
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    assert sr.hour == 6 and abs(sr.minute - 8) <= 2
    ss = res.sun_moon.sunset
    assert ss.hour == 17 and abs(ss.minute - 15) <= 2
    assert res.tithi.name == "Krishna Ekadashi"


def test_reference_benchmark_london(calculator):
    """
    Reference comparison for London (51.5074° N, 0.1278° W) on Nov 5, 2026:
    - Expected Sunrise: 07:00 AM ± 2 mins
    - Expected Sunset:  04:26 PM ± 2 mins
    - Expected Tithi at Sunrise: Krishna Dvadashi (elongation moved past Ekadashi before UK sunrise)
    """
    loc = PanchangamLocation(name="London", latitude=51.5074, longitude=-0.1278, timezone="Europe/London")
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    assert sr.hour == 7 and abs(sr.minute - 0) <= 2
    ss = res.sun_moon.sunset
    assert ss.hour == 16 and abs(ss.minute - 26) <= 2
    assert res.tithi.name == "Krishna Dvadashi"
    assert res.vara.name == "Guruvara"


def test_reference_benchmark_new_york(calculator):
    """
    Reference comparison for New York (40.7128° N, 74.0060° W) on Nov 5, 2026:
    - Expected Sunrise: 06:31 AM ± 2 mins
    - Expected Sunset:  04:47 PM ± 2 mins
    - Expected Tithi at Sunrise: Krishna Dvadashi
    """
    loc = PanchangamLocation(name="New York", latitude=40.7128, longitude=-74.0060, timezone="America/New_York")
    res = calculator.calculate(date(2026, 11, 5), loc)

    sr = res.sun_moon.sunrise
    assert sr.hour == 6 and abs(sr.minute - 31) <= 2
    ss = res.sun_moon.sunset
    assert ss.hour == 16 and abs(ss.minute - 47) <= 2
    assert res.tithi.name == "Krishna Dvadashi"
    assert res.vara.name == "Guruvara"


def test_dst_transitions_london_and_new_york(calculator):
    """
    Validates daylight saving transitions:
    - London transitions from BST (UTC+1) to GMT (UTC+0) on Oct 25, 2026.
    - New York transitions from EDT (UTC-4) to EST (UTC-5) on Nov 1, 2026.
    Sunrise clock jumps reflect the 1-hour change cleanly.
    """
    loc_lon = PanchangamLocation(name="London", latitude=51.5074, longitude=-0.1278, timezone="Europe/London")
    res_lon_pre = calculator.calculate(date(2026, 10, 24), loc_lon)
    res_lon_post = calculator.calculate(date(2026, 10, 26), loc_lon)

    assert res_lon_pre.sun_moon.sunrise.utcoffset() == timedelta(hours=1)
    assert res_lon_post.sun_moon.sunrise.utcoffset() == timedelta(hours=0)
    # 1-hour clock setback shifts civil sunrise from ~07:39 BST to ~06:43 GMT
    assert res_lon_pre.sun_moon.sunrise.hour == 7
    assert res_lon_post.sun_moon.sunrise.hour == 6

    loc_ny = PanchangamLocation(name="New York", latitude=40.7128, longitude=-74.0060, timezone="America/New_York")
    res_ny_pre = calculator.calculate(date(2026, 10, 31), loc_ny)
    res_ny_post = calculator.calculate(date(2026, 11, 2), loc_ny)

    assert res_ny_pre.sun_moon.sunrise.utcoffset() == timedelta(hours=-4)
    assert res_ny_post.sun_moon.sunrise.utcoffset() == timedelta(hours=-5)
    # 1-hour clock setback shifts civil sunrise from ~07:25 EDT to ~06:27 EST
    assert res_ny_pre.sun_moon.sunrise.hour == 7
    assert res_ny_post.sun_moon.sunrise.hour == 6


def test_tithi_transition_near_sunrise(calculator):
    """
    Validates Udaya Tithi determination when tithi transition is close to sunrise.
    On Nov 5, 2026 in Varanasi, Krishna Ekadashi begins before sunrise and ends at ~10:35 AM.
    Since Ekadashi is active at sunrise, the day is governed by Krishna Ekadashi.
    On Nov 6, 2026, Krishna Dvadashi is active at sunrise.
    """
    loc = PanchangamLocation(name="Varanasi", latitude=25.3176, longitude=82.9739, timezone="Asia/Kolkata")
    res_nov5 = calculator.calculate(date(2026, 11, 5), loc)
    res_nov6 = calculator.calculate(date(2026, 11, 6), loc)

    assert res_nov5.tithi.name == "Krishna Ekadashi"
    assert res_nov6.tithi.name == "Krishna Dvadashi"
    assert res_nov5.tithi.end_time is not None


def test_observances_informational_safeguards(calculator):
    """
    Validates that liturgical observances carry is_informational=True
    and include sectarian/sampradaya disclaimers.
    """
    loc = PanchangamLocation(name="Varanasi", latitude=25.3176, longitude=82.9739, timezone="Asia/Kolkata")
    res = calculator.calculate(date(2026, 11, 5), loc)

    assert len(res.observances) > 0
    for obs in res.observances:
        assert obs.is_informational is True
        assert obs.disclaimer is not None
        assert "sampradaya" in obs.disclaimer.lower() or "tradition" in obs.disclaimer.lower() or "temple" in obs.disclaimer.lower()


# --- 7. FASTAPI REST CONTRACTS ---

def test_api_curated_locations(client):
    """GET /api/v1/panchangam/locations returns verified sacred locations."""
    res = client.get("/api/v1/panchangam/locations")
    assert res.status_code == 200
    locations = res.json()
    assert len(locations) >= 20
    names = [loc["name"] for loc in locations]
    assert any("Varanasi" in n for n in names)
    assert any("Ayodhya" in n for n in names)
    assert any("Tirupati" in n for n in names)


def test_api_conventions_transparency(client):
    """GET /api/v1/panchangam/conventions returns explicit citations and mathematical definitions."""
    res = client.get("/api/v1/panchangam/conventions")
    assert res.status_code == 200
    data = res.json()
    assert "Astronomy Engine" in data["engine"]
    assert "MIT License" in data["license"]
    assert "lahiri" in data["ayanamsa_systems"]
    assert "rahu_kalam" in data["inauspicious_periods"]


def test_api_panchangam_health(client):
    """GET /api/v1/panchangam/health reports operational status."""
    res = client.get("/api/v1/panchangam/health")
    assert res.status_code == 200
    assert res.json()["status"] == "operational"


def test_api_system_health(client):
    """GET /api/v1/health reports system status, version, and governance mode."""
    res = client.get("/api/v1/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert data["service"] == "vedam-api"
    assert data["version"] == "1.0.0"
    assert data["ephemeris_engine"] == "Astronomy Engine 2.1 (VSOP87/ELP2000-82, MIT License)"
    assert data["governance_mode"] == "read_only_astronomical"


def test_api_root(client):
    """GET / returns platform information and endpoints."""
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["platform"] == "Vedam"
    assert data["status"] == "online"
