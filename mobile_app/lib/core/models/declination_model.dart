import 'sacred_origin.dart';

/// Supported World Magnetic Model (WMM) epochs and datasets.
enum GeomagneticModelType {
  wmm2025(
    name: 'WMM-2025',
    epoch: 2025.0,
    validityStartYear: 2025.0,
    validityEndYear: 2030.0,
    description: 'Official NOAA / NCEI & BGS World Magnetic Model 2025–2030 epoch.',
  ),
  wmm2020(
    name: 'WMM-2020',
    epoch: 2020.0,
    validityStartYear: 2020.0,
    validityEndYear: 2025.0,
    description: 'Official NOAA / NCEI & BGS World Magnetic Model 2020–2025 epoch.',
  );

  final String name;
  final double epoch;
  final double validityStartYear;
  final double validityEndYear;
  final String description;

  const GeomagneticModelType({
    required this.name,
    required this.epoch,
    required this.validityStartYear,
    required this.validityEndYear,
    required this.description,
  });

  bool isDateSupported(double decimalYear) {
    return decimalYear >= validityStartYear && decimalYear < validityEndYear;
  }
}

/// Operational status and validity state of an offline geomagnetic declination calculation.
enum DeclinationStatus {
  valid,
  modelExpired,
  unsupportedDate,
  invalidCoordinates,
  nonFiniteInput,
  blackoutZone,
  cautionZone,
  unavailable;

  String get label {
    switch (this) {
      case DeclinationStatus.valid:
        return 'Valid Offline Declination';
      case DeclinationStatus.modelExpired:
        return 'Geomagnetic Model Expired';
      case DeclinationStatus.unsupportedDate:
        return 'Date Outside Model Validity Span';
      case DeclinationStatus.invalidCoordinates:
        return 'Invalid Geographic Coordinates';
      case DeclinationStatus.nonFiniteInput:
        return 'Non-Finite Input Coordinates';
      case DeclinationStatus.blackoutZone:
        return 'Magnetic Blackout Zone (Near Pole)';
      case DeclinationStatus.cautionZone:
        return 'Magnetic Caution Zone (Low Horizontal Field)';
      case DeclinationStatus.unavailable:
        return 'Declination Unavailable';
    }
  }
}

/// Qualitative status of relative sacred alignment between device heading and target temple bearing.
enum RelativeAlignmentQuality {
  approximateComparisonAvailable,
  withheldDestinationUnverified,
  lowSensorQuality,
  staleHeading,
  originMismatch,
  originUnavailable,
  declinationUnavailable,
  modelExpired,
  alignmentUnavailable;

  String get label {
    switch (this) {
      case RelativeAlignmentQuality.approximateComparisonAvailable:
        return 'Approximate Temple-Complex Alignment';
      case RelativeAlignmentQuality.withheldDestinationUnverified:
        return 'Withheld: Destination Coordinate Provisional';
      case RelativeAlignmentQuality.lowSensorQuality:
        return 'Sensor Interference / Uncalibrated';
      case RelativeAlignmentQuality.staleHeading:
        return 'Stale Heading Reading';
      case RelativeAlignmentQuality.originMismatch:
        return 'Origin Mismatch Between Declination and Bearing';
      case RelativeAlignmentQuality.originUnavailable:
        return 'Origin Not Selected';
      case RelativeAlignmentQuality.declinationUnavailable:
        return 'Declination Unavailable';
      case RelativeAlignmentQuality.modelExpired:
        return 'Geomagnetic Model Expired';
      case RelativeAlignmentQuality.alignmentUnavailable:
        return 'Relative Alignment Unavailable';
    }
  }
}

/// Immutable result of an offline geomagnetic declination calculation.
///
/// Follows official scientific sign conventions (NOAA / NCEI WMM):
/// - Positive (+) indicates Eastward declination (Magnetic North is East of True North).
/// - Negative (-) indicates Westward declination (Magnetic North is West of True North).
class DeclinationResult {
  final double? declinationDegrees;
  final GeomagneticModelType modelType;
  final String modelName;
  final double modelEpoch;
  final double modelValidityEnd;
  final DateTime calculationTimestamp;
  final double decimalYear;
  final SacredOrigin origin;
  final double altitudeKm;
  final double? horizontalIntensityNt;
  final double? totalIntensityNt;
  final double? estimatedUncertaintyDegrees;
  final DeclinationStatus status;
  final String? statusMessage;

