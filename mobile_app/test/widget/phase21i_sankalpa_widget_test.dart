import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/sankalpa_generator_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21I — Vedic Sankalpa Generator Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'vedam_sankalpa_gotra': 'Kashyapa',
        'vedam_sankalpa_name': 'Arjuna',
        'vedam_sankalpa_gender': 'male',
        'vedam_sankalpa_river_basin': 'ganga',
        'vedam_sankalpa_deity': 'Lord Shiva',
      });
    });

    Widget createTestableWidget({
      DailyPanchangamData? panchangam,
      SankalpaPurpose purpose = SankalpaPurpose.dailySadhana,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: SankalpaGeneratorModal(
            panchangam: panchangam,
            initialPurpose: purpose,
          ),
        ),
      );
    }

    testWidgets('Loads saved profile and renders classical Sankalpa', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vedic Sankalpa Generator'), findsOneWidget);
      expect(find.text('Sacred Intention & Panchangam Alignment'), findsOneWidget);
      expect(find.text('VEDIC SANKALPA (SACRED TEXT)'), findsOneWidget);

      // Verify that loaded profile is incorporated into text
      expect(find.textContaining('Kashyapa'), findsWidgets);
      expect(find.textContaining('Arjuna'), findsWidgets);
      expect(find.textContaining('Lord Shiva'), findsWidgets);
    });

    testWidgets('Toggles between Devanagari and IAST transliteration', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Initially Devanagari
      expect(find.textContaining('ॐ विष्णुर्विष्णुर्विष्णुः'), findsOneWidget);

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final iastSwitchFinder = find.byKey(const Key('switch_iast'));

      await tester.scrollUntilVisible(iastSwitchFinder, 100, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(iastSwitchFinder, findsOneWidget);
      await tester.tap(iastSwitchFinder);
      await tester.pumpAndSettle();

      // Scroll back up to verify recitation card has changed to IAST
      await tester.scrollUntilVisible(find.text('VEDIC SANKALPA (SACRED TEXT)'), -100, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('oṃ viṣṇur-viṣṇur-viṣṇuḥ'), findsOneWidget);
    });

    testWidgets('Toggles between Full and Short concise Sankalpa', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('VEDIC SANKALPA (SACRED TEXT)'), findsOneWidget);

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final shortSwitchFinder = find.byKey(const Key('switch_short'));

      await tester.scrollUntilVisible(shortSwitchFinder, 100, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(shortSwitchFinder, findsOneWidget);
      await tester.tap(shortSwitchFinder);
      await tester.pumpAndSettle();

      // Scroll back up to inspect updated concise card
      await tester.scrollUntilVisible(find.text('SANKALPA (CONCISE)'), -100, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(find.text('SANKALPA (CONCISE)'), findsOneWidget);
      expect(find.textContaining('ॐ अद्य'), findsOneWidget);
    });

    testWidgets('Switches ritual purpose and regenerates intention dynamically', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Tap Mantra Japa choice chip
      final japaChip = find.text('Mantra Japa (जप साधना)');
      await tester.tap(japaChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('मन्त्रजपं करिष्ये'), findsWidgets);

      // Tap Puja Worship choice chip
      final pujaChip = find.text('Puja Worship (षोडशोपचार पूजा)');
      await tester.ensureVisible(pujaChip);
      await tester.tap(pujaChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('षोडशोपचार पूजां करिष्ये'), findsWidgets);
    });

    testWidgets('Expands Structural Breakdown accordion to display 5 Vedic sections', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final breakdownFinder = find.byKey(const Key('tile_structural_breakdown'));

      await tester.scrollUntilVisible(breakdownFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(breakdownFinder, findsOneWidget);
      await tester.tap(breakdownFinder);
      await tester.pumpAndSettle();

      expect(find.text('COSMIC INVOCATION & EPOCH (कालोद्देश)'), findsOneWidget);
      expect(find.text('SACRED GEOGRAPHY (देशनिर्देश)'), findsOneWidget);
      expect(find.text('DAILY PANCHANGAM COORDINATES (पञ्चाङ्ग)'), findsOneWidget);
    });

    testWidgets('Renders cleanly in Dark Mode without layout overflow', (tester) async {
      await tester.pumpWidget(createTestableWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Vedic Sankalpa Generator'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
