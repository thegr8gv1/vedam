/// Result of a great-circle geographic initial bearing and distance calculation.
///
/// Clearly defined as a physical geodetic calculation between two coordinates on Earth.
/// Not a religious dictate, spiritual merit score, or theological obligation.
class BearingResult {
  final bool isAvailable;
  final double? degrees;
  final String? cardinalDirection;
  final String? sanskritDirection;
  final String? dikpala;
  final double? distanceKm;
  final String? unavailabilityReason;

  const BearingResult._({
    required this.isAvailable,
    this.degrees,
    this.cardinalDirection,
    this.sanskritDirection,
    this.dikpala,
    this.distanceKm,
    this.unavailabilityReason,
  });

  /// Factory for a successfully calculated geographic initial bearing.
  factory BearingResult.calculated({
    required double degrees,
    required double distanceKm,
  }) {
    // Normalization safety: ensure degrees is strictly in [0.0, 360.0)
    final normalized = (degrees % 360.0 + 360.0) % 360.0;
    final (cardinal, sanskrit, dikpala) = _resolveDirection(normalized);

    return BearingResult._(
      isAvailable: true,
      degrees: normalized,
      cardinalDirection: cardinal,
      sanskritDirection: sanskrit,
      dikpala: dikpala,
      distanceKm: distanceKm,
    );
  }

  /// Factory for an unavailable or undefined calculation (e.g., identical origin & destination).
  factory BearingResult.unavailable({required String reason}) {
    return BearingResult._(
      isAvailable: false,
      unavailabilityReason: reason,
    );
  }

  /// Formatted bearing string, e.g. "42.5° NE (Ishanya)".
  String get formattedBearing {
    if (!isAvailable || degrees == null) return 'Bearing Unavailable';
    return '${degrees!.toStringAsFixed(1)}° $cardinalDirection ($sanskritDirection)';
  }

  /// Formatted distance string, e.g. "642 km".
  String get formattedDistance {
    if (!isAvailable || distanceKm == null) return 'Distance Unavailable';
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Resolves degrees into 8-point compass cardinal direction and traditional Ashta Dikpala alignment.
  static (String cardinal, String sanskrit, String dikpala) _resolveDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) {
      return ('N', 'Uttara', 'Kubera');
    } else if (deg >= 22.5 && deg < 67.5) {
      return ('NE', 'Ishanya', 'Ishana');
    } else if (deg >= 67.5 && deg < 112.5) {
      return ('E', 'Purva', 'Indra');
    } else if (deg >= 112.5 && deg < 157.5) {
      return ('SE', 'Agneya', 'Agni');
    } else if (deg >= 157.5 && deg < 202.5) {
      return ('S', 'Dakshina', 'Yama');
    } else if (deg >= 202.5 && deg < 247.5) {
      return ('SW', 'Nairruti', 'Nirrti');
    } else if (deg >= 247.5 && deg < 292.5) {
      return ('W', 'Pashchima', 'Varuna');
    } else {
      return ('NW', 'Vayavya', 'Vayu');
    }
  }

  @override
  String toString() => isAvailable
      ? 'BearingResult($formattedBearing, $formattedDistance)'
      : 'BearingResult(unavailable: $unavailabilityReason)';
}
