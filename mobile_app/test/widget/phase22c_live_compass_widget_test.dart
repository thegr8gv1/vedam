import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/services/compass_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_temples_data.dart';
import 'package:vedam_app/presentation/screens/divyadishi/widgets/live_compass_sheet.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

void main() {
  late MockCompassSensorProvider mockProvider;
  late CompassService compassService;
  late DivyaDishiState state;
  late Temple somnathTemple;

  setUp(() {
    mockProvider = MockCompassSensorProvider(isAvailable: true);
    compassService = CompassService(provider: mockProvider);
    state = DivyaDishiState(
      compassService: compassService,
      initialOrigin: SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi')),
    );
    somnathTemple = AuthenticTemplesData.initialTemples.firstWhere((t) => t.id == 'TEMPLE-0007');
  });

  tearDown(() {
    mockProvider.close();
  });

  Widget createTestWidget({Temple? temple}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: LiveCompassSheet(
          state: state,
          selectedTemple: temple,
          compassService: compassService,
        ),
      ),
    );
  }

  group('Phase 22C - LiveCompassSheet Widget Tests', () {
    testWidgets('Renders initial inactive compass UI with disclosures and Start button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(temple: somnathTemple));
      await tester.pumpAndSettle();

      // Header & subtitle
      expect(find.text('Live Sacred Compass'), findsOneWidget);
      expect(find.text('Foreground orientation aid • Zero GPS tracking'), findsOneWidget);

      // Devotional disclaimer banner
      expect(find.textContaining('DEVOTIONAL AID ONLY'), findsOneWidget);

      // Target temple card
      expect(find.text('Somnath Temple'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.textContaining('True Geodetic Bearing:'), findsOneWidget);

      // Initial stopped compass state
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('MAGNETIC NORTH'), findsNothing);
      expect(find.text('Start Live Compass'), findsOneWidget);

      // Interference guidance
      expect(find.textContaining('Calibration & Interference:'), findsOneWidget);
    });

    testWidgets('Tapping Start Live Compass activates sensor and displays live magnetic heading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(temple: somnathTemple));
      await tester.pumpAndSettle();

      // Tap Start Compass
      await tester.tap(find.text('Start Live Compass'));
      await tester.pump();

      // Emit reading from mock sensor
      mockProvider.emitReading(heading: 135.0, reference: 'MAGNETIC', accuracy: 3);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      // Verify active readout
      expect(find.text('135°'), findsOneWidget);
      expect(find.text('SE (Agneya)'), findsOneWidget);
      expect(find.text('MAGNETIC NORTH'), findsOneWidget);
      expect(find.text('HIGH ACCURACY'), findsOneWidget);

      // Verify Magnetic vs True North transparency notice
      expect(find.text('Magnetic vs True North Notice'), findsOneWidget);
      expect(find.textContaining('Turn-angle alignment is withheld'), findsOneWidget);

      // Stop button replaces Start button
      expect(find.text('Stop Compass'), findsOneWidget);
      expect(find.text('Start Live Compass'), findsNothing);
    });

    testWidgets('Low accuracy event updates accuracy badge to LOW ACCURACY', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Live Compass'));
      await tester.pump();

      mockProvider.emitReading(heading: 45.0, accuracy: 1); // Low accuracy code
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      expect(find.text('LOW ACCURACY'), findsOneWidget);
      expect(find.text('45°'), findsOneWidget);
      expect(find.text('NE (Ishanya)'), findsOneWidget);
    });

    testWidgets('Tapping Stop Compass halts sensor and restores Start Live Compass button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start compass
      await tester.tap(find.text('Start Live Compass'));
      await tester.pump();

      mockProvider.emitReading(heading: 270.0);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      expect(find.text('Stop Compass'), findsOneWidget);

      // Tap Stop Compass
      await tester.tap(find.text('Stop Compass'));
      await tester.pumpAndSettle();

      expect(find.text('Start Live Compass'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
      expect(compassService.isActive, isFalse);
    });

    testWidgets('Hardware unavailable state displays clear unsupported message and Close button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unavailProvider = MockCompassSensorProvider(isAvailable: false);
      final unavailService = CompassService(provider: unavailProvider);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LiveCompassSheet(
            state: state,
            compassService: unavailService,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Start
      await tester.tap(find.text('Start Live Compass'));
      await tester.pumpAndSettle();

      expect(find.textContaining('hardware is unavailable in this environment'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      unavailProvider.close();
    });
  });
}
