import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/data/fixtures/default_sadhana_practices_data.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SadhanaState Unit Tests', () {
    test('Initial state populates default routine and zero completed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      expect(state.activeRoutine.length, DefaultSadhanaPracticesData.defaultActiveRoutineIds.length);
      expect(state.completedPracticeIds.isEmpty, true);
      expect(state.completedRoutineCount, 0);
      expect(state.completionProgress, 0.0);
    });

    test('Toggling practice completion updates count and progress', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      final firstId = state.activeRoutine.first.id;
      expect(state.isPracticeCompleted(firstId), false);

      state.togglePracticeCompletion(firstId);
      expect(state.isPracticeCompleted(firstId), true);
      expect(state.completedRoutineCount, 1);
      expect(state.completionProgress, greaterThan(0.0));

      state.togglePracticeCompletion(firstId);
      expect(state.isPracticeCompleted(firstId), false);
      expect(state.completedRoutineCount, 0);
      expect(state.completionProgress, 0.0);
    });

    test('Customizing routine: adding and removing practices', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      final initialLength = state.activeRoutine.length;
      final practiceToAdd = state.allCatalogPractices.firstWhere(
        (p) => !state.activeRoutine.any((r) => r.id == p.id),
      );

      state.addPracticeToRoutine(practiceToAdd.id);
      expect(state.activeRoutine.length, initialLength + 1);
      expect(state.activeRoutine.any((p) => p.id == practiceToAdd.id), true);

      // Re-adding same practice does not duplicate
      state.addPracticeToRoutine(practiceToAdd.id);
      expect(state.activeRoutine.length, initialLength + 1);

      // Removing practice
      state.removePracticeFromRoutine(practiceToAdd.id);
      expect(state.activeRoutine.length, initialLength);
      expect(state.activeRoutine.any((p) => p.id == practiceToAdd.id), false);
    });

    test('Reordering practices within active routine', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      final first = state.activeRoutine[0];
      final second = state.activeRoutine[1];

      state.reorderRoutine(0, 2);
      expect(state.activeRoutine[0].id, second.id);
      expect(state.activeRoutine[1].id, first.id);
    });

    test('Local date rollover resets daily completed practices', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      final firstId = state.activeRoutine.first.id;
      state.togglePracticeCompletion(firstId);
      expect(state.completedPracticeIds.contains(firstId), true);

      // Same day check does not reset
      state.checkDateRollOver(now: DateTime(2026, 11, 5, 23, 59));
      expect(state.completedPracticeIds.contains(firstId), true);

      // Next day check resets completed list
      state.checkDateRollOver(now: DateTime(2026, 11, 6, 0, 1));
      expect(state.completedPracticeIds.isEmpty, true);
      expect(state.isPracticeCompleted(firstId), false);
      expect(state.currentDate.day, 6);
    });

    test('App restart persistence loads saved routine and completions', () async {
      SharedPreferences.setMockInitialValues({
        'vedam_sadhana_routine_ids': [
          'practice_ganesh_puja',
          'practice_shiva_puja',
        ],
        'vedam_sadhana_last_date': '2026-11-05',
        'vedam_sadhana_completed_ids': ['practice_ganesh_puja'],
      });
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      expect(state.activeRoutine.length, 2);
      expect(state.activeRoutine[0].id, 'practice_ganesh_puja');
      expect(state.activeRoutine[1].id, 'practice_shiva_puja');
      expect(state.isPracticeCompleted('practice_ganesh_puja'), true);
      expect(state.isPracticeCompleted('practice_shiva_puja'), false);
    });

    test('Guided Puja navigation, pause, resume, and completion lifecycle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));

      final guide = AuthenticPujaGuidesData.allGuides.first;
      state.startGuide(guide);

      expect(state.hasActiveGuideSession, true);
      expect(state.activeGuide?.id, guide.id);
      expect(state.activeGuideStepIndex, 0);
      expect(state.currentGuideStep?.stepNumber, 1);
      expect(state.isGuidePaused, false);
      expect(state.isGuideCompleted, false);

      // Pause and resume
      state.pauseGuide();
      expect(state.isGuidePaused, true);
      state.resumeGuide();
      expect(state.isGuidePaused, false);

      // Step navigation
      state.nextGuideStep();
      expect(state.activeGuideStepIndex, 1);
      expect(state.currentGuideStep?.stepNumber, 2);

      state.previousGuideStep();
      expect(state.activeGuideStepIndex, 0);

      // Direct step jump
      state.goToStep(guide.steps.length - 1);
      expect(state.activeGuideStepIndex, guide.steps.length - 1);

      // Complete guide on last step
      state.nextGuideStep();
      expect(state.isGuideCompleted, true);
      expect(state.hasActiveGuideSession, false);

      // Corresponding practice in routine automatically marked completed
      expect(state.isPracticeCompleted('practice_ganesh_puja'), true);

      // Exit guide clears active session
      state.exitGuide();
      expect(state.activeGuide, null);
    });
  });
}
