/// Represents a validated geodetic coordinate pair (latitude, longitude) on the WGS 84 ellipsoid.
class GeographicCoordinate {
  final double latitude;
  final double longitude;

  /// Creates a validated GeographicCoordinate.
  /// Throws [ArgumentError] if latitude is outside [-90.0, 90.0] or longitude is outside [-180.0, 180.0],
  /// or if either value is not a finite number (NaN / Infinity).
  GeographicCoordinate(this.latitude, this.longitude) {
    if (!latitude.isFinite) {
      throw ArgumentError.value(latitude, 'latitude', 'Latitude must be a finite number');
    }
    if (!longitude.isFinite) {
      throw ArgumentError.value(longitude, 'longitude', 'Longitude must be a finite number');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError.value(latitude, 'latitude', 'Latitude must be between -90.0 and 90.0 degrees');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError.value(longitude, 'longitude', 'Longitude must be between -180.0 and 180.0 degrees');
    }
  }

  /// Creates a GeographicCoordinate from string representations. Returns null if invalid or malformed.
  static GeographicCoordinate? tryParse(String latStr, String lonStr) {
    final lat = double.tryParse(latStr.trim());
    final lon = double.tryParse(lonStr.trim());
    if (lat == null || lon == null) return null;
    try {
      return GeographicCoordinate(lat, lon);
    } catch (_) {
      return null;
    }
  }

  /// Formatted decimal string, e.g. "13.6833° N, 79.3472° E".
  String get formatted {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lonDir';
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory GeographicCoordinate.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    return GeographicCoordinate(lat, lon);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeographicCoordinate &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-7 &&
          (longitude - other.longitude).abs() < 1e-7;

  @override
  int get hashCode => Object.hash(
        (latitude * 10000000).round(),
        (longitude * 10000000).round(),
      );

  @override
  String toString() => 'GeographicCoordinate($formatted)';
}
