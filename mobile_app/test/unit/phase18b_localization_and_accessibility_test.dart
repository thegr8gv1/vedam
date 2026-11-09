import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/devotee_preferences.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/theme/text_styles.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/personalization_state.dart';

void main() {
  group('Phase 18B: InterfaceLanguage & Architecture Tests', () {
    test('InterfaceLanguage defines all 5 approved regional languages with ISO codes', () {
      expect(InterfaceLanguage.values.length, 5);
      expect(InterfaceLanguage.english.code, 'en');
      expect(InterfaceLanguage.telugu.code, 'te');
      expect(InterfaceLanguage.tamil.code, 'ta');
      expect(InterfaceLanguage.kannada.code, 'kn');
      expect(InterfaceLanguage.malayalam.code, 'ml');

      expect(InterfaceLanguage.english.locale, const Locale('en'));
      expect(InterfaceLanguage.telugu.locale, const Locale('te'));
      expect(InterfaceLanguage.tamil.locale, const Locale('ta'));
      expect(InterfaceLanguage.kannada.locale, const Locale('kn'));
      expect(InterfaceLanguage.malayalam.locale, const Locale('ml'));
    });

    test('InterfaceLanguage.fromCode parses safely with English fallback', () {
      expect(InterfaceLanguage.fromCode('en'), InterfaceLanguage.english);
      expect(InterfaceLanguage.fromCode('te'), InterfaceLanguage.telugu);
      expect(InterfaceLanguage.fromCode('ta'), InterfaceLanguage.tamil);
      expect(InterfaceLanguage.fromCode('kn'), InterfaceLanguage.kannada);
      expect(InterfaceLanguage.fromCode('ml'), InterfaceLanguage.malayalam);

      // Fallback on invalid or unsupported code
      expect(InterfaceLanguage.fromCode('xyz'), InterfaceLanguage.english);
      expect(InterfaceLanguage.fromCode(''), InterfaceLanguage.english);
    });

    test('AppState manages interfaceLanguage and notifies listeners', () {
      final appState = AppState();
      expect(appState.interfaceLanguage, InterfaceLanguage.english);
      expect(appState.locale, const Locale('en'));

      int notifications = 0;
      appState.addListener(() => notifications++);

      appState.setInterfaceLanguage(InterfaceLanguage.telugu);
      expect(appState.interfaceLanguage, InterfaceLanguage.telugu);
      expect(appState.locale, const Locale('te'));
      expect(notifications, 1);

      // Idempotency: setting the same language should not notify
      appState.setInterfaceLanguage(InterfaceLanguage.telugu);
      expect(notifications, 1);
    });

    test('Independence: Changing interface language does NOT modify scripture script', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      final pz = PersonalizationState(appState: appState);

      // Set initial script to Devanagari
      await pz.setScriptureScript(ScriptOption.devanagari);
      expect(appState.activeScript, ScriptOption.devanagari);
      expect(pz.scriptureScript, ScriptOption.devanagari);

      // Change UI interface language to Telugu
      await pz.setInterfaceLanguage('te');
      expect(pz.interfaceLanguage, 'te');
      expect(appState.interfaceLanguage, InterfaceLanguage.telugu);

      // Verify scripture script remains Devanagari (strictly independent)
      expect(appState.activeScript, ScriptOption.devanagari);
      expect(pz.scriptureScript, ScriptOption.devanagari);

      // Change UI interface language to Tamil
      await pz.setInterfaceLanguage('ta');
      expect(appState.interfaceLanguage, InterfaceLanguage.tamil);
      expect(appState.activeScript, ScriptOption.devanagari);
    });

    test('PersonalizationState persists interface language in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      final pz = PersonalizationState(appState: appState);

      await pz.setInterfaceLanguage('kn');
      expect(pz.interfaceLanguage, 'kn');
      expect(appState.interfaceLanguage, InterfaceLanguage.kannada);

      // Re-instantiate state to verify restoration
      final restoredState = PersonalizationState(appState: appState);
      // Wait microtask for async _init
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(restoredState.interfaceLanguage, 'kn');
    });

    test('Phase 18A compatibility: Existing preferences load with interface language defaults', () {
      final existingPrefs = {
        'selected_deity_ids': ['shiva', 'ganesha'],
        'scripture_script': 'devanagari',
        'sadhana_goals': {'japa_target': 108},
      };

      final parsed = DevoteePreferences.fromJson(existingPrefs);
      expect(parsed.interfaceLanguage, 'en');
      expect(parsed.scriptureScript, ScriptOption.devanagari);
      expect(parsed.selectedDeityIds, contains('shiva'));
    });
  });

  group('Phase 18B: Accessibility & Typography Fallbacks', () {
    test('AppTextStyles provides comprehensive Indic font family fallbacks', () {
      final fallback = AppTextStyles.indicFontFamilyFallback;
      expect(fallback, contains('Noto Sans Devanagari'));
      expect(fallback, contains('Noto Sans Telugu'));
      expect(fallback, contains('Noto Sans Tamil'));
      expect(fallback, contains('Noto Sans Kannada'));
      expect(fallback, contains('Noto Sans Malayalam'));
      expect(fallback, contains('Roboto'));
    });

    test('Verse styles incorporate font fallback list and scale properly', () {
      final devanagariStyle = AppTextStyles.verseDevanagari(false, scale: 1.18);
      expect(devanagariStyle.fontFamilyFallback, isNotNull);
      expect(devanagariStyle.fontFamilyFallback, contains('Noto Sans Devanagari'));
      expect(devanagariStyle.fontSize, closeTo(20 * 1.18, 0.01));

      final transliterationStyle = AppTextStyles.verseTransliteration(true, scale: 1.35);
      expect(transliterationStyle.fontFamilyFallback, isNotNull);
      expect(transliterationStyle.fontFamilyFallback, contains('Noto Sans Devanagari'));
      expect(transliterationStyle.fontSize, closeTo(15 * 1.35, 0.01));
    });

    test('TextScalePreference scales are calibrated accurately', () {
      expect(TextScalePreference.normal.scale, 1.0);
      expect(TextScalePreference.large.scale, 1.18);
      expect(TextScalePreference.extraLarge.scale, 1.35);
    });
  });

  group('Phase 18B: ARB Localization Resources Verification', () {
    test('All 5 ARB resource files exist and contain valid JSON', () {
      final locales = ['en', 'te', 'ta', 'kn', 'ml'];
      for (final loc in locales) {
        final file = File('lib/l10n/app_$loc.arb');
        expect(file.existsSync(), isTrue, reason: 'app_$loc.arb must exist');

        final content = file.readAsStringSync();
        final Map<String, dynamic> parsed = jsonDecode(content);
        expect(parsed['@@locale'], loc);
        expect(parsed.containsKey('appTitle'), isTrue);
        expect(parsed.containsKey('navHome'), isTrue);
        expect(parsed.containsKey('navLibrary'), isTrue);
        expect(parsed.containsKey('navSadhana'), isTrue);
        expect(parsed.containsKey('navSaved'), isTrue);
        expect(parsed.containsKey('navSettings'), isTrue);
        expect(parsed.containsKey('offlineModeBanner'), isTrue);
        expect(parsed.containsKey('offlineAvailable'), isTrue);
      }
    });

    test('Translated ARB keys preserve placeholders from English template', () {
      final enFile = File('lib/l10n/app_en.arb');
      final Map<String, dynamic> enJson = jsonDecode(enFile.readAsStringSync());

      final placeholderKeys = [
        'libraryVerseCount',
        'readerVerse',
        'readerVerseOf',
        'japaTargetLabel',
        'japaCompletedChants',
        'japaChantsRemaining',
        'japaMalaCompleted',
        'sadhanaStep',
      ];

      final locales = ['te', 'ta', 'kn', 'ml'];
      for (final loc in locales) {
        final locFile = File('lib/l10n/app_$loc.arb');
        final Map<String, dynamic> locJson = jsonDecode(locFile.readAsStringSync());

        for (final key in placeholderKeys) {
          expect(locJson.containsKey(key), isTrue, reason: '$key must be present in $loc');
          final enVal = enJson[key] as String;
          final locVal = locJson[key] as String;

          // Check placeholder tokens like {count}, {number}, {current}, {total}, {step}
          final regex = RegExp(r'\{[a-zA-Z0-9_]+\}');
          final enPlaceholders = regex.allMatches(enVal).map((m) => m.group(0)!).toSet();
          final locPlaceholders = regex.allMatches(locVal).map((m) => m.group(0)!).toSet();

          expect(locPlaceholders, enPlaceholders,
              reason: 'Placeholders for key $key in $loc must match English template exactly');
        }
      }
    });
  });

  group('Phase 18B: Offline Audio & Capabilities Inventory', () {
    test('Mantra repository clearly marks bundled vs unbundled recordings', () {
      final repo = MantraRepositoryImpl();
      final all = repo.getAllMantras();
      expect(all.isNotEmpty, isTrue);

      final bundled = all.where((m) => m.isBundled).toList();
      final unbundled = all.where((m) => !m.isBundled).toList();

      expect(bundled.isNotEmpty, isTrue);
      expect(unbundled.isNotEmpty, isTrue);

      // Verify bundled recordings declare a local asset path
      for (final m in bundled) {
        expect(m.bundledAssetPath, isNotNull);
        expect(m.bundledAssetPath!.startsWith('assets/audio/bundled/'), isTrue);
      }
    });
  });
}
