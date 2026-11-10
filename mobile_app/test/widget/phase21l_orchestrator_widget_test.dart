import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/practice_sequence.dart';
import 'package:vedam_app/presentation/screens/sadhana/orchestrator/journal_history_modal.dart';
import 'package:vedam_app/presentation/screens/sadhana/orchestrator/nitya_sadhana_dashboard.dart';
import 'package:vedam_app/presentation/screens/sadhana/orchestrator/sequence_editor_modal.dart';
import 'package:vedam_app/presentation/screens/sadhana/orchestrator/sequence_execution_modal.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/orchestrator_state.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NityaSadhanaDashboard Widget Tests', () {
    testWidgets('Renders Nitya Sadhana header, morning/evening cards, and streak badges', (tester) async {
      final orchestratorState = OrchestratorState();
      final appState = AppState();
      await tester.pump();

      await tester.pumpWidget(
        _wrapWithApp(
          SingleChildScrollView(
            child: NityaSadhanaDashboard(
              orchestratorState: orchestratorState,
              appState: appState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Nitya Sadhana Flow'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);

      // Check Morning and Evening sequence cards
      expect(find.text('Morning Sadhana'), findsOneWidget);
      expect(find.text('Evening Sadhana'), findsOneWidget);
      expect(find.text('Start Practice'), findsNWidgets(2));

      // Check Streak Badges
      expect(find.text('Days Streak'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('Practice Days'), findsOneWidget);

      // Check Custom Sequence action
      expect(find.text('Create Custom Sequence'), findsOneWidget);
    });

    testWidgets('Displays contextual recommendation banner and dismisses upon tap', (tester) async {
      final orchestratorState = OrchestratorState();
      final appState = AppState();

      await tester.pumpWidget(
        _wrapWithApp(
          SingleChildScrollView(
            child: NityaSadhanaDashboard(
              orchestratorState: orchestratorState,
              appState: appState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify recommendation banner rendered with provenance badge (offline approximation fallback)
      expect(find.text('Offline Approximation'), findsOneWidget);

      // Tap dismiss button
      final dismissBtn = find.byTooltip('Dismiss for today');
      expect(dismissBtn, findsOneWidget);
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      // Verify banner disappeared
      expect(find.text('Offline Approximation'), findsNothing);
    });

    testWidgets('Renders active in-progress session banner with Resume button', (tester) async {
      final orchestratorState = OrchestratorState();
      final appState = AppState();
      await tester.pump();

      final morning = orchestratorState.morningSequence!;
      await orchestratorState.startSequence(morning);

      await tester.pumpWidget(
        _wrapWithApp(
          SingleChildScrollView(
            child: NityaSadhanaDashboard(
              orchestratorState: orchestratorState,
              appState: appState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice in Progress: Morning Sadhana'), findsOneWidget);
      expect(find.text('Resume Practice'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });
  });

  group('JournalHistoryModal Widget Tests', () {
    testWidgets('Renders empty state when no practice entries recorded yet', (tester) async {
      final orchestratorState = OrchestratorState();
      await tester.pump();

      await tester.pumpWidget(
        _wrapWithApp(
          JournalHistoryModal(orchestratorState: orchestratorState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Devotional Practice Journal'), findsOneWidget);
      expect(find.text('Private local offline record'), findsOneWidget);
      expect(find.text('No practice records yet'), findsOneWidget);
    });

    testWidgets('Renders past journal entry and confirms clear history', (tester) async {
      final orchestratorState = OrchestratorState();
      await tester.pump();

      final morning = PracticeSequence.defaultMorning();
      await orchestratorState.startSequence(morning);
      // Conclude it
      for (int i = 0; i < morning.steps.length; i++) {
        await orchestratorState.completeStep(i, sequence: morning);
      }

      await tester.pumpWidget(
        _wrapWithApp(
          JournalHistoryModal(orchestratorState: orchestratorState),
        ),
      );
      await tester.pumpAndSettle();

      // Check entry appears
      expect(find.text('Morning Sadhana'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify Clear Journal button exists
      final clearBtn = find.byTooltip('Clear Journal History');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Clear Practice Journal?'), findsOneWidget);
      expect(find.text('Clear Journal'), findsOneWidget);

      // Tap Confirm Clear
      await tester.tap(find.text('Clear Journal'));
      await tester.pumpAndSettle();

      expect(orchestratorState.journalEntries.isEmpty, isTrue);
    });
  });

  group('SequenceEditorModal Widget Tests', () {
    testWidgets('Renders steps, allows toggling enabled and optional badges', (tester) async {
      final orchestratorState = OrchestratorState();
      await tester.pump();

      final morning = PracticeSequence.defaultMorning();

      await tester.pumpWidget(
        _wrapWithApp(
          SequenceEditorModal(
            orchestratorState: orchestratorState,
            sequence: morning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customize Practice Sequence'), findsOneWidget);
      expect(find.text('Save Sequence'), findsOneWidget);
      expect(find.text('Prātaḥ Sankalpa'), findsOneWidget);
      expect(find.text('Gayatri Mahamantra Japa'), findsOneWidget);

      // Verify Required & Optional badges exist
      expect(find.text('Required'), findsWidgets);
      expect(find.text('Optional'), findsWidgets);

      // Tap an Optional/Required badge to toggle
      await tester.tap(find.text('Optional').first);
      await tester.pumpAndSettle();
    });
  });

  group('SequenceExecutionModal Widget Tests', () {
    testWidgets('Renders progression view, steps forward, and concludes', (tester) async {
      final orchestratorState = OrchestratorState();
      await tester.pump();

      // Simple 2-step custom sequence for testing
      final testSeq = PracticeSequence(
        id: 'test_quick_seq',
        name: 'Quick Sadhana',
        type: PracticeSequenceType.custom,
        steps: const [
          PracticeStep(
            id: 'step_1',
            title: 'Initial Resolve',
            description: 'Set your sacred intention.',
            stepType: PracticeStepType.sankalpa,
            estimatedMinutes: 2,
            isOptional: false,
          ),
          PracticeStep(
            id: 'step_2',
            title: 'Quiet Reflection',
            description: 'Sit in quiet peace.',
            stepType: PracticeStepType.personalContemplation,
            estimatedMinutes: 3,
            isOptional: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWithApp(
          SequenceExecutionModal(
            orchestratorState: orchestratorState,
            sequence: testSeq,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Progression elements
      expect(find.text('Quick Sadhana'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Initial Resolve'), findsOneWidget);
      expect(find.text('Open Sankalpa Generator'), findsOneWidget);
      expect(find.text('Confirm Complete & Next'), findsOneWidget);

      // Advance step 1
      await tester.tap(find.text('Confirm Complete & Next'));
      await tester.pumpAndSettle();

      // Now at step 2
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Quiet Reflection'), findsOneWidget);
      expect(find.text('Skip Step'), findsOneWidget);
      expect(find.text('Confirm Complete Sadhana'), findsOneWidget);

      // Complete session
      await tester.tap(find.text('Confirm Complete Sadhana'));
      await tester.pumpAndSettle();

      // Verify concluding screen
      expect(find.text('Practice Concluded'), findsOneWidget);
      expect(find.text('ॐ शान्तिः शान्तिः शान्तिः'), findsOneWidget);
      expect(find.text('Return to Sadhana'), findsOneWidget);
    });
  });
}
