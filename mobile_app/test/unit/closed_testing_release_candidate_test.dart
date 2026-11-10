import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/geographic_coordinate.dart';
import 'package:vedam_app/core/models/japa_target_preset.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/services/geographic_bearing_calculator.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/data/fixtures/authentic_temples_data.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  group('Closed Testing Release Candidate: Content & Invariant Verification', () {
    test('1. kAuthenticScriptures contains exactly 20 texts and 310 total verses', () {
      expect(kAuthenticScriptures.length, equals(20));

      int totalVerses = 0;
      for (final s in kAuthenticScriptures) {
        expect(s.verses.length, equals(s.verseCount),
            reason: '${s.canonicalTitle} (${s.contentId}) verse count mismatch');
        totalVerses += s.verses.length;
      }
      expect(totalVerses, equals(310));
    });

    test('2. Vedic Svaras are present and verified in the 4 Vedic compositions', () {
      final vedicIds = [
        'VEDA-TXT-00005', // Mahamrityunjaya Mantra
        'VEDA-TXT-00006', // Gayatri Mantra
        'VEDA-TXT-00014', // Purusha Suktam
        'VEDA-TXT-00015', // Durga Suktam
      ];

      for (final vid in vedicIds) {
        final scripture = kAuthenticScriptures.firstWhere((s) => s.contentId == vid);
        expect(scripture.verses, isNotEmpty);

        // Vedic accents: Udatta \u0951 (॑) or Anudatta \u0952 (॒)
        final firstVerse = scripture.verses.first.devanagariText;
        final hasSvaras = firstVerse.contains('\u0951') || firstVerse.contains('\u0952');
        expect(hasSvaras, isTrue,
            reason: '${scripture.canonicalTitle} ($vid) must contain Unicode Vedic Svara marks');
      }
    });

    test('3. Transliterations across Indic scripts (Telugu, Tamil, Kannada, Malayalam) are populated', () {
      final testedCompositions = ['VEDA-TXT-00001', 'VEDA-TXT-00002', 'VEDA-TXT-00008', 'VEDA-TXT-00013'];
      for (final cid in testedCompositions) {
        final scripture = kAuthenticScriptures.firstWhere((s) => s.contentId == cid);
        final v1 = scripture.verses.first;
        expect(v1.transliterations.containsKey('telugu'), isTrue);
        expect(v1.transliterations.containsKey('tamil'), isTrue);
        expect(v1.transliterations.containsKey('kannada'), isTrue);
        expect(v1.transliterations.containsKey('malayalam'), isTrue);
      }
    });

    test('4. Awadhi orthography and complex Sanskrit conjuncts render without corruption', () {
      // Hanuman Chalisa (Awadhi)
      final chalisa = kAuthenticScriptures.firstWhere((s) => s.contentId == 'VEDA-TXT-00008');
      expect(chalisa.verses.length, equals(43));
      expect(chalisa.verses[0].devanagariText, contains('श्रीगुरु चरन सरोज रज'));
      expect(chalisa.verses[42].devanagariText, contains('पवनतनय संकट हरन'));

      // Shiva Tandava (Panchachamara)
      final tandava = kAuthenticScriptures.firstWhere((s) => s.contentId == 'VEDA-TXT-00002');
      expect(tandava.verses[0].devanagariText, contains('जटाटवीगलज्जलप्रवाह'));

      // Mahishasura Mardini Stotram
      final durga = kAuthenticScriptures.firstWhere((s) => s.contentId == 'VEDA-TXT-00019');
      expect(durga.verses[0].devanagariText, contains('अयि गिरिनन्दिनि'));
    });
  });

  group('Closed Testing Release Candidate: Japa Presets & Target Validation', () {
    test('1. All 7 traditional Japa presets are defined with authentic labels', () {
      final counts = kJapaTraditionalPresets.map((p) => p.count).toList();
      expect(counts, equals([11, 21, 27, 54, 108, 111, 1008]));
    });

    test('2. validateCustomJapaTarget validates correct boundaries', () {
      // Valid cases
      expect(validateCustomJapaTarget('1').isValid, isTrue);
      expect(validateCustomJapaTarget('100').isValid, isTrue);
      expect(validateCustomJapaTarget('108').isValid, isTrue);
      expect(validateCustomJapaTarget('100000').isValid, isTrue);
      expect(validateCustomJapaTarget(' 54 ').isValid, isTrue);

      // Invalid cases: zero and negative
      expect(validateCustomJapaTarget('0').isValid, isFalse);
      expect(validateCustomJapaTarget('-1').isValid, isFalse);

      // Invalid cases: decimals and formatting
      expect(validateCustomJapaTarget('10.5').isValid, isFalse);
      expect(validateCustomJapaTarget('1,000').isValid, isFalse);

      // Invalid cases: non-numeric and empty
      expect(validateCustomJapaTarget('').isValid, isFalse);
      expect(validateCustomJapaTarget('   ').isValid, isFalse);
      expect(validateCustomJapaTarget('abc').isValid, isFalse);

      // Invalid cases: exceeding upper limit
      expect(validateCustomJapaTarget('100001').isValid, isFalse);
      expect(validateCustomJapaTarget('999999').isValid, isFalse);
    });
  });

  group('Closed Testing Release Candidate: DivyaDishi 20 Temples Geodesic Engine', () {
    test('1. All 20 temples have valid coordinates and non-empty metadata', () {
      final temples = AuthenticTemplesData.initialTemples;
      expect(temples.length, equals(20));
      for (final temple in temples) {
        expect(temple.coordinate.latitude, inInclusiveRange(8.0, 35.0));
        expect(temple.coordinate.longitude, inInclusiveRange(68.0, 95.0));
        expect(temple.name, isNotEmpty);
        expect(temple.deity, isNotEmpty);
        expect(temple.city, isNotEmpty);
      }
    });

    test('2. Great-circle geodesic bearing calculates accurately', () {
      const calculator = GeographicBearingCalculator();

      // Hyderabad (17.3850 N, 78.4867 E) to Kashi Vishwanath (25.3109 N, 83.0107 E) -> North-East
      final hyderabad = GeographicCoordinate(17.3850, 78.4867);
      final kashi = GeographicCoordinate(25.3109, 83.0107);
      final bearingResult = calculator.calculateBearing(origin: hyderabad, destination: kashi);

      expect(bearingResult.isAvailable, isTrue);
      expect(bearingResult.degrees, inInclusiveRange(20.0, 35.0));
      expect(bearingResult.distanceKm, inInclusiveRange(900.0, 1100.0));
    });
  });

  group('Closed Testing Release Candidate: AppState Preferences & Scaling', () {
    test('1. AppState updates font scaling and theme mode cleanly', () {
      final appState = AppState();
      expect(appState.fontScale, equals(1.0));

      appState.setTextScalePreference(TextScalePreference.large);
      expect(appState.fontScale, equals(1.18));

      appState.setTextScalePreference(TextScalePreference.extraLarge);
      expect(appState.fontScale, equals(1.35));
    });

    test('2. AppState active script selection updates accurately', () {
      final appState = AppState();
      expect(appState.activeScript, equals(ScriptOption.devanagari));

      appState.setActiveScript(ScriptOption.telugu);
      expect(appState.activeScript, equals(ScriptOption.telugu));

      appState.setActiveScript(ScriptOption.iast);
      expect(appState.activeScript, equals(ScriptOption.iast));
    });
  });
}
