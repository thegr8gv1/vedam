import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/devotional_reminder.dart';

enum ReminderPermissionStatus {
  granted,
  denied,
  notDetermined,
}

abstract class ReminderService {
  Future<void> initialize();
  Future<ReminderPermissionStatus> getPermissionStatus();
  Future<ReminderPermissionStatus> requestPermission();
  Future<void> scheduleReminder(DevotionalReminder reminder);
  Future<void> cancelReminder(String reminderId);
  Future<void> cancelAllReminders();
}

class LocalNotificationReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init exception (handled): $e');
    }
  }

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async {
    if (kIsWeb) return ReminderPermissionStatus.granted;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areNotificationsEnabled =
            await androidPlugin.areNotificationsEnabled();
        if (areNotificationsEnabled == null) return ReminderPermissionStatus.notDetermined;
        return areNotificationsEnabled
            ? ReminderPermissionStatus.granted
            : ReminderPermissionStatus.denied;
      }
    } catch (_) {}

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<ReminderPermissionStatus> requestPermission() async {
    if (kIsWeb) return ReminderPermissionStatus.granted;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return (granted ?? false)
            ? ReminderPermissionStatus.granted
            : ReminderPermissionStatus.denied;
      }
    } catch (_) {}

    return ReminderPermissionStatus.granted;
  }

  int _idToInteger(String id) {
    // Generate a deterministic 31-bit positive integer from string ID
    return id.hashCode.abs() % 2147483647;
  }

  @override
  Future<void> scheduleReminder(DevotionalReminder reminder) async {
    if (!reminder.isEnabled) {
      await cancelReminder(reminder.id);
      return;
    }

    await initialize();

    final notifId = _idToInteger(reminder.id);

    const androidDetails = AndroidNotificationDetails(
      'vedam_devotional_reminders',
      'Devotional Reminders',
      channelDescription:
          'Respectful reminders for personal Sadhana and devotional observances.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      final now = tz.TZDateTime.now(tz.local);

      if (reminder.scheduledDate != null) {
        // One-off specific date reminder (e.g. Vrat observance morning)
        final parts = reminder.scheduledDate!.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);

          final scheduledDate = tz.TZDateTime(
            tz.local,
            year,
            month,
            day,
            reminder.hour,
            reminder.minute,
          );

          if (scheduledDate.isAfter(now)) {
            await _notificationsPlugin.zonedSchedule(
              id: notifId,
              title: reminder.title,
              body: reminder.body,
              scheduledDate: scheduledDate,
              notificationDetails: notifDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      } else {
        // Daily recurring reminder (e.g. Morning Sadhana, Evening Prayer)
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _notificationsPlugin.zonedSchedule(
          id: notifId,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling reminder (gracefully handled): $e');
    }
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    final notifId = _idToInteger(reminderId);
    try {
      await _notificationsPlugin.cancel(id: notifId);
    } catch (_) {}
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}

/// In-memory mock reminder service for unit tests and headless environments.
class MockReminderService implements ReminderService {
  ReminderPermissionStatus currentPermission = ReminderPermissionStatus.notDetermined;
  final Map<String, DevotionalReminder> scheduledReminders = {};
  int requestPermissionCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async {
    return currentPermission;
  }

  @override
  Future<ReminderPermissionStatus> requestPermission() async {
    requestPermissionCallCount++;
    currentPermission = ReminderPermissionStatus.granted;
    return currentPermission;
  }

  @override
  Future<void> scheduleReminder(DevotionalReminder reminder) async {
    if (reminder.isEnabled) {
      scheduledReminders[reminder.id] = reminder;
    } else {
      scheduledReminders.remove(reminder.id);
    }
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    scheduledReminders.remove(reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduledReminders.clear();
  }
}
