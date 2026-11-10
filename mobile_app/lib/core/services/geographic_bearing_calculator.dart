import 'dart:math' as math;
import '../models/bearing_result.dart';
import '../models/geographic_coordinate.dart';

/// Pure mathematical calculation engine for great-circle initial bearings and geodetic distances.
///
/// Designed to be completely decoupled from platform APIs, hardware compasses, location sensors,
/// or internet connectivity.
class GeographicBearingCalculator {
  /// Radius of Earth in kilometers (WGS 84 mean spherical radius).
  static const double earthRadiusKm = 6371.0;

  const GeographicBearingCalculator();

  /// Instance method wrapper for [calculateInitialBearing].
  BearingResult calculateBearing({
    required GeographicCoordinate origin,
    required GeographicCoordinate destination,
    bool isApproximate = false,
    String? provisionalDisclaimer,
  }) =>
      calculateInitialBearing(
        origin: origin,
        destination: destination,
        isApproximate: isApproximate,
        provisionalDisclaimer: provisionalDisclaimer,
      );

  /// Calculates the initial great-circle forward azimuth (bearing) from [origin] to [destination].
  ///
  /// Features:
  /// - Range: Strictly normalized to [0.0, 360.0) degrees.
  /// - Identical Points: Returns an explicit [BearingResult.unavailable] rather than an arbitrary 0° azimuth.
  /// - Antimeridian / Date-line Crossing: Properly handles longitude wrapping across the 180° meridian.
  /// - Numerical Guarding: Protects against division-by-zero, non-finite values, and trig out-of-range inputs.
  static BearingResult calculateInitialBearing({
    required GeographicCoordinate origin,
    required GeographicCoordinate destination,
    bool isApproximate = false,
    String? provisionalDisclaimer,
  }) {
    // 1. Check for identical or sub-meter coincident coordinates
    final dLatRaw = (origin.latitude - destination.latitude).abs();
    final dLonRaw = (origin.longitude - destination.longitude).abs();
    if (dLatRaw < 1e-7 && dLonRaw < 1e-7) {
      return BearingResult.unavailable(
        reason: 'Origin and destination coordinates are identical (azimuth is undefined).',
      );
    }

    // 2. Convert coordinates from degrees to radians
    final lat1 = origin.latitude * math.pi / 180.0;
    final lon1 = origin.longitude * math.pi / 180.0;
    final lat2 = destination.latitude * math.pi / 180.0;
    final lon2 = destination.longitude * math.pi / 180.0;

    // 3. Difference in longitude with antimeridian wrapping to [-pi, pi]
    double dLon = lon2 - lon1;
    if (dLon > math.pi) {
      dLon -= 2.0 * math.pi;
    } else if (dLon < -math.pi) {
      dLon += 2.0 * math.pi;
    }

    // 4. Great-circle initial bearing formula:
    // y = sin(dLon) * cos(lat2)
    // x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    // theta = atan2(y, x)
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final theta = math.atan2(y, x);

    // Convert from radians to degrees and normalize to [0.0, 360.0)
    final rawDegrees = theta * 180.0 / math.pi;
    final normalizedBearing = (rawDegrees % 360.0 + 360.0) % 360.0;

    // 5. Great-circle distance using Haversine formula
    final dLat = lat2 - lat1;
    final sinHalfDLat = math.sin(dLat / 2.0);
    final sinHalfDLon = math.sin(dLon / 2.0);

    final a = sinHalfDLat * sinHalfDLat + math.cos(lat1) * math.cos(lat2) * sinHalfDLon * sinHalfDLon;
    final clampedA = a.clamp(0.0, 1.0);
    final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));
    final distanceKm = earthRadiusKm * c;

    // Sub-meter check
    if (distanceKm < 0.001) {
      return BearingResult.unavailable(
        reason: 'Origin and destination are coincident (distance < 1 meter).',
      );
    }

    return BearingResult.calculated(
      degrees: normalizedBearing,
      distanceKm: distanceKm,
      isApproximate: isApproximate,
      provisionalDisclaimer: provisionalDisclaimer,
    );
  }
}
