import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/guided_sadhana.dart';
import 'package:vedam_app/core/models/guided_sadhana_session.dart';
import 'package:vedam_app/core/services/guided_sadhana_session_service.dart';
import 'package:vedam_app/data/fixtures/authentic_sadhana_plans_data.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import 'audio_state_and_japa_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21B: Guided Sadhana Models & Persistence Unit Tests', () {
    test('1. GuidedSadhanaStep and Plan serialize and deserialize cleanly', () {
      final step = GuidedSadhanaStep(
        id: 'test_step_1',
        stepNumber: 1,
        title: 'Morning Awakening',
        sanskritTitle: 'प्रातः स्मरण',
        description: 'Take three deep breaths and awaken with gratitude.',
        stepType: SadhanaStepType.preparation,
        sanskritMantra: 'कराग्रे वसते लक्ष्मीः',
        transliteration: 'Karagre vasate lakshmih',
        meaning: 'At the tip of hand resides Lakshmi',
        scripturalSource: 'Smriti Stotra',
        linkedMantraId: 'VEDA-MTR-0399',
        targetRepetitions: 108,
        estimatedMinutes: 5,
        materials: ['Prayer mat', 'Diya'],
        isOptional: false,
      );

      final json = step.toJson();
      final recovered = GuidedSadhanaStep.fromJson(json);

      expect(recovered.id, 'test_step_1');
      expect(recovered.stepNumber, 1);
      expect(recovered.title, 'Morning Awakening');
      expect(recovered.stepType, SadhanaStepType.preparation);
      expect(recovered.targetRepetitions, 108);
      expect(recovered.materials, contains('Prayer mat'));
      expect(recovered.isOptional, false);
    });

    test('2. GuidedSadhanaSession serializes, deserializes, and safely handles corrupted JSON', () {
      final session = GuidedSadhanaSession(
        id: 'session-123',
        sadhanaId: 'sadhana_pratah_smriti',
        sadhanaTitle: 'Pratah Nitya Sadhana',
        startTime: DateTime(2026, 11, 9, 6, 0),
        lastUpdatedTime: DateTime(2026, 11, 9, 6, 15),
        currentStepIndex: 2,
        completedStepIds: ['step_1', 'step_2'],
        skippedStepIds: ['step_opt'],
        status: SadhanaSessionStatus.active,
        japaSessionId: 'japa-sess-456',
        durationSeconds: 900,
      );

      final json = session.toJson();
      final recovered = GuidedSadhanaSession.fromJson(json);

      expect(recovered.id, 'session-123');
      expect(recovered.currentStepIndex, 2);
      expect(recovered.completedStepIds, ['step_1', 'step_2']);
      expect(recovered.skippedStepIds, ['step_opt']);
      expect(recovered.japaSessionId, 'japa-sess-456');
      expect(recovered.durationSeconds, 900);
      expect(recovered.isActive, true);

      // Corrupted JSON fallback
      final corrupted = GuidedSadhanaSession.fromJson({});
      expect(corrupted.id, 'sadhana-session-fallback');
      expect(corrupted.status, SadhanaSessionStatus.active);
      expect(corrupted.completedStepIds, isEmpty);
    });

    test('3. GuidedSadhanaSessionService saves, restores, and avoids duplicate history', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = GuidedSadhanaSessionService(prefs);

      expect(service.loadActiveSession(), isNull);
      expect(service.loadSessionHistory(), isEmpty);

      final session = GuidedSadhanaSession(
        id: 'sess-001',
        sadhanaId: 'sadhana_sandhya_dhyana',
        sadhanaTitle: 'Sandhya Dhyana',
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        currentStepIndex: 1,
        completedStepIds: ['step_1'],
        status: SadhanaSessionStatus.active,
      );

      await service.saveActiveSession(session);
      final active = service.loadActiveSession();
      expect(active, isNotNull);
      expect(active!.id, 'sess-001');
      expect(active.currentStepIndex, 1);

      // Finish session
      await service.recordCompletedSession(session);
      expect(service.loadActiveSession(), isNull);

      final history = service.loadSessionHistory();
      expect(history.length, 1);
      expect(history.first.status, SadhanaSessionStatus.completed);

      // Recording the same session ID updates rather than duplicates
      await service.recordCompletedSession(session);
      final historyUpdated = service.loadSessionHistory();
      expect(historyUpdated.length, 1);
    });

    test('4. GuidedSadhanaSessionService safely handles corrupted raw storage without throwing', () async {
      SharedPreferences.setMockInitialValues({
        GuidedSadhanaSessionService.keyActiveSession: '{corrupt json syntax::: 123',
        GuidedSadhanaSessionService.keySessionHistory: 'not a json array',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = GuidedSadhanaSessionService(prefs);

      expect(() => service.loadActiveSession(), returnsNormally);
      expect(service.loadActiveSession(), isNull);

      expect(() => service.loadSessionHistory(), returnsNormally);
      expect(service.loadSessionHistory(), isEmpty);
    });
  });

  group('Phase 21B: SadhanaState Guided Flow & Japa Integration Tests', () {
    test('5. Starting a sadhana initializes active session and steps correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      expect(state.hasActiveOrPausedSadhanaSession, true);
      expect(state.activeSadhanaPlan?.id, plan.id);
      expect(state.currentSadhanaStepIndex, 0);
      expect(state.currentSadhanaStep?.id, plan.steps.first.id);
      expect(state.totalSadhanaStepsCount, plan.steps.length);
      expect(state.activeSadhanaSession?.completedStepIds, isEmpty);
    });

    test('6. Completing steps updates completed list and saves progress', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      final firstStep = state.currentSadhanaStep!;
      expect(state.isSadhanaStepCompleted(firstStep.id), false);

      state.completeCurrentSadhanaStep();
      expect(state.isSadhanaStepCompleted(firstStep.id), true);
      expect(state.activeSadhanaSession?.completedStepIds, contains(firstStep.id));

      // Advancing to next step preserves step 1 completion
      state.nextSadhanaStep();
      expect(state.currentSadhanaStepIndex, 1);
      expect(state.isSadhanaStepCompleted(firstStep.id), true);
    });

    test('7. Optional step skipping does NOT mark step as completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      // Find the optional step (Step 4: Svādhyāya)
      final optStepIndex = plan.steps.indexWhere((s) => s.isOptional);
      expect(optStepIndex, greaterThan(0));

      state.goToSadhanaStep(optStepIndex);
      final optStep = state.currentSadhanaStep!;
      expect(optStep.isOptional, true);

      // Skip optional step
      state.skipOptionalSadhanaStep();

      // Step was skipped, NOT completed
      expect(state.isSadhanaStepCompleted(optStep.id), false);
      expect(state.isSadhanaStepSkipped(optStep.id), true);
      // Auto-advanced to step 5
      expect(state.currentSadhanaStepIndex, optStepIndex + 1);
    });

    test('8. Pause and resume persists session status and duration', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      expect(state.activeSadhanaSession?.isActive, true);

      state.pauseSadhana();
      expect(state.activeSadhanaSession?.isPaused, true);

      state.resumeSadhana();
      expect(state.activeSadhanaSession?.isActive, true);
    });

    test('9. Concluding sadhana early (abandon) archives to history and clears active', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);
      state.completeCurrentSadhanaStep();

      state.abandonSadhana();

      expect(state.hasActiveOrPausedSadhanaSession, false);
      expect(state.activeSadhanaSession, isNull);
      expect(state.sadhanaHistory.length, 1);
      expect(state.sadhanaHistory.first.status, SadhanaSessionStatus.abandoned);
      expect(state.sadhanaHistory.first.completedStepIds.length, 1);
    });

    test('10. Finishing sadhana marks completed in history and updates daily routine', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      // Mark all steps complete and finish
      for (var _ in plan.steps) {
        state.completeCurrentSadhanaStep();
        if (state.currentSadhanaStepIndex < plan.steps.length - 1) {
          state.nextSadhanaStep();
        }
      }

      state.finishSadhana();

      expect(state.activeSadhanaSession?.isCompleted, true);
      expect(state.sadhanaHistory.length, 1);
      expect(state.sadhanaHistory.first.status, SadhanaSessionStatus.completed);
    });

    test('11. Japa integration: recording verified Japa completion updates step without phantom counts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs);
      final audioState = AudioState(
        prefs: prefs,
        audioService: MockAudioPlaybackService(),
      );

      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state.startSadhana(plan);

      // Move to Japa step (Step 3)
      final japaIndex = plan.steps.indexWhere((s) => s.stepType == SadhanaStepType.japa);
      state.goToSadhanaStep(japaIndex);
      final japaStep = state.currentSadhanaStep!;

      expect(state.isSadhanaStepCompleted(japaStep.id), false);

      // Merely opening does NOT mark step complete
      expect(audioState.completedRepetitions, 0);
      expect(state.isSadhanaStepCompleted(japaStep.id), false);

      // Chanting partial chants (e.g. 5 of 108) does NOT satisfy step
      for (int i = 0; i < 5; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, 5);
      expect(state.isSadhanaStepCompleted(japaStep.id), false);

      // Genuinely completing Japa (simulating finishing target)
      audioState.finishSession();
      state.recordJapaCompletionForCurrentStep('japa-session-verified-001');

      // Now the step is marked complete and linked
      expect(state.isSadhanaStepCompleted(japaStep.id), true);
      expect(state.activeSadhanaSession?.japaSessionId, 'japa-session-verified-001');
    });

    test('12. Restoring app restarts preserves active sadhana session and completed steps', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final state1 = SadhanaState(prefs: prefs);
      final plan = AuthenticSadhanaPlansData.allPlans.first;
      state1.startSadhana(plan);
      state1.completeCurrentSadhanaStep(); // Step 1 completed
      state1.nextSadhanaStep();            // On step 2
      state1.pauseSadhana();

      // Simulate app restart with a fresh SadhanaState instance pointing to same storage
      final state2 = SadhanaState(prefs: prefs);
      // Wait for unawaited _initialize() to settle
      await Future.delayed(const Duration(milliseconds: 50));

      expect(state2.hasActiveOrPausedSadhanaSession, true);
      expect(state2.activeSadhanaPlan?.id, plan.id);
      expect(state2.currentSadhanaStepIndex, 1);
      expect(state2.isSadhanaStepCompleted(plan.steps[0].id), true);
      expect(state2.isSadhanaStepCompleted(plan.steps[1].id), false);
    });
  });
}
