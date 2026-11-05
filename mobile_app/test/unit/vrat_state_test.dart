import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  group('VratState Unit & Persistence Tests', () {
    late SharedPreferences prefs;
    late MockReminderService mockReminderService;
    late VratState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
      state = VratState(prefs: prefs, reminderService: mockReminderService);
      // Wait for async init to finish
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('Initial state creates seed observance and default disabled reminders', () {
      expect(state.observances.isNotEmpty, true);
      expect(state.observances.first.type, VratType.ekadashi);

      // Verify default reminders exist and are disabled by default (opt-in policy)
      expect(state.reminders.isNotEmpty, true);
      for (final r in state.reminders) {
        expect(r.isEnabled, false, reason: 'Default reminders must be opt-in');
      }
    });

    test('Add, update, and delete observance lifecycle', () async {
      final newObs = VratObservance(
        id: 'vrat_test_pradosham',
        type: VratType.pradosham,
        title: 'Shiva Pradosham',
        sanskritTitle: 'प्रदोष व्रतम्',
        targetDate: '2026-11-15',
        location: 'Varanasi, India',
        tradition: 'Shaiva',
        calendarConvention: CalendarConvention.traditionalRegional,
        createdAt: '2026-11-05T12:00:00Z',
      );

      await state.addObservance(newObs);
      expect(state.getObservanceById('vrat_test_pradosham'), isNotNull);
      expect(state.observances.any((o) => o.id == 'vrat_test_pradosham'), true);

      // Update observance
      final updated = newObs.copyWith(title: 'Shiva Pradosham Twilight Adoration');
      await state.updateObservance(updated);
      expect(state.getObservanceById('vrat_test_pradosham')!.title, 'Shiva Pradosham Twilight Adoration');

      // Delete observance
      await state.deleteObservance('vrat_test_pradosham');
      expect(state.getObservanceById('vrat_test_pradosham'), isNull);
    });

    test('Status transitions and completion timestamp tracking', () async {
      final obs = state.observances.first;
      expect(obs.status, ObservanceStatus.planned);

      // Transition to In Progress
      await state.updateObservanceStatus(obs.id, ObservanceStatus.inProgress);
      expect(state.getObservanceById(obs.id)!.status, ObservanceStatus.inProgress);

      // Transition to Completed
      await state.updateObservanceStatus(
        obs.id,
        ObservanceStatus.completed,
        personalNotes: 'Completed peacefully with family prayer.',
      );
      final completedObs = state.getObservanceById(obs.id)!;
      expect(completedObs.status, ObservanceStatus.completed);
      expect(completedObs.completedAt, isNotNull);
      expect(completedObs.personalNotes, 'Completed peacefully with family prayer.');

      // Active vs Past lists filter properly
      expect(state.pastObservances.any((o) => o.id == obs.id), true);
      expect(state.activeObservances.any((o) => o.id == obs.id), false);
    });

    test('Checklist item toggling and custom step addition', () async {
      final obs = state.observances.first;
      expect(obs.checklist.isNotEmpty, true);
      final firstItemId = obs.checklist.first.id;
      final initialDone = obs.checklist.first.isDone;

      // Toggle checklist item
      await state.toggleChecklistItem(obs.id, firstItemId);
      final updatedObs = state.getObservanceById(obs.id)!;
      expect(updatedObs.checklist.first.isDone, !initialDone);

      // Add custom checklist item
      const customItem = VratChecklistItem(
        id: 'chk_custom_deepa',
        title: 'Light 5 ghee lamps at twilight',
        category: 'ritual',
      );
      await state.addChecklistItem(obs.id, customItem);
      final withCustom = state.getObservanceById(obs.id)!;
      expect(withCustom.checklist.any((c) => c.id == 'chk_custom_deepa'), true);
    });

    test('Panchangam offline fallback provides clear non-authoritative suggestion', () {
      final result = state.getInformationalPanchangamContext(VratType.ekadashi, null);
      expect(result['status']!.contains('unavailable'), true);
      expect(result['notice']!.contains('does not invent'), true);
      expect(result['suggestion']!.contains('manually'), true);
    });

    test('App restart persistence preserves user observances and checklist state', () async {
      final obs = state.observances.first;
      await state.toggleChecklistItem(obs.id, obs.checklist.first.id);

      // Simulate app restart by instantiating new VratState with the same SharedPreferences
      final reloadedState = VratState(prefs: prefs, reminderService: mockReminderService);
      await Future.delayed(const Duration(milliseconds: 50));

      final reloadedObs = reloadedState.getObservanceById(obs.id);
      expect(reloadedObs, isNotNull);
      expect(reloadedObs!.checklist.first.isDone, true);
    });
  });
}
