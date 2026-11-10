import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/geographic_coordinate.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/services/compass_service.dart';
import 'package:vedam_app/presentation/screens/divyadishi/widgets/live_compass_sheet.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

class _FakeCompassSensorProvider implements CompassSensorProvider {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  void emit(double heading, {int accuracy = 3, String reference = 'magnetic'}) {
    _controller.add({
      'heading': heading,
      'accuracy': accuracy,
      'reference': reference,
    });
  }

  @override
  Stream<Map<String, dynamic>> get headingStream => _controller.stream;

  @override
  Future<bool> isSensorAvailable() async => true;

  void dispose() {
    _controller.close();
  }
}

void main() {
  late _FakeCompassSensorProvider fakeProvider;
  late CompassService compassService;
  late DivyaDishiState state;

  final kashiTemple = Temple(
    id: 'kashi_vishwanath',
    name: 'Kashi Vishwanath',
    deity: 'Shiva',
    tradition: TempleTradition.shaivism,
    city: 'Varanasi',
    state: 'Uttar Pradesh',
    country: 'India',
    coordinate: GeographicCoordinate(25.3109, 83.0107),
    verificationStatus: CoordinateVerificationStatus.pendingVerification,
    pointType: CoordinatePointType.compoundCenter,
    sourceName: 'User-Supplied Research Ledger',
    confidenceLevel: 'Provisional Compound Center',
    significance: 'One of the twelve Jyotirlingas.',
  );

  setUp(() {
    fakeProvider = _FakeCompassSensorProvider();
    compassService = CompassService(provider: fakeProvider);
    state = DivyaDishiState(compassService: compassService);
  });

  tearDown(() {
    fakeProvider.dispose();
  });

  Widget buildTestWidget({Temple? temple}) {
    return MaterialApp(
      home: Scaffold(
        body: LiveCompassSheet(
          state: state,
          selectedTemple: temple,
          compassService: compassService,
        ),
      ),
    );
  }

  testWidgets('1. Renders magnetic-only fallback when no origin is selected', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Live Sacred Compass'), findsOneWidget);
    expect(find.text('Start Live Compass'), findsOneWidget);
    expect(
      find.text('Select an approximate city origin to calculate geomagnetic declination for True North.'),
      findsOneWidget,
    );

    // Start compass and emit magnetic reading without origin
    await tester.tap(find.text('Start Live Compass'));
    await tester.pumpAndSettle();

    fakeProvider.emit(120.0, accuracy: 3, reference: 'magnetic');
    await tester.pumpAndSettle();

    expect(find.text('MAGNETIC NORTH'), findsOneWidget);
    expect(find.text('HIGH ACCURACY'), findsOneWidget);
    expect(find.text('Stop Compass'), findsOneWidget);
  });

  testWidgets('2. Origin selection enables True North badge, declination pill, and provenance', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
    state.setOrigin(varanasi);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Start compass and emit reading
    await tester.tap(find.text('Start Live Compass'));
    await tester.pumpAndSettle();

    fakeProvider.emit(100.0, accuracy: 3);
    await tester.pumpAndSettle();

    expect(find.text('TRUE NORTH (WMM-2025)'), findsOneWidget);
    expect(find.textContaining('DECLINATION:'), findsOneWidget);
    expect(find.textContaining('Varanasi, India'), findsOneWidget);
    expect(find.textContaining('Measured Sensor: 100.0° Mag'), findsOneWidget);
    expect(find.text('HIGH ACCURACY'), findsOneWidget);
  });

  testWidgets('3. Safeguard withholds destination alignment by default, opt-in exposes approximate comparison',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
    state.setOrigin(varanasi);

    await tester.pumpWidget(buildTestWidget(temple: kashiTemple));
    await tester.pumpAndSettle();

    // Start compass
    await tester.tap(find.text('Start Live Compass'));
    await tester.pumpAndSettle();

    fakeProvider.emit(90.0, accuracy: 3);
    await tester.pumpAndSettle();

    // Target temple card rendered with PENDING badge
    expect(find.text('Kashi Vishwanath'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);

    // Default safeguard notice rendered; turn angle withheld
    expect(find.text('Destination Coordinate Safeguard'), findsOneWidget);
    expect(find.text('Show Approximate Alignment Comparison'), findsOneWidget);
    expect(find.text('APPROXIMATE TEMPLE-COMPLEX ALIGNMENT'), findsNothing);

    // Tap to opt in
    await tester.tap(find.text('Show Approximate Alignment Comparison'));
    await tester.pumpAndSettle();

    // Now APPROXIMATE TEMPLE-COMPLEX ALIGNMENT is rendered
    expect(find.text('APPROXIMATE TEMPLE-COMPLEX ALIGNMENT'), findsOneWidget);
    expect(find.textContaining('Turn'), findsOneWidget);
    expect(find.textContaining('municipal centroid'), findsOneWidget);
    expect(find.textContaining('provisional temple coordinates'), findsOneWidget);

    // Tap hide icon
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Destination Coordinate Safeguard'), findsOneWidget);
    expect(find.text('APPROXIMATE TEMPLE-COMPLEX ALIGNMENT'), findsNothing);
  });

  testWidgets('4. Missing origin with target temple displays guidance notice', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(temple: kashiTemple));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Live Compass'));
    await tester.pumpAndSettle();

    fakeProvider.emit(100.0, accuracy: 3);
    await tester.pumpAndSettle();

    expect(find.textContaining('Select an approximate city origin to calculate geomagnetic declination'), findsOneWidget);
  });
}
