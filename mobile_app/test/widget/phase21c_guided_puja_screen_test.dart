import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/presentation/screens/sadhana/guided_puja_screen.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/puja_guide_overview_modal.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/puja_history_modal.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/puja_preparation_modal.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21C: GuidedPujaScreen Widget & Integration Tests', () {
    late SharedPreferences prefs;
    late SadhanaState sadhanaState;
    final guide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 9));
    });

    testWidgets('1. GuidedPujaScreen renders Step 1 with Devanagari, Action, and Japa card',
        (WidgetTester tester) async {
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

      // Verify Title & Step counter
      expect(find.text('Daily Ganesha Pancha Upachara Puja'), findsOneWidget);
      expect(find.text('STEP 1 OF ${guide.steps.length}'), findsOneWidget);

      // Verify Action Guidance
      expect(find.text('PRAYER ACTION'), findsOneWidget);
      expect(find.textContaining('Anjali Mudra'), findsOneWidget);

      // Verify Sacred Sanskrit Mantra
      expect(find.text('SACRED SANSKRIT MANTRA'), findsOneWidget);
      expect(find.textContaining('वक्रतुण्ड'), findsOneWidget);
      expect(find.textContaining('Vakratuṇḍa'), findsOneWidget);

      // Verify Linked Japa Card & Target Repetitions (11 chants)
      expect(find.text('LINKED CHANTING PRACTICE'), findsOneWidget);
      expect(find.text('11 CHANTS'), findsOneWidget);
      expect(find.text('NEXT STEP'), findsOneWidget);
    });

    testWidgets('2. Preparation Checklist modal opens, toggles materials, and updates count',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PujaPreparationModal.show(
                  context: ctx,
                  guide: guide,
                  sadhanaState: sadhanaState,
                ),
                child: const Text('Open Prep'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Prep'));
      await tester.pumpAndSettle();

      expect(find.text('PŪJĀ SĀMAGRĪ & PREPARATION'), findsOneWidget);
      expect(find.text('Required Materials'), findsOneWidget);
      expect(find.text('Optional Materials'), findsOneWidget);
      expect(find.text('SAVE & RETURN TO WORSHIP'), findsOneWidget);

      // Toggle first required material
      final firstMaterial = guide.requiredMaterials.first;
      expect(sadhanaState.isMaterialPrepared(firstMaterial), false);

      await tester.tap(find.text(firstMaterial));
      await tester.pumpAndSettle();

      expect(sadhanaState.isMaterialPrepared(firstMaterial), true);

      // Close modal
      await tester.tap(find.text('SAVE & RETURN TO WORSHIP'));
      await tester.pumpAndSettle();
      expect(find.text('PŪJĀ SĀMAGRĪ & PREPARATION'), findsNothing);
    });

    testWidgets('3. Steps overview modal opens and displays upcoming steps without altering step index',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      sadhanaState.startPujaSession(guide);
      expect(sadhanaState.activeGuideStepIndex, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PujaGuideOverviewModal.show(
                  context: ctx,
                  guide: guide,
                  currentStepIndex: sadhanaState.activeGuideStepIndex,
                  onStart: () {},
                ),
                child: const Text('Open Overview'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Overview'));
      await tester.pumpAndSettle();

      expect(find.text('Ordered Steps (${guide.steps.length} Steps)'), findsOneWidget);
      expect(find.text('Gandham Samarpayāmi (Offering Sandalwood Paste)'), findsOneWidget);

      // Step index must strictly remain at 0
      expect(sadhanaState.activeGuideStepIndex, 0);

      // Close overview
      await tester.tap(find.byTooltip('Close Overview'));
      await tester.pumpAndSettle();
      expect(find.text('Ordered Steps (${guide.steps.length} Steps)'), findsNothing);
    });

    testWidgets('4. Optional step displays OPTIONAL badge and SKIP button; skipping advances step',
        (WidgetTester tester) async {
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

      // Advance to Step 2
      await tester.tap(find.text('NEXT STEP'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 2 OF ${guide.steps.length}'), findsOneWidget);

      // Advance to Step 3 (which is marked isOptional: true)
      await tester.tap(find.text('NEXT STEP'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF ${guide.steps.length}'), findsOneWidget);
      expect(find.text('OPTIONAL'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      final step3 = sadhanaState.currentGuideStep!;
      expect(step3.isOptional, true);

      // Tap SKIP
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Must be on Step 4
      expect(find.text('STEP 4 OF ${guide.steps.length}'), findsOneWidget);
      expect(sadhanaState.activePujaSession!.skippedStepIds, contains(step3.id));
      expect(sadhanaState.activePujaSession!.completedStepIds, isNot(contains(step3.id)));
    });

    testWidgets('5. Step through all steps and COMPLETE WORSHIP shows reverent completion view',
        (WidgetTester tester) async {
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

      // Jump to last step
      sadhanaState.goToPujaStep(guide.steps.length - 1);
      await tester.pumpAndSettle();

      expect(find.text('STEP ${guide.steps.length} OF ${guide.steps.length}'), findsOneWidget);
      expect(find.text('COMPLETE WORSHIP'), findsOneWidget);

      await tester.tap(find.text('COMPLETE WORSHIP'));
      await tester.pumpAndSettle();

      // Verify completion view
      expect(find.text('Pūjā Sampanna (Worship Completed)'), findsOneWidget);
      expect(find.textContaining('सर्वं श्रीकृष्णार्पणमस्तु'), findsOneWidget);
      expect(find.text('RETURN TO DAILY SADHANA'), findsOneWidget);
      expect(sadhanaState.isGuideCompleted, true);
      expect(sadhanaState.pujaHistory.length, 1);
    });

    testWidgets('6. PujaHistoryModal renders completed sessions and handles Clear History',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Complete a session first
      sadhanaState.startPujaSession(guide);
      sadhanaState.completeCurrentPujaStep();
      sadhanaState.finishPujaSession();

      expect(sadhanaState.pujaHistory.length, 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PujaHistoryModal.show(
                  context: ctx,
                  sadhanaState: sadhanaState,
                ),
                child: const Text('Open History'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open History'));
      await tester.pumpAndSettle();

      expect(find.text('Completed Puja Sessions'), findsOneWidget);
      expect(find.text('Daily Ganesha Pancha Upachara Puja'), findsOneWidget);
      expect(find.text('SAMPANNA'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear and confirm in dialog
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Puja History?'), findsOneWidget);
      await tester.tap(find.text('Clear History'));
      await tester.pumpAndSettle();

      expect(sadhanaState.pujaHistory, isEmpty);
      expect(find.text('No Puja Records Yet'), findsOneWidget);
    });

    testWidgets('7. Compact screen (360x640dp) with 1.35x font scaling renders without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.35),
              size: Size(360, 640),
            ),
            child: GuidedPujaScreen(
              guide: guide,
              sadhanaState: sadhanaState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex errors were thrown and key elements are present
      expect(tester.takeException(), isNull);
      expect(find.text('Daily Ganesha Pancha Upachara Puja'), findsOneWidget);
      expect(find.text('NEXT STEP'), findsOneWidget);
    });
  });
}
