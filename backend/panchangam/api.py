"""
FastAPI REST router for the Vedam Panchangam Engine.
Provides endpoints for calculating location-aware daily Panchangam,
querying curated sacred locations, and retrieving calculation conventions.
"""

from datetime import date, datetime, timezone
from typing import List, Optional
import zoneinfo

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import ValidationError

from backend.panchangam.models import (
    AyanamsaType,
    CalculationConventions,
    DailyPanchangamResponse,
    PanchangamLocation,
)
from backend.panchangam.panchangam_calculator import PanchangamCalculator
from backend.panchangam.locations import SACRED_LOCATIONS, get_default_location


router = APIRouter(prefix="/api/v1/panchangam", tags=["Panchangam"])
calculator = PanchangamCalculator()


@router.get(
    "/daily",
    response_model=DailyPanchangamResponse,
    summary="Calculate daily Hindu Panchangam for a specific location and date",
)
def get_daily_panchangam(
    target_date: Optional[date] = Query(
        None, alias="date", description="Target date in YYYY-MM-DD format (defaults to today)"
    ),
    latitude: Optional[float] = Query(
        None, ge=-90.0, le=90.0, description="Observer latitude in decimal degrees"
    ),
    longitude: Optional[float] = Query(
        None, ge=-180.0, le=180.0, description="Observer longitude in decimal degrees"
    ),
    location_name: Optional[str] = Query(
        None, alias="name", description="Human-readable location or city name"
    ),
    tz_str: Optional[str] = Query(
        None, alias="timezone", description="IANA timezone identifier, e.g. 'Asia/Kolkata'"
    ),
    ayanamsa: AyanamsaType = Query(
        AyanamsaType.LAHIRI, description="Ayanamsa system to apply (default: lahiri)"
    ),
) -> DailyPanchangamResponse:
    """
    Computes exact astronomical Panchangam values:
    - 5 limbs: Vara, Tithi, Nakshatra, Yoga, Karana
    - End times and transitions
    - Real local Sunrise, Sunset, Moonrise, Moonset
    - True daylight interval divisions: Rahu Kalam, Yamagandam, Gulika Kalam, Abhijit Muhurat
    """
    # 1. Resolve Location
    if latitude is not None and longitude is not None:
        if not tz_str:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A valid IANA 'timezone' parameter is required when custom coordinates are provided.",
            )
        try:
            # Verify timezone validity with standard library zoneinfo
            zoneinfo.ZoneInfo(tz_str)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid IANA timezone string: '{tz_str}'. Example valid timezones: 'Asia/Kolkata', 'America/New_York'.",
            )
        
        loc = PanchangamLocation(
            name=location_name or f"Custom ({latitude:.4f}, {longitude:.4f})",
            latitude=latitude,
            longitude=longitude,
            timezone=tz_str,
        )
    else:
        # Default to canonical traditional location: Varanasi (Kashi)
        loc = get_default_location()

    # 2. Resolve Target Date
    if target_date is None:
        try:
            tz = zoneinfo.ZoneInfo(loc.timezone)
            target_date = datetime.now(tz).date()
        except Exception:
            target_date = datetime.now(timezone.utc).date()

    # 3. Execute Astronomical Calculation
    try:
        response = calculator.calculate(
            target_date=target_date,
            location=loc,
            ayanamsa_type=ayanamsa,
        )
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Astronomical calculation error: {str(e)}",
        )


@router.get(
    "/locations",
    response_model=List[PanchangamLocation],
    summary="Get list of curated sacred pilgrimage sites and major global cities",
)
def get_curated_locations(
    query: Optional[str] = Query(None, description="Optional search term to filter locations")
) -> List[PanchangamLocation]:
    """Returns curated sacred locations and global diaspora hubs with verified coordinates."""
    if not query:
        return SACRED_LOCATIONS
    q = query.strip().lower()
    return [loc for loc in SACRED_LOCATIONS if q in loc.name.lower()]


@router.get(
    "/conventions",
    summary="Get documentation of astronomical calculation conventions, ayanamsa, and standards",
)
def get_calculation_conventions() -> dict:
    """Returns detailed descriptions of formulas, coordinate systems, and astronomical models."""
    return {
        "engine": "Astronomy Engine 2.1 (VSOP87 / ELP2000-82)",
        "license": "MIT License (Don Cross / cosinekitty)",
        "accuracy": "Sub-arcsecond solar accuracy, 10-arcsecond lunar accuracy",
        "ayanamsa_systems": {
            "lahiri": {
                "name": "Lahiri (Chitra Paksha)",
                "standard": "Indian Astronomical Ephemeris / Calendar Reform Committee (1952)",
                "epoch_j2000": "23° 51' 25.533\"",
                "precession_rate": "5029.0966 arcseconds per Julian century",
                "default": True,
            },
            "raman": {"name": "B.V. Raman Ayanamsa", "offset_from_lahiri": "+1.45°"},
            "krishnamurti": {"name": "KP Ayanamsa", "offset_from_lahiri": "-0.10°"},
            "sayana": {"name": "Sayana (Tropical, 0 Ayanamsa)", "offset_from_lahiri": "0°"},
        },
        "pancha_anga_formulas": {
            "tithi": "floor((Moon_tropical_lon - Sun_tropical_lon) mod 360 / 12) + 1 (1 to 30)",
            "nakshatra": "floor(Moon_sidereal_lon / (360/27 = 13°20')) + 1 (1 to 27)",
            "yoga": "floor((Sun_sidereal_lon + Moon_sidereal_lon) mod 360 / (360/27 = 13°20')) + 1 (1 to 27)",
            "karana": "floor((Moon_tropical_lon - Sun_tropical_lon) mod 360 / 6) + 1 (1 to 60)",
            "vara": "Local civil day governed by sunrise-to-sunrise Ahargana convention",
        },
        "inauspicious_periods": {
            "rahu_kalam": "1/8th daytime interval ruled by Rahu (Sun:8, Mon:2, Tue:7, Wed:5, Thu:6, Fri:4, Sat:3)",
            "yamagandam": "1/8th daytime interval ruled by Yama (Sun:5, Mon:4, Tue:3, Wed:2, Thu:1, Fri:7, Sat:6)",
            "gulika_kalam": "1/8th daytime interval ruled by Gulika (Sun:7, Mon:6, Tue:5, Wed:4, Thu:3, Fri:2, Sat:1)",
            "abhijit_muhurat": "8th of 15 daylight muhurtas, centered at solar noon",
            "brahma_muhurta": "96 to 48 minutes before local sunrise",
        },
        "solar_horizon_convention": "Upper limb touch with standard atmospheric refraction (-50 arcminutes)",
        "governance_rule": "Section 8 Sanskrit and Liturgical integrity strictly maintained",
    }


@router.get(
    "/health",
    summary="Health check for the Panchangam astronomical engine",
)
def get_panchangam_health() -> dict:
    """Returns engine status, UTC timestamp, and version."""
    return {
        "status": "operational",
        "service": "vedam-panchangam-engine",
        "version": "1.0.0",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }
