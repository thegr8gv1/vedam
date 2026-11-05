import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/presentation/screens/panchangam/panchangam_screen.dart';
import 'package:vedam_app/state/panchangam_state.dart';

class StubPanchangamRepository implements PanchangamRepository {
  bool throwError = false;

  @override
  Future<DailyPanchangamData> getDailyPanchangam({
    required DateTime date,
    required PanchangamLocation location,
    String ayanamsa = 'lahiri',
  }) async {
    if (throwError) {
      throw const PanchangamUnavailableException(
        message: 'Astronomical Engine Offline',
        details: 'Server unreachable',
      );
    }
    return DailyPanchangamData(
      calculationTimestampUtc: DateTime.now(),
      requestedDate: date,
      location: location,
      vara: const PanchaAngaElement(
        number: 5,
        name: 'Guruvara',
        sanskritName: 'गुरुवार (Thursday)',
        meaning: 'Wisdom, spiritual study',
        presidingDeity: 'Brihaspati (Jupiter)',
      ),
      sunMoon: const SunMoonEvents(
        sunriseFormatted: '06:08 AM',
        sunsetFormatted: '05:14 PM',
        dayLengthHours: 11.1,
        dayLengthFormatted: '11h 6m',
        moonIlluminationPercent: 20.0,
      ),
      tithi: const PanchaAngaElement(
        number: 26,
        name: 'Krishna Ekadashi',
        sanskritName: 'कृष्ण एकादशी',
        endTimeFormatted: '10:35 AM',
        meaning: 'Rama Ekadashi fasting',
        presidingDeity: 'Vishnu',
      ),
      nakshatra: const PanchaAngaElement(
        number: 12,
        name: 'Uttara Phalguni',
        sanskritName: 'उत्तर फाल्गुनी',
        endTimeFormatted: '03:55 AM',
        meaning: 'Noble friendship, vows',
        presidingDeity: 'Aryaman',
      ),
      yoga: const PanchaAngaElement(
        number: 26,
        name: 'Aindra (Indra)',
        sanskritName: 'ऐन्द्र',
        endTimeFormatted: '07:12 PM',
        meaning: 'Nobility and strength',
      ),
      karana: const PanchaAngaElement(
        number: 52,
        name: 'Balava',
        sanskritName: 'बालव',
        endTimeFormatted: '10:35 AM',
        meaning: 'Spiritual humility',
      ),
      paksha: 'Krishna Paksha (Waning)',
      rahuKalam: TimePeriod(
        name: 'Rahu Kalam',
        sanskritName: 'राहुकाल',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '01:04 PM - 02:28 PM',
        isAuspicious: false,
        description: 'Governed by Rahu',
      ),
      yamagandam: TimePeriod(
        name: 'Yamagandam',
        sanskritName: 'यमगण्ड',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '06:08 AM - 07:31 AM',
        isAuspicious: false,
        description: 'Governed by Yama',
      ),
      gulikaKalam: TimePeriod(
        name: 'Gulika Kalam',
        sanskritName: 'गुलिक काल',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        formatted: '08:54 AM - 10:17 AM',
        isAuspicious: true,
        description: 'Governed by Gulika',
      ),
      abhijitMuhurat: TimePeriod(
        name: 'Abhijit Muhurat',
        sanskritName: 'अभिजित् मुहूर्त',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 48)),
        formatted: '11:45 AM - 12:33 PM',
        isAuspicious: true,
        description: 'Midday 8th muhurta',
      ),
      observances: const [
        Observance(
          name: 'Krishna Ekadashi Vratam',
          sanskritName: 'कृष्ण एकादशी व्रतम्',
          category: 'Ekadashi',
          description: 'Sacred fast',
        )
      ],
      conventions: const CalculationConventions(
        ayanamsaUsed: 'Lahiri (Chitra Paksha)',
        ayanamsaValueDegrees: 24.23,
        ayanamsaValueFormatted: '24° 13\' 55.59"',
        ephemerisEngine: 'Astronomy Engine 2.1',
        coordinateSystem: 'Geocentric',
        sunriseConvention: '-50\'',
        timeScale: 'TT to UTC',
        udayaTithiRule: 'Sunrise tithi governs day',
      ),
    );
  }

  @override
  Future<List<PanchangamLocation>> getCuratedLocations({String? query}) async {
    return [PanchangamLocation.varanasi];
  }
}

void main() {
  testWidgets('PanchangamScreen renders real calculated Panchangam elements', (tester) async {
    final repo = StubPanchangamRepository();
    final state = PanchangamState(
      repository: repo,
      initialDate: DateTime(2026, 11, 5),
    );

    // Provide large virtual viewport height
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PanchangamScreen(
          state: state,
          repository: repo,
        ),
      ),
    );

    // Initial pump triggers loadPanchangam
    await tester.pumpAndSettle();

    // Verify Header and Location
    expect(find.text('Panchangam (पञ्चाङ्गम्)'), findsOneWidget);
    expect(find.textContaining('Varanasi'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);

    // Verify 5 Primary Elements
    expect(find.textContaining('Guruvara'), findsOneWidget);
    expect(find.text('Krishna Ekadashi • कृष्ण एकादशी'), findsOneWidget);
    expect(find.text('Uttara Phalguni • उत्तर फाल्गुनी'), findsOneWidget);
    expect(find.text('Aindra (Indra) • ऐन्द्र'), findsOneWidget);
    expect(find.text('Balava • बालव'), findsOneWidget);

    // Verify Sun & Moon timings
    expect(find.text('06:08 AM'), findsOneWidget);
    expect(find.text('05:14 PM'), findsOneWidget);

    // Verify Muhurtas
    expect(find.text('01:04 PM - 02:28 PM'), findsOneWidget); // Rahu Kalam
    expect(find.text('11:45 AM - 12:33 PM'), findsOneWidget); // Abhijit

    // Verify Observance
    expect(find.textContaining('Krishna Ekadashi Vratam'), findsOneWidget);

    // Verify Calculation Conventions card
    expect(find.text('ASTRONOMICAL CALCULATION STANDARDS'), findsOneWidget);
  });

  testWidgets('PanchangamScreen renders honest unavailable state when disconnected', (tester) async {
    final repo = StubPanchangamRepository()..throwError = true;
    final state = PanchangamState(
      repository: repo,
      initialDate: DateTime(2026, 11, 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PanchangamScreen(
          state: state,
          repository: repo,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Unavailable view
    expect(find.text('Astronomical Engine Offline'), findsOneWidget);
    expect(find.textContaining('Section 8 authenticity standards'), findsOneWidget);
    expect(find.text('Retry Astronomical Calculation'), findsOneWidget);
  });
}
