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
class SacredOrigin {
  final OriginType type;
  final String name;
  final GeographicCoordinate coordinate;
  final bool isApproximate;
  final String provenance;
  final DateTime? timestamp;

  const SacredOrigin({
    required this.type,
    required this.name,
    required this.coordinate,
    required this.isApproximate,
    required this.provenance,
    this.timestamp,
  });

  /// Factory for approximate city centers.
  factory SacredOrigin.fromCity({
    required String cityName,
    required double lat,
    required double lon,
    String? country,
  }) {
    return SacredOrigin(
      type: OriginType.approximateCity,
      name: country != null ? '$cityName, $country' : cityName,
      coordinate: GeographicCoordinate(lat, lon),
      isApproximate: true,
      provenance: 'Approximate city center reference point. Not exact GPS fix.',
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
      provenance: 'Manually entered coordinates.',
      timestamp: DateTime.now(),
    );
  }

  /// Pre-seeded list of major cities for instant, 100% private offline selection.
  static final List<SacredOrigin> canonicalCities = [
    SacredOrigin.fromCity(cityName: 'Varanasi', country: 'India', lat: 25.3176, lon: 82.9739),
    SacredOrigin.fromCity(cityName: 'New Delhi', country: 'India', lat: 28.6139, lon: 77.2090),
    SacredOrigin.fromCity(cityName: 'Mumbai', country: 'India', lat: 19.0760, lon: 72.8777),
    SacredOrigin.fromCity(cityName: 'Bengaluru', country: 'India', lat: 12.9716, lon: 77.5946),
    SacredOrigin.fromCity(cityName: 'Chennai', country: 'India', lat: 13.0827, lon: 80.2707),
    SacredOrigin.fromCity(cityName: 'Kolkata', country: 'India', lat: 22.5726, lon: 88.3639),
    SacredOrigin.fromCity(cityName: 'Hyderabad', country: 'India', lat: 17.3850, lon: 78.4867),
    SacredOrigin.fromCity(cityName: 'Tirupati', country: 'India', lat: 13.6288, lon: 79.4192),
    SacredOrigin.fromCity(cityName: 'Ayodhya', country: 'India', lat: 26.7922, lon: 82.1998),
    SacredOrigin.fromCity(cityName: 'Ujjain', country: 'India', lat: 23.1765, lon: 75.7885),
    SacredOrigin.fromCity(cityName: 'Madurai', country: 'India', lat: 9.9252, lon: 78.1198),
    SacredOrigin.fromCity(cityName: 'Haridwar', country: 'India', lat: 29.9457, lon: 78.1642),
    SacredOrigin.fromCity(cityName: 'Kathmandu', country: 'Nepal', lat: 27.7172, lon: 85.3240),
  ];
}
