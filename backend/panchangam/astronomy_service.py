"""
Astronomical calculation service for the Vedam Hindu Panchangam Engine.
Provides clean abstractions over the underlying astronomical library,
implementing VSOP87 / ELP2000-82 ephemerides, Lahiri Ayanamsa,
apparent topocentric rise/set calculations, and root-finding solvers for
Pancha Anga transition boundaries.
"""

from abc import ABC, abstractmethod
from datetime import datetime, timezone, timedelta
from typing import Optional, Tuple
import math
import zoneinfo

import astronomy as astro
from backend.panchangam.models import AyanamsaType


class AstronomicalEngine(ABC):
    """Abstract base class for astronomical calculations."""

    @abstractmethod
    def get_ayanamsa(self, dt_utc: datetime, ayanamsa_type: AyanamsaType = AyanamsaType.LAHIRI) -> float:
        """Returns ayanamsa in decimal degrees for a UTC timestamp."""
        pass

    @abstractmethod
    def get_sun_coordinates(self, dt_utc: datetime) -> Tuple[float, float]:
        """Returns (tropical_ecliptic_longitude, tropical_ecliptic_latitude) in degrees."""
        pass

    @abstractmethod
    def get_moon_coordinates(self, dt_utc: datetime) -> Tuple[float, float]:
        """Returns (tropical_ecliptic_longitude, tropical_ecliptic_latitude) in degrees."""
        pass

    @abstractmethod
    def get_sunrise_sunset(
        self, dt_local_midnight: datetime, latitude: float, longitude: float, altitude: float = 0.0
    ) -> Tuple[Optional[datetime], Optional[datetime], Optional[datetime]]:
        """Returns (sunrise_utc, sunset_utc, solar_noon_utc) for the civil day."""
        pass

    @abstractmethod
    def get_moonrise_moonset(
        self, dt_local_midnight: datetime, latitude: float, longitude: float, altitude: float = 0.0
    ) -> Tuple[Optional[datetime], Optional[datetime]]:
        """Returns (moonrise_utc, moonset_utc) for the civil day."""
        pass


