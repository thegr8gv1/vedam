import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/core/services/sankalpa_service.dart';

void main() {
  group('Phase 21I — Vedic Sankalpa Generator Unit Tests', () {
    late SankalpaService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = SankalpaService();
    });

    test('Generates complete 5-component Sankalpa with default offline fallback', () {
      final input = SankalpaInput(
        gotra: 'Kashyapa',
        devoteeName: 'Ananda',
        gender: SankalpaGender.male,
        purpose: SankalpaPurpose.dailySadhana,
        riverBasin: RiverBasinOption.ganga,
        deityName: 'Lord Shiva',
        date: DateTime(2025, 4, 15), // Post-Chaitra 2025
      );

      final output = service.generateSankalpa(input);

      expect(output.components.length, equals(5));
      expect(output.sanskritFull, contains('ॐ विष्णुर्विष्णुर्विष्णुः'));
      expect(output.sanskritFull, contains('गङ्गातीरे'));
      expect(output.sanskritFull, contains('Kashyapa-गोत्रस्य'));
      expect(output.sanskritFull, contains('Ananda शर्मणः'));
      expect(output.sanskritFull, contains('Lord Shiva'));
      expect(output.sanskritFull, contains('नित्यसाधनां करिष्ये'));

      // Check IAST
      expect(output.iastFull, contains('oṃ viṣṇur-viṣṇur-viṣṇuḥ'));
      expect(output.iastFull, contains('gaṅgātīre'));
      expect(output.iastFull, contains('śarmaṇaḥ'));

      // Check English
      expect(output.englishFull, contains('Lord Vishnu'));
      expect(output.englishFull, contains('Ganga Basin'));
      expect(output.englishFull, contains('Lord Shiva'));
    });

    test('Correctly binds live DailyPanchangamData coordinates into Sankalpa', () {
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
        paksha: 'शुक्ल',
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
        observances: const [
          Observance(name: 'Kartika Masa', sanskritName: 'कार्तिक मास', category: 'Month', description: 'Holy Month'),
        ],
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

      final input = SankalpaInput(
        gotra: 'Bharadwaja',
        devoteeName: 'Sita',
        gender: SankalpaGender.female,
        purpose: SankalpaPurpose.vratObservance,
        riverBasin: RiverBasinOption.godavari,
        deityName: 'Sri Mahavishnu',
        date: DateTime(2025, 11, 2),
        panchangam: mockPanchangam,
      );

      final output = service.generateSankalpa(input);

      // Verified exact substitution from PanchangamData
      expect(output.tithi, equals('एकादशी'));
      expect(output.vara, equals('सोमवासर'));
      expect(output.nakshatra, equals('पुष्य'));
      expect(output.paksha, equals('शुक्ल'));
      expect(output.masa, equals('Kartika Masa'));
      expect(output.sanskritFull, contains('गोदावर्याः'));
      expect(output.sanskritFull, contains('Sita नामधेयायाः'));
      expect(output.sanskritFull, contains('व्रत/उपवास नियमधारणं करिष्ये'));
    });

    test('Generates distinct prayer intentions across all ritual purposes', () {
      final date = DateTime(2025, 5, 20);

      // 1. Daily Sadhana
      final sadhana = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.dailySadhana,
        date: date,
      ));
      expect(sadhana.sanskritFull, contains('नित्यसाधनां करिष्ये'));
      expect(sadhana.shortSanskrit, contains('नित्यसाधनां करिष्ये'));

      // 2. Japa Practice
      final japa = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.japaPractice,
        deityName: 'Gayatri Mata',
        date: date,
      ));
      expect(japa.sanskritFull, contains('मन्त्रजपं करिष्ये'));
      expect(japa.sanskritFull, contains('Gayatri Mata'));
      expect(japa.shortSanskrit, contains('मन्त्रजपं करिष्ये'));

      // 3. Shodashopachara Puja
      final puja = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.shodashopacharaPuja,
        deityName: 'Ganesha',
        date: date,
      ));
      expect(puja.sanskritFull, contains('षोडशोपचार पूजां करिष्ये'));
      expect(puja.shortSanskrit, contains('षोडशोपचार पूजां करिष्ये'));

      // 4. Vrat Observance
      final vrat = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.vratObservance,
        date: date,
      ));
      expect(vrat.sanskritFull, contains('व्रत/उपवास नियमधारणं करिष्ये'));
      expect(vrat.shortSanskrit, contains('व्रतनियमधारणं करिष्ये'));

      // 5. Sandhyavandanam
      final sandhya = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.sandhyavandanam,
        date: date,
      ));
      expect(sandhya.sanskritFull, contains('सन्ध्यावन्दनं करिष्ये'));
      expect(sandhya.shortSanskrit, contains('सन्ध्यावन्दनं करिष्ये'));

      // 6. Custom Intention
      final custom = service.generateSankalpa(SankalpaInput(
        purpose: SankalpaPurpose.custom,
        customIntention: 'Loka Kalyana and Family Health',
        date: date,
      ));
      expect(custom.sanskritFull, contains('Loka Kalyana and Family Health'));
      expect(custom.englishFull, contains('Loka Kalyana and Family Health'));
    });

    test('Properly handles all RiverBasin options in Sanskrit, IAST and English', () {
      final date = DateTime(2025, 6, 1);

      for (final basin in RiverBasinOption.values) {
        final out = service.generateSankalpa(SankalpaInput(
          riverBasin: basin,
          date: date,
        ));

        expect(out.sanskritFull, contains(basin.sanskritPhrase));
        expect(out.iastFull, contains(basin.iastPhrase));
        expect(out.englishFull, contains(basin.displayName));
      }
    });

    test('Saves and restores devotee profile via SharedPreferences', () async {
      await service.saveProfile(
        gotra: 'Shrivatsa',
        devoteeName: 'Madhava',
        gender: SankalpaGender.male,
        riverBasin: RiverBasinOption.kaveri,
        deityName: 'Lord Ranganatha',
      );

      final loaded = await service.loadSavedProfile();

      expect(loaded.gotra, equals('Shrivatsa'));
      expect(loaded.devoteeName, equals('Madhava'));
      expect(loaded.gender, equals(SankalpaGender.male));
      expect(loaded.riverBasin, equals(RiverBasinOption.kaveri));
      expect(loaded.deityName, equals('Lord Ranganatha'));
    });

    test('Provides valid concise short Sankalpa for rapid daily recitation', () {
      final input = SankalpaInput(
        gotra: 'Vishnu',
        devoteeName: 'Bhakta',
        gender: SankalpaGender.unspecified,
        purpose: SankalpaPurpose.dailySadhana,
        date: DateTime(2025, 8, 15),
      );

      final out = service.generateSankalpa(input);

      expect(out.shortSanskrit, startsWith('ॐ अद्य'));
      expect(out.shortSanskrit, endsWith('करिष्ये ॥'));
      expect(out.shortIast, startsWith('oṃ adya'));
      expect(out.shortIast, endsWith('kariṣye ||'));
      expect(out.shortEnglish, startsWith('Om. On this'));
    });
  });
}
