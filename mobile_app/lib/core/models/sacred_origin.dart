import 'geographic_coordinate.dart';

/// Origin derivation mechanism for direction calculations.
enum OriginType {
  approximateCity,
  manualCoordinate,
  deviceGps;

  String get label {
    switch (this) {
      case OriginType.approximateCity:
        return 'Approximate City Center';
      case OriginType.manualCoordinate:
        return 'Custom Coordinate';
      case OriginType.deviceGps:
        return 'Device Location (GPS)';
    }
  }
}

/// Abstract representation of location permission state without invoking platform sensors.
enum LocationPermissionState {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  unavailable;

  String get description {
    switch (this) {
      case LocationPermissionState.notRequested:
        return 'Permission has not been requested yet.';
      case LocationPermissionState.granted:
        return 'Location permission granted.';
      case LocationPermissionState.denied:
        return 'Location permission denied by devotee. Manual city selection remains fully available.';
      case LocationPermissionState.permanentlyDenied:
        return 'Location permission permanently denied. Enable in system settings or use manual city selection.';
      case LocationPermissionState.unavailable:
        return 'Location services unavailable on this device.';
    }
  }
}

/// Represents the devotee's reference point for geographic bearing calculations.
/// Guarantees transparency between approximate municipal centroids and high-precision fixes.
class SacredOrigin {
  final OriginType type;
  final String name;
  final GeographicCoordinate coordinate;
  final bool isApproximate;
  final double accuracyRadiusKm;
  final String? country;
  final String? region;
  final String provenance;
  final String sourceGazetteer;
  final String limitation;
  final DateTime? timestamp;

  const SacredOrigin({
    required this.type,
    required this.name,
    required this.coordinate,
    required this.isApproximate,
    this.accuracyRadiusKm = 15.0,
    this.country,
    this.region,
    required this.provenance,
    this.sourceGazetteer = 'National / Municipal Geographical Gazetteer',
    this.limitation = 'Approximate reference point with inherent radius of uncertainty. Not an exact GPS fix.',
    this.timestamp,
  });

  /// Factory for approximate city centers.
  factory SacredOrigin.fromCity({
    required String cityName,
    required double lat,
    required double lon,
    String? country,
    String? region,
    double accuracyRadiusKm = 15.0,
    String sourceGazetteer = 'National / Municipal Geographical Gazetteer',
  }) {
    return SacredOrigin(
      type: OriginType.approximateCity,
      name: country != null ? '$cityName, $country' : cityName,
      coordinate: GeographicCoordinate(lat, lon),
      isApproximate: true,
      accuracyRadiusKm: accuracyRadiusKm,
      country: country,
      region: region,
      provenance: 'Approximate city center reference point. Not an exact GPS fix.',
      sourceGazetteer: sourceGazetteer,
      limitation: 'Represents approximate city centroid with approximately ±$accuracyRadiusKm km uncertainty.',
      timestamp: DateTime.now(),
    );
  }

  /// Factory for custom user-entered coordinates.
  factory SacredOrigin.fromManualCoordinate({
    required String label,
    required double lat,
    required double lon,
  }) {
    return SacredOrigin(
      type: OriginType.manualCoordinate,
      name: label.trim().isNotEmpty ? label : 'Manual Coordinates',
      coordinate: GeographicCoordinate(lat, lon),
      isApproximate: false,
      accuracyRadiusKm: 0.0,
      provenance: 'Manually entered coordinates.',
      sourceGazetteer: 'User-specified coordinate pair',
      limitation: 'Exact mathematical coordinate as specified by devotee.',
      timestamp: DateTime.now(),
    );
  }

  /// Pre-seeded list of 13 major cities for instant, 100% private offline selection.
  /// Sourced from official state administrative centers and geographical gazetteers.
  static final List<SacredOrigin> canonicalCities = [
    SacredOrigin.fromCity(
      cityName: 'Varanasi',
      country: 'India',
      region: 'Uttar Pradesh',
      lat: 25.3176,
      lon: 82.9739,
      sourceGazetteer: 'Survey of India / Varanasi Municipal Corporation Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'New Delhi',
      country: 'India',
      region: 'National Capital Territory',
      lat: 28.6139,
      lon: 77.2090,
      sourceGazetteer: 'Survey of India / New Delhi Municipal Council Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Mumbai',
      country: 'India',
      region: 'Maharashtra',
      lat: 19.0760,
      lon: 72.8777,
      sourceGazetteer: 'Municipal Corporation of Greater Mumbai Reference Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Bengaluru',
      country: 'India',
      region: 'Karnataka',
      lat: 12.9716,
      lon: 77.5946,
      sourceGazetteer: 'Bruhat Bengaluru Mahanagara Palike Administrative Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Chennai',
      country: 'India',
      region: 'Tamil Nadu',
      lat: 13.0827,
      lon: 80.2707,
      sourceGazetteer: 'Greater Chennai Corporation Administrative Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Kolkata',
      country: 'India',
      region: 'West Bengal',
      lat: 22.5726,
      lon: 88.3639,
      sourceGazetteer: 'Kolkata Municipal Corporation Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Hyderabad',
      country: 'India',
      region: 'Telangana',
      lat: 17.3850,
      lon: 78.4867,
      sourceGazetteer: 'Greater Hyderabad Municipal Corporation Reference Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Tirupati',
      country: 'India',
      region: 'Andhra Pradesh',
      lat: 13.6288,
      lon: 79.4192,
      sourceGazetteer: 'Tirupati Municipal Corporation Urban Centroid (Plains)',
    ),
    SacredOrigin.fromCity(
      cityName: 'Ayodhya',
      country: 'India',
      region: 'Uttar Pradesh',
      lat: 26.7922,
      lon: 82.1998,
      sourceGazetteer: 'Ayodhya Municipal Corporation Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Ujjain',
      country: 'India',
      region: 'Madhya Pradesh',
      lat: 23.1765,
      lon: 75.7885,
      sourceGazetteer: 'Ujjain Municipal Corporation Zero-Meridian Reference Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Madurai',
      country: 'India',
      region: 'Tamil Nadu',
      lat: 9.9252,
      lon: 78.1198,
      sourceGazetteer: 'Madurai Municipal Corporation Central Zone Reference',
    ),
    SacredOrigin.fromCity(
      cityName: 'Haridwar',
      country: 'India',
      region: 'Uttarakhand',
      lat: 29.9457,
      lon: 78.1642,
      sourceGazetteer: 'Haridwar Municipal Corporation Reference Centroid',
    ),
    SacredOrigin.fromCity(
      cityName: 'Kathmandu',
      country: 'Nepal',
      region: 'Bagmati Province',
      lat: 27.7172,
      lon: 85.3240,
      sourceGazetteer: 'Survey Department of Nepal / Kathmandu Metropolitan City Centroid',
    ),
  ];
}
