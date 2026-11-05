import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/config/api_config.dart';

void main() {
  group('ApiConfig Tests', () {
    test('ApiConfig provides well-formed default base URL and endpoints', () {
      final baseUrl = ApiConfig.baseUrl;
      expect(baseUrl.isNotEmpty, true);
      expect(baseUrl.startsWith('http://'), true);

      expect(ApiConfig.healthUrl, equals('$baseUrl/api/v1/health'));
      expect(ApiConfig.panchangamDailyUrl, equals('$baseUrl/api/v1/panchangam/daily'));
      expect(ApiConfig.panchangamLocationsUrl, equals('$baseUrl/api/v1/panchangam/locations'));
    });

    test('ApiConfig endpoints do not contain duplicate consecutive slashes', () {
      expect(ApiConfig.healthUrl.contains('//api'), false);
      expect(ApiConfig.panchangamDailyUrl.contains('//api'), false);
      expect(ApiConfig.panchangamLocationsUrl.contains('//api'), false);
    });
  });
}
