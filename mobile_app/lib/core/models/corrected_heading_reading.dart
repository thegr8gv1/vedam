import 'bearing_result.dart';
import 'declination_model.dart';
import 'heading_model.dart';
import 'sacred_origin.dart';
import 'temple.dart';

/// Point-in-time true geographic heading derived from raw magnetic sensor measurements
/// corrected by offline World Magnetic Model (WMM) declination.
class CorrectedHeadingReading {
  final HeadingReading rawReading;
  final DeclinationResult? declination;
  final double? trueHeading;
  final DateTime timestamp;
  final bool isAvailable;
  final String? unavailabilityReason;

  const CorrectedHeadingReading._({
    required this.rawReading,
    this.declination,
    this.trueHeading,
    required this.timestamp,
    required this.isAvailable,
    this.unavailabilityReason,
  });

  /// Factory for a successfully corrected true heading reading.
  factory CorrectedHeadingReading.fromReadingAndDeclination({
    required HeadingReading raw,
    required DeclinationResult? declination,
    SacredOrigin? expectedOrigin,
  }) {
    final now = DateTime.now();

    // 1. Guard raw magnetic reading validity
    if (!raw.hasValidHeading || raw.heading == null) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: raw.message ?? 'Compass reading is inactive or unavailable.',
      );
    }

    // 2. Guard against stale sensor readings
    if (raw.isStale || raw.state == HeadingSensorState.stale) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: 'Heading reading is stale; sensor updates paused.',
      );
    }

    // 3. Guard against unreliable sensor accuracy
    if (raw.accuracy == HeadingAccuracy.unreliable) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: 'Compass sensor accuracy is unreliable due to magnetic interference.',
      );
    }

    // 4. Guard declination availability
    if (declination == null || !declination.isValid || declination.declinationDegrees == null) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: declination?.statusMessage ??
            'Select an origin to calculate local geomagnetic declination for True North.',
      );
    }

    // 5. Guard origin consistency
    if (expectedOrigin != null && declination.origin.name != expectedOrigin.name) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: 'Declination was calculated for a different origin point.',
      );
    }

    // 6. Compute True North: True Heading = Magnetic Heading + Declination
    final unnormalized = raw.heading! + declination.declinationDegrees!;
    final normalized = HeadingReading.normalizeDegrees(unnormalized);

    if (normalized == null) {
      return CorrectedHeadingReading._(
        rawReading: raw,
        declination: declination,
        trueHeading: null,
        timestamp: now,
        isAvailable: false,
        unavailabilityReason: 'Failed to normalize corrected true heading.',
      );
    }

    return CorrectedHeadingReading._(
      rawReading: raw,
      declination: declination,
      trueHeading: normalized,
      timestamp: now,
      isAvailable: true,
    );
  }

  /// Formatted True North readout (e.g. "135.3° True").
  String get formattedTrueHeading {
    if (!isAvailable || trueHeading == null) return '—';
    return '${trueHeading!.toStringAsFixed(1)}° True';
  }

  /// Formatted raw magnetic sensor readout (e.g. "135.0° Mag").
  String get formattedMagneticHeading => rawReading.formattedHeading;
}

/// Represents the devotional relative angle between device True Heading and a sacred temple bearing.
class RelativeSacredAlignment {
  final CorrectedHeadingReading correctedHeading;
  final BearingResult targetBearing;
  final String templeId;
  final String templeName;
  final double? turnAngleDegrees;
  final RelativeAlignmentQuality quality;
  final bool userOptedIn;
  final String qualityNotice;
  final String dualUncertaintyDisclaimer;

  const RelativeSacredAlignment._({
    required this.correctedHeading,
    required this.targetBearing,
    required this.templeId,
    required this.templeName,
    this.turnAngleDegrees,
    required this.quality,
    required this.userOptedIn,
    required this.qualityNotice,
    required this.dualUncertaintyDisclaimer,
  });

