import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  group('AppState Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('initial state matches defaults', () {
      expect(appState.themePreference, ThemePreference.system);
      expect(appState.textScalePreference, TextScalePreference.normal);
      expect(appState.fontScale, 1.0);
      expect(appState.activeScript, ScriptOption.devanagari);
    });

    test('theme preference updates themeMode', () {
      appState.setThemePreference(ThemePreference.dark);
      expect(appState.themePreference, ThemePreference.dark);
      expect(appState.themeMode, ThemeMode.dark);

      appState.setThemePreference(ThemePreference.light);
      expect(appState.themePreference, ThemePreference.light);
      expect(appState.themeMode, ThemeMode.light);
    });

    test('text scale preference updates fontScale', () {
      appState.setTextScalePreference(TextScalePreference.large);
      expect(appState.fontScale, 1.18);

      appState.setTextScalePreference(TextScalePreference.extraLarge);
      expect(appState.fontScale, 1.35);
    });

    test('active script updates correctly', () {
      appState.setActiveScript(ScriptOption.telugu);
      expect(appState.activeScript, ScriptOption.telugu);

      appState.setActiveScript(ScriptOption.iast);
      expect(appState.activeScript, ScriptOption.iast);
    });

    test('toggleFavorite adds and removes scriptures', () {
      // Check toggle
      expect(appState.isFavorite(10), isFalse);
      appState.toggleFavorite(10);
      expect(appState.isFavorite(10), isTrue);
      expect(appState.favoriteScriptureIds.contains(10), isTrue);

      appState.toggleFavorite(10);
      expect(appState.isFavorite(10), isFalse);
    });

    test('recordRecentlyRead adds to top of recents and dedupes', () {
      appState.recordRecentlyRead(15);
      expect(appState.recentlyReadScriptureIds.first, 15);

      appState.recordRecentlyRead(20);
      expect(appState.recentlyReadScriptureIds.first, 20);

      // Re-record 15 moves it back to top
      appState.recordRecentlyRead(15);
      expect(appState.recentlyReadScriptureIds.first, 15);
    });
  });
}
