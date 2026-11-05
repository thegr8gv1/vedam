import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/models/panchangam_data.dart';

class PanchangamUnavailableException implements Exception {
  final String message;
  final String details;

  const PanchangamUnavailableException({
    required this.message,
    required this.details,
  });

  @override
  String toString() => '$message: $details';
}

abstract class PanchangamRepository {
  Future<DailyPanchangamData> getDailyPanchangam({
    required DateTime date,
    required PanchangamLocation location,
    String ayanamsa = 'lahiri',
  });

  Future<List<PanchangamLocation>> getCuratedLocations({String? query});
}

class PanchangamRepositoryImpl implements PanchangamRepository {
  final http.Client _client;
  final String _baseUrl;

  PanchangamRepositoryImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    // In Flutter web or local dev, port 8000 is default
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator loops back to host via 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  @override
  Future<DailyPanchangamData> getDailyPanchangam({
    required DateTime date,
    required PanchangamLocation location,
    String ayanamsa = 'lahiri',
  }) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('$_baseUrl/api/v1/panchangam/daily').replace(
      queryParameters: {
        'date': dateStr,
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'name': location.name,
        'timezone': location.timezone,
        'ayanamsa': ayanamsa,
      },
    );

    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return DailyPanchangamData.fromJson(body);
      } else {
        throw PanchangamUnavailableException(
          message: 'Panchangam Calculation Server Error (${response.statusCode})',
          details: response.body,
        );
      }
    } catch (e) {
      if (e is PanchangamUnavailableException) rethrow;
      throw PanchangamUnavailableException(
        message: 'Astronomical Engine Unavailable',
        details: 'Unable to connect to Vedam calculation service at $_baseUrl. '
            'In adherence to Section 8 authenticity rules, Vedam does not display '
            'conjectural or fabricated planetary values. Please ensure the backend engine is running.',
      );
    }
  }

  @override
  Future<List<PanchangamLocation>> getCuratedLocations({String? query}) async {
    // Try online endpoint first
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/panchangam/locations').replace(
        queryParameters: query != null && query.isNotEmpty ? {'query': query} : null,
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => PanchangamLocation.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback to static bundled curated catalog if network is down
    }

    final catalog = _curatedFallbackLocations;
    if (query == null || query.isEmpty) return catalog;
    final q = query.toLowerCase();
    return catalog.where((loc) => loc.name.toLowerCase().contains(q)).toList();
  }

  static const List<PanchangamLocation> _curatedFallbackLocations = [
    PanchangamLocation(
      name: 'Varanasi (Kashi), UP, India',
      latitude: 25.3176,
      longitude: 82.9739,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 80.0,
    ),
    PanchangamLocation(
      name: 'Ayodhya, UP, India',
      latitude: 26.7922,
      longitude: 82.1998,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 102.0,
    ),
    PanchangamLocation(
      name: 'Tirupati (Tirumala), AP, India',
      latitude: 13.6833,
      longitude: 79.3500,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 853.0,
    ),
    PanchangamLocation(
      name: 'Ujjain (Mahakaleshwar), MP, India',
      latitude: 23.1765,
      longitude: 75.7885,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 494.0,
    ),
    PanchangamLocation(
      name: 'Rameswaram, TN, India',
      latitude: 9.2876,
      longitude: 79.3129,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 10.0,
    ),
    PanchangamLocation(
      name: 'Haridwar, Uttarakhand, India',
      latitude: 29.9457,
      longitude: 78.1642,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 314.0,
    ),
    PanchangamLocation(
      name: 'Kanchipuram, TN, India',
      latitude: 12.8342,
      longitude: 79.7036,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 83.0,
    ),
    PanchangamLocation(
      name: 'Puri (Jagannath), Odisha, India',
      latitude: 19.8135,
      longitude: 85.8312,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 15.0,
    ),
    PanchangamLocation(
      name: 'Chennai, Tamil Nadu, India',
      latitude: 13.0827,
      longitude: 80.2707,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 6.0,
    ),
    PanchangamLocation(
      name: 'Bengaluru, Karnataka, India',
      latitude: 12.9716,
      longitude: 77.5946,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 920.0,
    ),
    PanchangamLocation(
      name: 'Mumbai, Maharashtra, India',
      latitude: 19.0760,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 14.0,
    ),
    PanchangamLocation(
      name: 'New Delhi, Delhi, India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 'Asia/Kolkata',
      altitudeMeters: 216.0,
    ),
    PanchangamLocation(
      name: 'New York, NY, USA',
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: 'America/New_York',
      altitudeMeters: 10.0,
    ),
    PanchangamLocation(
      name: 'London, England, UK',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
      altitudeMeters: 25.0,
    ),
  ];
}
