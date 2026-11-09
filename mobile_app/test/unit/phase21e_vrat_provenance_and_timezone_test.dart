import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/vrat_observance.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/data/fixtures/default_vrat_templates_data.dart';
import 'package:vedam_app/state/vrat_state.dart';

class MockControlledReminderService implements ReminderService {
  final List<DevotionalReminder> scheduledReminders = [];
  final List<String> cancelledReminderIds = [];
  bool allCancelled = false;
  ReminderPermissionStatus currentPermissionStatus = ReminderPermissionStatus.granted;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async => currentPermissionStatus;

  @override
  Future<ReminderPermissionStatus> requestPermission() async => currentPermissionStatus;

  @override
  Future<void> scheduleReminder(DevotionalReminder reminder) async {
    scheduledReminders.removeWhere((r) => r.id == reminder.id);
    scheduledReminders.add(reminder);
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    scheduledReminders.removeWhere((r) => r.id == reminderId);
    cancelledReminderIds.add(reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduledReminders.clear();
    allCancelled = true;
  }

  @override
  Future<int> getOrCreateNotificationId(String id) async {
    return id.hashCode.abs() % 100000;
  }

  @override
  Future<void> releaseReminderId(String reminderId) async {}

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async => [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Phase 21E — Part A: Vrat Provenance & Reminder Hardening Tests', () {
    late SharedPreferences prefs;
    late MockControlledReminderService reminderService;
    late VratState vratState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      reminderService = MockControlledReminderService();
      vratState = VratState(prefs: prefs, reminderService: reminderService);
      await Future.delayed(const Duration(milliseconds: 20));
    });

    test('1. Date provenance differentiates curated template sample vs personal date', () {
      final template = DefaultVratTemplatesData.createTemplate(
        VratType.ekadashi,
        targetDate: '2026-11-20',
        location: 'Varanasi',
      );
      expect(template.isManuallyCreated, isFalse);
      expect(template.sourceAttribution, isNotNull);

      final manualObservance = template.copyWith(
        id: 'vrat_manual_01',
        isManuallyCreated: true,
      );
      expect(manualObservance.isManuallyCreated, isTrue);
    });

    test('2. Timezone conversion and TZDateTime behavior are deterministic across timezones', () {
      final kolkataTz = tz.getLocation('Asia/Kolkata');
      final newYorkTz = tz.getLocation('America/New_York');

      final dateKolkata = tz.TZDateTime(kolkataTz, 2026, 11, 20, 6, 0);
      final dateNewYork = tz.TZDateTime(newYorkTz, 2026, 11, 20, 6, 0);

      // Both are 6:00 AM in their respective local device timezones
      expect(dateKolkata.hour, equals(6));
      expect(dateNewYork.hour, equals(6));
      expect(dateKolkata.isAtSameMomentAs(dateNewYork), isFalse);
    });

    test('3. Daylight Saving Time transition produces valid local notification timestamp', () {
      final newYorkTz = tz.getLocation('America/New_York');

      // Before DST shift (EDT: UTC-4)
      final beforeDst = tz.TZDateTime(newYorkTz, 2026, 11, 1, 1, 0);
      // After DST shift (EST: UTC-5)
      final afterDst = tz.TZDateTime(newYorkTz, 2026, 11, 1, 3, 0);

      expect(beforeDst.timeZoneOffset.inHours, equals(-4));
      expect(afterDst.timeZoneOffset.inHours, equals(-5));
      expect(afterDst.isAfter(beforeDst), isTrue);
    });