  /// Factory constructor enforcing all Section 8 and Section 9 safeguards.
  factory RelativeSacredAlignment.evaluate({
    required CorrectedHeadingReading correctedHeading,
    required BearingResult targetBearing,
    required Temple targetTemple,
    required SacredOrigin? currentOrigin,
    bool userOptedIn = false,
  }) {
    // 1. Guard origin selection
    if (currentOrigin == null) {
      return RelativeSacredAlignment._(
        correctedHeading: correctedHeading,
        targetBearing: targetBearing,
        templeId: targetTemple.id,
        templeName: targetTemple.name,
        turnAngleDegrees: null,
        quality: RelativeAlignmentQuality.originUnavailable,
        userOptedIn: userOptedIn,
        qualityNotice: 'Select an origin to calculate temple bearing and declination.',
        dualUncertaintyDisclaimer: '',
      );
    }

    // 2. Guard corrected heading availability
    if (!correctedHeading.isAvailable || correctedHeading.trueHeading == null) {
      return RelativeSacredAlignment._(
        correctedHeading: correctedHeading,
        targetBearing: targetBearing,
        templeId: targetTemple.id,
        templeName: targetTemple.name,
        turnAngleDegrees: null,
        quality: correctedHeading.rawReading.isStale
            ? RelativeAlignmentQuality.staleHeading
            : correctedHeading.rawReading.accuracy == HeadingAccuracy.unreliable
                ? RelativeAlignmentQuality.lowSensorQuality
                : RelativeAlignmentQuality.declinationUnavailable,
        userOptedIn: userOptedIn,
        qualityNotice: correctedHeading.unavailabilityReason ?? 'Corrected True Heading is unavailable.',
        dualUncertaintyDisclaimer: '',
      );
    }

    // 3. Guard target bearing availability
    if (!targetBearing.isAvailable || targetBearing.degrees == null) {
      return RelativeSacredAlignment._(
        correctedHeading: correctedHeading,
        targetBearing: targetBearing,
        templeId: targetTemple.id,
        templeName: targetTemple.name,
        turnAngleDegrees: null,
        quality: RelativeAlignmentQuality.alignmentUnavailable,
        userOptedIn: userOptedIn,
        qualityNotice: targetBearing.unavailabilityReason ?? 'Target temple bearing is unavailable.',
        dualUncertaintyDisclaimer: '',
      );
    }

    // 4. Guard origin consistency between declination and bearing
    if (correctedHeading.declination?.origin.name != currentOrigin.name) {
      return RelativeSacredAlignment._(
        correctedHeading: correctedHeading,
        targetBearing: targetBearing,
        templeId: targetTemple.id,
        templeName: targetTemple.name,
        turnAngleDegrees: null,
        quality: RelativeAlignmentQuality.originMismatch,
        userOptedIn: userOptedIn,
        qualityNotice: 'Origin mismatch between declination correction and geographic bearing.',
        dualUncertaintyDisclaimer: '',
      );
    }

    // 5. Shortest signed angular difference [-180, +180]
    final diff = (targetBearing.degrees! - correctedHeading.trueHeading! + 540.0) % 360.0 - 180.0;

    // 6. Safeguard for provisional temple coordinates (all 20 temples pendingVerification / compoundCenter)
    final isProvisional = targetTemple.verificationStatus != CoordinateVerificationStatus.verified ||
        targetTemple.pointType != CoordinatePointType.innerSanctum;

    final dualDisclaimer =
        'Approximate alignment comparison based on municipal centroid (±${currentOrigin.accuracyRadiusKm.round()} km) '
        'and provisional temple coordinates (${targetTemple.pointType.label}, pending verification). '
        'Contemplative orientation aid only; carries no ritual mandate or precision navigation guarantee.';

    if (isProvisional && !userOptedIn) {
      return RelativeSacredAlignment._(
        correctedHeading: correctedHeading,
        targetBearing: targetBearing,
        templeId: targetTemple.id,
        templeName: targetTemple.name,
        turnAngleDegrees: null,
        quality: RelativeAlignmentQuality.withheldDestinationUnverified,
        userOptedIn: false,
        qualityNotice: 'Alignment guidance withheld: destination temple coordinates are provisional '
            '(${targetTemple.pointType.label}). Tap "Show Approximate Alignment Comparison" to review.',
        dualUncertaintyDisclaimer: dualDisclaimer,
      );
    }

    return RelativeSacredAlignment._(
      correctedHeading: correctedHeading,
      targetBearing: targetBearing,
      templeId: targetTemple.id,
      templeName: targetTemple.name,
      turnAngleDegrees: diff,
      quality: RelativeAlignmentQuality.approximateComparisonAvailable,
      userOptedIn: userOptedIn,
      qualityNotice: 'APPROXIMATE TEMPLE-COMPLEX ALIGNMENT',
      dualUncertaintyDisclaimer: dualDisclaimer,
    );
  }

  /// Whether a valid turn angle is calculated and ready for display.
  bool get hasValidTurnAngle =>
      turnAngleDegrees != null && !turnAngleDegrees!.isNaN && !turnAngleDegrees!.isInfinite;

  /// Human-readable relative orientation guidance (e.g. "Turn 42° Right (Clockwise)").
  String get formattedGuidance {
    if (!hasValidTurnAngle) return qualityNotice;
    final absDiff = turnAngleDegrees!.abs();
    if (absDiff <= 5.0) {
      return 'Facing Sacred Direction (±5°)';
    }
    final direction = turnAngleDegrees! > 0 ? 'Right (Clockwise)' : 'Left (Counter-Clockwise)';
    return 'Turn ${absDiff.round()}° $direction';
  }
}
