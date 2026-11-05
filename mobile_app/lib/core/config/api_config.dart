import 'package:flutter/foundation.dart';

/// Centralized API and networking configuration for the Vedam application.
///
/// Supports compile-time environment injection via:
///   `--dart-define=API_BASE_URL=http://<ip-or-host>:<port>`
///
/// If not explicitly provided, resolves platform-appropriate defaults:
///   - Android Emulator: `http://10.0.2.2:8000`
///   - Flutter Web & Desktop: `http://localhost:8000`
///   - Physical devices / other: `http://localhost:8000`
class ApiConfig {
  ApiConfig._();

  /// Compile-time injected base URL, if provided.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolves the effective base URL for the backend API.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.replaceAll(RegExp(r'/+$'), ''); // trim trailing slashes
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  /// System health check endpoint.
  static String get healthUrl => '$baseUrl/api/v1/health';

  /// Daily panchangam calculation endpoint.
  static String get panchangamDailyUrl => '$baseUrl/api/v1/panchangam/daily';

  /// Curated sacred locations endpoint.
  static String get panchangamLocationsUrl => '$baseUrl/api/v1/panchangam/locations';
}
