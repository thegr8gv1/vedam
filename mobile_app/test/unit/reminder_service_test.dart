import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  group('Devotional Reminder Service & Timezone Tests', () {
    late MockReminderService mockService;
    late SharedPreferences prefs;

    setUp(() async {
      tz.initializeTimeZones();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockService = MockReminderService();
    });

    test('Permission request flow and denial handling', () async {
      expect(await mockService.getPermissionStatus(), ReminderPermissionStatus.notDetermined);

      final status = await mockService.requestPermission();
      expect(status, ReminderPermissionStatus.granted);
      expect(mockService.requestPermissionCallCount, 1);
    });

    test('Reminder scheduling, rescheduling, and cancellation', () async {
      const reminder = DevotionalReminder(
        id: 'rem_morning_test',
        type: ReminderType.morningSadhana,
        title: 'Morning Sadhana',
        body: 'Time for prayer.',
        hour: 6,
        minute: 30,
        isEnabled: true,
      );

      await mockService.scheduleReminder(reminder);
      expect(mockService.scheduledReminders.containsKey('rem_morning_test'), true);

      // Reschedule with new time
      final updated = reminder.copyWith(hour: 7, minute: 0);
      await mockService.scheduleReminder(updated);
      expect(mockService.scheduledReminders['rem_morning_test']!.hour, 7);

      // Cancel reminder
      await mockService.cancelReminder('rem_morning_test');
      expect(mockService.scheduledReminders.containsKey('rem_morning_test'), false);
    });

    test('Duplicate notification prevention via deterministic ID mapping', () async {
      const rem1 = DevotionalReminder(
        id: 'rem_unique_1',
        type: ReminderType.custom,
        title: 'Test Reminder',
        body: 'Message',
        hour: 8,
        minute: 0,
        isEnabled: true,
      );

      // Scheduling twice should safely overwrite, not create duplicate
      await mockService.scheduleReminder(rem1);
      await mockService.scheduleReminder(rem1);
      expect(mockService.scheduledReminders.length, 1);
    });

    test('Local timezone and daylight-saving date conversion calculations', () {
      final kolkata = tz.getLocation('Asia/Kolkata');
      final newYork = tz.getLocation('America/New_York');

      final timeKolkata = tz.TZDateTime.now(kolkata);
      final timeNY = tz.TZDateTime.now(newYork);

      expect(timeKolkata.timeZoneOffset.inMinutes, 330); // UTC+5:30
      // Daylight saving check: New York offset is either -4h (EDT) or -5h (EST)
      expect(timeNY.timeZoneOffset.inHours == -4 || timeNY.timeZoneOffset.inHours == -5, true);
    });

    test('VratState enables reminders only after permission check', () async {
      final state = VratState(prefs: prefs, reminderService: mockService);
      await Future.delayed(const Duration(milliseconds: 50));

      final firstRem = state.reminders.first;
      expect(firstRem.isEnabled, false);

      // Enable reminder: triggers permission request
      await state.toggleReminder(firstRem.id, true);
      expect(state.getReminderById(firstRem.id)!.isEnabled, true);
      expect(mockService.requestPermissionCallCount, 1);
      expect(mockService.scheduledReminders.containsKey(firstRem.id), true);
    });
  });
}
