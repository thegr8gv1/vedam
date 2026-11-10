import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/core/services/sankalpa_service.dart';

void main() {
  group('Phase 21K — Sankalpa Default Safety & Privacy Regression Unit Tests', () {
    late SankalpaService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = SankalpaService();
    });

    test('1. Unknown or empty Gotra is safely omitted and NEVER silently fabricated as Vishnu', () {
      final date = DateTime(2025, 4, 15);

      // Empty string Gotra
      final out1 = service.generateSankalpa(SankalpaInput(
        gotra: '',
        devoteeName: 'Ananda',
        date: date,
      ));
      expect(out1.sanskritFull, isNot(contains('विष्णु-गोत्र')));
      expect(out1.sanskritFull, isNot(contains('Vishnu-गोत्र')));
      expect(out1.sanskritFull, isNot(contains('गोत्रस्य')));
      expect(out1.sanskritFull, contains('Ananda नामधेयस्य मम आत्मनः'));
      expect(out1.iastFull, isNot(contains('gotrasya')));
      expect(out1.englishFull, isNot(contains('gotra')));
      expect(out1.englishFull, contains('Known as Ananda,'));
      expect(out1.shortSanskrit, contains('Ananda नामधेयस्य मम'));
      expect(out1.shortSanskrit, isNot(contains('गोत्र')));

      // Whitespace Gotra
      final out2 = service.generateSankalpa(SankalpaInput(
        gotra: '   ',
        devoteeName: 'Devotee',
        date: date,
      ));
      expect(out2.sanskritFull, isNot(contains('विष्णु-गोत्र')));
      expect(out2.sanskritFull, isNot(contains('Vishnu-गोत्र')));
      expect(out2.sanskritFull, isNot(contains('गोत्रस्य')));
      expect(out2.shortSanskrit, isNot(contains('गोत्र')));
    });

    test('2. Explicitly supplied Gotra values are faithfully preserved and declined', () {
      final date = DateTime(2025, 4, 15);

      // Kashyapa gotra
      final kashyapa = service.generateSankalpa(SankalpaInput(
        gotra: 'Kashyapa',
        devoteeName: 'Siddhartha',
        date: date,
      ));
      expect(kashyapa.sanskritFull, contains('Kashyapa-गोत्रस्य Siddhartha नामधेयस्य'));
      expect(kashyapa.iastFull, contains('Kashyapa-gotrasya'));
      expect(kashyapa.englishFull, contains('of Kashyapa gotra, known as Siddhartha,'));
      expect(kashyapa.shortSanskrit, contains('Kashyapa-गोत्रस्य Siddhartha नामधेयस्य मम'));

      // Bharadvaja gotra
      final bharadvaja = service.generateSankalpa(SankalpaInput(
        gotra: 'Bharadvaja',
        devoteeName: 'Kalyani',
        gender: SankalpaGender.female,
        date: date,
      ));
      expect(bharadvaja.sanskritFull, contains('Bharadvaja-गोत्रस्य Kalyani नामधेयायाः'));

      // User deliberately supplies 'Vishnu' gotra
      final explicitVishnu = service.generateSankalpa(SankalpaInput(
        gotra: 'Vishnu',
        devoteeName: 'Ramesh',
        date: date,
      ));
      expect(explicitVishnu.sanskritFull, contains('Vishnu-गोत्रस्य Ramesh'));
    });

    test('3. Personal-details-hidden mode strictly prevents name or lineage leakage', () {
      final date = DateTime(2025, 4, 15);
      final out = service.generateSankalpa(SankalpaInput(
        gotra: 'SecretGotra',
        devoteeName: 'SecretDevoteeName',
        isAnonymous: true,
        date: date,
      ));

      // No trace of personal identifiers anywhere in any output format
      expect(out.sanskritFull, isNot(contains('SecretGotra')));
      expect(out.sanskritFull, isNot(contains('SecretDevoteeName')));
      expect(out.iastFull, isNot(contains('SecretGotra')));
      expect(out.iastFull, isNot(contains('SecretDevoteeName')));
      expect(out.englishFull, isNot(contains('SecretGotra')));
      expect(out.englishFull, isNot(contains('SecretDevoteeName')));
      expect(out.shortSanskrit, isNot(contains('SecretGotra')));
      expect(out.shortSanskrit, isNot(contains('SecretDevoteeName')));
      expect(out.shortIast, isNot(contains('SecretDevoteeName')));
      expect(out.shortEnglish, isNot(contains('SecretDevoteeName')));

      // Check all individual structural components for leakage
      for (final comp in out.components) {
        expect(comp.sanskritText, isNot(contains('SecretGotra')));
        expect(comp.sanskritText, isNot(contains('SecretDevoteeName')));
        expect(comp.iastText, isNot(contains('SecretGotra')));
        expect(comp.iastText, isNot(contains('SecretDevoteeName')));
        expect(comp.englishMeaning, isNot(contains('SecretGotra')));
        expect(comp.englishMeaning, isNot(contains('SecretDevoteeName')));
      }

      // Verify authentic first-person contemplative wording
      expect(out.sanskritFull, contains('मम आत्मनः श्रुतिस्मृतिपुराणोक्त-फलप्राप्त्यर्थं'));
      expect(out.iastFull, contains('mama ātmanaḥ śruti-smṛti-purāṇokta-phala-prāptyarthaṃ'));
      expect(out.englishFull, contains('For myself, for the attainment of the fruits'));
      expect(out.shortSanskrit, contains('मम समस्तदुरितक्षयपूर्वकं'));
      expect(out.shortIast, contains('mama samasta-durita-kṣaya-pūrvakaṃ'));
      expect(out.shortEnglish, contains('I, for the dissolution of all obstacles'));
    });

    test('4. SharedPreferences persistence maintains empty Gotra without default pollution', () async {
      // Save profile with empty gotra
      await service.saveProfile(
        gotra: '',
        devoteeName: 'Devotee',
        gender: SankalpaGender.unspecified,
        riverBasin: RiverBasinOption.ganga,
        deityName: 'Sri Parameshwara',
        isAnonymous: false,
      );

      // Reload profile
      final loaded = await service.loadSavedProfile();
      expect(loaded.gotra, equals(''));
      expect(loaded.devoteeName, equals('Devotee'));
      expect(loaded.riverBasin, equals(RiverBasinOption.ganga));
      expect(loaded.isAnonymous, isFalse);

      // Generate from loaded profile
      final out = service.generateSankalpa(loaded);
      expect(out.sanskritFull, isNot(contains('विष्णु-गोत्र')));
      expect(out.sanskritFull, isNot(contains('Vishnu-गोत्र')));
      expect(out.sanskritFull, isNot(contains('गोत्रस्य')));
    });

    test('5. SharedPreferences persistence preserves personal-details-hidden preference', () async {
      await service.saveProfile(
        gotra: 'Sandilya',
        devoteeName: 'Bhakta',
        gender: SankalpaGender.male,
        riverBasin: RiverBasinOption.godavariDakshine,
        deityName: 'Lord Shiva',
        isAnonymous: true,
      );

      final loaded = await service.loadSavedProfile();
      expect(loaded.isAnonymous, isTrue);
      expect(loaded.gotra, equals('Sandilya'));
      expect(loaded.devoteeName, equals('Bhakta'));

      final out = service.generateSankalpa(loaded);
      expect(out.sanskritFull, isNot(contains('Sandilya')));
      expect(out.sanskritFull, isNot(contains('Bhakta')));
      expect(out.sanskritFull, contains('मम आत्मनः'));
    });

    test('6. All six ritual purposes remain functional and chant-ready', () {
      final date = DateTime(2025, 4, 15);

      for (final purpose in SankalpaPurpose.values) {
        final out = service.generateSankalpa(SankalpaInput(
          purpose: purpose,
          date: date,
        ));

        expect(out.sanskritFull, isNot(contains('/')));
        expect(out.shortSanskrit, isNot(contains('/')));
        expect(out.components.length, equals(5));

        switch (purpose) {
          case SankalpaPurpose.dailySadhana:
            expect(out.sanskritFull, contains('नित्यकर्म-नित्यसाधनां करिष्ये'));
            break;
          case SankalpaPurpose.japaPractice:
            expect(out.sanskritFull, contains('मन्त्रजपं करिष्ये'));
            break;
          case SankalpaPurpose.shodashopacharaPuja:
            expect(out.sanskritFull, contains('षोडशोपचार पूजां करिष्ये'));
            break;
          case SankalpaPurpose.vratObservance:
            expect(out.sanskritFull, contains('व्रतोपवास-नियमधारणं करिष्ये'));
            break;
          case SankalpaPurpose.sandhyavandanam:
            expect(out.sanskritFull, contains('सन्ध्यावन्दनं करिष्ये'));
            break;
          case SankalpaPurpose.custom:
            expect(out.sanskritFull, contains('शुभसङ्कल्पं करिष्ये'));
            break;
        }
      }
    });

    test('7. All river basins remain functional without grammatical corruption', () {
      final date = DateTime(2025, 4, 15);

      for (final river in RiverBasinOption.values) {
        final out = service.generateSankalpa(SankalpaInput(
          riverBasin: river,
          date: date,
        ));

        expect(out.sanskritFull, isNot(contains('/')));
        expect(out.sanskritFull, isNot(contains('अस्मिन् अस्मिन्')));
        expect(out.sanskritFull, contains(river.sanskritPhrase));
        expect(out.iastFull, contains(river.iastPhrase));
      }
    });

    test('8. Offline and Live Panchangam flags accurately indicate epistemological status', () {
      final date = DateTime(2025, 4, 15);

      // Offline calculation
      final offlineOut = service.generateSankalpa(SankalpaInput(date: date, panchangam: null));
      expect(offlineOut.isApproximateFallback, isTrue);

      // Live ephemeris calculation
      final mockPanchangam = DailyPanchangamData(
        calculationTimestampUtc: DateTime(2025, 4, 15, 6, 0),
        requestedDate: DateTime(2025, 4, 15),
        location: PanchangamLocation.varanasi,
        vara: const PanchaAngaElement(number: 2, name: 'Mangalavara', sanskritName: 'भौमवासर', meaning: 'Tuesday'),
        sunMoon: const SunMoonEvents(
          sunriseFormatted: '05:45 AM',
          sunsetFormatted: '06:15 PM',
          dayLengthHours: 12.5,
          dayLengthFormatted: '12h 30m',
          moonIlluminationPercent: 90.0,
        ),
        tithi: const PanchaAngaElement(number: 3, name: 'Tritiya', sanskritName: 'तृतीया', meaning: '3rd Lunar Day'),
        nakshatra: const PanchaAngaElement(number: 6, name: 'Ardra', sanskritName: 'आर्द्रा', meaning: 'Moist Asterism'),
        yoga: const PanchaAngaElement(number: 2, name: 'Priti', sanskritName: 'प्रीति', meaning: 'Love'),
        karana: const PanchaAngaElement(number: 2, name: 'Balava', sanskritName: 'बालव', meaning: 'Childhood'),
        paksha: 'Krishna Paksha',
        rahuKalam: TimePeriod(name: 'Rahu', sanskritName: 'राहु', formatted: '03:00 PM - 04:30 PM', startTime: date, endTime: date, isAuspicious: false, description: 'Inauspicious'),
        yamagandam: TimePeriod(name: 'Yama', sanskritName: 'यम', formatted: '09:00 AM - 10:30 AM', startTime: date, endTime: date, isAuspicious: false, description: 'Inauspicious'),
        gulikaKalam: TimePeriod(name: 'Gulika', sanskritName: 'गुलिक', formatted: '12:00 PM - 01:30 PM', startTime: date, endTime: date, isAuspicious: true, description: 'Auspicious'),
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

      final liveOut = service.generateSankalpa(SankalpaInput(date: date, panchangam: mockPanchangam));
      expect(liveOut.isApproximateFallback, isFalse);
    });
  });
}
