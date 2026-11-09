import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Future<int> getOrCreateNotificationId(String id);
  Future<void> releaseReminderId(String reminderId);
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  });
}

class LocalNotificationReminderService implements ReminderService {
  static const String _prefsKeyIdRegistry = 'vedam_reminder_id_registry_v1';
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final SharedPreferences? _injectedPrefs;
  final Map<String, int> _idRegistry = {};
  bool _isInitialized = false;
  bool _registryLoaded = false;

  LocalNotificationReminderService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    SharedPreferences? prefs,
  })  : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _injectedPrefs = prefs;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    await _ensureRegistryLoaded();

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

  Future<void> _ensureRegistryLoaded() async {
    if (_registryLoaded) return;
    try {
      final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyIdRegistry);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _idRegistry.clear();
        decoded.forEach((k, v) {
          if (v is int) _idRegistry[k] = v;
        });
      }
      _registryLoaded = true;
    } catch (e) {
      debugPrint('Registry load note (handled): $e');
      _registryLoaded = true;
    }
  }

  Future<void> _saveRegistry() async {
    try {
      final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyIdRegistry, jsonEncode(_idRegistry));
    } catch (e) {
      debugPrint('Registry save note: $e');
    }
  }

  @override
  Future<int> getOrCreateNotificationId(String id) async {
    await _ensureRegistryLoaded();
    if (_idRegistry.containsKey(id)) {
      return _idRegistry[id]!;
    }

    // Deterministic 31-bit positive candidate integer
    int candidate = id.hashCode.abs() % 2147483647;
    if (candidate == 0) candidate = 1;

    // Linear probing if candidate hash collides with an already allocated reminder
    final allocated = _idRegistry.values.toSet();
    while (allocated.contains(candidate)) {
      candidate = (candidate + 1) % 2147483647;
      if (candidate == 0) candidate = 1;
    }

    _idRegistry[id] = candidate;
    await _saveRegistry();
    return candidate;
  }

  @override
  Future<void> releaseReminderId(String reminderId) async {
    await _ensureRegistryLoaded();
    if (_idRegistry.containsKey(reminderId)) {
      final notifId = _idRegistry.remove(reminderId)!;
      await _saveRegistry();
      try {
        await _notificationsPlugin.cancel(id: notifId);
      } catch (_) {}
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
    return id.hashCode.abs() % 2147483647;
  }

  @override
  Future<void> scheduleReminder(DevotionalReminder reminder) async {
    if (!reminder.isEnabled) {
      await cancelReminder(reminder.id);
      return;
    }

    await initialize();

    final notifId = await getOrCreateNotificationId(reminder.id);

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
    await _ensureRegistryLoaded();
    final notifId = _idRegistry[reminderId] ?? _idToInteger(reminderId);
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

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    await initialize();
    final notifId = await getOrCreateNotificationId(id);

    const androidDetails = AndroidNotificationDetails(
      'vedam_devotional_reminders',
      'Devotional Reminders',
      channelDescription:
          'Respectful reminders for personal Sadhana and devotional observances.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      debugPrint('Immediate notification delivery note: $e');
    }
  }
}

/// In-memory mock reminder service for unit tests and headless environments.
class MockReminderService implements ReminderService {
  ReminderPermissionStatus currentPermission = ReminderPermissionStatus.notDetermined;
  final Map<String, DevotionalReminder> scheduledReminders = {};
  final Map<String, int> allocatedNotifIds = {};
  final List<Map<String, dynamic>> deliveredNotifications = [];
  int requestPermissionCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<int> getOrCreateNotificationId(String id) async {
    if (allocatedNotifIds.containsKey(id)) {
      return allocatedNotifIds[id]!;
    }
    int candidate = id.hashCode.abs() % 2147483647;
    if (candidate == 0) candidate = 1;
    final allocated = allocatedNotifIds.values.toSet();
    while (allocated.contains(candidate)) {
      candidate = (candidate + 1) % 2147483647;
      if (candidate == 0) candidate = 1;
    }
    allocatedNotifIds[id] = candidate;
    return candidate;
  }

  @override
  Future<void> releaseReminderId(String reminderId) async {
    allocatedNotifIds.remove(reminderId);
    scheduledReminders.remove(reminderId);
  }

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
      await getOrCreateNotificationId(reminder.id);
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
    allocatedNotifIds.clear();
  }

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    final notifId = await getOrCreateNotificationId(id);
    deliveredNotifications.add({
      'id': notifId,
      'reminderId': id,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
