import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/data/fixtures/default_vrat_templates_data.dart';
import 'package:vedam_app/state/vrat_state.dart';

class MockReminderService implements ReminderService {
  final List<DevotionalReminder> scheduledReminders = [];
  final List<String> cancelledIds = [];
  ReminderPermissionStatus currentStatus = ReminderPermissionStatus.granted;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async => currentStatus;

  @override
  Future<ReminderPermissionStatus> requestPermission() async => currentStatus;

  @override
  Future<int> getOrCreateNotificationId(String id) async => id.hashCode.abs() % 2147483647;

  @override
  Future<void> releaseReminderId(String reminderId) async {
    cancelledIds.add(reminderId);
  }

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<bool> scheduleReminder(DevotionalReminder reminder) async {
    scheduledReminders.removeWhere((r) => r.id == reminder.id);
    scheduledReminders.add(reminder);
    return true;
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    cancelledIds.add(reminderId);
    scheduledReminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduledReminders.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async => [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21D: Vrat & Observance Data Models & Serialization Tests', () {
    test('1. VratType enum covers all 8 traditional and custom categories', () {
      expect(VratType.values, contains(VratType.ekadashi));
      expect(VratType.values, contains(VratType.pradosham));
      expect(VratType.values, contains(VratType.purnima));
      expect(VratType.values, contains(VratType.amavasya));
      expect(VratType.values, contains(VratType.sankashtiChaturthi));
      expect(VratType.values, contains(VratType.monthlyShivaratri));
      expect(VratType.values, contains(VratType.navaratri));
      expect(VratType.values, contains(VratType.custom));
      expect(VratType.values.length, 8);
    });

    test('2. VratObservance serialization supports new fields with backward compatibility', () {
      final observance = VratObservance(
        id: 'vrat_test_01',
        type: VratType.monthlyShivaratri,
        title: 'Masa Shivaratri Adoration',
        sanskritTitle: 'मास शिवरात्रि व्रतम्',
        targetDate: '2026-11-28',
        location: 'Kashi',
        tradition: 'Shaiva Grihya',
        isManuallyCreated: true,
        sourceAttribution: 'Shiva Purana / Grihya Tradition',
        timingNotes: 'Nishita Kala midnight vigil and quiet prayer',
        fastingNotice: 'Strict fasting is optional. Health and prayer take precedence.',
        createdAt: '2026-11-09T12:00:00Z',
      );

      final jsonMap = observance.toJson();
      expect(jsonMap['type'], 'monthlyShivaratri');
      expect(jsonMap['is_manually_created'], true);
      expect(jsonMap['source_attribution'], 'Shiva Purana / Grihya Tradition');
      expect(jsonMap['timing_notes'], contains('Nishita Kala'));
      expect(jsonMap['fasting_notice'], contains('Strict fasting is optional'));

      // Deserialize
      final deserialized = VratObservance.fromJson(jsonMap);
      expect(deserialized.id, 'vrat_test_01');
      expect(deserialized.type, VratType.monthlyShivaratri);
      expect(deserialized.isManuallyCreated, true);
      expect(deserialized.sourceAttribution, 'Shiva Purana / Grihya Tradition');
      expect(deserialized.timingNotes, contains('Nishita Kala'));

      // Backward compatibility test: payload missing Phase 21D fields
      final legacyJson = {
        'id': 'legacy_vrat_01',
        'type': 'ekadashi',
        'title': 'Legacy Ekadashi',
        'sanskrit_title': 'एकादशी',
        'target_date': '2026-11-10',
        'location': 'Varanasi',
        'tradition': 'Vaishnava',
        'calendar_convention': 'traditionalRegional',
        'status': 'planned',
        'created_at': '2026-11-01T00:00:00Z',
      };

      final legacyLoaded = VratObservance.fromJson(legacyJson);
      expect(legacyLoaded.isManuallyCreated, false);
      expect(legacyLoaded.sourceAttribution, isNull);
      expect(legacyLoaded.timingNotes, isNull);
      expect(legacyLoaded.fastingNotice, contains('Fasting and dietary restrictions are traditional options'));
    });

    test('3. Default templates produce complete metadata and safety guidance for all types', () {
      for (final type in VratType.values) {
        final template = DefaultVratTemplatesData.createTemplate(
          type,
          targetDate: '2026-12-01',
          location: 'Varanasi, India',
        );

        expect(template.id, isNotEmpty);
        expect(template.title, isNotEmpty);
        expect(template.sanskritTitle, isNotEmpty);
        expect(template.tradition, isNotEmpty);
        expect(template.checklist.isNotEmpty, true);
        expect(template.fastingNotice, contains('health'));

        if (type == VratType.custom) {
          expect(template.isManuallyCreated, true);
        } else {
          expect(template.isManuallyCreated, false);
          expect(template.sourceAttribution, isNotNull);
        }
      }
    });
  });

  group('Phase 21D: VratState Lifecycle, Status & History Management Tests', () {
    late SharedPreferences prefs;
    late MockReminderService mockReminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockReminderService = MockReminderService();
    });

