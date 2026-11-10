import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/bearing_result.dart';
import 'package:vedam_app/core/models/corrected_heading_reading.dart';
import 'package:vedam_app/core/models/declination_model.dart';
import 'package:vedam_app/core/models/geographic_coordinate.dart';
import 'package:vedam_app/core/models/heading_model.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/services/geomagnetic_declination_service.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

void main() {
  group('Phase 22D — Geomagnetic Model & WMM Reference Verification', () {
    const service = GeomagneticDeclinationService();

    test('1. WMM-2025 calculates official NOAA reference points with high precision', () {
      // Space Needle, Seattle, WA (Date: 2025.25, Alt: 0 km)
      final seattleOrigin = SacredOrigin.fromManualCoordinate(
        label: 'Seattle',
        lat: 47.6205,
        lon: -122.3493,
      );
      final seattleRes = service.calculateDeclination(
        origin: seattleOrigin,
        date: DateTime(2025, 4, 2), // approx 2025.25
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(seattleRes.isValid, isTrue);
      expect(seattleRes.declinationDegrees, closeTo(15.0656, 0.05));
      expect(seattleRes.modelName, 'WMM-2025');
      expect(seattleRes.horizontalIntensityNt, closeTo(19065.1, 100.0));
      expect(seattleRes.estimatedUncertaintyDegrees, closeTo(0.385, 0.05));

      // Equator (Date: 2025.0, Alt: 0 km)
      final eqOrigin = SacredOrigin.fromManualCoordinate(label: 'Equator', lat: 0.0, lon: 0.0);
      final eqRes = service.calculateDeclination(
        origin: eqOrigin,
        date: DateTime(2025, 1, 1),
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(eqRes.isValid, isTrue);
      expect(eqRes.declinationDegrees, closeTo(-4.0162, 0.05)); // West-negative

      // High Latitude benchmark (Lat: -80, Lon: 240 -> -120, Alt: 100 km, Date: 2025.0)
      final highLatOrigin = SacredOrigin.fromManualCoordinate(label: 'HighLat', lat: -80.0, lon: -120.0);
      final highLatRes = service.calculateDeclination(
        origin: highLatOrigin,
        altitudeKm: 100.0,
        date: DateTime(2025, 1, 1),
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(highLatRes.isValid, isTrue);
      expect(highLatRes.declinationDegrees, closeTo(68.2137, 0.1));

      // Greenwich, London (Date: 2026.0, Alt: 0 km)
      final greenwichOrigin = SacredOrigin.fromManualCoordinate(label: 'Greenwich', lat: 51.5074, lon: -0.1278);
      final greenwichRes = service.calculateDeclination(
        origin: greenwichOrigin,
        date: DateTime(2026, 1, 1),
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(greenwichRes.isValid, isTrue);
      expect(greenwichRes.declinationDegrees, closeTo(1.0768, 0.05));
    });

    test('2. WMM-2025 declination calculations across canonical Indian cities match scientific expectation', () {
      final date2026 = DateTime(2026, 11, 10);

      // Varanasi (Lat: 25.3176, Lon: 82.9739)
      final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
      final vRes = service.calculateDeclination(origin: varanasi, date: date2026);
      expect(vRes.isValid, isTrue);
      expect(vRes.declinationDegrees, closeTo(0.3269, 0.05));
      expect(vRes.formattedDeclination, contains('+'));
      expect(vRes.formattedDeclination, contains('E'));

      // New Delhi (Lat: 28.6139, Lon: 77.2090)
      final delhi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('New Delhi'));
      final dRes = service.calculateDeclination(origin: delhi, date: date2026);
      expect(dRes.isValid, isTrue);
      expect(dRes.declinationDegrees, closeTo(1.3303, 0.05));
      expect(dRes.formattedDeclination, contains('+1.3° E'));

      // Mumbai (Lat: 19.0760, Lon: 72.8777) - Near Agonic line
      final mumbai = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Mumbai'));
      final mRes = service.calculateDeclination(origin: mumbai, date: date2026);
      expect(mRes.isValid, isTrue);
      expect(mRes.declinationDegrees, closeTo(-0.0100, 0.05));

      // Bengaluru (Lat: 12.9716, Lon: 77.5946)
      final blr = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Bengaluru'));
      final bRes = service.calculateDeclination(origin: blr, date: date2026);
      expect(bRes.isValid, isTrue);
      expect(bRes.declinationDegrees, closeTo(-1.0721, 0.05));
      expect(bRes.formattedDeclination, contains('-'));
      expect(bRes.formattedDeclination, contains('W'));

      // Chennai (Lat: 13.0827, Lon: 80.2707)
      final chennai = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Chennai'));
      final cRes = service.calculateDeclination(origin: chennai, date: date2026);
      expect(cRes.isValid, isTrue);
      expect(cRes.declinationDegrees, closeTo(-1.0685, 0.05));
    });

    test('3. WMM-2020 historical model support validates historical benchmark vectors', () {
      final eqOrigin = SacredOrigin.fromManualCoordinate(label: 'Equator', lat: 0.0, lon: 0.0);
      final eq2020 = service.calculateDeclination(
        origin: eqOrigin,
        date: DateTime(2020, 1, 1),
        modelType: GeomagneticModelType.wmm2020,
      );
      expect(eq2020.isValid, isTrue);
      expect(eq2020.declinationDegrees, closeTo(-4.6683, 0.05));
      expect(eq2020.horizontalIntensityNt, closeTo(27628.0, 100.0));
    });

    test('4. Date boundary validation and model expiration safeguards', () {
      final origin = SacredOrigin.canonicalCities.first;

      // Date before 2025 for WMM-2025
      final pastRes = service.calculateDeclination(
        origin: origin,
        date: DateTime(2024, 6, 1),
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(pastRes.isValid, isFalse);
      expect(pastRes.status, DeclinationStatus.modelExpired);
      expect(pastRes.declinationDegrees, isNull);

      // Date after 2030 for WMM-2025
      final futureRes = service.calculateDeclination(
        origin: origin,
        date: DateTime(2031, 1, 1),
        modelType: GeomagneticModelType.wmm2025,
      );
      expect(futureRes.isValid, isFalse);
      expect(futureRes.status, DeclinationStatus.modelExpired);
      expect(futureRes.declinationDegrees, isNull);
    });

    test('5. Rejection of invalid coordinates and non-finite inputs', () {
      // Latitude > 90 throws ArgumentError at coordinate construction boundary
      expect(
        () => SacredOrigin.fromManualCoordinate(label: 'North of Pole', lat: 95.0, lon: 0.0),
        throwsArgumentError,
      );

      // Latitude < -90 throws ArgumentError
      expect(
        () => SacredOrigin.fromManualCoordinate(label: 'South of Pole', lat: -95.0, lon: 0.0),
        throwsArgumentError,
      );

      // Longitude > 180 throws ArgumentError
      expect(
        () => SacredOrigin.fromManualCoordinate(label: 'Invalid Lon', lat: 20.0, lon: 400.0),
        throwsArgumentError,
      );

      // NaN latitude throws ArgumentError
      expect(
        () => SacredOrigin.fromManualCoordinate(label: 'NaN', lat: double.nan, lon: 0.0),
        throwsArgumentError,
      );

      // Infinity latitude throws ArgumentError
      expect(
        () => SacredOrigin.fromManualCoordinate(label: 'Inf', lat: double.infinity, lon: 0.0),
        throwsArgumentError,
      );
    });

    test('6. Altitude fallback handling: unknown altitude defaults to 0.0 km transparently', () {
      final origin = SacredOrigin.canonicalCities.first;
      final fixedDate = DateTime(2026, 11, 10, 12, 0);
      final resNoAlt = service.calculateDeclination(origin: origin, altitudeKm: null, date: fixedDate);
      final resZeroAlt = service.calculateDeclination(origin: origin, altitudeKm: 0.0, date: fixedDate);

      expect(resNoAlt.isValid, isTrue);
      expect(resNoAlt.altitudeKm, 0.0);
      expect(resNoAlt.declinationDegrees, equals(resZeroAlt.declinationDegrees));
    });
  });

  group('Phase 22D — Heading Correction Engine Tests', () {
    final testOrigin = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('New Delhi'));
    final testDeclination = DeclinationResult.valid(
      declinationDegrees: 1.5,
      modelType: GeomagneticModelType.wmm2025,
      timestamp: DateTime(2026, 11, 10),
      decimalYear: 2026.86,
      origin: testOrigin,
    );

    test('1. Magnetic heading plus east-positive declination computes True Heading', () {
      final raw = HeadingReading.active(
        heading: 30.0,
        reference: HeadingReference.magnetic,
      );
      final corrected = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw,
        declination: testDeclination,
        expectedOrigin: testOrigin,
      );
      expect(corrected.isAvailable, isTrue);
      expect(corrected.trueHeading, closeTo(31.5, 0.001));
      expect(corrected.formattedTrueHeading, '31.5° True');
      expect(corrected.formattedMagneticHeading, '30.0° Mag');
    });

    test('2. Magnetic heading plus west-negative declination computes True Heading', () {
      final westDeclination = DeclinationResult.valid(
        declinationDegrees: -2.0,
        modelType: GeomagneticModelType.wmm2025,
        timestamp: DateTime(2026, 11, 10),
        decimalYear: 2026.86,
        origin: testOrigin,
      );
      final raw = HeadingReading.active(
        heading: 45.0,
        reference: HeadingReference.magnetic,
      );
      final corrected = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw,
        declination: westDeclination,
        expectedOrigin: testOrigin,
      );
      expect(corrected.isAvailable, isTrue);
      expect(corrected.trueHeading, closeTo(43.0, 0.001));
    });

    test('3. 0°/360° boundary wraparound and negative degree wraparound', () {
      // 359° + 2° = 361° -> 1°
      final raw1 = HeadingReading.active(heading: 359.0, reference: HeadingReference.magnetic);
      final decl1 = DeclinationResult.valid(
        declinationDegrees: 2.0,
        modelType: GeomagneticModelType.wmm2025,
        timestamp: DateTime.now(),
        decimalYear: 2026.86,
        origin: testOrigin,
      );
      final corr1 = CorrectedHeadingReading.fromReadingAndDeclination(raw: raw1, declination: decl1);
      expect(corr1.trueHeading, closeTo(1.0, 0.001));

      // 1° + (-3°) = -2° -> 358°
      final raw2 = HeadingReading.active(heading: 1.0, reference: HeadingReference.magnetic);
      final decl2 = DeclinationResult.valid(
        declinationDegrees: -3.0,
        modelType: GeomagneticModelType.wmm2025,
        timestamp: DateTime.now(),
        decimalYear: 2026.86,
        origin: testOrigin,
      );
      final corr2 = CorrectedHeadingReading.fromReadingAndDeclination(raw: raw2, declination: decl2);
      expect(corr2.trueHeading, closeTo(358.0, 0.001));
    });

    test('4. Stale or unreliable sensor reading safely withholds True Heading', () {
      final rawStale = HeadingReading.stale(
        previous: HeadingReading.active(heading: 120.0, reference: HeadingReference.magnetic),
      );
      final corrStale = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: rawStale,
        declination: testDeclination,
      );
      expect(corrStale.isAvailable, isFalse);
      expect(corrStale.trueHeading, isNull);
      expect(corrStale.unavailabilityReason, contains('stale'));

      final rawUnreliable = HeadingReading.active(
        heading: 120.0,
        reference: HeadingReference.magnetic,
        accuracy: HeadingAccuracy.unreliable,
      );
      final corrUnreliable = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: rawUnreliable,
        declination: testDeclination,
      );
      expect(corrUnreliable.isAvailable, isFalse);
      expect(corrUnreliable.trueHeading, isNull);
      expect(corrUnreliable.unavailabilityReason, contains('unreliable'));
    });

    test('5. Missing or invalid declination safely withholds True Heading while preserving raw sensor reading', () {
      final raw = HeadingReading.active(heading: 120.0, reference: HeadingReference.magnetic);
      final corrNoDecl = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw,
        declination: null,
      );
      expect(corrNoDecl.isAvailable, isFalse);
      expect(corrNoDecl.trueHeading, isNull);
      expect(corrNoDecl.rawReading.heading, 120.0);
      expect(corrNoDecl.formattedMagneticHeading, '120.0° Mag');
    });

    test('6. Explicit proof that uncorrected magnetic readings cannot be used as True Headings', () {
      final raw = HeadingReading.active(heading: 90.0, reference: HeadingReference.magnetic);
      // Directly querying raw reading relative angle withholds calculation
      expect(raw.calculateRelativeAngle(targetBearingTrue: 100.0), isNull);
    });
  });

  group('Phase 22D — Origin Consistency & Privacy Tests', () {
    test('1. Each of the 13 canonical cities retains its gazetteer and ±15 km uncertainty', () {
      expect(SacredOrigin.canonicalCities.length, 13);
      for (final city in SacredOrigin.canonicalCities) {
        expect(city.isApproximate, isTrue);
        expect(city.accuracyRadiusKm, 15.0);
        expect(city.sourceGazetteer, isNotEmpty);
        expect(city.provenance, contains('Approximate'));
      }
    });

    test('2. Manual coordinate origin preserves user-specified status and label', () {
      final manual = SacredOrigin.fromManualCoordinate(label: 'Custom Hermitage', lat: 30.12, lon: 78.34);
      expect(manual.isApproximate, isFalse);
      expect(manual.accuracyRadiusKm, 0.0);
      expect(manual.name, 'Custom Hermitage');
      expect(manual.type, OriginType.manualCoordinate);
    });

    test('3. State origin changes invalidate old declination and recalculate for new origin', () {
      final state = DivyaDishiState();
      expect(state.selectedOrigin, isNull);
      expect(state.currentDeclination, isNull);

      final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
      state.setOrigin(varanasi);
      expect(state.selectedOrigin?.name, varanasi.name);
      expect(state.currentDeclination, isNotNull);
      expect(state.currentDeclination?.origin.name, varanasi.name);
      expect(state.currentDeclination?.declinationDegrees, closeTo(0.33, 0.05));

      final chennai = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Chennai'));
      state.setOrigin(chennai);
      expect(state.selectedOrigin?.name, chennai.name);
      expect(state.currentDeclination?.origin.name, chennai.name);
      expect(state.currentDeclination?.declinationDegrees, closeTo(-1.07, 0.05));

      state.setOrigin(null);
      expect(state.selectedOrigin, isNull);
      expect(state.currentDeclination, isNull);
    });
  });

  group('Phase 22D — Relative Sacred Alignment Safeguards & Math Tests', () {
    final originVaranasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
    final declVaranasi = DeclinationResult.valid(
      declinationDegrees: 0.33,
      modelType: GeomagneticModelType.wmm2025,
      timestamp: DateTime.now(),
      decimalYear: 2026.86,
      origin: originVaranasi,
    );

    // Kashi Vishwanath temple fixture
    final kashiTemple = Temple(
      id: 'kashi_vishwanath',
      name: 'Kashi Vishwanath',
      deity: 'Shiva',
      tradition: TempleTradition.shaivism,
      city: 'Varanasi',
      state: 'Uttar Pradesh',
      country: 'India',
      coordinate: GeographicCoordinate(25.3109, 83.0107),
      verificationStatus: CoordinateVerificationStatus.pendingVerification,
      pointType: CoordinatePointType.compoundCenter,
      sourceName: 'User-Supplied Research Ledger',
      confidenceLevel: 'Provisional Compound Center',
      significance: 'One of the twelve Jyotirlingas.',
    );

    test('1. Shortest signed angular difference calculation covers clockwise, counter-clockwise, and 0/360 boundary', () {
      final bearing = BearingResult.calculated(degrees: 100.0, distanceKm: 50.0);

      // Facing 80° True -> Temple is 100° True -> Turn +20° Clockwise
      final raw1 = HeadingReading.active(heading: 79.67, reference: HeadingReference.magnetic);
      final corr1 = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw1,
        declination: declVaranasi,
        expectedOrigin: originVaranasi,
      );
      expect(corr1.trueHeading, closeTo(80.0, 0.01));

      final align1 = RelativeSacredAlignment.evaluate(
        correctedHeading: corr1,
        targetBearing: bearing,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: true,
      );
      expect(align1.turnAngleDegrees, closeTo(20.0, 0.01));
      expect(align1.formattedGuidance, 'Turn 20° Right (Clockwise)');

      // Facing 140° True -> Temple is 100° True -> Turn -40° Counter-Clockwise
      final raw2 = HeadingReading.active(heading: 139.67, reference: HeadingReference.magnetic);
      final corr2 = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw2,
        declination: declVaranasi,
        expectedOrigin: originVaranasi,
      );
      final align2 = RelativeSacredAlignment.evaluate(
        correctedHeading: corr2,
        targetBearing: bearing,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: true,
      );
      expect(align2.turnAngleDegrees, closeTo(-40.0, 0.01));
      expect(align2.formattedGuidance, 'Turn 40° Left (Counter-Clockwise)');

      // 0/360 Boundary: Facing 350° True -> Temple is 10° True -> Turn +20° Clockwise
      final bearingNorth = BearingResult.calculated(degrees: 10.0, distanceKm: 50.0);
      final raw3 = HeadingReading.active(heading: 349.67, reference: HeadingReference.magnetic);
      final corr3 = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw3,
        declination: declVaranasi,
        expectedOrigin: originVaranasi,
      );
      final align3 = RelativeSacredAlignment.evaluate(
        correctedHeading: corr3,
        targetBearing: bearingNorth,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: true,
      );
      expect(align3.turnAngleDegrees, closeTo(20.0, 0.01));

      // Aligned within ±5°
      final raw4 = HeadingReading.active(heading: 8.67, reference: HeadingReference.magnetic);
      final corr4 = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw4,
        declination: declVaranasi,
        expectedOrigin: originVaranasi,
      );
      final align4 = RelativeSacredAlignment.evaluate(
        correctedHeading: corr4,
        targetBearing: bearingNorth,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: true,
      );
      expect(align4.formattedGuidance, 'Facing Sacred Direction (±5°)');
    });

    test('2. Provisional destination safeguard: pending temple destination withholds turn guidance by default', () {
      final bearing = BearingResult.calculated(degrees: 100.0, distanceKm: 50.0);
      final raw = HeadingReading.active(heading: 79.67, reference: HeadingReference.magnetic);
      final corr = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw,
        declination: declVaranasi,
        expectedOrigin: originVaranasi,
      );

      // Default evaluation without userOptedIn
      final alignDefault = RelativeSacredAlignment.evaluate(
        correctedHeading: corr,
        targetBearing: bearing,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: false,
      );
      expect(alignDefault.turnAngleDegrees, isNull);
      expect(alignDefault.quality, RelativeAlignmentQuality.withheldDestinationUnverified);
      expect(alignDefault.qualityNotice, contains('withheld'));
      expect(alignDefault.dualUncertaintyDisclaimer, contains('provisional'));

      // Opted-in evaluation
      final alignOptedIn = RelativeSacredAlignment.evaluate(
        correctedHeading: corr,
        targetBearing: bearing,
        targetTemple: kashiTemple,
        currentOrigin: originVaranasi,
        userOptedIn: true,
      );
      expect(alignOptedIn.turnAngleDegrees, isNotNull);
      expect(alignOptedIn.quality, RelativeAlignmentQuality.approximateComparisonAvailable);
      expect(alignOptedIn.qualityNotice, 'APPROXIMATE TEMPLE-COMPLEX ALIGNMENT');
    });

    test('3. Rejection on mismatched origin between declination and bearing', () {
      final bearing = BearingResult.calculated(degrees: 100.0, distanceKm: 50.0);
      final raw = HeadingReading.active(heading: 80.0, reference: HeadingReference.magnetic);
      final originChennai = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Chennai'));

      // Heading corrected with Varanasi declination, but current origin set to Chennai
      final corr = CorrectedHeadingReading.fromReadingAndDeclination(
        raw: raw,
        declination: declVaranasi,
      );
      final align = RelativeSacredAlignment.evaluate(
        correctedHeading: corr,
        targetBearing: bearing,
        targetTemple: kashiTemple,
        currentOrigin: originChennai,
      );
      expect(align.turnAngleDegrees, isNull);
      expect(align.quality, RelativeAlignmentQuality.originMismatch);
    });
  });
}