  const DeclinationResult._({
    this.declinationDegrees,
    required this.modelType,
    required this.modelName,
    required this.modelEpoch,
    required this.modelValidityEnd,
    required this.calculationTimestamp,
    required this.decimalYear,
    required this.origin,
    this.altitudeKm = 0.0,
    this.horizontalIntensityNt,
    this.totalIntensityNt,
    this.estimatedUncertaintyDegrees,
    required this.status,
    this.statusMessage,
  });

  /// Factory for a successfully calculated declination.
  factory DeclinationResult.valid({
    required double declinationDegrees,
    required GeomagneticModelType modelType,
    required DateTime timestamp,
    required double decimalYear,
    required SacredOrigin origin,
    double altitudeKm = 0.0,
    double? horizontalIntensityNt,
    double? totalIntensityNt,
    double? estimatedUncertaintyDegrees,
    DeclinationStatus status = DeclinationStatus.valid,
    String? message,
  }) {
    return DeclinationResult._(
      declinationDegrees: declinationDegrees,
      modelType: modelType,
      modelName: modelType.name,
      modelEpoch: modelType.epoch,
      modelValidityEnd: modelType.validityEndYear,
      calculationTimestamp: timestamp,
      decimalYear: decimalYear,
      origin: origin,
      altitudeKm: altitudeKm,
      horizontalIntensityNt: horizontalIntensityNt,
      totalIntensityNt: totalIntensityNt,
      estimatedUncertaintyDegrees: estimatedUncertaintyDegrees,
      status: status,
      statusMessage: message,
    );
  }

  /// Factory for an unavailable or rejected declination calculation.
  factory DeclinationResult.unavailable({
    required GeomagneticModelType modelType,
    required SacredOrigin origin,
    required DeclinationStatus status,
    required String message,
    DateTime? timestamp,
    double? decimalYear,
  }) {
    return DeclinationResult._(
      declinationDegrees: null,
      modelType: modelType,
      modelName: modelType.name,
      modelEpoch: modelType.epoch,
      modelValidityEnd: modelType.validityEndYear,
      calculationTimestamp: timestamp ?? DateTime.now(),
      decimalYear: decimalYear ?? modelType.epoch,
      origin: origin,
      status: status,
      statusMessage: message,
    );
  }

  /// Whether the declination is numerically valid and usable for true-heading conversion.
  bool get isValid =>
      status == DeclinationStatus.valid &&
      declinationDegrees != null &&
      !declinationDegrees!.isNaN &&
      !declinationDegrees!.isInfinite;

  /// East-positive / West-negative formatted string (e.g. "+0.3° E" or "-1.1° W").
  String get formattedDeclination {
    if (!isValid) return 'Declination Unavailable';
    final sign = declinationDegrees! >= 0 ? '+' : '';
    final dir = declinationDegrees! >= 0 ? 'E' : 'W';
    return '$sign${declinationDegrees!.toStringAsFixed(1)}° $dir';
  }

  /// Long-form description with cardinal orientation and model name.
  String get verboseDescription {
    if (!isValid) return statusMessage ?? status.label;
    final dir = declinationDegrees! >= 0 ? 'East' : 'West';
    final mag = declinationDegrees!.abs().toStringAsFixed(2);
    final unc = estimatedUncertaintyDegrees != null
        ? ' (±${estimatedUncertaintyDegrees!.toStringAsFixed(2)}°)'
        : '';
    return '$mag° $dir$unc via $modelName ($originNameWithProvenance)';
  }

  /// Provenance string for the origin used.
  String get originNameWithProvenance {
    final uncertainty = origin.isApproximate ? ' [±${origin.accuracyRadiusKm.round()} km centroid]' : ' [User coordinate]';
    return '${origin.name}$uncertainty';
  }

  /// Scientific convention documentation notice.
  static String get conventionNotice =>
      'Convention: East-positive (+) / West-negative (-). True North = Magnetic Heading + Declination.';

  Map<String, dynamic> toJson() {
    return {
      'declination_degrees': declinationDegrees,
      'model_type': modelType.name,
      'model_name': modelName,
      'model_epoch': modelEpoch,
      'model_validity_end': modelValidityEnd,
      'timestamp': calculationTimestamp.toIso8601String(),
      'decimal_year': decimalYear,
      'origin_name': origin.name,
      'origin_is_approximate': origin.isApproximate,
      'altitude_km': altitudeKm,
      'horizontal_intensity_nt': horizontalIntensityNt,
      'total_intensity_nt': totalIntensityNt,
      'estimated_uncertainty_degrees': estimatedUncertaintyDegrees,
      'status': status.name,
      'status_message': statusMessage,
    };
  }
}
