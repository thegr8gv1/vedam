import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 20E: Future Reminder Lifecycle & Scheduling Verification', () {
    late MockReminderService mockReminderService;

    setUp(() {
      mockReminderService = MockReminderService();
    });

    test('1. Future reminder scheduling submits valid trigger, allocates ID, and updates pending requests', () async {
      final now = DateTime.now().add(const Duration(seconds: 10));
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final reminder = DevotionalReminder(
        id: 'future_test_1',
        type: ReminderType.morningSadhana,
        title: 'Morning Sadhana Recitation',
        body: 'Time for daily Gayatri practice.',
        hour: now.hour,
        minute: now.minute,
        second: now.second,
        scheduledDate: dateStr,
        isEnabled: true,
      );

      await mockReminderService.scheduleReminder(reminder);
      expect(mockReminderService.scheduledReminders.containsKey('future_test_1'), isTrue);

      final notifId = await mockReminderService.getOrCreateNotificationId('future_test_1');
      expect(notifId, greaterThan(0));

      final pending = await mockReminderService.getPendingNotificationRequests();
      expect(pending.any((p) => p.id == notifId && p.title == reminder.title), isTrue);
    });

    test('2. Cancellation cleanly removes reminder from pending requests', () async {
      const reminder = DevotionalReminder(
        id: 'cancel_test_1',
        type: ReminderType.custom,
        title: 'Temporary Reminder',
        body: 'To be cancelled',
        hour: 7,
        minute: 0,
        isEnabled: true,
      );

      await mockReminderService.scheduleReminder(reminder);
      final notifId = await mockReminderService.getOrCreateNotificationId('cancel_test_1');
      expect((await mockReminderService.getPendingNotificationRequests()).any((p) => p.id == notifId), isTrue);

      await mockReminderService.cancelReminder('cancel_test_1');
      expect(mockReminderService.scheduledReminders.containsKey('cancel_test_1'), isFalse);
      expect((await mockReminderService.getPendingNotificationRequests()).any((p) => p.id == notifId), isFalse);
    });

    test('3. Rescheduling updates pending request without creating duplicate IDs', () async {
      const reminder = DevotionalReminder(
        id: 'reschedule_test_1',
        type: ReminderType.mantraJapa,
        title: 'Japa Reminder',
        body: 'Initial time',
        hour: 8,
        minute: 0,
        isEnabled: true,
      );

      await mockReminderService.scheduleReminder(reminder);
      final id1 = await mockReminderService.getOrCreateNotificationId('reschedule_test_1');

      // Reschedule for a different time
      final updated = reminder.copyWith(hour: 9, minute: 30, body: 'Updated time');
      await mockReminderService.scheduleReminder(updated);
      final id2 = await mockReminderService.getOrCreateNotificationId('reschedule_test_1');

      expect(id1, equals(id2), reason: 'Deterministic ID allocation must prevent duplicate notification slots');
      final pending = await mockReminderService.getPendingNotificationRequests();
      final matching = pending.where((p) => p.id == id1).toList();
      expect(matching.length, equals(1), reason: 'Only 1 pending notification must exist for this reminder ID');
      expect(matching.first.body, equals('Updated time'));
    });

    test('4. SharedPreferences storage persists reminder ID mappings across service restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final service1 = LocalNotificationReminderService(prefs: prefs);
      final allocated1 = await service1.getOrCreateNotificationId('persist_test_1');
      expect(allocated1, greaterThan(0));

      // Simulate app restart with a fresh instance pointing to the same prefs
      final service2 = LocalNotificationReminderService(prefs: prefs);
      final allocated2 = await service2.getOrCreateNotificationId('persist_test_1');
      expect(allocated2, equals(allocated1), reason: 'Rebooted service must restore deterministic notification ID');
    });

    test('5. Vrat specific observance reminder preserves date and devotional privacy', () async {
      const vratReminder = DevotionalReminder(
        id: 'vrat_rama_ekadashi',
        type: ReminderType.personalVrat,
        title: 'Rama Ekadashi Observance',
        body: 'Today is Rama Ekadashi. Practice silence and fasting.',
        hour: 6,
        minute: 0,
        scheduledDate: '2026-11-05',
        linkedVratId: 'vrat_001',
        isEnabled: true,
      );

      await mockReminderService.scheduleReminder(vratReminder);
      final pending = await mockReminderService.getPendingNotificationRequests();
      expect(pending.any((p) => p.title == 'Rama Ekadashi Observance'), isTrue);

      // Verify privacy: body contains only devotional guidance, no private metrics
      final req = pending.firstWhere((p) => p.title == 'Rama Ekadashi Observance');
      expect(req.body, contains('Rama Ekadashi'));
      expect(req.body, isNot(contains('passcode')));
      expect(req.body, isNot(contains('devotee_id')));
    });
  });
}
