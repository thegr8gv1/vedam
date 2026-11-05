import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/presentation/screens/sadhana/guided_puja_screen.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GuidedPujaScreen renders steps, navigates, and shows completion view',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));
    final guide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: GuidedPujaScreen(
          guide: guide,
          sadhanaState: sadhanaState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Step 1
    expect(find.text('Daily Ganesha Pancha Upachara Puja'), findsOneWidget);
    expect(find.text('STEP 1 OF ${guide.steps.length}'), findsOneWidget);
    expect(find.text('DHYĀNAM'), findsOneWidget);
    expect(find.textContaining('Vakratuṇḍa'), findsOneWidget);
    expect(find.text('LINKED CHANTING PRACTICE'), findsOneWidget);
    expect(find.text('NEXT STEP'), findsOneWidget);

    // 2. Navigate to Step 2
    await tester.tap(find.text('NEXT STEP'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF ${guide.steps.length}'), findsOneWidget);
    expect(find.text('GANDHAM'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsOneWidget);

    // 3. Navigate back to Step 1
    await tester.tap(find.text('PREVIOUS'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF ${guide.steps.length}'), findsOneWidget);

    // 4. Fast forward to last step
    sadhanaState.goToStep(guide.steps.length - 1);
    await tester.pumpAndSettle();

    expect(find.text('STEP ${guide.steps.length} OF ${guide.steps.length}'), findsOneWidget);
    expect(find.text('COMPLETE WORSHIP'), findsOneWidget);

    // 5. Complete Worship
    await tester.tap(find.text('COMPLETE WORSHIP'));
    await tester.pumpAndSettle();

    // Verify Completion View
    expect(find.text('Pūjā Sampanna (Worship Completed)'), findsOneWidget);
    expect(find.textContaining('सर्वं श्रीकृष्णार्पणमस्तु'), findsOneWidget);
    expect(find.text('RETURN TO DAILY SADHANA'), findsOneWidget);
  });
}