class AstronomyEngineAdapter(AstronomicalEngine):
    """
    Concrete adapter leveraging Don Cross's Astronomy Engine (MIT License).
    Uses VSOP87 for solar and ELP2000-82 for lunar ephemerides.
    """

    def _datetime_to_astro_time(self, dt_utc: datetime) -> astro.Time:
        """Convert timezone-aware UTC datetime to astronomy.Time."""
        dt_utc = dt_utc.astimezone(timezone.utc)
        return astro.Time.Make(
            dt_utc.year, dt_utc.month, dt_utc.day,
            dt_utc.hour, dt_utc.minute, dt_utc.second + dt_utc.microsecond / 1_000_000.0
        )

    def _astro_time_to_datetime(self, t: astro.Time) -> datetime:
        """Convert astronomy.Time to timezone-aware UTC datetime."""
        utc_dt = t.Utc()
        return utc_dt.replace(tzinfo=timezone.utc)

    def get_ayanamsa(self, dt_utc: datetime, ayanamsa_type: AyanamsaType = AyanamsaType.LAHIRI) -> float:
        """
        Calculates Ayanamsa in decimal degrees.
        Lahiri (Chitra Paksha) is the Government of India standard:
        At J2000.0 (JD 2451545.0), Ayanamsa = 23° 51' 25.533" = 23.8570925°
        Precession rate = 5029.0966" per Julian century.
        """
        if ayanamsa_type == AyanamsaType.SAYANA:
            return 0.0

        t_astro = self._datetime_to_astro_time(dt_utc)
        # In astronomy-engine, t_astro.tt is days from J2000.0
        t_centuries = t_astro.tt / 36525.0

        # Lahiri (Chitra Paksha) standard polynomial
        lahiri_seconds = (
            85885.533
            + 5029.0966 * t_centuries
            + 1.1116 * (t_centuries ** 2)
            - 0.00011 * (t_centuries ** 3)
        )
        lahiri_deg = lahiri_seconds / 3600.0

        if ayanamsa_type == AyanamsaType.LAHIRI:
            return lahiri_deg
        elif ayanamsa_type == AyanamsaType.KRISHNAMURTI:
            # KP Ayanamsa is approximately 6 minutes of arc less than Lahiri
            return lahiri_deg - (360.0 / 3600.0)
        elif ayanamsa_type == AyanamsaType.RAMAN:
            # Raman Ayanamsa is approximately 1° 27' more than Lahiri
            return lahiri_deg + 1.45
        return lahiri_deg

    def get_sun_coordinates(self, dt_utc: datetime) -> Tuple[float, float]:
        """Returns geocentric apparent ecliptic coordinates of the Sun in degrees (lon, lat)."""
        t = self._datetime_to_astro_time(dt_utc)
        ecl = astro.SunPosition(t)
        return (ecl.elon % 360.0, ecl.elat)

    def get_moon_coordinates(self, dt_utc: datetime) -> Tuple[float, float]:
        """Returns geocentric apparent ecliptic coordinates of the Moon in degrees (lon, lat)."""
        t = self._datetime_to_astro_time(dt_utc)
        sph = astro.EclipticGeoMoon(t)
        return (sph.lon % 360.0, sph.lat)

    def get_sidereal_coordinates(
        self, dt_utc: datetime, ayanamsa_type: AyanamsaType = AyanamsaType.LAHIRI
    ) -> Tuple[float, float, float]:
        """
        Returns (sun_sidereal_lon, moon_sidereal_lon, ayanamsa_deg).
        All longitudes strictly normalized to [0, 360).
        """
        ayanamsa = self.get_ayanamsa(dt_utc, ayanamsa_type)
        sun_trop, _ = self.get_sun_coordinates(dt_utc)
        moon_trop, _ = self.get_moon_coordinates(dt_utc)

        sun_sid = (sun_trop - ayanamsa) % 360.0
        moon_sid = (moon_trop - ayanamsa) % 360.0
        return (sun_sid, moon_sid, ayanamsa)

    def get_sunrise_sunset(
        self, dt_local_midnight: datetime, latitude: float, longitude: float, altitude: float = 0.0
    ) -> Tuple[Optional[datetime], Optional[datetime], Optional[datetime]]:
        """
        Calculates Sunrise, Sunset, and Solar Noon for the local civil day.
        Standard convention: Center of solar disc at -50' (accounting for 34' refraction + 16' semi-diameter).
        """
        # UTC time at local midnight
        dt_utc_start = dt_local_midnight.astimezone(timezone.utc)
        t_start = self._datetime_to_astro_time(dt_utc_start)
        observer = astro.Observer(latitude, longitude, altitude)

        try:
            rise_t = astro.SearchRiseSet(astro.Body.Sun, observer, astro.Direction.Rise, t_start, 1.2)
            sunrise_utc = self._astro_time_to_datetime(rise_t) if rise_t else None
        except Exception:
            sunrise_utc = None

        try:
            set_t = astro.SearchRiseSet(astro.Body.Sun, observer, astro.Direction.Set, t_start, 1.2)
            sunset_utc = self._astro_time_to_datetime(set_t) if set_t else None
        except Exception:
            sunset_utc = None

        # Solar noon (transit)
        solar_noon_utc = None
        if sunrise_utc and sunset_utc:
            # Approximate midpoint of daylight
            mid_diff = (sunset_utc - sunrise_utc) / 2
            solar_noon_utc = sunrise_utc + mid_diff

        return (sunrise_utc, sunset_utc, solar_noon_utc)

    def get_moonrise_moonset(
        self, dt_local_midnight: datetime, latitude: float, longitude: float, altitude: float = 0.0
    ) -> Tuple[Optional[datetime], Optional[datetime]]:
        """Calculates Moonrise and Moonset for the civil day if occurring."""
        dt_utc_start = dt_local_midnight.astimezone(timezone.utc)
        t_start = self._datetime_to_astro_time(dt_utc_start)
        observer = astro.Observer(latitude, longitude, altitude)

        try:
            rise_t = astro.SearchRiseSet(astro.Body.Moon, observer, astro.Direction.Rise, t_start, 1.0)
            moonrise_utc = self._astro_time_to_datetime(rise_t) if rise_t else None
        except Exception:
            moonrise_utc = None

        try:
            set_t = astro.SearchRiseSet(astro.Body.Moon, observer, astro.Direction.Set, t_start, 1.0)
            moonset_utc = self._astro_time_to_datetime(set_t) if set_t else None
        except Exception:
            moonset_utc = None

        return (moonrise_utc, moonset_utc)

    def get_moon_illumination(self, dt_utc: datetime) -> float:
        """Returns lunar illumination fraction between 0.0 and 100.0%."""
        t = self._datetime_to_astro_time(dt_utc)
        illum = astro.Illumination(astro.Body.Moon, t)
        return round(illum.phase_fraction * 100.0, 1)

    def find_boundary_transition(
        self,
        start_utc: datetime,
        angle_fn,
        target_angle_deg: float,
        search_window_hours: float = 32.0,
        tolerance_seconds: float = 2.0
    ) -> Optional[datetime]:
        """
        Robust root finder for when an astronomical angle crosses target_angle_deg.
        angle_fn(dt_utc) -> current angle in degrees [0, 360).
        Uses Illinois/bisection hybrid over continuous angular difference.
        """
        t_start = start_utc
        t_end = start_utc + timedelta(hours=search_window_hours)

        def angular_diff(dt: datetime) -> float:
            ang = angle_fn(dt) % 360.0
            diff = (ang - target_angle_deg + 180.0) % 360.0 - 180.0
            return diff

        step_hours = 0.5  # 30-minute sampling bracket
        t_curr = t_start
        f_curr = angular_diff(t_curr)

        while t_curr < t_end:
            t_next = min(t_curr + timedelta(hours=step_hours), t_end)
            f_next = angular_diff(t_next)

            # Check for zero crossing (moving from negative to positive)
            if f_curr <= 0.0 and f_next >= 0.0:
                # Bracket isolated! Perform high-precision binary bisection
                low = t_curr
                high = t_next
                for _ in range(35):
                    mid = low + (high - low) / 2
                    f_mid = angular_diff(mid)
                    if abs((high - low).total_seconds()) <= tolerance_seconds:
                        return mid
                    if f_mid <= 0.0:
                        low = mid
                    else:
                        high = mid
                return low + (high - low) / 2

            t_curr = t_next
            f_curr = f_next

        return None
