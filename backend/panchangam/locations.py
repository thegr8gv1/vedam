"""
Curated sacred pilgrimage and global location database for Vedam Panchangam.
Provides precise coordinates and accurate IANA timezone identifiers.
"""

from typing import List
from backend.panchangam.models import PanchangamLocation


SACRED_LOCATIONS: List[PanchangamLocation] = [
    # Sacred Tirthas & Kshetram
    PanchangamLocation(
        name="Varanasi (Kashi), UP, India",
        latitude=25.3176,
        longitude=82.9739,
        timezone="Asia/Kolkata",
        altitude_meters=80.0,
    ),
    PanchangamLocation(
        name="Ayodhya, UP, India",
        latitude=26.7922,
        longitude=82.1998,
        timezone="Asia/Kolkata",
        altitude_meters=102.0,
    ),
    PanchangamLocation(
        name="Tirupati (Tirumala), AP, India",
        latitude=13.6833,
        longitude=79.3500,
        timezone="Asia/Kolkata",
        altitude_meters=853.0,
    ),
    PanchangamLocation(
        name="Ujjain (Mahakaleshwar), MP, India",
        latitude=23.1765,
        longitude=75.7885,
        timezone="Asia/Kolkata",
        altitude_meters=494.0,
    ),
    PanchangamLocation(
        name="Rameswaram, TN, India",
        latitude=9.2876,
        longitude=79.3129,
        timezone="Asia/Kolkata",
        altitude_meters=10.0,
    ),
    PanchangamLocation(
        name="Haridwar, Uttarakhand, India",
        latitude=29.9457,
        longitude=78.1642,
        timezone="Asia/Kolkata",
        altitude_meters=314.0,
    ),
    PanchangamLocation(
        name="Kanchipuram, TN, India",
        latitude=12.8342,
        longitude=79.7036,
        timezone="Asia/Kolkata",
        altitude_meters=83.0,
    ),
    PanchangamLocation(
        name="Puri (Jagannath), Odisha, India",
        latitude=19.8135,
        longitude=85.8312,
        timezone="Asia/Kolkata",
        altitude_meters=15.0,
    ),
    PanchangamLocation(
        name="Dwarka, Gujarat, India",
        latitude=22.2442,
        longitude=68.9685,
        timezone="Asia/Kolkata",
        altitude_meters=12.0,
    ),
    PanchangamLocation(
        name="Kedarnath, Uttarakhand, India",
        latitude=30.7352,
        longitude=79.0669,
        timezone="Asia/Kolkata",
        altitude_meters=3583.0,
    ),

    # Major Indian Cities
    PanchangamLocation(
        name="Chennai, Tamil Nadu, India",
        latitude=13.0827,
        longitude=80.2707,
        timezone="Asia/Kolkata",
        altitude_meters=6.0,
    ),
    PanchangamLocation(
        name="Bengaluru, Karnataka, India",
        latitude=12.9716,
        longitude=77.5946,
        timezone="Asia/Kolkata",
        altitude_meters=920.0,
    ),
    PanchangamLocation(
        name="Mumbai, Maharashtra, India",
        latitude=19.0760,
        longitude=72.8777,
        timezone="Asia/Kolkata",
        altitude_meters=14.0,
    ),
    PanchangamLocation(
        name="New Delhi, Delhi, India",
        latitude=28.6139,
        longitude=77.2090,
        timezone="Asia/Kolkata",
        altitude_meters=216.0,
    ),
    PanchangamLocation(
        name="Hyderabad, Telangana, India",
        latitude=17.3850,
        longitude=78.4867,
        timezone="Asia/Kolkata",
        altitude_meters=542.0,
    ),
    PanchangamLocation(
        name="Kolkata, West Bengal, India",
        latitude=22.5726,
        longitude=88.3639,
        timezone="Asia/Kolkata",
        altitude_meters=9.0,
    ),

    # Key Global Diaspora Centers
    PanchangamLocation(
        name="New York, NY, USA",
        latitude=40.7128,
        longitude=-74.0060,
        timezone="America/New_York",
        altitude_meters=10.0,
    ),
    PanchangamLocation(
        name="Dallas / Fort Worth, TX, USA",
        latitude=32.7767,
        longitude=-96.7970,
        timezone="America/Chicago",
        altitude_meters=131.0,
    ),
    PanchangamLocation(
        name="San Francisco, CA, USA",
        latitude=37.7749,
        longitude=-122.4194,
        timezone="America/Los_Angeles",
        altitude_meters=16.0,
    ),
    PanchangamLocation(
        name="London, England, UK",
        latitude=51.5074,
        longitude=-0.1278,
        timezone="Europe/London",
        altitude_meters=25.0,
    ),
    PanchangamLocation(
        name="Singapore",
        latitude=1.3521,
        longitude=103.8198,
        timezone="Asia/Singapore",
        altitude_meters=15.0,
    ),
    PanchangamLocation(
        name="Sydney, NSW, Australia",
        latitude=-33.8688,
        longitude=151.2093,
        timezone="Australia/Sydney",
        altitude_meters=19.0,
    ),
    PanchangamLocation(
        name="Dubai, UAE",
        latitude=25.2048,
        longitude=55.2708,
        timezone="Asia/Dubai",
        altitude_meters=5.0,
    ),
    PanchangamLocation(
        name="Tokyo, Japan",
        latitude=35.6762,
        longitude=139.6503,
        timezone="Asia/Tokyo",
        altitude_meters=44.0,
    ),
]


def get_default_location() -> PanchangamLocation:
    """Returns Varanasi (Kashi) as the canonical traditional reference location."""
    return SACRED_LOCATIONS[0]


def find_location_by_name(query: str) -> List[PanchangamLocation]:
    """Case-insensitive search over curated locations."""
    q = query.strip().lower()
    return [loc for loc in SACRED_LOCATIONS if q in loc.name.lower()]
