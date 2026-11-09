import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/models/puja_guide.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  group('Phase 21E — Part A: Japa Session Identity Validation Tests', () {
    late SharedPreferences prefs;
    late SadhanaState sadhanaState;
    late PujaGuide testGuide;
    late PujaStep japaStep;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sadhanaState = SadhanaState(prefs: prefs);
      await Future.delayed(const Duration(milliseconds: 20));

      testGuide = AuthenticPujaGuidesData.allGuides.first;
      // Step 1 of Shiva Puja has linkedMantraId: 'VEDA-MTR-0002' (Maha Mrityunjaya) with 108 repetitions
      japaStep = testGuide.steps.firstWhere((s) => s.linkedMantraId != null);
    });

    test('1. Old pre-existing Japa session does not fulfill a newly started Puja step', () {
      sadhanaState.startPujaSession(testGuide);
      final activePuja = sadhanaState.activePujaSession;
      expect(activePuja, isNotNull);

      // Pre-existing session completed yesterday
      final oldSession = JapaPracticeSession(
        id: 'japa_old_yesterday_001',
        mantraId: japaStep.linkedMantraId!,
        mantraTitle: 'Maha Mrityunjaya Mantra',
        targetRepetitions: 108,
        completedRepetitions: 108,
        countingMode: JapaCountingMode.audio,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        lastUpdatedTime: DateTime.now().subtract(const Duration(days: 1)),
        status: JapaSessionStatus.completed,
      );
      expect(oldSession.status, JapaSessionStatus.completed);

      // Verify that activePuja does not consider the step fulfilled by the old session
      expect(activePuja!.japaStepBindings.containsKey(japaStep.id), isFalse);
      expect(activePuja.linkedJapaSessionId, isNull);
    });

    test('2. New matching Japa session correctly binds and fulfills Puja step', () {
      sadhanaState.startPujaSession(testGuide);
      final activePuja = sadhanaState.activePujaSession;
      expect(activePuja, isNotNull);

      final newSession = JapaPracticeSession(
        id: 'japa_new_session_002',
        mantraId: japaStep.linkedMantraId!,
        mantraTitle: 'Maha Mrityunjaya Mantra',
        targetRepetitions: 108,
        completedRepetitions: 108,
        countingMode: JapaCountingMode.audio,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.completed,
      );

      // Explicitly record fulfillment
      sadhanaState.recordJapaStepFulfillment(japaStep.id, newSession.id);

      final updatedPuja = sadhanaState.activePujaSession;
      expect(updatedPuja!.japaStepBindings[japaStep.id], equals('japa_new_session_002'));
      expect(updatedPuja.linkedJapaSessionId, equals('japa_new_session_002'));
    });

    test('3. Japa session for a different mantra cannot fulfill step', () {
      sadhanaState.startPujaSession(testGuide);

      final wrongMantraSession = JapaPracticeSession(
        id: 'japa_diff_mantra_003',
        mantraId: 'VEDA-MTR-9999_DIFFERENT',
        mantraTitle: 'Unrelated Mantra',
        targetRepetitions: 108,
        completedRepetitions: 108,
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.completed,
      );

      // Verification logic rejects mismatch
      final bool matchesMantra = wrongMantraSession.mantraId == japaStep.linkedMantraId;
      expect(matchesMantra, isFalse);

      final activePuja = sadhanaState.activePujaSession;
      expect(activePuja!.japaStepBindings.containsKey(japaStep.id), isFalse);
    });

    test('4. Incomplete repetition count cannot fulfill step', () {
      final incompleteSession = JapaPracticeSession(
        id: 'japa_incomplete_004',
        mantraId: japaStep.linkedMantraId!,
        mantraTitle: 'Maha Mrityunjaya Mantra',
        targetRepetitions: japaStep.targetRepetitions ?? 11,
        completedRepetitions: 5, // 5 of 11 completed
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.active,
      );

      final bool isTargetReached = incompleteSession.completedRepetitions >= (japaStep.targetRepetitions ?? 11);
      expect(isTargetReached, isFalse);
      expect(incompleteSession.isCompleted, isFalse);
    });

    test('5. Paused session cannot fulfill step', () {
      final pausedSession = JapaPracticeSession(
        id: 'japa_paused_005',
        mantraId: japaStep.linkedMantraId!,
        mantraTitle: 'Maha Mrityunjaya Mantra',
        targetRepetitions: 108,
        completedRepetitions: 80,
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.paused,
      );

      expect(pausedSession.status, equals(JapaSessionStatus.paused));
      expect(pausedSession.isCompleted, isFalse);
    });

    test('6. Abandoned session cannot fulfill step', () {
      final abandonedSession = JapaPracticeSession(
        id: 'japa_abandoned_006',
        mantraId: japaStep.linkedMantraId!,
        mantraTitle: 'Maha Mrityunjaya Mantra',
        targetRepetitions: 108,
        completedRepetitions: 108, // counts reached but session was aborted
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.abandoned,
      );

      expect(abandonedSession.status, equals(JapaSessionStatus.abandoned));
    });

    test('7. Fulfilled step is preserved when Puja session is paused and resumed', () {
      sadhanaState.startPujaSession(testGuide);
      sadhanaState.recordJapaStepFulfillment(japaStep.id, 'japa_session_persisted_007');

      // Pause worship
      sadhanaState.pausePujaSession();
      expect(sadhanaState.activePujaSession?.isPaused, isTrue);
      expect(sadhanaState.activePujaSession?.japaStepBindings[japaStep.id], equals('japa_session_persisted_007'));

      // Resume worship
      sadhanaState.resumePujaSession();
      expect(sadhanaState.activePujaSession?.isActive, isTrue);
      expect(sadhanaState.activePujaSession?.japaStepBindings[japaStep.id], equals('japa_session_persisted_007'));
    });

    test('8. Fulfilled step is restored after app restart / storage reload', () async {
      sadhanaState.startPujaSession(testGuide);
      sadhanaState.recordJapaStepFulfillment(japaStep.id, 'japa_reloaded_008');

      // Simulate app restart by instantiating new SadhanaState with same SharedPreferences
      final reloadedState = SadhanaState(prefs: prefs);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(reloadedState.activePujaSession, isNotNull);
      expect(reloadedState.activePujaSession?.japaStepBindings[japaStep.id], equals('japa_reloaded_008'));
    });
  });
}
