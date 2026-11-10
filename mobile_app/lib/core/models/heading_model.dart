/// Heading reference systems for compass orientation.
enum HeadingReference {
  magnetic,
  trueNorth,
  unknown;

  String get label {
    switch (this) {
      case HeadingReference.magnetic:
        return 'Magnetic North';
      case HeadingReference.trueNorth:
        return 'True Geographic North';
      case HeadingReference.unknown:
        return 'Unknown Reference';
    }
  }

  static HeadingReference fromString(String? value) {
    if (value == null) return HeadingReference.unknown;
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('true')) return HeadingReference.trueNorth;
    if (normalized.contains('mag')) return HeadingReference.magnetic;
    return HeadingReference.unknown;
  }
}

/// Qualitative sensor accuracy level reported by hardware or platform APIs.
enum HeadingAccuracy {
  high,
  medium,
  low,
  unreliable,
  unknown;

  String get label {
    switch (this) {
      case HeadingAccuracy.high:
        return 'High Accuracy';
      case HeadingAccuracy.medium:
        return 'Medium Accuracy';
      case HeadingAccuracy.low:
        return 'Low Accuracy';
      case HeadingAccuracy.unreliable:
        return 'Unreliable (Interference)';
      case HeadingAccuracy.unknown:
        return 'Unspecified Accuracy';
    }
  }

  static HeadingAccuracy fromCode(int? code) {
    switch (code) {
      case 3:
        return HeadingAccuracy.high;
      case 2:
        return HeadingAccuracy.medium;
      case 1:
        return HeadingAccuracy.low;
      case 0:
        return HeadingAccuracy.unreliable;
      default:
        return HeadingAccuracy.unknown;
    }
  }
}

/// Operational state of the foreground device compass sensor.
enum HeadingSensorState {
  inactive,
  requestingPermission,
  active,
  lowAccuracy,
  stale,
  unavailable,
  permissionDenied,
  error;

  String get label {
    switch (this) {
      case HeadingSensorState.inactive:
        return 'Compass Inactive';
      case HeadingSensorState.requestingPermission:
        return 'Requesting Sensor Activation';
      case HeadingSensorState.active:
        return 'Compass Active';
      case HeadingSensorState.lowAccuracy:
        return 'Low Accuracy (Calibrate)';
      case HeadingSensorState.stale:
        return 'Stale Reading';
      case HeadingSensorState.unavailable:
        return 'Sensor Unavailable';
      case HeadingSensorState.permissionDenied:
        return 'Permission Denied';
      case HeadingSensorState.error:
        return 'Sensor Error';
    }
  }
}

/// Immutable domain model representing a point-in-time device heading reading.
class HeadingReading {
  final double? heading;
  final HeadingReference reference;
  final HeadingAccuracy accuracy;
  final HeadingSensorState state;
  final DateTime? timestamp;
  final bool isStale;
  final String? message;

  const HeadingReading._({
    this.heading,
    required this.reference,
    required this.accuracy,
    required this.state,
    this.timestamp,
    this.isStale = false,
    this.message,
  });

  /// Inactive reading when sensor is turned off.
  factory HeadingReading.inactive({String? message}) {
    return HeadingReading._(
      heading: null,
      reference: HeadingReference.unknown,
      accuracy: HeadingAccuracy.unknown,
      state: HeadingSensorState.inactive,
      message: message ?? 'Compass is stopped. Tap Start Compass to activate foreground sensor.',
    );
  }

  /// Active valid heading reading normalized to [0.0, 360.0).
  factory HeadingReading.active({
    required double heading,
    required HeadingReference reference,
    HeadingAccuracy accuracy = HeadingAccuracy.high,
    DateTime? timestamp,
    String? message,
  }) {
    final normalized = normalizeDegrees(heading);
    if (normalized == null) {
      return HeadingReading.error(message: 'Invalid non-finite or null heading received.');
    }
    return HeadingReading._(
      heading: normalized,
      reference: reference,
      accuracy: accuracy,
      state: accuracy == HeadingAccuracy.low || accuracy == HeadingAccuracy.unreliable
          ? HeadingSensorState.lowAccuracy
          : HeadingSensorState.active,
      timestamp: timestamp ?? DateTime.now(),
      isStale: false,
      message: message,
    );
  }

  /// Reading marked stale when sensor updates cease during an active session.
  factory HeadingReading.stale({
    required HeadingReading previous,
    String? reason,
  }) {
    return HeadingReading._(
      heading: previous.heading,
      reference: previous.reference,
      accuracy: previous.accuracy,
      state: HeadingSensorState.stale,
      timestamp: previous.timestamp,
      isStale: true,
      message: reason ?? 'Sensor updates paused or delayed. Move device gently.',
    );
  }

