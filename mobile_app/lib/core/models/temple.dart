import 'geographic_coordinate.dart';

/// Coordinate verification state for a temple location.
enum CoordinateVerificationStatus {
  userSuppliedUnverified,
  pendingVerification,
  verified,
  rejected;

  String get label {
    switch (this) {
      case CoordinateVerificationStatus.userSuppliedUnverified:
        return 'User-Supplied (Unverified)';
      case CoordinateVerificationStatus.pendingVerification:
        return 'Pending Verification';
      case CoordinateVerificationStatus.verified:
        return 'Independently Verified';
      case CoordinateVerificationStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isVerified => this == CoordinateVerificationStatus.verified;
  bool get needsNotice => this != CoordinateVerificationStatus.verified;
}

/// Physical feature referenced by the geodetic coordinate.
enum CoordinatePointType {
  entranceGateway,
  compoundCenter,
  innerSanctum,
  unknown;

  String get label {
    switch (this) {
      case CoordinatePointType.entranceGateway:
        return 'Entrance Gateway (Gopuram/Mahadwara)';
      case CoordinatePointType.compoundCenter:
        return 'Temple Compound Center';
      case CoordinatePointType.innerSanctum:
        return 'Inner Sanctum (Garbhagriha)';
      case CoordinatePointType.unknown:
        return 'Unspecified Point';
    }
  }
}

/// Primary spiritual tradition or sampradaya of the temple.
enum TempleTradition {
  shaivism,
  vaishnavism,
  shaktism,
  smarta,
  vedicUniversal,
  other;

  String get label {
    switch (this) {
      case TempleTradition.shaivism:
        return 'Shaivism';
      case TempleTradition.vaishnavism:
        return 'Vaishnavism';
      case TempleTradition.shaktism:
        return 'Shaktism';
      case TempleTradition.smarta:
        return 'Smarta';
      case TempleTradition.vedicUniversal:
        return 'Vedic / Universal';
      case TempleTradition.other:
        return 'Other Traditional';
    }
  }
}

/// Immutable domain model representing a sacred temple or kshetra in the DivyaDishi directory.
class Temple {
  final String id;
  final String name;
  final List<String> alternateNames;
  final String deity;
  final String city;
  final String district;
  final String state;
  final String country;
  final GeographicCoordinate coordinate;
  final CoordinateVerificationStatus verificationStatus;
  final CoordinatePointType pointType;
  final String sourceName;
  final String? sourceReference;
  final DateTime? verificationDate;
  final String confidenceLevel;
  final String? notes;
  final TempleTradition tradition;
  final String? significance;
  final List<String> primaryFestivals;

  const Temple({
    required this.id,
    required this.name,
    this.alternateNames = const [],
    required this.deity,
    required this.city,
    this.district = '',
    required this.state,
    required this.country,
    required this.coordinate,
    required this.verificationStatus,
    required this.pointType,
    required this.sourceName,
    this.sourceReference,
    this.verificationDate,
    required this.confidenceLevel,
    this.notes,
    this.tradition = TempleTradition.other,
    this.significance,
    this.primaryFestivals = const [],
  });

  /// Short geographic location string, e.g. "Varanasi, Uttar Pradesh, India".
  String get locationFormatted {
    final parts = [city, state, country].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'alternate_names': alternateNames,
        'deity': deity,
        'city': city,
        'district': district,
        'state': state,
        'country': country,
        'coordinate': coordinate.toJson(),
        'verification_status': verificationStatus.name,
        'point_type': pointType.name,
        'source_name': sourceName,
        'source_reference': sourceReference,
        'verification_date': verificationDate?.toIso8601String(),
        'confidence_level': confidenceLevel,
        'notes': notes,
        'tradition': tradition.name,
        'significance': significance,
        'primary_festivals': primaryFestivals,
      };

  factory Temple.fromJson(Map<String, dynamic> json) {
    return Temple(
      id: json['id'] as String,
      name: json['name'] as String,
      alternateNames: (json['alternate_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      deity: json['deity'] as String,
      city: json['city'] as String,
      district: json['district'] as String? ?? '',
      state: json['state'] as String,
      country: json['country'] as String,
      coordinate: GeographicCoordinate.fromJson(json['coordinate'] as Map<String, dynamic>),
      verificationStatus: CoordinateVerificationStatus.values.firstWhere(
        (e) => e.name == json['verification_status'],
        orElse: () => CoordinateVerificationStatus.userSuppliedUnverified,
      ),
      pointType: CoordinatePointType.values.firstWhere(
        (e) => e.name == json['point_type'],
        orElse: () => CoordinatePointType.unknown,
      ),
      sourceName: json['source_name'] as String? ?? 'User-Supplied Research',
      sourceReference: json['source_reference'] as String?,
      verificationDate: json['verification_date'] != null
          ? DateTime.tryParse(json['verification_date'] as String)
          : null,
      confidenceLevel: json['confidence_level'] as String? ?? 'PROVISIONAL',
      notes: json['notes'] as String?,
      tradition: TempleTradition.values.firstWhere(
        (e) => e.name == json['tradition'],
        orElse: () => TempleTradition.other,
      ),
      significance: json['significance'] as String?,
      primaryFestivals: (json['primary_festivals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
