import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/presentation/screens/sadhana/sadhana_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SadhanaScreen renders dashboard, practices, catalog, and Japa counter',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));
    final appState = AppState();

    // Large test viewport
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SadhanaScreen(
          appState: appState,
          sadhanaState: sadhanaState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify App Bar and Date
    expect(find.text('Daily Sadhana'), findsOneWidget);
    expect(find.textContaining('NOVEMBER 2026'), findsOneWidget);

    // 2. Verify Overview Card
    expect(find.text('DAILY PRACTICE OVERVIEW'), findsOneWidget);
    expect(find.text('0 of 5 Completed'), findsOneWidget);
    expect(find.textContaining('shraddha'), findsOneWidget);

    // 3. Verify Active Practices in Routine
    expect(find.text('MY DAILY ROUTINE'), findsOneWidget);
    expect(find.text('Prātah Smaraṇam (Morning Prayer)'), findsOneWidget);
    expect(find.text('Daily Ganesha Puja'), findsOneWidget);
    expect(find.text('Gayatri Mahamantra Japa'), findsOneWidget);

    // 4. Verify Toggle Completion
    final checkIconsBefore = find.byIcon(Icons.check);
    expect(checkIconsBefore, findsNothing);

    // Tap first practice checkmark circle
    final toggleFinder = find.byKey(const Key('toggle_practice_morning_prayer'));
    expect(toggleFinder, findsOneWidget);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    // After tap, overview updates
    expect(find.text('1 of 5 Completed'), findsOneWidget);

    // 5. Verify Guided Puja Catalog
    expect(find.text('Guided Puja Catalog'), findsOneWidget);
    expect(find.text('Daily Ganesha Pancha Upachara Puja'), findsOneWidget);
    expect(find.text('Daily Shiva Pancha Upachara Puja'), findsOneWidget);
    expect(find.text('Daily Vishnu Pancha Upachara Puja'), findsOneWidget);
    expect(find.text('Daily Mahalakshmi Prarthana & Puja'), findsOneWidget);

    // 6. Verify Manual Japa Mala Counter
    expect(find.text('MANUAL JAPA MALA COUNTER'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('CHANT & COUNT BEAD'), findsOneWidget);

    // Tap Bead count button (scroll to ensure visible first)
    final beadButtonFinder = find.text('CHANT & COUNT BEAD');
    await tester.ensureVisible(beadButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(beadButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Reset button
    await tester.tap(find.byTooltip('Reset Counter'));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsWidgets);
  });
}
