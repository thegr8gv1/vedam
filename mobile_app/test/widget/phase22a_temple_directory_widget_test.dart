import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/divyadishi/temple_directory_screen.dart';
import 'package:vedam_app/presentation/screens/divyadishi/widgets/temple_detail_modal.dart';
import 'package:vedam_app/state/divyadishi_state.dart';

void main() {
  Widget createTestWidget({DivyaDishiState? state}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: TempleDirectoryScreen(state: state),
    );
  }

  group('Phase 22A - TempleDirectoryScreen Widget Tests', () {
    testWidgets('Renders directory screen with header, warning banner, and origin bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DivyaDishiState();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('DivyaDishi Directory'), findsOneWidget);
      expect(find.text('Provisional Sacred Temples'), findsOneWidget);

      // Verify Warning Banner
      expect(find.textContaining('PROVISIONAL DIRECTORY: Coordinates are user-supplied'), findsOneWidget);

      // Verify Origin Status Bar
      expect(find.text('No origin selected (Bearings uncalculated)'), findsOneWidget);
      expect(find.text('Set City'), findsOneWidget);

      // Verify Search input
      expect(find.byType(TextField), findsOneWidget);

      // Verify Filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('India'), findsOneWidget);
      expect(find.text('Nepal'), findsOneWidget);

      // Verify initial cards and UNVERIFIED tags
      expect(find.text('Somnath Temple'), findsOneWidget);
      expect(find.text('UNVERIFIED'), findsWidgets);
    });

    testWidgets('Search query filters temple list in UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DivyaDishiState();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Somnath');
      await tester.pumpAndSettle();

      expect(find.text('Somnath Temple'), findsOneWidget);
      expect(find.text('Kashi Vishwanath Temple'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Somnath Temple'), findsOneWidget);
      expect(find.text('Kashi Vishwanath Temple'), findsOneWidget);
    });

    testWidgets('Country filter choice chip filters temple list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DivyaDishiState();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Tap Nepal filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Nepal'));
      await tester.pumpAndSettle();

      expect(find.text('Pashupatinath Temple'), findsOneWidget);
      expect(find.text('Muktinath Temple'), findsOneWidget);
      expect(find.text('Janaki Mandir'), findsOneWidget);
      expect(find.text('Somnath Temple'), findsNothing);

      // Tap All filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Somnath Temple'), findsOneWidget);
      expect(find.text('Kashi Vishwanath Temple'), findsOneWidget);
    });

    testWidgets('Origin selection dialog updates reference origin and computes bearings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DivyaDishiState();
      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Tap 'Set City' button
      await tester.tap(find.text('Set City'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Select Origin Point'), findsOneWidget);
      expect(find.text('Varanasi, India'), findsOneWidget);

      // Select Varanasi
      await tester.tap(find.text('Varanasi, India'));
      await tester.pumpAndSettle();

      // Verify origin status bar updated
      expect(find.text('Reference Origin: Varanasi, India (Approximate)'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Verify bearing badges appear on temple cards
      expect(find.byIcon(Icons.explore), findsWidgets);
    });

    testWidgets('Tapping a temple opens TempleDetailModal with provenance and bearing info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DivyaDishiState();
      final varanasi = SacredOrigin.canonicalCities.firstWhere((c) => c.name.contains('Varanasi'));
      state.setOrigin(varanasi);

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Tap on Somnath Temple card
      await tester.tap(find.text('Somnath Temple'));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.byType(TempleDetailModal), findsOneWidget);
      expect(find.text('Somnath Temple'), findsWidgets);
      expect(find.textContaining('PROVISIONAL COORDINATE NOTICE'), findsOneWidget);
      expect(find.text('Sacred Bearing & Direction'), findsOneWidget);
      expect(find.text('Traditional Dishā'), findsOneWidget);
      expect(find.text('Great-Circle Distance'), findsOneWidget);
      expect(find.textContaining('From: Varanasi, India'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(TempleDetailModal), findsNothing);
    });
  });
}
