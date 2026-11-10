import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/services/temple_directory_service.dart';
import 'package:vedam_app/data/fixtures/authentic_temples_data.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

void main() {
  group('Phase 22A - Sacred Temple Directory Data & Provenance Integrity', () {
    test('Directory contains exactly 20 initial provisional temples', () {
      final temples = AuthenticTemplesData.initialTemples;
      expect(temples.length, equals(20));
    });

    test('All 20 initial temples are marked as USER_SUPPLIED_UNVERIFIED', () {
      final temples = AuthenticTemplesData.initialTemples;
      for (final temple in temples) {
        expect(
          temple.verificationStatus,
          equals(CoordinateVerificationStatus.userSuppliedUnverified),
          reason: 'Temple ${temple.name} must be marked as userSuppliedUnverified',
        );
        expect(temple.verificationStatus.isVerified, isFalse);
        expect(temple.verificationStatus.needsNotice, isTrue);
      }
    });

    test('All 20 initial temples have valid geodetic coordinates', () {
      final temples = AuthenticTemplesData.initialTemples;
      for (final temple in temples) {
        expect(temple.coordinate.latitude, greaterThanOrEqualTo(8.0));
        expect(temple.coordinate.latitude, lessThanOrEqualTo(36.0));
        expect(temple.coordinate.longitude, greaterThanOrEqualTo(68.0));
        expect(temple.coordinate.longitude, lessThanOrEqualTo(98.0));
        expect(temple.coordinate.latitude.isFinite, isTrue);
        expect(temple.coordinate.longitude.isFinite, isTrue);
      }
    });

    test('Temple models serialize and deserialize without loss', () {
      final temple = AuthenticTemplesData.initialTemples.first;
      final json = temple.toJson();
      final revived = Temple.fromJson(json);

      expect(revived.id, equals(temple.id));
      expect(revived.name, equals(temple.name));
      expect(revived.deity, equals(temple.deity));
      expect(revived.city, equals(temple.city));
      expect(revived.state, equals(temple.state));
      expect(revived.country, equals(temple.country));
      expect(revived.verificationStatus, equals(temple.verificationStatus));
      expect(revived.pointType, equals(temple.pointType));
      expect(revived.tradition, equals(temple.tradition));
      expect(revived.coordinate, equals(temple.coordinate));
    });

    test('Country representation matches researched catalog (17 India, 3 Nepal)', () {
      final temples = AuthenticTemplesData.initialTemples;
      final indiaTemples = temples.where((t) => t.country == 'India').toList();
      final nepalTemples = temples.where((t) => t.country == 'Nepal').toList();

      expect(indiaTemples.length, equals(17));
      expect(nepalTemples.length, equals(3));
      expect(nepalTemples.map((t) => t.name), containsAll(['Pashupatinath Temple', 'Janaki Mandir', 'Muktinath Temple']));
    });
  });

  group('Phase 22A - TempleDirectoryService Queries & Filtering', () {
    late TempleDirectoryService service;

    setUp(() {
      service = TempleDirectoryService();
    });

    test('getAllTemples returns all 20 records', () {
      expect(service.getAllTemples().length, equals(20));
    });

    test('getTempleById retrieves existing temple and returns null for unknown id', () {
      final temple = service.getTempleById('TEMPLE-0007');
      expect(temple, isNotNull);
      expect(temple!.name, equals('Somnath Temple'));

      expect(service.getTempleById('nonexistent_temple'), isNull);
    });

    test('searchAndFilter by country', () {
      final nepal = service.searchAndFilter(country: 'Nepal');
      expect(nepal.length, equals(3));

      final india = service.searchAndFilter(country: 'India');
      expect(india.length, equals(17));
    });

    test('searchAndFilter by tradition', () {
      final shaiva = service.searchAndFilter(tradition: TempleTradition.shaivism);
      expect(shaiva, isNotEmpty);
      expect(shaiva.every((t) => t.tradition == TempleTradition.shaivism), isTrue);

      final vaishnava = service.searchAndFilter(tradition: TempleTradition.vaishnavism);
      expect(vaishnava, isNotEmpty);
      expect(vaishnava.every((t) => t.tradition == TempleTradition.vaishnavism), isTrue);
    });

    test('searchAndFilter by query matches name, deity, and city', () {
      // By name
      final kashi = service.searchAndFilter(query: 'Vishwanath');
      expect(kashi.length, equals(1));
      expect(kashi.first.id, equals('TEMPLE-0002'));

      // By deity
      final krishna = service.searchAndFilter(query: 'Krishna');
      expect(krishna, isNotEmpty);

      // By city
      final puri = service.searchAndFilter(query: 'Puri');
      expect(puri.length, equals(1));
      expect(puri.first.id, equals('TEMPLE-0003'));

      // By country
      final nepal = service.searchAndFilter(query: 'Nepal');
      expect(nepal.length, equals(3));
    });
  });

  group('Phase 22A - SacredOrigin & Canonical Cities Selection', () {
    test('Canonical cities list contains 13 representative approximate points', () {
      final cities = SacredOrigin.canonicalCities;
      expect(cities.length, equals(13));
      expect(cities.every((c) => c.type == OriginType.approximateCity), isTrue);
      expect(cities.every((c) => c.isApproximate), isTrue);

      final names = cities.map((c) => c.name).toList();
      expect(names, containsAll([
        'Varanasi, India',
        'New Delhi, India',
        'Mumbai, India',
        'Bengaluru, India',
        'Chennai, India',
        'Kolkata, India',
        'Hyderabad, India',
        'Tirupati, India',
        'Ayodhya, India',
        'Ujjain, India',
        'Madurai, India',
        'Haridwar, India',
        'Kathmandu, Nepal',
      ]));
    });

    test('LocationPermissionState documentation strings are defined', () {
      for (final state in LocationPermissionState.values) {
        expect(state.description, isNotEmpty);
      }
    });
  });

  group('Phase 22A - DivyaDishiState Flow & Bearing Computations', () {
    late DivyaDishiState state;

    setUp(() {
      state = DivyaDishiState();
    });

    test('Initial state has no origin and displays all 20 temples', () {
      expect(state.selectedOrigin, isNull);
      expect(state.temples.length, equals(20));
      expect(state.totalTempleCount, equals(20));
    });

    test('Bearing is unavailable when no origin is selected', () {
      final temple = state.temples.first;
      final bearing = state.calculateBearing(temple);

      expect(bearing.isAvailable, isFalse);
      expect(bearing.unavailabilityReason, contains('Select an origin'));
    });

    test('Setting origin enables bearing calculation to all temples', () {
      final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
      state.setOrigin(varanasi);

      expect(state.selectedOrigin, equals(varanasi));

      for (final temple in state.temples) {
        final bearing = state.calculateBearing(temple);
        if (temple.id == 'TEMPLE-0002') {
          // Both are within Varanasi, short distance (< 5 km)
          expect(bearing.isAvailable, isTrue);
          expect(bearing.distanceKm, lessThan(10.0));
        } else {
          expect(bearing.isAvailable, isTrue);
          expect(bearing.degrees, isNotNull);
          expect(bearing.cardinalDirection, isNotNull);
          expect(bearing.sanskritDirection, isNotNull);
          expect(bearing.distanceKm, greaterThan(0.0));
        }
      }
    });

    test('Search query and filtering update temple list in state', () {
      state.setSearchQuery('Nepal');
      expect(state.temples.length, equals(3));

      state.resetFilters();
      expect(state.temples.length, equals(20));

      state.setCountryFilter('India');
      expect(state.temples.length, equals(17));

      state.setTraditionFilter(TempleTradition.shaivism);
      expect(state.temples.every((t) => t.tradition == TempleTradition.shaivism), isTrue);

      state.resetFilters();
      expect(state.temples.length, equals(20));
    });
  });
}
