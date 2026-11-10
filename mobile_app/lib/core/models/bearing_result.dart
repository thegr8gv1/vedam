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
  final String? traditionVariant;
  final double? distanceKm;
  final bool isApproximate;
  final String? unavailabilityReason;
  final String? provisionalDisclaimer;

  const BearingResult._({
    required this.isAvailable,
    this.degrees,
    this.cardinalDirection,
    this.sanskritDirection,
    this.dikpala,
    this.traditionVariant,
    this.distanceKm,
    this.isApproximate = false,
    this.unavailabilityReason,
    this.provisionalDisclaimer,
  });

  /// Factory for a successfully calculated geographic initial bearing.
  factory BearingResult.calculated({
    required double degrees,
    required double distanceKm,
    bool isApproximate = false,
    String? provisionalDisclaimer,
  }) {
    // Normalization safety: ensure degrees is strictly in [0.0, 360.0)
    final normalized = (degrees % 360.0 + 360.0) % 360.0;
    final (cardinal, sanskrit, dikpala, variant) = _resolveDirection(normalized);

    return BearingResult._(
      isAvailable: true,
      degrees: normalized,
      cardinalDirection: cardinal,
      sanskritDirection: sanskrit,
      dikpala: dikpala,
      traditionVariant: variant,
      distanceKm: distanceKm,
      isApproximate: isApproximate,
      provisionalDisclaimer: provisionalDisclaimer ??
          (isApproximate
              ? 'Great-circle calculation based on approximate origin or provisional coordinates. Physical orientation aid only; carries no ritual mandate.'
              : 'Great-circle forward azimuth calculation. Physical orientation aid only; carries no ritual mandate.'),
    );
  }

  /// Factory for an unavailable or undefined calculation (e.g., identical origin & destination).
  factory BearingResult.unavailable({required String reason}) {
    return BearingResult._(
      isAvailable: false,
      unavailabilityReason: reason,
      isApproximate: true,
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

  /// Resolves degrees into 8-point compass cardinal direction, Sanskrit Dishā, and Ashta Dikpala alignment
  /// supported by classical Vastu Shastra (Brihat Samhita, Manasara) and Puranic literature.
  static (String cardinal, String sanskrit, String dikpala, String variant) _resolveDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) {
      return ('N', 'Uttara', 'Kubera', 'Puranic: Kubera / Vedic: Soma');
    } else if (deg >= 22.5 && deg < 67.5) {
      return ('NE', 'Ishanya', 'Ishana', 'Aspect of Shiva / Rudra');
    } else if (deg >= 67.5 && deg < 112.5) {
      return ('E', 'Purva', 'Indra', 'Vedic Devendra / Lord of the East');
    } else if (deg >= 112.5 && deg < 157.5) {
      return ('SE', 'Agneya', 'Agni', 'Sacred Fire Deity');
    } else if (deg >= 157.5 && deg < 202.5) {
      return ('S', 'Dakshina', 'Yama', 'Lord of Dharma and Ancestors');
    } else if (deg >= 202.5 && deg < 247.5) {
      return ('SW', 'Nairruti', 'Nirrti', 'Nirriti / Puranic Rakshasa guardian');
    } else if (deg >= 247.5 && deg < 292.5) {
      return ('W', 'Pashchima', 'Varuna', 'Lord of Cosmic Waters and Rta');
    } else {
      return ('NW', 'Vayavya', 'Vayu', 'Lord of Wind and Prana');
    }
  }

  @override
  String toString() => isAvailable
      ? 'BearingResult($formattedBearing, $formattedDistance, approximate: $isApproximate)'
      : 'BearingResult(unavailable: $unavailabilityReason)';
}
