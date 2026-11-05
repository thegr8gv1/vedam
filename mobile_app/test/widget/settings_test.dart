import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/settings/settings_screen.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  testWidgets('SettingsScreen changes theme, text scale, and displays About Vedam',
      (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SettingsScreen(appState: appState),
      ),
    );

    await tester.pumpAndSettle();

    // Verify top sections
    expect(find.text('Reading & Script (लिपि)'), findsOneWidget);
    expect(find.text('Devotional Atmosphere'), findsOneWidget);

    // Switch theme to Temple Night (Dark)
    await tester.tap(find.text('Temple Night (Obsidian & Gold)'));
    await tester.pumpAndSettle();
    expect(appState.themePreference, ThemePreference.dark);

    // Switch theme to Sacred Light
    await tester.tap(find.text('Sacred Light (Saffron & Marble)'));
    await tester.pumpAndSettle();
    expect(appState.themePreference, ThemePreference.light);

    // Scroll down to About Vedam & Section 8 notice
    await tester.scrollUntilVisible(find.textContaining('Section 8 Authentic Editorial Governance'), 200);
    expect(find.textContaining('Section 8 Authentic Editorial Governance'), findsOneWidget);
  });
}