    test('4. Mark observance completed sets status, completed timestamp, and saves to history', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      final obs = state.observances.first;
      expect(obs.status, ObservanceStatus.planned);
      expect(obs.completedAt, isNull);

      await state.markObservanceCompleted(obs.id, personalNotes: 'Observed peacefully with evening light');
      await pumpEventQueue();

      final updated = state.getObservanceById(obs.id)!;
      expect(updated.status, ObservanceStatus.completed);
      expect(updated.completedAt, isNotNull);
      expect(updated.personalNotes, 'Observed peacefully with evening light');
      expect(state.pastObservances.any((o) => o.id == obs.id), true);
    });

    test('5. Compassionate skipping records note without deficit and updates state', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      final obs = state.observances.first;
      await state.markObservanceSkipped(obs.id, reason: 'Traveling for work; health prioritized');
      await pumpEventQueue();

      final updated = state.getObservanceById(obs.id)!;
      expect(updated.status, ObservanceStatus.skipped);
      expect(updated.personalNotes, contains('Traveling for work'));
      expect(state.pastObservances.any((o) => o.id == obs.id), true);
      expect(state.activeObservances.any((o) => o.id == obs.id), false);
    });

    test('6. Rescheduling an observance updates target date and linked reminder', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      final obs = state.observances.first;
      final reminder = DevotionalReminder(
        id: 'rem_linked_${obs.id}',
        type: ReminderType.personalVrat,
        title: 'Observance Reminder',
        body: 'Reminder for practice',
        scheduledDate: obs.targetDate,
        hour: 6,
        minute: 0,
        isEnabled: true,
        linkedVratId: obs.id,
      );
      await state.addReminder(reminder);
      await pumpEventQueue();

      // Reschedule observance to next week
      await state.rescheduleObservance(obs.id, '2026-11-20');
      await pumpEventQueue();

      final updatedObs = state.getObservanceById(obs.id)!;
      expect(updatedObs.targetDate, '2026-11-20');

      final updatedReminder = state.getReminderForVrat(obs.id)!;
      expect(updatedReminder.scheduledDate, '2026-11-20');
      expect(mockReminderService.scheduledReminders.any((r) => r.scheduledDate == '2026-11-20'), true);
    });

    test('7. Clear history purges past completed/skipped items and retains active plans', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      // Add a planned observance and a completed one
      final planned = DefaultVratTemplatesData.createTemplate(
        VratType.pradosham,
        targetDate: '2026-12-05',
        location: 'Varanasi',
      );
      final completed = DefaultVratTemplatesData.createTemplate(
        VratType.purnima,
        targetDate: '2026-10-15',
        location: 'Varanasi',
      ).copyWith(status: ObservanceStatus.completed, completedAt: '2026-10-15T20:00:00Z');

      await state.addObservance(planned);
      await state.addObservance(completed);
      await pumpEventQueue();

      expect(state.pastObservances.isNotEmpty, true);
      final activeCountBefore = state.activeObservances.length;

      // Clear past history
      await state.clearHistory();
      await pumpEventQueue();

      expect(state.pastObservances.isEmpty, true);
      expect(state.activeObservances.length, activeCountBefore);
      expect(state.getObservanceById(planned.id), isNotNull);
      expect(state.getObservanceById(completed.id), isNull);
    });

    test('8. Deleting an observance automatically cancels its linked reminder', () async {
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      final obs = state.observances.first;
      final reminder = DevotionalReminder(
        id: 'rem_to_cancel_${obs.id}',
        type: ReminderType.personalVrat,
        title: 'Observance Reminder',
        body: 'Reminder for practice',
        scheduledDate: obs.targetDate,
        hour: 6,
        minute: 0,
        isEnabled: true,
        linkedVratId: obs.id,
      );
      await state.addReminder(reminder);
      await pumpEventQueue();

      expect(mockReminderService.scheduledReminders.any((r) => r.id == reminder.id), true);

      await state.deleteObservance(obs.id);
      await pumpEventQueue();

      expect(state.getObservanceById(obs.id), isNull);
      expect(state.getReminderForVrat(obs.id), isNull);
      expect(mockReminderService.cancelledIds, contains(reminder.id));
    });

    test('9. Preference data corruption is safely handled without crash', () async {
      // Intentionally insert corrupted JSON into preferences
      await prefs.setString('vrat_user_observances_v1', '{invalid_corrupted_json:::');

      // Instantiating VratState should recover gracefully
      final state = VratState(prefs: prefs, reminderService: mockReminderService);
      await pumpEventQueue();

      expect(state.isLoaded, true);
      expect(state.observances, isNotEmpty); // Seeded default recovered
    });

    test('10. Fasting safety guidance is non-prescriptive and cites health exceptions', () {
      expect(VratState.fastingSafetyAdvisory, contains('strictly optional'));
      expect(VratState.fastingSafetyAdvisory, contains('medical conditions'));
      expect(VratState.fastingSafetyAdvisory, contains('pregnant'));
      expect(VratState.fastingSafetyAdvisory, contains('zero spiritual deficit'));
    });
  });
}
