import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/heading_model.dart';
import 'package:vedam_app/core/services/compass_service.dart';

void main() {
  group('Phase 22C - HeadingReading Model & Normalization Tests', () {
    test('Degree normalization handles cardinal, intercardinal, negative, and overflow angles', () {
      expect(HeadingReading.normalizeDegrees(0.0), equals(0.0));
      expect(HeadingReading.normalizeDegrees(90.0), equals(90.0));
      expect(HeadingReading.normalizeDegrees(180.0), equals(180.0));
      expect(HeadingReading.normalizeDegrees(270.0), equals(270.0));
      expect(HeadingReading.normalizeDegrees(360.0), equals(0.0));

      // Overflows
      expect(HeadingReading.normalizeDegrees(450.0), equals(90.0));
      expect(HeadingReading.normalizeDegrees(720.0), equals(0.0));
      expect(HeadingReading.normalizeDegrees(360.5), closeTo(0.5, 0.0001));

      // Negative angles
      expect(HeadingReading.normalizeDegrees(-90.0), equals(270.0));
      expect(HeadingReading.normalizeDegrees(-180.0), equals(180.0));
      expect(HeadingReading.normalizeDegrees(-360.0), equals(0.0));
      expect(HeadingReading.normalizeDegrees(-450.0), equals(270.0));
    });

    test('Non-finite, NaN, and null values safely return null without throwing', () {
      expect(HeadingReading.normalizeDegrees(null), isNull);
      expect(HeadingReading.normalizeDegrees(double.nan), isNull);
      expect(HeadingReading.normalizeDegrees(double.infinity), isNull);
      expect(HeadingReading.normalizeDegrees(double.negativeInfinity), isNull);
    });

    test('HeadingReading.active rejects non-finite headings by producing an error reading', () {
      final invalidReading = HeadingReading.active(
        heading: double.nan,
        reference: HeadingReference.magnetic,
      );
      expect(invalidReading.state, equals(HeadingSensorState.error));
      expect(invalidReading.hasValidHeading, isFalse);
      expect(invalidReading.heading, isNull);
    });

    test('HeadingReference correctly distinguishes Magnetic vs True North', () {
      expect(HeadingReference.fromString('MAGNETIC'), equals(HeadingReference.magnetic));
      expect(HeadingReference.fromString('magnetic'), equals(HeadingReference.magnetic));
      expect(HeadingReference.fromString('TRUE'), equals(HeadingReference.trueNorth));
      expect(HeadingReference.fromString('true_north'), equals(HeadingReference.trueNorth));
      expect(HeadingReference.fromString(null), equals(HeadingReference.unknown));
      expect(HeadingReference.fromString('arbitrary'), equals(HeadingReference.unknown));

      expect(HeadingReference.magnetic.label, equals('Magnetic North'));
      expect(HeadingReference.trueNorth.label, equals('True Geographic North'));
    });

    test('HeadingAccuracy parses platform sensor status codes correctly', () {
      expect(HeadingAccuracy.fromCode(3), equals(HeadingAccuracy.high));
      expect(HeadingAccuracy.fromCode(2), equals(HeadingAccuracy.medium));
      expect(HeadingAccuracy.fromCode(1), equals(HeadingAccuracy.low));
      expect(HeadingAccuracy.fromCode(0), equals(HeadingAccuracy.unreliable));
      expect(HeadingAccuracy.fromCode(null), equals(HeadingAccuracy.unknown));
      expect(HeadingAccuracy.fromCode(-1), equals(HeadingAccuracy.unknown));
    });

    test('CRITICAL SAFETY INVARIANT: Relative angle is withheld when reference is MAGNETIC', () {
      final magneticReading = HeadingReading.active(
        heading: 45.0,
        reference: HeadingReference.magnetic,
      );
      // Even with a valid target true bearing, magnetic heading cannot be compared directly
      final relativeAngle = magneticReading.calculateRelativeAngle(targetBearingTrue: 90.0);
      expect(relativeAngle, isNull, reason: 'Magnetic heading must NEVER be directly compared with True North bearing');
    });

    test('Relative angle is computed only when reference is explicitly TRUE_NORTH', () {
      final trueReading = HeadingReading.active(
        heading: 45.0,
        reference: HeadingReference.trueNorth,
      );
      final relativeAngle = trueReading.calculateRelativeAngle(targetBearingTrue: 90.0);
      expect(relativeAngle, isNotNull);
      expect(relativeAngle, closeTo(45.0, 0.001));

      // Target to the left (counterclockwise)
      final leftAngle = trueReading.calculateRelativeAngle(targetBearingTrue: 15.0);
      expect(leftAngle, closeTo(330.0, 0.001)); // 15 - 45 + 360 = 330
    });

    test('Serialization and deserialization roundtrip preserves all heading properties', () {
      final reading = HeadingReading.active(
        heading: 142.5,
        reference: HeadingReference.magnetic,
        accuracy: HeadingAccuracy.high,
        timestamp: DateTime(2026, 11, 10, 10, 0, 0),
        message: 'Calibrated reading',
      );

      final json = reading.toJson();
      final revived = HeadingReading.fromJson(json);

      expect(revived.heading, equals(142.5));
      expect(revived.reference, equals(HeadingReference.magnetic));
      expect(revived.accuracy, equals(HeadingAccuracy.high));
      expect(revived.state, equals(HeadingSensorState.active));
      expect(revived.hasValidHeading, isTrue);
      expect(revived.formattedHeading, equals('142.5° Mag'));
    });
  });

  group('Phase 22C - CompassService Lifecycle & Hardware Decoupling Tests', () {
    late MockCompassSensorProvider mockProvider;
    late CompassService service;

    setUp(() {
      mockProvider = MockCompassSensorProvider(isAvailable: true);
      service = CompassService(provider: mockProvider);
    });

    tearDown(() {
      service.dispose();
      mockProvider.close();
    });

    test('Initial state is inactive with null heading', () {
      expect(service.reading.state, equals(HeadingSensorState.inactive));
      expect(service.reading.hasValidHeading, isFalse);
      expect(service.isActive, isFalse);
    });

    test('Unavailable provider immediately transitions to unavailable state', () async {
      final unavailableProvider = MockCompassSensorProvider(isAvailable: false);
      final unavailableService = CompassService(provider: unavailableProvider);

      await unavailableService.startCompass();

      expect(unavailableService.reading.state, equals(HeadingSensorState.unavailable));
      expect(unavailableService.isActive, isFalse);

      unavailableService.dispose();
      unavailableProvider.close();
    });

    test('startCompass activates sensor stream and processes incoming readings', () async {
      await service.startCompass();

      // Emit reading
      mockProvider.emitReading(heading: 120.0, reference: 'MAGNETIC', accuracy: 3);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.isActive, isTrue);
      expect(service.reading.state, equals(HeadingSensorState.active));
      expect(service.reading.heading, equals(120.0));
      expect(service.reading.reference, equals(HeadingReference.magnetic));
      expect(service.reading.accuracy, equals(HeadingAccuracy.high));
    });

    test('Duplicate startCompass calls do not create duplicate subscriptions', () async {
      await service.startCompass();
      await service.startCompass(); // Second call should be a no-op

      mockProvider.emitReading(heading: 85.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.reading.heading, equals(85.0));
    });

    test('stopCompass immediately unsubscribes and resets state to inactive', () async {
      await service.startCompass();
      mockProvider.emitReading(heading: 200.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.isActive, isTrue);

      service.stopCompass();

      expect(service.isActive, isFalse);
      expect(service.reading.state, equals(HeadingSensorState.inactive));
      expect(service.reading.hasValidHeading, isFalse);

      // Emitting data after stop should NOT update service
      mockProvider.emitReading(heading: 250.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.reading.state, equals(HeadingSensorState.inactive));
    });

    test('Low accuracy sensor event transitions reading to lowAccuracy state', () async {
      await service.startCompass();

      mockProvider.emitReading(heading: 180.0, accuracy: 1); // Low accuracy code
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.reading.state, equals(HeadingSensorState.lowAccuracy));
      expect(service.reading.accuracy, equals(HeadingAccuracy.low));
      expect(service.reading.hasValidHeading, isTrue);
    });

    test('PlatformException for permission denied transitions to permissionDenied state', () async {
      await service.startCompass();

      mockProvider.emitError(PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'Orientation sensor permission was denied',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.reading.state, equals(HeadingSensorState.permissionDenied));
      expect(service.reading.hasValidHeading, isFalse);
    });

    test('pauseCompass stops sensor stream and resumeCompass restarts it', () async {
      await service.startCompass();
      mockProvider.emitReading(heading: 90.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.isActive, isTrue);

      // Pause (e.g. app backgrounded)
      service.pauseCompass();
      expect(service.isActive, isFalse);
      expect(service.reading.state, equals(HeadingSensorState.inactive));

      // Resume (app returned to foreground)
      await service.resumeCompass();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      mockProvider.emitReading(heading: 95.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.isActive, isTrue);
      expect(service.reading.heading, equals(95.0));
    });

    test('No heading history is retained: service only stores latest point-in-time reading', () async {
      await service.startCompass();

      for (int i = 0; i < 20; i++) {
        mockProvider.emitReading(heading: (i * 10.0) % 360.0);
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }

      // Final reading reflects only the last value
      expect(service.reading.heading, equals(190.0));
    });
  });
}