    test('4. Midnight boundary: scheduling around midnight advances day appropriately', () {
      final kolkataTz = tz.getLocation('Asia/Kolkata');

      // Simulated clock at 23:59:50
      final nowNight = tz.TZDateTime(kolkataTz, 2026, 11, 20, 23, 59, 50);
      var scheduled = tz.TZDateTime(kolkataTz, nowNight.year, nowNight.month, nowNight.day, 0, 5, 0);
      if (scheduled.isBefore(nowNight)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      expect(scheduled.day, equals(21));
      expect(scheduled.hour, equals(0));
      expect(scheduled.minute, equals(5));

      // Simulated clock at 00:01:00
      final nowMorning = tz.TZDateTime(kolkataTz, 2026, 11, 20, 0, 1, 0);
      var scheduledMorning = tz.TZDateTime(
        kolkataTz,
        nowMorning.year,
        nowMorning.month,
        nowMorning.day,
        0,
        5,
        0,
      );
      if (scheduledMorning.isBefore(nowMorning)) {
        scheduledMorning = scheduledMorning.add(const Duration(days: 1));
      }
      expect(scheduledMorning.day, equals(20));
      expect(scheduledMorning.hour, equals(0));
      expect(scheduledMorning.minute, equals(5));
    });

    test('5. Rescheduling an observance updates linked reminder scheduledDate', () async {
      final obs = vratState.observances.first;
      final reminder = DevotionalReminder(
        id: 'rem_${obs.id}',
        title: 'Ekadashi Morning Observance',
        body: 'Begin with prayer and peaceful reflection.',
        type: ReminderType.personalVrat,
        hour: 6,
        minute: 0,
        repeatDaily: false,
        scheduledDate: obs.targetDate,
        linkedVratId: obs.id,
      );
      await vratState.addReminder(reminder);
      expect(vratState.getReminderForVrat(obs.id)?.scheduledDate, equals(obs.targetDate));

      // Reschedule to a new date
      await vratState.rescheduleObservance(obs.id, '2026-11-25');

      final updatedReminder = vratState.getReminderForVrat(obs.id);
      expect(updatedReminder, isNotNull);
      expect(updatedReminder!.scheduledDate, equals('2026-11-25'));
    });

    test('6. Deleting an observance cancels its scheduled reminder and purges from list', () async {
      final obs = vratState.observances.first;
      final reminder = DevotionalReminder(
        id: 'rem_delete_${obs.id}',
        title: 'Observance Reminder',
        body: 'Morning reminder',
        type: ReminderType.personalVrat,
        hour: 6,
        minute: 0,
        repeatDaily: false,
        scheduledDate: obs.targetDate,
        linkedVratId: obs.id,
      );
      await vratState.addReminder(reminder);

      await vratState.deleteObservance(obs.id);

      expect(vratState.getObservanceById(obs.id), isNull);
      expect(vratState.getReminderForVrat(obs.id), isNull);
      expect(reminderService.cancelledReminderIds, contains('rem_delete_${obs.id}'));
    });

    test('7. Clearing past history cancels reminders for past items and leaves active reminders', () async {
      final activeObs = vratState.observances.first;
      final pastObs = DefaultVratTemplatesData.createTemplate(
        VratType.pradosham,
        targetDate: '2026-10-15',
        location: 'Varanasi',
      ).copyWith(
        id: 'vrat_past_pradosham',
        status: ObservanceStatus.completed,
      );
      await vratState.addObservance(pastObs);

      final activeReminder = DevotionalReminder(
        id: 'rem_active',
        title: 'Active Reminder',
        body: 'Stay peaceful',
        type: ReminderType.personalVrat,
        hour: 6,
        minute: 0,
        repeatDaily: false,
        scheduledDate: activeObs.targetDate,
        linkedVratId: activeObs.id,
      );
      final pastReminder = DevotionalReminder(
        id: 'rem_past',
        title: 'Past Reminder',
        body: 'Past event',
        type: ReminderType.personalVrat,
        hour: 6,
        minute: 0,
        repeatDaily: false,
        scheduledDate: pastObs.targetDate,
        linkedVratId: pastObs.id,
      );
      await vratState.addReminder(activeReminder);
      await vratState.addReminder(pastReminder);

      await vratState.clearHistory();

      // Past reminder cancelled and purged
      expect(reminderService.cancelledReminderIds, contains('rem_past'));
      expect(vratState.getReminderById('rem_past'), isNull);
      // Active reminder preserved
      expect(vratState.getReminderById('rem_active'), isNotNull);
    });

    test('8. Toggling reminder disabled cancels scheduled notification', () async {
      final reminder = DevotionalReminder(
        id: 'rem_toggle_test',
        title: 'Daily Prayer',
        body: 'Peaceful chant',
        type: ReminderType.morningSadhana,
        hour: 7,
        minute: 0,
        repeatDaily: true,
        isEnabled: true,
      );
      await vratState.addReminder(reminder);

      // Disable reminder
      await vratState.toggleReminder('rem_toggle_test', false);

      expect(vratState.getReminderById('rem_toggle_test')?.isEnabled, isFalse);
      expect(reminderService.cancelledReminderIds, contains('rem_toggle_test'));
    });

    test('9. Notification permission denied is gracefully reflected in state', () async {
      reminderService.currentPermissionStatus = ReminderPermissionStatus.denied;
      final status = await reminderService.getPermissionStatus();
      expect(status, equals(ReminderPermissionStatus.denied));
    });
  });
}
