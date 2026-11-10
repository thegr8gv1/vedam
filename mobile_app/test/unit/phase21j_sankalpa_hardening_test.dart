import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/core/services/sankalpa_service.dart';

void main() {
  group('Phase 21J — Sankalpa Correctness, Transparency & Hardening Unit Tests', () {
    late SankalpaService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = SankalpaService();
    });

    test('1. Verified liturgical phrasing across all 6 purposes contains zero unrecitable slashes', () {
      final date = DateTime(2025, 4, 15);

      for (final purpose in SankalpaPurpose.values) {
        final out = service.generateSankalpa(SankalpaInput(
          purpose: purpose,
          deityName: 'Sri Parameshwara',
          date: date,
        ));

        // Must not contain awkward literal slashes in the chantable text
        expect(out.sanskritFull, isNot(contains('प्रातः/सायं')));
        expect(out.sanskritFull, isNot(contains('व्रत/उपवास')));
        expect(out.sanskritFull, isNot(contains('/')));
        expect(out.shortSanskrit, isNot(contains('/')));
        expect(out.iastFull, isNot(contains('/')));
        expect(out.shortIast, isNot(contains('/')));
      }
    });

    test('2. Verified river basin options and universal desha contain zero word duplication', () {
      final date = DateTime(2025, 4, 15);

      for (final basin in RiverBasinOption.values) {
        final out = service.generateSankalpa(SankalpaInput(
          riverBasin: basin,
          date: date,
        ));

        // Check that 'अस्मिन्' is not duplicated consecutively
        expect(out.sanskritFull, isNot(contains('अस्मिन् अस्मिन्')));
        expect(out.sanskritFull, isNot(contains('अस्मिन् पुण्यदेशे अस्मिन्')));
        expect(out.sanskritFull, isNot(contains('तीरे/तीरे')));
        expect(out.sanskritFull, isNot(contains('/')));
      }

      // Check specific Godavari North/South options
      final south = service.generateSankalpa(SankalpaInput(
        riverBasin: RiverBasinOption.godavariDakshine,
        date: date,
      ));
      expect(south.sanskritFull, contains('गोदावर्याः दक्षिणे तीरे'));

      final north = service.generateSankalpa(SankalpaInput(
        riverBasin: RiverBasinOption.godavariUttare,
        date: date,
      ));
      expect(north.sanskritFull, contains('गोदावर्याः उत्तरे तीरे'));
    });

    test('3. Missing Panchangam triggers approximate fallback flag with valid mathematical calculations', () {
      final input = SankalpaInput(
        date: DateTime(2025, 5, 10),
        panchangam: null, // Offline / missing
      );

      final out = service.generateSankalpa(input);

      expect(out.isApproximateFallback, isTrue);
      expect(out.samvatsara, isNotEmpty);
      expect(out.ayana, isNotEmpty);
      expect(out.ritu, isNotEmpty);
      expect(out.masa, isNotEmpty);
      expect(out.paksha, isNotEmpty);
      expect(out.tithi, isNotEmpty);
      expect(out.vara, isNotEmpty);
      expect(out.nakshatra, isNotEmpty);
    });

    test('4. Live Panchangam clears approximate fallback flag and applies authentic declensions', () {
      final mockPanchangam = DailyPanchangamData(
        calculationTimestampUtc: DateTime(2025, 11, 2, 6, 0),
        requestedDate: DateTime(2025, 11, 2),
        location: PanchangamLocation.varanasi,
        vara: const PanchaAngaElement(number: 1, name: 'Somavara', sanskritName: 'सोमवासर', meaning: 'Monday'),
        sunMoon: const SunMoonEvents(
          sunriseFormatted: '06:15 AM',
          sunsetFormatted: '05:30 PM',
          dayLengthHours: 11.25,
          dayLengthFormatted: '11h 15m',
          moonIlluminationPercent: 50.0,
        ),
        tithi: const PanchaAngaElement(number: 11, name: 'Ekadashi', sanskritName: 'एकादशी', meaning: '11th Lunar Day'),
        nakshatra: const PanchaAngaElement(number: 8, name: 'Pushya', sanskritName: 'पुष्य', meaning: 'Nourishing Asterism'),
        yoga: const PanchaAngaElement(number: 1, name: 'Vishkambha', sanskritName: 'विष्कम्भ', meaning: 'Support'),
        karana: const PanchaAngaElement(number: 1, name: 'Bava', sanskritName: 'बव', meaning: 'Auspicious'),
        paksha: 'Shukla Paksha',
        rahuKalam: TimePeriod(
          name: 'Rahu Kalam',
          sanskritName: 'राहुकाल',
          formatted: '07:30 AM - 09:00 AM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: false,
          description: 'Inauspicious',
        ),
        yamagandam: TimePeriod(
          name: 'Yamagandam',
          sanskritName: 'यमगण्ड',
          formatted: '10:30 AM - 12:00 PM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: false,
          description: 'Inauspicious',
        ),
        gulikaKalam: TimePeriod(
          name: 'Gulika Kalam',
          sanskritName: 'गुलिक काल',
          formatted: '01:30 PM - 03:00 PM',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isAuspicious: true,
          description: 'Auspicious',
        ),
        observances: const [],
        conventions: const CalculationConventions(
          ayanamsaUsed: 'Lahiri',
          ayanamsaValueDegrees: 24.1,
          ayanamsaValueFormatted: '24° 06\' 00"',
          ephemerisEngine: 'Swiss Ephemeris',
          coordinateSystem: 'Geocentric',
          sunriseConvention: 'Geometric Center',
          timeScale: 'UTC',
          udayaTithiRule: 'Standard Sunrise',
        ),
      );

      final out = service.generateSankalpa(SankalpaInput(
        date: DateTime(2025, 11, 2),
        panchangam: mockPanchangam,
      ));

      expect(out.isApproximateFallback, isFalse);
      expect(out.sanskritFull, contains('शुक्लपक्षे')); // Declined cleanly
      expect(out.sanskritFull, contains('सोमवासरे')); // Declined cleanly without duplicate वासर
      expect(out.sanskritFull, contains('एकादशी-शुभतिथौ')); // Compounded smoothly
    });

    test('5. Anonymous / Universal mode produces clean non-personal formula (मम आत्मनः)', () {
      final out = service.generateSankalpa(SankalpaInput(
        date: DateTime(2025, 4, 15),
        isAnonymous: true,
        gotra: 'Kashyapa', // Should be ignored when anonymous
        devoteeName: 'SecretDevotee', // Should be ignored when anonymous
      ));

      expect(out.sanskritFull, contains('मम आत्मनः'));
      expect(out.sanskritFull, isNot(contains('Kashyapa')));
      expect(out.sanskritFull, isNot(contains('SecretDevotee')));
      expect(out.iastFull, isNot(contains('SecretDevotee')));
      expect(out.englishFull, contains('as a humble seeker'));
    });

    test('6. Gender declensions apply correctly for Male, Female, and Unspecified', () {
      final date = DateTime(2025, 4, 15);

      final male = service.generateSankalpa(SankalpaInput(
        devoteeName: 'Ramachandra',
        gender: SankalpaGender.male,
        date: date,
      ));
      expect(male.sanskritFull, contains('Ramachandra शर्मणः'));
      expect(male.iastFull, contains('Ramachandra śarmaṇaḥ'));

      final female = service.generateSankalpa(SankalpaInput(
        devoteeName: 'Kalyani',
        gender: SankalpaGender.female,
        date: date,
      ));
      expect(female.sanskritFull, contains('Kalyani नामधेयायाः'));
      expect(female.iastFull, contains('Kalyani nāmadheyāyāḥ'));

      final unspec = service.generateSankalpa(SankalpaInput(
        devoteeName: 'Devotee',
        gender: SankalpaGender.unspecified,
        date: date,
      ));
      expect(unspec.sanskritFull, contains('Devotee नामधेयस्य'));
      expect(unspec.iastFull, contains('Devotee nāmadheyasya'));
    });

    test('7. Empty and irregular Gotra/Name inputs recover safely', () {
      final date = DateTime(2025, 4, 15);

      // Empty Gotra defaults to Vishnu
      final emptyGotra = service.generateSankalpa(SankalpaInput(
        gotra: '',
        devoteeName: 'Arjuna',
        date: date,
      ));
      expect(emptyGotra.sanskritFull, contains('विष्णु-गोत्रस्य'));

      // Gotra with existing 'gotra' suffix doesn't double-suffix
      final suffixedGotra = service.generateSankalpa(SankalpaInput(
        gotra: 'Kashyapa-gotra',
        devoteeName: 'Arjuna',
        date: date,
      ));
      expect(suffixedGotra.sanskritFull, contains('Kashyapa-gotra-गोत्रोत्पन्नस्य'));
      expect(suffixedGotra.sanskritFull, isNot(contains('gotra-गोत्रस्य-गोत्रस्य')));

      // Empty name defaults safely
      final emptyName = service.generateSankalpa(SankalpaInput(
        gotra: 'Atri',
        devoteeName: '',
        date: date,
      ));
      expect(emptyName.sanskritFull, contains('मम आत्मनः'));
    });

    test('8. Persistence handles anonymous flag and recovers gracefully from corrupted state', () async {
      await service.saveProfile(
        gotra: 'Vasishta',
        devoteeName: 'Arundhati',
        gender: SankalpaGender.female,
        riverBasin: RiverBasinOption.narmada,
        deityName: 'Maa Narmada',
        isAnonymous: true,
      );

      final loaded = await service.loadSavedProfile();
      expect(loaded.gotra, equals('Vasishta'));
      expect(loaded.devoteeName, equals('Arundhati'));
      expect(loaded.gender, equals(SankalpaGender.female));
      expect(loaded.riverBasin, equals(RiverBasinOption.narmada));
      expect(loaded.isAnonymous, isTrue);

      // Corrupted preference simulation: empty strings and unknown enums
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SankalpaService.keyGender, 'corrupted_value');
      await prefs.setString(SankalpaService.keyRiverBasin, 'unknown_river');

      final recovered = await service.loadSavedProfile();
      expect(recovered.gender, equals(SankalpaGender.unspecified));
      expect(recovered.riverBasin, equals(RiverBasinOption.pavitraDeshe));
    });

    test('9. Scholarly disclaimer is present and mandates human-review/purohita advisory', () {
      final out = service.generateSankalpa(SankalpaInput(date: DateTime.now()));
      expect(out.scholarlyDisclaimer, contains('Traditional Recitation Template'));
      expect(out.scholarlyDisclaimer, contains('qualified family priest or acharya'));
    });
  });
}
