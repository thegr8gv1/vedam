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

  /// Safe parser supporting multiple string formats (e.g. UPPER_SNAKE_CASE or camelCase).
  static CoordinateVerificationStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CoordinateVerificationStatus.userSuppliedUnverified;
    }
    final normalized = value.trim().toLowerCase().replaceAll('_', '');
    for (final status in CoordinateVerificationStatus.values) {
      if (status.name.toLowerCase() == normalized ||
          status.name.toLowerCase() == value.trim().toLowerCase()) {
        return status;
      }
    }
    if (normalized.contains('unverified')) return CoordinateVerificationStatus.userSuppliedUnverified;
    if (normalized.contains('pending')) return CoordinateVerificationStatus.pendingVerification;
    if (normalized.contains('verified')) return CoordinateVerificationStatus.verified;
    if (normalized.contains('reject')) return CoordinateVerificationStatus.rejected;
    return CoordinateVerificationStatus.userSuppliedUnverified;
  }
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

  /// Safe parser supporting multiple string formats (e.g. UPPER_SNAKE_CASE or camelCase).
  static CoordinatePointType fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CoordinatePointType.unknown;
    }
    final normalized = value.trim().toLowerCase().replaceAll('_', '');
    for (final type in CoordinatePointType.values) {
      if (type.name.toLowerCase() == normalized ||
          type.name.toLowerCase() == value.trim().toLowerCase()) {
        return type;
      }
    }
    if (normalized.contains('entrance') || normalized.contains('gateway') || normalized.contains('gopuram')) {
      return CoordinatePointType.entranceGateway;
    }
    if (normalized.contains('compound') || normalized.contains('center')) {
      return CoordinatePointType.compoundCenter;
    }
    if (normalized.contains('sanctum') || normalized.contains('garbhagriha')) {
      return CoordinatePointType.innerSanctum;
    }
    return CoordinatePointType.unknown;
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

  static TempleTradition fromString(String? value) {
    if (value == null || value.trim().isEmpty) return TempleTradition.other;
    final normalized = value.trim().toLowerCase().replaceAll('_', '');
    for (final t in TempleTradition.values) {
      if (t.name.toLowerCase() == normalized) return t;
    }
    return TempleTradition.other;
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
  final GeographicCoordinate? originalCoordinate;
  final CoordinateVerificationStatus verificationStatus;
  final CoordinatePointType pointType;
  final String sourceName;
  final String? sourceReference;
  final String? sourceUrl;
  final List<String> corroborationSources;
  final DateTime? verificationDate;
  final String confidenceLevel;
  final String? notes;
  final String? verificationNotes;
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
    this.originalCoordinate,
    required this.verificationStatus,
    required this.pointType,
    required this.sourceName,
    this.sourceReference,
    this.sourceUrl,
    this.corroborationSources = const [],
    this.verificationDate,
    required this.confidenceLevel,
    this.notes,
    this.verificationNotes,
    this.tradition = TempleTradition.other,
    this.significance,
    this.primaryFestivals = const [],
  });

  /// Short geographic location string, e.g. "Varanasi, Uttar Pradesh, India".
  String get locationFormatted {
    final parts = [city, state, country].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Whether the coordinate has undergone modification from the initial provisional record.
  bool get hasCoordinateChanged =>
      originalCoordinate != null && originalCoordinate != coordinate;

  Temple copyWith({
    String? id,
    String? name,
    List<String>? alternateNames,
    String? deity,
    String? city,
    String? district,
    String? state,
    String? country,
    GeographicCoordinate? coordinate,
    GeographicCoordinate? originalCoordinate,
    CoordinateVerificationStatus? verificationStatus,
    CoordinatePointType? pointType,
    String? sourceName,
    String? sourceReference,
    String? sourceUrl,
    List<String>? corroborationSources,
    DateTime? verificationDate,
    String? confidenceLevel,
    String? notes,
    String? verificationNotes,
    TempleTradition? tradition,
    String? significance,
    List<String>? primaryFestivals,
  }) {
    return Temple(
      id: id ?? this.id,
      name: name ?? this.name,
      alternateNames: alternateNames ?? this.alternateNames,
      deity: deity ?? this.deity,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      country: country ?? this.country,
      coordinate: coordinate ?? this.coordinate,
      originalCoordinate: originalCoordinate ?? this.originalCoordinate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      pointType: pointType ?? this.pointType,
      sourceName: sourceName ?? this.sourceName,
      sourceReference: sourceReference ?? this.sourceReference,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      corroborationSources: corroborationSources ?? this.corroborationSources,
      verificationDate: verificationDate ?? this.verificationDate,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      notes: notes ?? this.notes,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      tradition: tradition ?? this.tradition,
      significance: significance ?? this.significance,
      primaryFestivals: primaryFestivals ?? this.primaryFestivals,
    );
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
        if (originalCoordinate != null) 'original_coordinate': originalCoordinate!.toJson(),
        'verification_status': verificationStatus.name,
        'point_type': pointType.name,
        'source_name': sourceName,
        'source_reference': sourceReference,
        if (sourceUrl != null) 'source_url': sourceUrl,
        if (corroborationSources.isNotEmpty) 'corroboration_sources': corroborationSources,
        'verification_date': verificationDate?.toIso8601String(),
        'confidence_level': confidenceLevel,
        'notes': notes,
        if (verificationNotes != null) 'verification_notes': verificationNotes,
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
      originalCoordinate: json['original_coordinate'] != null
          ? GeographicCoordinate.fromJson(json['original_coordinate'] as Map<String, dynamic>)
          : null,
      verificationStatus: CoordinateVerificationStatus.fromString(json['verification_status'] as String?),
      pointType: CoordinatePointType.fromString(json['point_type'] as String?),
      sourceName: json['source_name'] as String? ?? 'User-Supplied Research',
      sourceReference: json['source_reference'] as String?,
      sourceUrl: json['source_url'] as String?,
      corroborationSources: (json['corroboration_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      verificationDate: json['verification_date'] != null
          ? DateTime.tryParse(json['verification_date'] as String)
          : null,
      confidenceLevel: json['confidence_level'] as String? ?? 'PROVISIONAL',
      notes: json['notes'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      tradition: TempleTradition.fromString(json['tradition'] as String?),
      significance: json['significance'] as String?,
      primaryFestivals: (json['primary_festivals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
