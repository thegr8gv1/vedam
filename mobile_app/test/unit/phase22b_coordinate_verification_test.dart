import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/geographic_coordinate.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/services/geographic_bearing_calculator.dart';
import 'package:vedam_app/data/fixtures/authentic_temples_data.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

void main() {
  group('Phase 22B - CoordinatePointType Model Hardening & Deserialization', () {
    test('All 4 coordinate point types exist with appropriate display labels', () {
      expect(CoordinatePointType.values.length, equals(4));
      expect(CoordinatePointType.innerSanctum.label, equals('Inner Sanctum (Garbhagriha)'));
      expect(CoordinatePointType.compoundCenter.label, equals('Temple Compound Center'));
      expect(CoordinatePointType.entranceGateway.label, equals('Entrance Gateway (Gopuram/Mahadwara)'));
      expect(CoordinatePointType.unknown.label, equals('Unspecified Point'));
    });

    test('CoordinatePointType.fromString safely deserializes known and unknown formats', () {
      expect(CoordinatePointType.fromString('innerSanctum'), equals(CoordinatePointType.innerSanctum));
      expect(CoordinatePointType.fromString('inner_sanctum'), equals(CoordinatePointType.innerSanctum));
      expect(CoordinatePointType.fromString('INNErsanctum'), equals(CoordinatePointType.innerSanctum));
      expect(CoordinatePointType.fromString('compoundCenter'), equals(CoordinatePointType.compoundCenter));
      expect(CoordinatePointType.fromString('compound_center'), equals(CoordinatePointType.compoundCenter));
      expect(CoordinatePointType.fromString('entranceGateway'), equals(CoordinatePointType.entranceGateway));
      expect(CoordinatePointType.fromString('entrance_gateway'), equals(CoordinatePointType.entranceGateway));
      expect(CoordinatePointType.fromString('unknown'), equals(CoordinatePointType.unknown));

      // Fallbacks for malformed or unrecognized strings
      expect(CoordinatePointType.fromString(null), equals(CoordinatePointType.unknown));
      expect(CoordinatePointType.fromString(''), equals(CoordinatePointType.unknown));
      expect(CoordinatePointType.fromString('arbitrary_point'), equals(CoordinatePointType.unknown));
    });
  });

  group('Phase 22B - CoordinateVerificationStatus Hardening & Deserialization', () {
    test('All 4 verification status values exist with expected audit flags', () {
      expect(CoordinateVerificationStatus.values.length, equals(4));

      expect(CoordinateVerificationStatus.verified.isVerified, isTrue);
      expect(CoordinateVerificationStatus.verified.needsNotice, isFalse);

      expect(CoordinateVerificationStatus.pendingVerification.isVerified, isFalse);
      expect(CoordinateVerificationStatus.pendingVerification.needsNotice, isTrue);

      expect(CoordinateVerificationStatus.userSuppliedUnverified.isVerified, isFalse);
      expect(CoordinateVerificationStatus.userSuppliedUnverified.needsNotice, isTrue);

      expect(CoordinateVerificationStatus.rejected.isVerified, isFalse);
      expect(CoordinateVerificationStatus.rejected.needsNotice, isTrue);
    });

    test('CoordinateVerificationStatus.fromString safely deserializes variants without crashing', () {
      expect(
        CoordinateVerificationStatus.fromString('pendingVerification'),
        equals(CoordinateVerificationStatus.pendingVerification),
      );
      expect(
        CoordinateVerificationStatus.fromString('pending_verification'),
        equals(CoordinateVerificationStatus.pendingVerification),
      );
      expect(
        CoordinateVerificationStatus.fromString('PENDING_VERIFICATION'),
        equals(CoordinateVerificationStatus.pendingVerification),
      );
      expect(
        CoordinateVerificationStatus.fromString('verified'),
        equals(CoordinateVerificationStatus.verified),
      );
      expect(
        CoordinateVerificationStatus.fromString('rejected'),
        equals(CoordinateVerificationStatus.rejected),
      );
      expect(
        CoordinateVerificationStatus.fromString('userSuppliedUnverified'),
        equals(CoordinateVerificationStatus.userSuppliedUnverified),
      );

      // Safe fallback
      expect(
        CoordinateVerificationStatus.fromString('unknown_status'),
        equals(CoordinateVerificationStatus.userSuppliedUnverified),
      );
      expect(
        CoordinateVerificationStatus.fromString(null),
        equals(CoordinateVerificationStatus.userSuppliedUnverified),
      );
    });
  });

  group('Phase 22B - 20-Temple Research Ledger & Coordinate Provenance Audit', () {
    final temples = AuthenticTemplesData.initialTemples;

    test('Directory contains all 20 researched temples with comprehensive provenance fields', () {
      expect(temples.length, equals(20));

      for (final temple in temples) {
        expect(temple.sourceName, isNotNull, reason: '${temple.name} missing sourceName');
        expect(temple.sourceName, isNotEmpty, reason: '${temple.name} empty sourceName');
        expect(temple.sourceUrl, isNotNull, reason: '${temple.name} missing sourceUrl');
        expect(temple.sourceUrl, startsWith('https://'), reason: '${temple.name} sourceUrl not HTTPS');
        expect(temple.corroborationSources, isNotEmpty, reason: '${temple.name} missing corroborations');
        expect(temple.verificationNotes, isNotNull, reason: '${temple.name} missing verificationNotes');
        expect(temple.verificationDate, isNotNull, reason: '${temple.name} missing verificationDate');
        expect(temple.pointType, equals(CoordinatePointType.compoundCenter));
        expect(temple.verificationStatus, equals(CoordinateVerificationStatus.pendingVerification));
      }
    });

    test('TEMPLE-0012 (Ram Janmabhoomi) sanctum refinement is recorded with original coordinate audit trail', () {
      final ramTemple = temples.firstWhere((t) => t.id == 'TEMPLE-0012');
      expect(ramTemple.name, equals('Ram Janmabhoomi Temple'));

      // Coordinate change was detected and recorded
      expect(ramTemple.hasCoordinateChanged, isTrue);
      expect(ramTemple.originalCoordinate, isNotNull);

      // Original coordinate preserved (Ayodhya Ram Kot town entrance coordinate)
      expect(ramTemple.originalCoordinate!.latitude, closeTo(26.7939, 0.0001));
      expect(ramTemple.originalCoordinate!.longitude, closeTo(82.1966, 0.0001));

      // Refined coordinate points to consecrated temple sanctum site
      expect(ramTemple.coordinate.latitude, closeTo(26.7956, 0.0001));
      expect(ramTemple.coordinate.longitude, closeTo(82.1943, 0.0001));

      // Source trust metadata
      expect(ramTemple.sourceName, contains('Shri Ram Janmbhoomi Teerth Kshetra'));
      expect(ramTemple.sourceUrl, contains('srjbtkshetra.org'));
      expect(ramTemple.verificationNotes, contains('consecrated sanctum location'));
    });

    test('Temple model serialization roundtrip retains all Phase 22B provenance fields', () {
      final ramTemple = temples.firstWhere((t) => t.id == 'TEMPLE-0012');
      final json = ramTemple.toJson();

      expect(json['source_name'], contains('Shri Ram Janmbhoomi Teerth Kshetra'));
      expect(json['source_url'], contains('srjbtkshetra.org'));
      expect(json['original_coordinate'], isNotNull);
      expect(json['corroboration_sources'], isList);
      expect(json['verification_notes'], isNotNull);

      final revived = Temple.fromJson(json);
      expect(revived.id, equals(ramTemple.id));
      expect(revived.sourceName, equals(ramTemple.sourceName));
      expect(revived.sourceUrl, equals(ramTemple.sourceUrl));
      expect(revived.originalCoordinate?.latitude, equals(ramTemple.originalCoordinate?.latitude));
      expect(revived.originalCoordinate?.longitude, equals(ramTemple.originalCoordinate?.longitude));
      expect(revived.corroborationSources, equals(ramTemple.corroborationSources));
      expect(revived.verificationNotes, equals(ramTemple.verificationNotes));
      expect(revived.hasCoordinateChanged, isTrue);
    });
  });

  group('Phase 22B - Canonical Sacred Origin (13 Cities) Provenance & Uncertainty', () {
    final cities = SacredOrigin.canonicalCities;

    test('All 13 cities specify accurate municipal centroid sources and ±15 km uncertainty radius', () {
      expect(cities.length, equals(13));

      for (final city in cities) {
        expect(city.isApproximate, isTrue);
        expect(city.type, equals(OriginType.approximateCity));
        expect(city.accuracyRadiusKm, equals(15.0), reason: '${city.name} must declare 15km uncertainty');
        expect(city.sourceGazetteer, isNotEmpty, reason: '${city.name} missing sourceGazetteer');
        expect(city.region, isNotEmpty, reason: '${city.name} missing region');
        expect(city.country, isNotEmpty, reason: '${city.name} missing country');
        expect(city.limitation, contains('uncertainty'), reason: '${city.name} limitation missing uncertainty warning');
      }
    });

    test('Origins clearly distinguish India vs Nepal coverage', () {
      final indiaCities = cities.where((c) => c.country == 'India').toList();
      final nepalCities = cities.where((c) => c.country == 'Nepal').toList();

      expect(indiaCities.length, equals(12));
      expect(nepalCities.length, equals(1));
      expect(nepalCities.first.name, equals('Kathmandu, Nepal'));
    });
  });

  group('Phase 22B - Ashta Dikpala & Sanskrit Disha Scriptural Traditions', () {
    test('Cardinal and ordinal directions include classical textual variants', () {
      final calculator = GeographicBearingCalculator();

      // Test North (Brihat Samhita / Kubera, Vedic / Soma)
      final northBearing = calculator.calculateBearing(
        origin: GeographicCoordinate(20.0, 80.0),
        destination: GeographicCoordinate(25.0, 80.0),
      );
      expect(northBearing.cardinalDirection, equals('N'));
      expect(northBearing.sanskritDirection, equals('Uttara'));
      expect(northBearing.dikpala, contains('Kubera'));
      expect(northBearing.traditionVariant, contains('Soma'));

      // Test Northeast (Ishana / Shiva-Rudra)
      final neBearing = calculator.calculateBearing(
        origin: GeographicCoordinate(20.0, 80.0),
        destination: GeographicCoordinate(25.0, 85.0),
      );
      expect(neBearing.cardinalDirection, equals('NE'));
      expect(neBearing.sanskritDirection, equals('Ishanya'));
      expect(neBearing.dikpala, contains('Ishana'));
      expect(neBearing.traditionVariant, contains('Rudra'));

      // Test Southwest (Nirrti / Rakshasa)
      final swBearing = calculator.calculateBearing(
        origin: GeographicCoordinate(20.0, 80.0),
        destination: GeographicCoordinate(15.0, 75.0),
      );
      expect(swBearing.cardinalDirection, equals('SW'));
      expect(swBearing.sanskritDirection, equals('Nairruti'));
      expect(swBearing.dikpala, contains('Nirrti'));
      expect(swBearing.traditionVariant, contains('Rakshasa'));
    });

    test('BearingResult captures isApproximate flag and plain-language disclaimer', () {
      final state = DivyaDishiState();
      final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
      state.setOrigin(varanasi);

      final temple = state.temples.firstWhere((t) => t.id == 'TEMPLE-0001');
      final bearing = state.calculateBearing(temple);

      expect(bearing.isAvailable, isTrue);
      expect(bearing.isApproximate, isTrue);
      expect(bearing.provisionalDisclaimer, isNotNull);
      expect(bearing.provisionalDisclaimer, contains('Devotional orientation aid only'));
      expect(bearing.provisionalDisclaimer, contains('approximate city origin'));
    });
  });
}
