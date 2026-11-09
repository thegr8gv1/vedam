import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/guided_sadhana.dart';
import 'package:vedam_app/data/fixtures/authentic_sadhana_plans_data.dart';
import 'package:vedam_app/presentation/screens/sadhana/guided_sadhana_screen.dart';
import 'package:vedam_app/presentation/screens/sadhana/widgets/sadhana_history_modal.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';

import '../unit/audio_state_and_japa_test.dart';

Widget createTestWidget({
  required Widget child,
  double textScale = 1.0,
  Size size = const Size(360, 640),
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21B: GuidedSadhanaScreen Widget & Integration Tests', () {
    late SharedPreferences prefs;
    late SadhanaState sadhanaState;
    late AudioState audioState;
    late GuidedSadhanaPlan plan;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sadhanaState = SadhanaState(prefs: prefs);
      audioState = AudioState(
        prefs: prefs,
        audioService: MockAudioPlaybackService(),
      );
      plan = AuthenticSadhanaPlansData.allPlans.first;
    });

    testWidgets('1. GuidedSadhanaScreen renders step 1 completely with title, progress, and actions', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & step indicator
      expect(find.text(plan.title), findsOneWidget);
      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      expect(find.text('0 of 5 Completed'), findsOneWidget);

      // Verify step 1 content
      expect(find.text(plan.steps[0].title), findsOneWidget);
      expect(find.text(plan.steps[0].description), findsOneWidget);

      // Verify bottom navigation
      expect(find.text('Prev'), findsOneWidget);
      expect(find.text('Complete Step'), findsOneWidget);
    });

    testWidgets('2. Completing step 1 updates progress and allows advancing to step 2', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Complete Step
      await tester.tap(find.text('Complete Step'));
      await tester.pumpAndSettle();

      // Progress updates to 1 of 5
      expect(find.text('1 of 5 Completed'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);

      // Tap Next Step
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Now on Step 2
      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(find.text(plan.steps[1].title), findsOneWidget);
    });

    testWidgets('3. Japa step renders integrated card and target repetitions', (tester) async {
      // Start directly on step 3 (Japa step)
      sadhanaState.startSadhana(plan, stepIndex: 2);

      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 3 OF 5'), findsOneWidget);
      expect(find.text(plan.steps[2].title), findsOneWidget);
      expect(find.text('Japa Practice Integration'), findsOneWidget);
      expect(find.textContaining('Target: 108 Chants'), findsOneWidget);
      expect(find.text('BEGIN JAPA PRACTICE (108 CHANTS)'), findsOneWidget);
    });

    testWidgets('4. Optional step can be skipped without marking complete', (tester) async {
      // Step 4 is optional (Svādhyāya)
      sadhanaState.startSadhana(plan, stepIndex: 3);

      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 4 OF 5'), findsOneWidget);
      expect(find.text('OPTIONAL'), findsOneWidget);
      expect(find.text('Skip (Optional)'), findsOneWidget);

      // Tap Skip
      await tester.tap(find.text('Skip (Optional)'));
      await tester.pumpAndSettle();

      // Auto-advances to step 5 without marking step 4 completed
      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(sadhanaState.isSadhanaStepCompleted(plan.steps[3].id), false);
      expect(sadhanaState.isSadhanaStepSkipped(plan.steps[3].id), true);
    });

    testWidgets('5. Finishing sadhana displays the calm completion view with summary', (tester) async {
      sadhanaState.startSadhana(plan, stepIndex: 4);
      sadhanaState.completeCurrentSadhanaStep();

      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On final step, button says Finish Sadhana
      expect(find.text('Finish Sadhana'), findsOneWidget);
      await tester.tap(find.text('Finish Sadhana'));
      await tester.pumpAndSettle();

      // Completion view renders
      expect(find.text('॥ साधना पूर्णम् ॥'), findsOneWidget);
      expect(find.text('Sadhana Completed with Steadfast Reverence'), findsOneWidget);
      expect(find.text('Return to Daily Sadhana'), findsOneWidget);
    });

    testWidgets('6. SadhanaHistoryModal displays empty state and opens properly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SadhanaHistoryModal.show(ctx, sadhanaState),
                child: const Text('Open History'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open History'));
      await tester.pumpAndSettle();

      expect(find.text('Sadhana History'), findsOneWidget);
      expect(find.text('No Guided Sadhana History Yet'), findsOneWidget);
    });

    testWidgets('7. Text scale 1.35x does not cause RenderFlex overflow on compact screen (360x640)', (tester) async {
      final List<FlutterErrorDetails> errors = [];
      FlutterError.onError = (details) {
        errors.add(details);
      };

      await tester.pumpWidget(
        createTestWidget(
          child: GuidedSadhanaScreen(
            plan: plan,
            sadhanaState: sadhanaState,
            audioState: audioState,
          ),
          textScale: 1.35,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors.where((e) => e.toString().contains('overflowed')).toList();
      expect(overflowErrors, isEmpty, reason: 'Layout must not overflow under 1.35x text scaling');
    });
  });
}
