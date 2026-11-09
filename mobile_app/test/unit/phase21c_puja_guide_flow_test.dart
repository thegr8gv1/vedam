import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/puja_guide.dart';
import 'package:vedam_app/core/models/puja_session.dart';
import 'package:vedam_app/core/services/puja_session_service.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/state/sadhana_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21C: Puja Content Models & Serialization Tests', () {
    test('1. PujaStep serialization preserves optional, targetRepetitions, and stable ID', () {
      final step = PujaStep(
        id: 'ganesh_step_1_dhyanam',
        stepNumber: 1,
        stepName: 'Dhyanam',
        actionDescription: 'Meditate on Lord Ganesha',
        sanskritMantra: 'ॐ गं गणपतये नमः',
        transliteration: 'Om gam ganapataye namah',
        meaning: 'Salutations to the remover of obstacles',
        scripturalSource: 'Mudgala Purana',
        stepProvenance: 'canonical_verse',
        linkedMantraId: 'VEDA-MTR-0454',
        linkedMantraTitle: 'Vakratunda Mahakaya',
        isOptional: false,
        targetRepetitions: 11,
      );

      final json = step.toJson();
      expect(json['id'], 'ganesh_step_1_dhyanam');
      expect(json['is_optional'], false);
      expect(json['target_repetitions'], 11);

      final restored = PujaStep.fromJson(json);
      expect(restored.id, 'ganesh_step_1_dhyanam');
      expect(restored.stepNumber, 1);
      expect(restored.isOptional, false);
      expect(restored.targetRepetitions, 11);
      expect(restored.sanskritMantra, 'ॐ गं गणपतये नमः');
    });

    test('2. PujaGuide separates required vs optional materials with backward compatibility', () {
      final guide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;
      expect(guide.requiredMaterials.isNotEmpty, true);
      expect(guide.optionalMaterials.isNotEmpty, true);
      expect(guide.materialsList.isNotEmpty, true);

      // Verify JSON serialization
      final json = guide.toJson();
      expect(json['required_materials'], isNotNull);
      expect(json['optional_materials'], isNotNull);

      final restored = PujaGuide.fromJson(json);
      expect(restored.id, 'guide_ganesh_puja');
      expect(restored.requiredMaterials.length, guide.requiredMaterials.length);
      expect(restored.optionalMaterials.length, guide.optionalMaterials.length);
    });

    test('3. PujaSession JSON serialization and deserialization', () {
      final now = DateTime(2026, 11, 9, 10, 0, 0);
      final session = PujaSession(
        id: 'test_puja_session_1',
        guideId: 'guide_shiva_puja',
        startTime: now,
        lastUpdatedTime: now,
        currentStepIndex: 2,
        completedStepIds: ['shiva_step_1_dhyanam', 'shiva_step_2_abhishekam'],
        skippedStepIds: [],
        preparedMaterials: ['Clean water for Abhisheka with small spoon'],
        status: PujaSessionStatus.active,
        durationSeconds: 120,
      );

      final json = session.toJson();
      expect(json['status'], 'active');
      expect(json['current_step_index'], 2);

      final restored = PujaSession.fromJson(json);
      expect(restored.id, 'test_puja_session_1');
      expect(restored.guideId, 'guide_shiva_puja');
      expect(restored.currentStepIndex, 2);
      expect(restored.completedStepIds, contains('shiva_step_1_dhyanam'));
      expect(restored.preparedMaterials, contains('Clean water for Abhisheka with small spoon'));
      expect(restored.isActive, true);
    });
  });

  group('Phase 21C: PujaSessionService Offline Persistence & Recovery Tests', () {
    late SharedPreferences prefs;
    late PujaSessionService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = PujaSessionService(prefs);
    });

    test('4. Saving and loading active session', () async {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      final session = PujaSession(
        id: 'session_active_1',
        guideId: 'guide_ganesh_puja',
        startTime: now,
        lastUpdatedTime: now,
        currentStepIndex: 1,
        completedStepIds: ['ganesh_step_1_dhyanam'],
        status: PujaSessionStatus.active,
      );

      await service.saveActiveSession(session);
      final loaded = service.loadActiveSession();

      expect(loaded, isNotNull);
      expect(loaded!.id, 'session_active_1');
      expect(loaded.currentStepIndex, 1);
      expect(loaded.completedStepIds, contains('ganesh_step_1_dhyanam'));
    });

    test('5. Corrupted active session is cleared safely without crashing', () async {
      await prefs.setString(PujaSessionService.activeSessionKey, '{invalid_json:::corrupt');

      final loaded = service.loadActiveSession();
      expect(loaded, isNull);
      expect(prefs.containsKey(PujaSessionService.activeSessionKey), false);
    });

    test('6. Recording completed session caps history at 50 and dedupes', () async {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      for (int i = 0; i < 55; i++) {
        final session = PujaSession(
          id: 'session_hist_$i',
          guideId: 'guide_ganesh_puja',
          startTime: now,
          lastUpdatedTime: now.add(Duration(minutes: i)),
          currentStepIndex: 4,
          status: PujaSessionStatus.completed,
          durationSeconds: 300,
        );
        await service.recordCompletedSession(session);
      }

      final history = service.loadSessionHistory();
      expect(history.length, 50);
      // Most recent should be first
      expect(history.first.id, 'session_hist_54');
    });

    test('7. Corrupted history is handled safely without crash', () async {
      await prefs.setString(PujaSessionService.sessionHistoryKey, '[{corrupted:json,');
      final history = service.loadSessionHistory();
      expect(history, isEmpty);
      expect(prefs.containsKey(PujaSessionService.sessionHistoryKey), false);
    });
  });

  group('Phase 21C: SadhanaState Puja Lifecycle & Progression Tests', () {
    late SharedPreferences prefs;
    late SadhanaState sadhanaState;
    final guide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 9));
    });

    test('8. Starting a Puja session initializes active session and persists', () {
      sadhanaState.startPujaSession(guide);

      expect(sadhanaState.activeGuide?.id, 'guide_ganesh_puja');
      expect(sadhanaState.activeGuideStepIndex, 0);
      expect(sadhanaState.hasActiveGuideSession, true);
      expect(sadhanaState.activePujaSession, isNotNull);
      expect(sadhanaState.activePujaSession!.isActive, true);

      // Verify persisted in SharedPreferences
      final raw = prefs.getString(PujaSessionService.activeSessionKey);
      expect(raw, isNotNull);
      expect(raw!.contains('guide_ganesh_puja'), true);
    });

    test('9. Completing a step increments index and records completedStepId', () {
      sadhanaState.startPujaSession(guide);
      final step1Id = guide.steps[0].id;

      sadhanaState.completeCurrentPujaStep();

      expect(sadhanaState.activeGuideStepIndex, 1);
      expect(sadhanaState.activePujaSession!.completedStepIds, contains(step1Id));
      expect(sadhanaState.activePujaSession!.currentStepIndex, 1);
    });

    test('10. Skipping an optional step adds to skippedStepIds and NOT to completedStepIds', () {
      // Find a guide with an optional step: Ganesha Step 3 is optional
      sadhanaState.startPujaSession(guide);
      sadhanaState.completeCurrentPujaStep(); // Step 1 completed -> now on Step 2
      sadhanaState.completeCurrentPujaStep(); // Step 2 completed -> now on Step 3 (optional)

      final step3 = sadhanaState.currentGuideStep!;
      expect(step3.isOptional, true);

      sadhanaState.skipOptionalPujaStep();

      expect(sadhanaState.activeGuideStepIndex, 3);
      expect(sadhanaState.activePujaSession!.skippedStepIds, contains(step3.id));
      expect(sadhanaState.activePujaSession!.completedStepIds, isNot(contains(step3.id)));
    });

    test('11. Non-optional step cannot be skipped', () {
      sadhanaState.startPujaSession(guide);
      final step1 = sadhanaState.currentGuideStep!;
      expect(step1.isOptional, false);

      sadhanaState.skipOptionalPujaStep();

      // Index and completed/skipped remain unchanged
      expect(sadhanaState.activeGuideStepIndex, 0);
      expect(sadhanaState.activePujaSession!.skippedStepIds, isEmpty);
      expect(sadhanaState.activePujaSession!.completedStepIds, isEmpty);
    });

    test('12. Material checklist toggle updates state and persists in session', () {
      sadhanaState.startPujaSession(guide);
      final material = guide.requiredMaterials.first;

      expect(sadhanaState.isMaterialPrepared(material), false);

      sadhanaState.toggleMaterialPrepared(material);
      expect(sadhanaState.isMaterialPrepared(material), true);
      expect(sadhanaState.activePujaSession!.preparedMaterials, contains(material));

      // Toggle off
      sadhanaState.toggleMaterialPrepared(material);
      expect(sadhanaState.isMaterialPrepared(material), false);
      expect(sadhanaState.activePujaSession!.preparedMaterials, isNot(contains(material)));
    });

    test('13. Pause and resume maintain active session status', () {
      sadhanaState.startPujaSession(guide);
      sadhanaState.pausePujaSession();

      expect(sadhanaState.isGuidePaused, true);
      expect(sadhanaState.activePujaSession!.isPaused, true);

      sadhanaState.resumePujaSession();
      expect(sadhanaState.isGuidePaused, false);
      expect(sadhanaState.activePujaSession!.isActive, true);
    });

    test('14. Finishing Puja saves record to history, marks completion, and clears active session', () {
      sadhanaState.startPujaSession(guide);

      // Fast forward through all steps
      for (int i = 0; i < guide.steps.length; i++) {
        sadhanaState.completeCurrentPujaStep();
      }

      expect(sadhanaState.isGuideCompleted, true);
      expect(sadhanaState.activePujaSession, isNull);
      expect(prefs.containsKey(PujaSessionService.activeSessionKey), false);

      // Verify in history
      expect(sadhanaState.pujaHistory.length, 1);
      expect(sadhanaState.pujaHistory.first.guideId, 'guide_ganesh_puja');
      expect(sadhanaState.pujaHistory.first.isCompleted, true);
    });

    test('15. Abandoning Puja cleans up active session without adding to completed history', () {
      sadhanaState.startPujaSession(guide);
      sadhanaState.completeCurrentPujaStep();

      sadhanaState.abandonPujaSession();

      expect(sadhanaState.activeGuide, isNull);
      expect(sadhanaState.activePujaSession, isNull);
      expect(sadhanaState.hasActiveGuideSession, false);
      expect(sadhanaState.pujaHistory, isEmpty);
      expect(prefs.containsKey(PujaSessionService.activeSessionKey), false);
    });

    test('16. Duplicate session prevention: re-opening active guide resumes existing session', () {
      sadhanaState.startPujaSession(guide);
      final initialSessionId = sadhanaState.activePujaSession!.id;

      sadhanaState.completeCurrentPujaStep();
      expect(sadhanaState.activeGuideStepIndex, 1);

      // Re-calling startPujaSession on the same guide must NOT create a new session ID
      sadhanaState.startPujaSession(guide);
      expect(sadhanaState.activePujaSession!.id, initialSessionId);
      expect(sadhanaState.activeGuideStepIndex, 1);
    });

    test('17. Restoring app restarts preserves active puja session, step index, and materials', () async {
      sadhanaState.startPujaSession(guide);
      sadhanaState.completeCurrentPujaStep(); // Now at step 1
      sadhanaState.toggleMaterialPrepared(guide.requiredMaterials.first);
      sadhanaState.pausePujaSession();

      // Simulate app kill and reboot by creating new SadhanaState with same SharedPreferences
      final reloadedState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 9));
      // Give asynchronous _initialize() a moment to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(reloadedState.hasActiveGuideSession, true);
      expect(reloadedState.activeGuide?.id, 'guide_ganesh_puja');
      expect(reloadedState.activeGuideStepIndex, 1);
      expect(reloadedState.isGuidePaused, true);
      expect(reloadedState.isMaterialPrepared(guide.requiredMaterials.first), true);
    });
  });
}
