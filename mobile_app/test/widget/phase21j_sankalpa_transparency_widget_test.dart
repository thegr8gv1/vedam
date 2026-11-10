import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/sankalpa_model.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/sankalpa_generator_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21J — Sankalpa Transparency & UI Hardening Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'vedam_sankalpa_gotra': 'Kashyapa',
        'vedam_sankalpa_name': 'Arjuna',
        'vedam_sankalpa_gender': 'male',
        'vedam_sankalpa_river_basin': 'ganga',
        'vedam_sankalpa_deity': 'Lord Shiva',
        'vedam_sankalpa_anonymous': false,
      });
    });

    DailyPanchangamData createMockPanchangam() {
      return DailyPanchangamData(
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
    }

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

    testWidgets('1. Shows APPROXIMATE • OFFLINE badge when Panchangam is offline', (tester) async {
      await tester.pumpWidget(createTestableWidget(panchangam: null));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chip_panchangam_source')), findsOneWidget);
      expect(find.text('APPROXIMATE • OFFLINE'), findsOneWidget);
      expect(find.textContaining('approximated mathematically'), findsOneWidget);
    });

    testWidgets('2. Shows LIVE PANCHANGAM badge when live ephemeris is provided', (tester) async {
      await tester.pumpWidget(createTestableWidget(panchangam: createMockPanchangam()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chip_panchangam_source')), findsOneWidget);
      expect(find.text('LIVE PANCHANGAM'), findsOneWidget);
      expect(find.textContaining('approximated mathematically'), findsNothing);
    });

    testWidgets('3. Renders Scholarly Disclosure card with traditional template advisory', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final disclosureFinder = find.byKey(const Key('card_scholarly_disclosure'));

      await tester.scrollUntilVisible(disclosureFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      expect(disclosureFinder, findsOneWidget);
      expect(find.textContaining('Traditional Recitation Template'), findsOneWidget);
      expect(find.textContaining('qualified family purohita or acharya'), findsOneWidget);
    });

    testWidgets('4. Toggling Anonymous switch updates formula to universal seeker and hides name inputs', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final scrollFinder = find.descendant(
        of: find.byKey(const Key('sankalpa_scroll_view')),
        matching: find.byType(Scrollable),
      ).first;
      final personalizationFinder = find.byKey(const Key('tile_personalization'));

      // Scroll to personalization accordion and open it
      await tester.scrollUntilVisible(personalizationFinder, 150, scrollable: scrollFinder);
      await tester.pumpAndSettle();
      await tester.tap(personalizationFinder);
      await tester.pumpAndSettle();

      final anonSwitchFinder = find.byKey(const Key('switch_anonymous'));
      expect(anonSwitchFinder, findsOneWidget);

      // Verify name fields are initially visible
      expect(find.text('Devotee Gotra (Optional)'), findsOneWidget);
      expect(find.text('Devotee Name'), findsOneWidget);

      // Toggle anonymous mode ON
      await tester.tap(anonSwitchFinder);
      await tester.pumpAndSettle();

      // Gotra and Name fields should now be hidden
      expect(find.text('Devotee Gotra (Optional)'), findsNothing);
      expect(find.text('Devotee Name'), findsNothing);

      // Scroll back up to recitation card
      await tester.scrollUntilVisible(find.text('VEDIC SANKALPA (SACRED TEXT)'), -150, scrollable: scrollFinder);
      await tester.pumpAndSettle();

      // Recitation text must now contain universal 'मम आत्मनः' and not 'Arjuna'
      expect(find.textContaining('मम आत्मनः'), findsWidgets);
      expect(find.textContaining('Arjuna'), findsNothing);
    });
  });
}
