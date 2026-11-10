import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/geographic_coordinate.dart';
import 'package:vedam_app/core/services/geographic_bearing_calculator.dart';

void main() {
  group('GeographicCoordinate Validation Tests', () {
    test('Valid coordinates within bounds instantiate successfully', () {
      final coord = GeographicCoordinate(25.3176, 82.9739); // Varanasi
      expect(coord.latitude, closeTo(25.3176, 1e-4));
      expect(coord.longitude, closeTo(82.9739, 1e-4));
      expect(coord.formatted, contains('25.3176° N'));
      expect(coord.formatted, contains('82.9739° E'));
    });

    test('Latitude outside [-90, 90] throws ArgumentError', () {
      expect(() => GeographicCoordinate(90.1, 0.0), throwsArgumentError);
      expect(() => GeographicCoordinate(-90.1, 0.0), throwsArgumentError);
    });

    test('Longitude outside [-180, 180] throws ArgumentError', () {
      expect(() => GeographicCoordinate(0.0, 180.1), throwsArgumentError);
      expect(() => GeographicCoordinate(0.0, -180.1), throwsArgumentError);
    });

    test('Non-finite numbers (NaN, Infinity) throw ArgumentError', () {
      expect(() => GeographicCoordinate(double.nan, 0.0), throwsArgumentError);
      expect(() => GeographicCoordinate(0.0, double.infinity), throwsArgumentError);
      expect(() => GeographicCoordinate(double.negativeInfinity, 0.0), throwsArgumentError);
    });

    test('tryParse parses valid strings and returns null on invalid strings', () {
      final valid = GeographicCoordinate.tryParse('13.6833', '79.3472');
      expect(valid, isNotNull);
      expect(valid!.latitude, closeTo(13.6833, 1e-4));

      expect(GeographicCoordinate.tryParse('abc', '79.3472'), isNull);
      expect(GeographicCoordinate.tryParse('13.6833', 'def'), isNull);
      expect(GeographicCoordinate.tryParse('95.0', '0.0'), isNull);
    });

    test('JSON serialization and deserialization roundtrip', () {
      final original = GeographicCoordinate(27.7172, 85.3240); // Kathmandu
      final json = original.toJson();
      final revived = GeographicCoordinate.fromJson(json);

      expect(revived.latitude, equals(original.latitude));
      expect(revived.longitude, equals(original.longitude));
      expect(revived, equals(original));
    });
  });

  group('GeographicBearingCalculator Mathematics & Direction Resolution', () {
    const calc = GeographicBearingCalculator();

    test('Due North: Origin on Equator to North Pole', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(50.0, 0.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(0.0, 0.1));
      expect(result.cardinalDirection, equals('N'));
      expect(result.sanskritDirection, equals('Uttara'));
      expect(result.dikpala, equals('Kubera'));
    });

    test('Due East: Origin on Equator to East point', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(0.0, 50.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(90.0, 0.1));
      expect(result.cardinalDirection, equals('E'));
      expect(result.sanskritDirection, equals('Purva'));
      expect(result.dikpala, equals('Indra'));
    });

    test('Due South: Origin on Equator to South point', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(-50.0, 0.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(180.0, 0.1));
      expect(result.cardinalDirection, equals('S'));
      expect(result.sanskritDirection, equals('Dakshina'));
      expect(result.dikpala, equals('Yama'));
    });

    test('Due West: Origin on Equator to West point', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(0.0, -50.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(270.0, 0.1));
      expect(result.cardinalDirection, equals('W'));
      expect(result.sanskritDirection, equals('Pashchima'));
      expect(result.dikpala, equals('Varuna'));
    });

    test('Intercardinal NE: ~45 degrees resolves to Ishanya / Ishana', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(40.0, 40.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, greaterThan(22.5));
      expect(result.degrees, lessThan(67.5));
      expect(result.cardinalDirection, equals('NE'));
      expect(result.sanskritDirection, equals('Ishanya'));
      expect(result.dikpala, equals('Ishana'));
    });

    test('Intercardinal SE: ~135 degrees resolves to Agneya / Agni', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(-40.0, 40.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, greaterThan(112.5));
      expect(result.degrees, lessThan(157.5));
      expect(result.cardinalDirection, equals('SE'));
      expect(result.sanskritDirection, equals('Agneya'));
      expect(result.dikpala, equals('Agni'));
    });

    test('Intercardinal SW: ~225 degrees resolves to Nairruti / Nirrti', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(-40.0, -40.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, greaterThan(202.5));
      expect(result.degrees, lessThan(247.5));
      expect(result.cardinalDirection, equals('SW'));
      expect(result.sanskritDirection, equals('Nairruti'));
      expect(result.dikpala, equals('Nirrti'));
    });

    test('Intercardinal NW: ~315 degrees resolves to Vayavya / Vayu', () {
      final origin = GeographicCoordinate(0.0, 0.0);
      final dest = GeographicCoordinate(40.0, -40.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, greaterThan(292.5));
      expect(result.degrees, lessThan(337.5));
      expect(result.cardinalDirection, equals('NW'));
      expect(result.sanskritDirection, equals('Vayavya'));
      expect(result.dikpala, equals('Vayu'));
    });
  });

  group('GeographicBearingCalculator Robustness & Edge Cases', () {
    const calc = GeographicBearingCalculator();

    test('Identical origin and destination coordinates yield unavailable bearing', () {
      final point = GeographicCoordinate(25.3176, 82.9739);
      final result = calc.calculateBearing(origin: point, destination: point);

      expect(result.isAvailable, isFalse);
      expect(result.degrees, isNull);
      expect(result.unavailabilityReason, contains('identical'));
    });

    test('Coincident sub-meter points yield unavailable bearing', () {
      final origin = GeographicCoordinate(25.3176000, 82.9739000);
      final dest = GeographicCoordinate(25.31760005, 82.97390005);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isFalse);
      expect(result.unavailabilityReason, isNotNull);
    });

    test('Antimeridian / 180° meridian crossing selects shortest great-circle path', () {
      // 179° E to -179° (179° W) near equator: shortest path is East (2° apart = ~222 km), NOT West (358° apart)
      final origin = GeographicCoordinate(0.0, 179.0);
      final dest = GeographicCoordinate(0.0, -179.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(90.0, 0.1)); // Heading East
      expect(result.cardinalDirection, equals('E'));
      expect(result.distanceKm, closeTo(222.4, 1.0));
    });

    test('Antimeridian crossing in reverse direction heads West', () {
      final origin = GeographicCoordinate(0.0, -179.0);
      final dest = GeographicCoordinate(0.0, 179.0);
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.degrees, closeTo(270.0, 0.1)); // Heading West
      expect(result.cardinalDirection, equals('W'));
      expect(result.distanceKm, closeTo(222.4, 1.0));
    });

    test('Real-world calculation: Varanasi to Kashi Vishwanath (< 4 km)', () {
      final origin = GeographicCoordinate(25.3176, 82.9739); // Approx Varanasi center
      final dest = GeographicCoordinate(25.3109, 83.0107); // Kashi Vishwanath
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.distanceKm, lessThan(10.0));
      expect(result.degrees, greaterThan(80.0));
      expect(result.degrees, lessThan(115.0));
      expect(result.cardinalDirection, equals('E'));
      expect(result.sanskritDirection, equals('Purva'));
    });

    test('Real-world calculation: New Delhi to Somnath Temple', () {
      final origin = GeographicCoordinate(28.6139, 77.2090); // New Delhi
      final dest = GeographicCoordinate(20.8880, 70.4012); // Somnath
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.distanceKm, greaterThan(900.0));
      expect(result.distanceKm, lessThan(1200.0));
      expect(result.cardinalDirection, equals('SW'));
      expect(result.sanskritDirection, equals('Nairruti'));
    });

    test('Real-world calculation: Bengaluru to Kedarnath', () {
      final origin = GeographicCoordinate(12.9716, 77.5946); // Bengaluru
      final dest = GeographicCoordinate(30.7352, 79.0669); // Kedarnath
      final result = calc.calculateBearing(origin: origin, destination: dest);

      expect(result.isAvailable, isTrue);
      expect(result.distanceKm, greaterThan(1900.0));
      expect(result.distanceKm, lessThan(2100.0));
      expect(result.cardinalDirection, equals('N'));
      expect(result.sanskritDirection, equals('Uttara'));
    });
  });
}
