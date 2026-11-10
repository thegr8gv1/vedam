import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/sankalpa_generator_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21K — Sankalpa Safety & Privacy Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'vedam_sankalpa_gotra': '',
        'vedam_sankalpa_name': 'Arjuna',
        'vedam_sankalpa_gender': 'male',
        'vedam_sankalpa_river_basin': 'ganga',
        'vedam_sankalpa_deity': 'Sri Parameshwara',
        'vedam_sankalpa_anonymous': false,
      });
    });

    Widget createTestableWidget({DailyPanchangamData? panchangam}) {
      return MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: SankalpaGeneratorModal(
            panchangam: panchangam,
            initialPurpose: SankalpaPurpose.dailySadhana,
          ),
        ),
      );
    }

    testWidgets('1. Displays empty Gotra as omitted and does NOT silently show Vishnu gotra', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Recitation text must not have Vishnu gotra
      expect(find.textContaining('Vishnu-गोत्रस्य'), findsNothing);
      expect(find.textContaining('विष्णु-गोत्रस्य'), findsNothing);
      expect(find.textContaining('Arjuna शर्मणः'), findsWidgets);
    });

    testWidgets('2. Personalization panel displays "Hide Personal Details" and optional Gotra helper text', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final personalizationFinder = find.byKey(const Key('tile_personalization'));

      await tester.scrollUntilVisible(personalizationFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();
      await tester.tap(personalizationFinder);
      await tester.pumpAndSettle();

      // Verify refined privacy wording
      expect(find.text('Hide Personal Details'), findsOneWidget);
      expect(find.textContaining('Omits personal lineage identifiers'), findsOneWidget);

      // Verify Gotra field label and helper
      expect(find.text('Devotee Gotra (Optional)'), findsOneWidget);
      expect(find.text('Leave blank to omit Gotra if unspecified or unknown'), findsOneWidget);
    });

    testWidgets('3. Toggling Hide Personal Details conceals identity fields and updates recitation', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final personalizationFinder = find.byKey(const Key('tile_personalization'));

      await tester.scrollUntilVisible(personalizationFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();
      await tester.tap(personalizationFinder);
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('switch_anonymous'));
      expect(switchFinder, findsOneWidget);

      // Devotee Name is initially visible
      expect(find.text('Devotee Name'), findsOneWidget);

      // Toggle ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Inputs are now hidden
      expect(find.text('Devotee Name'), findsNothing);
      expect(find.text('Devotee Gotra (Optional)'), findsNothing);

      // Scroll up to recitation
      await tester.scrollUntilVisible(find.text('VEDIC SANKALPA (SACRED TEXT)'), -150, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      // Recitation contains first-person phrasing and no 'Arjuna'
      expect(find.textContaining('मम आत्मनः'), findsWidgets);
      expect(find.textContaining('Arjuna'), findsNothing);
    });

    testWidgets('4. Scholarly Disclosure card displays explicit purohita/acharya advisory and Gotra omission note', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final cardFinder = find.byKey(const Key('card_scholarly_disclosure'));

      await tester.scrollUntilVisible(cardFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(cardFinder, findsOneWidget);
      expect(find.textContaining('does not claim universal ritual authority'), findsOneWidget);
      expect(find.textContaining('qualified family purohita or acharya'), findsOneWidget);
      expect(find.textContaining('Unspecified Gotra values are omitted'), findsOneWidget);
    });
  });
}
