import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/state/panchangam_state.dart';

class MockPanchangamRepository implements PanchangamRepository {
  bool shouldThrow = false;
  DailyPanchangamData? stubData;

  @override
  Future<DailyPanchangamData> getDailyPanchangam({
    required DateTime date,
    required PanchangamLocation location,
    String ayanamsa = 'lahiri',
  }) async {
    if (shouldThrow) {
      throw const PanchangamUnavailableException(
        message: 'Astronomical Engine Offline',
        details: 'Server unreachable',
      );
    }
    return stubData ??
        DailyPanchangamData(
          calculationTimestampUtc: DateTime.now(),
          requestedDate: date,
          location: location,
          vara: const PanchaAngaElement(
            number: 5,
            name: 'Guruvara',
            sanskritName: 'गुरुवार',
            meaning: 'Wisdom',
          ),
          sunMoon: const SunMoonEvents(
            sunriseFormatted: '06:08 AM',
            sunsetFormatted: '05:14 PM',
            dayLengthHours: 11.1,
            dayLengthFormatted: '11h 6m',
            moonIlluminationPercent: 20.0,
          ),
          tithi: const PanchaAngaElement(
            number: 26,
            name: 'Krishna Ekadashi',
            sanskritName: 'कृष्ण एकादशी',
            endTimeFormatted: '10:35 AM',
            meaning: 'Sacred fast',
          ),
          nakshatra: const PanchaAngaElement(
            number: 12,
            name: 'Uttara Phalguni',
            sanskritName: 'उत्तर फाल्गुनी',
            endTimeFormatted: '03:55 AM',
            meaning: 'Nobility',
          ),
          yoga: const PanchaAngaElement(
            number: 26,
            name: 'Aindra (Indra)',
            sanskritName: 'ऐन्द्र',
            meaning: 'Leadership',
          ),
          karana: const PanchaAngaElement(
            number: 52,
            name: 'Balava',
            sanskritName: 'बालव',
            meaning: 'Humility',
          ),
          paksha: 'Krishna Paksha',
          rahuKalam: TimePeriod(
            name: 'Rahu Kalam',
            sanskritName: 'राहुकाल',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
            formatted: '01:04 PM - 02:28 PM',
            isAuspicious: false,
            description: 'Inauspicious',
          ),
          yamagandam: TimePeriod(
            name: 'Yamagandam',
            sanskritName: 'यमगण्ड',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
            formatted: '06:08 AM - 07:31 AM',
            isAuspicious: false,
            description: 'Yama',
          ),
          gulikaKalam: TimePeriod(
            name: 'Gulika Kalam',
            sanskritName: 'गुलिक काल',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
            formatted: '08:54 AM - 10:17 AM',
            isAuspicious: true,
            description: 'Gulika',
          ),
          observances: const [],
          conventions: const CalculationConventions(
            ayanamsaUsed: 'Lahiri',
            ayanamsaValueDegrees: 24.23,
            ayanamsaValueFormatted: '24° 13\' 55"',
            ephemerisEngine: 'Astronomy Engine',
            coordinateSystem: 'Geocentric',
            sunriseConvention: '-50\'',
            timeScale: 'TT',
            udayaTithiRule: 'Sunrise',
          ),
        );
  }

  @override
  Future<List<PanchangamLocation>> getCuratedLocations({String? query}) async {
    return [PanchangamLocation.varanasi];
  }
}

void main() {
  group('PanchangamState Tests', () {
    test('Initial state defaults to Varanasi and today', () {
      final repo = MockPanchangamRepository();
      final initialDate = DateTime(2026, 11, 5);
      final state = PanchangamState(
        repository: repo,
        initialDate: initialDate,
      );

      expect(state.selectedDate, initialDate);
      expect(state.selectedLocation.name, contains('Varanasi'));
      expect(state.isLoading, false);
      expect(state.isUnavailable, false);
      expect(state.data, isNull);
    });

    test('Date navigation advances and retreats days', () {
      final repo = MockPanchangamRepository();
      final state = PanchangamState(
        repository: repo,
        initialDate: DateTime(2026, 11, 5),
      );

      state.goToNextDay();
      expect(state.selectedDate.day, 6);

      state.goToPreviousDay();
      expect(state.selectedDate.day, 5);

      state.goToDate(DateTime(2026, 12, 1));
      expect(state.selectedDate.month, 12);
      expect(state.selectedDate.day, 1);
    });

    test('Location updates correctly', () {
      final repo = MockPanchangamRepository();
      final state = PanchangamState(repository: repo);

      const chennai = PanchangamLocation(
        name: 'Chennai, Tamil Nadu, India',
        latitude: 13.0827,
        longitude: 80.2707,
        timezone: 'Asia/Kolkata',
      );

      state.setLocation(chennai);
      expect(state.selectedLocation.name, 'Chennai, Tamil Nadu, India');
      expect(state.selectedLocation.latitude, 13.0827);
    });

    test('Handles calculation error by entering unavailable state', () async {
      final repo = MockPanchangamRepository()..shouldThrow = true;
      final state = PanchangamState(repository: repo);

      await state.loadPanchangam();

      expect(state.isLoading, false);
      expect(state.isUnavailable, true);
      expect(state.data, isNull);
      expect(state.errorMessage, contains('Astronomical Engine Offline'));
    });

    test('Loads calculated data successfully', () async {
      final repo = MockPanchangamRepository();
      final state = PanchangamState(repository: repo);

      await state.loadPanchangam();

      expect(state.isLoading, false);
      expect(state.isUnavailable, false);
      expect(state.data, isNotNull);
      expect(state.data!.tithi.name, 'Krishna Ekadashi');
    });
  });
}