  /// Sensor hardware unavailable on this device or environment.
  factory HeadingReading.unavailable({String? reason}) {
    return HeadingReading._(
      heading: null,
      reference: HeadingReference.unknown,
      accuracy: HeadingAccuracy.unknown,
      state: HeadingSensorState.unavailable,
      message: reason ?? 'Geomagnetic orientation hardware is not available on this device.',
    );
  }

  /// Sensor access denied by platform or browser.
  factory HeadingReading.permissionDenied({String? reason}) {
    return HeadingReading._(
      heading: null,
      reference: HeadingReference.unknown,
      accuracy: HeadingAccuracy.unknown,
      state: HeadingSensorState.permissionDenied,
      message: reason ?? 'Device orientation access was denied.',
    );
  }

  /// Unhandled sensor stream exception or fatal error.
  factory HeadingReading.error({required String message}) {
    return HeadingReading._(
      heading: null,
      reference: HeadingReference.unknown,
      accuracy: HeadingAccuracy.unknown,
      state: HeadingSensorState.error,
      message: message,
    );
  }

  /// Normalizes any degree measurement strictly to [0.0, 360.0).
  /// Rejects null, NaN, and infinite inputs with null.
  static double? normalizeDegrees(double? deg) {
    if (deg == null || deg.isNaN || deg.isInfinite) return null;
    final normalized = (deg % 360.0 + 360.0) % 360.0;
    // Guard against -0.0
    return normalized == 360.0 || normalized == 0.0 ? 0.0 : normalized;
  }

  /// Whether reading has a finite, valid heading angle in [0, 360).
  bool get hasValidHeading =>
      heading != null &&
      !heading!.isNaN &&
      !heading!.isInfinite &&
      (state == HeadingSensorState.active ||
          state == HeadingSensorState.lowAccuracy ||
          state == HeadingSensorState.stale);

  /// Human-readable readout string (e.g. "245.3° Magnetic").
  String get formattedHeading {
    if (!hasValidHeading) return '—';
    final refSuffix = reference == HeadingReference.magnetic
        ? 'Mag'
        : reference == HeadingReference.trueNorth
            ? 'True'
            : '';
    return '${heading!.toStringAsFixed(1)}° $refSuffix'.trim();
  }

  /// Calculates the relative angle from device heading to a true-north temple bearing.
  ///
  /// CRITICAL GOVERNANCE & MATHEMATICAL INVARIANT:
  /// Direct comparison between a Magnetic heading and a True-North bearing is strictly
  /// withheld (returns null) unless [reference] is explicitly [HeadingReference.trueNorth].
  /// This prevents presenting misleading alignment advice to devotees.
  double? calculateRelativeAngle({required double targetBearingTrue}) {
    if (!hasValidHeading) return null;
    if (reference != HeadingReference.trueNorth) {
      // Withhold alignment calculation: cannot compare magnetic north with true north
      // without local geomagnetic declination compensation.
      return null;
    }
    final diff = (targetBearingTrue - heading! + 360.0) % 360.0;
    return diff;
  }

  HeadingReading copyWith({
    double? heading,
    HeadingReference? reference,
    HeadingAccuracy? accuracy,
    HeadingSensorState? state,
    DateTime? timestamp,
    bool? isStale,
    String? message,
  }) {
    return HeadingReading._(
      heading: heading ?? this.heading,
      reference: reference ?? this.reference,
      accuracy: accuracy ?? this.accuracy,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      isStale: isStale ?? this.isStale,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'reference': reference.name,
      'accuracy': accuracy.name,
      'state': state.name,
      'timestamp': timestamp?.toIso8601String(),
      'is_stale': isStale,
      'message': message,
    };
  }

  factory HeadingReading.fromJson(Map<String, dynamic> json) {
    final rawHeading = (json['heading'] as num?)?.toDouble();
    final ref = HeadingReference.fromString(json['reference'] as String?);
    final state = HeadingSensorState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => HeadingSensorState.inactive,
    );
    final acc = HeadingAccuracy.values.firstWhere(
      (a) => a.name == json['accuracy'],
      orElse: () => HeadingAccuracy.unknown,
    );
    final ts = json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null;
    final isStale = json['is_stale'] as bool? ?? false;
    final msg = json['message'] as String?;

    return HeadingReading._(
      heading: normalizeDegrees(rawHeading),
      reference: ref,
      accuracy: acc,
      state: state,
      timestamp: ts,
      isStale: isStale,
      message: msg,
    );
  }
}
