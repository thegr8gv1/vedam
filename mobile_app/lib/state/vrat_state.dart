import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/vrat_observance.dart';
import '../core/models/devotional_reminder.dart';
import '../core/models/panchangam_data.dart';
import '../core/services/reminder_service.dart';
import '../data/fixtures/default_vrat_templates_data.dart';

class VratState extends ChangeNotifier {
  static const String _prefsKeyObservances = 'vrat_user_observances_v1';
  static const String _prefsKeyReminders = 'vrat_user_reminders_v1';
  static const String _prefsKeyPermission = 'vrat_reminder_permission_v1';

  final SharedPreferences? _injectedPrefs;
  final ReminderService _reminderService;

  List<VratObservance> _observances = [
    DefaultVratTemplatesData.createTemplate(
      VratType.ekadashi,
      targetDate: '2026-11-05',
      location: 'Varanasi, India (25.3176°N, 82.9739°E)',
    ),
  ];
  List<DevotionalReminder> _reminders = List.from(DefaultVratTemplatesData.defaultReminders);
  ReminderPermissionStatus _permissionStatus = ReminderPermissionStatus.notDetermined;
  bool _isLoaded = false;

  VratState({
    SharedPreferences? prefs,
    ReminderService? reminderService,
  })  : _injectedPrefs = prefs,
        _reminderService = reminderService ?? LocalNotificationReminderService() {
    _initialize();
  }

  // Getters
  List<VratObservance> get observances => List.unmodifiable(_observances);
  List<DevotionalReminder> get reminders => List.unmodifiable(_reminders);
  ReminderPermissionStatus get permissionStatus => _permissionStatus;
  bool get isLoaded => _isLoaded;
  ReminderService get reminderService => _reminderService;

  List<VratObservance> get activeObservances {
    return _observances.where((o) =>
        o.status == ObservanceStatus.planned ||
        o.status == ObservanceStatus.inProgress).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  List<VratObservance> get pastObservances {
    return _observances.where((o) =>
        o.status == ObservanceStatus.completed ||
        o.status == ObservanceStatus.skipped ||
        o.status == ObservanceStatus.cancelled).toList()
      ..sort((a, b) => b.targetDate.compareTo(a.targetDate));
  }

  VratObservance? getObservanceById(String id) {
    try {
      return _observances.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  DevotionalReminder? getReminderById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  DevotionalReminder? getReminderForVrat(String vratId) {
    try {
      return _reminders.firstWhere((r) => r.linkedVratId == vratId);
    } catch (_) {
      return null;
    }
  }

  // Initialization and persistence
  Future<void> _initialize() async {
    await _reminderService.initialize();
    _permissionStatus = await _reminderService.getPermissionStatus();
    await _loadFromPreferences();
    _isLoaded = true;
    notifyListeners();
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await _getPrefs();

      // 1. Load Observances
      final rawObs = prefs.getString(_prefsKeyObservances);
      if (rawObs != null && rawObs.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawObs) as List<dynamic>;
        _observances = decoded
            .map((e) => VratObservance.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // Seed an initial upcoming template for easy discovery
        final todayStr = _formatDate(DateTime.now());
        final initialTemplate = DefaultVratTemplatesData.createTemplate(
          VratType.ekadashi,
          targetDate: todayStr,
          location: 'Varanasi, India (25.3176°N, 82.9739°E)',
        );
        _observances = [initialTemplate];
        await _saveObservances();
      }

      // 2. Load Reminders
      final rawRem = prefs.getString(_prefsKeyReminders);
      if (rawRem != null && rawRem.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawRem) as List<dynamic>;
        _reminders = decoded
            .map((e) => DevotionalReminder.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // Seed default opt-in reminders (disabled by default)
        _reminders = List.from(DefaultVratTemplatesData.defaultReminders);
        await _saveReminders();
      }
    } catch (e) {
      debugPrint('Error loading Vrat preferences: $e');
    }
  }

  Future<void> _saveObservances() async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(_observances.map((o) => o.toJson()).toList());
      await prefs.setString(_prefsKeyObservances, encoded);
    } catch (e) {
      debugPrint('Error saving Vrat observances: $e');
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString(_prefsKeyReminders, encoded);
    } catch (e) {
      debugPrint('Error saving Devotional reminders: $e');
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Observance Management
  Future<void> addObservance(VratObservance observance) async {
    _observances.removeWhere((o) => o.id == observance.id);
    _observances.add(observance);
    await _saveObservances();
    notifyListeners();
  }

  Future<void> updateObservance(VratObservance updated) async {
    final idx = _observances.indexWhere((o) => o.id == updated.id);
    if (idx != -1) {
      _observances[idx] = updated;
      await _saveObservances();
      notifyListeners();
    }
  }

  Future<void> deleteObservance(String id) async {
    _observances.removeWhere((o) => o.id == id);
    // Cancel any linked reminder
    final linkedReminders = _reminders.where((r) => r.linkedVratId == id).toList();
    for (final r in linkedReminders) {
      await deleteReminder(r.id);
    }
    await _saveObservances();
    notifyListeners();
  }

  Future<void> updateObservanceStatus(
    String id,
    ObservanceStatus newStatus, {
    String? personalNotes,
  }) async {
    final idx = _observances.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final current = _observances[idx];
      final isNowCompleted = newStatus == ObservanceStatus.completed;
      final completedAt = isNowCompleted ? DateTime.now().toIso8601String() : current.completedAt;

      _observances[idx] = current.copyWith(
        status: newStatus,
        personalNotes: personalNotes ?? current.personalNotes,
        completedAt: completedAt,
      );
      await _saveObservances();
      notifyListeners();
    }
  }

  Future<void> toggleChecklistItem(String vratId, String checklistItemId) async {
    final idx = _observances.indexWhere((o) => o.id == vratId);
    if (idx != -1) {
      final current = _observances[idx];
      final updatedChecklist = current.checklist.map((item) {
        if (item.id == checklistItemId) {
          return item.copyWith(isDone: !item.isDone);
        }
        return item;
      }).toList();

      _observances[idx] = current.copyWith(checklist: updatedChecklist);
      await _saveObservances();
      notifyListeners();
    }
  }

  Future<void> addChecklistItem(String vratId, VratChecklistItem item) async {
    final idx = _observances.indexWhere((o) => o.id == vratId);
    if (idx != -1) {
      final current = _observances[idx];
      final updatedChecklist = List<VratChecklistItem>.from(current.checklist)..add(item);
      _observances[idx] = current.copyWith(checklist: updatedChecklist);
      await _saveObservances();
      notifyListeners();
    }
  }

  // Reminders Management
  Future<void> requestNotificationPermission() async {
    _permissionStatus = await _reminderService.requestPermission();
    final prefs = await _getPrefs();
    await prefs.setString(_prefsKeyPermission, _permissionStatus.name);
    notifyListeners();
  }

  Future<void> addReminder(DevotionalReminder reminder) async {
    _reminders.removeWhere((r) => r.id == reminder.id);
    _reminders.add(reminder);
    await _saveReminders();

    if (reminder.isEnabled) {
      await _reminderService.scheduleReminder(reminder);
    } else {
      await _reminderService.cancelReminder(reminder.id);
    }
    notifyListeners();
  }

  Future<void> updateReminder(DevotionalReminder updated) async {
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      await _saveReminders();

      if (updated.isEnabled) {
        await _reminderService.scheduleReminder(updated);
      } else {
        await _reminderService.cancelReminder(updated.id);
      }
      notifyListeners();
    }
  }

  Future<void> toggleReminder(String reminderId, bool isEnabled) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx != -1) {
      // If user is enabling, check/request permission first
      if (isEnabled && _permissionStatus != ReminderPermissionStatus.granted) {
        await requestNotificationPermission();
        if (_permissionStatus != ReminderPermissionStatus.granted) {
          // User denied permission; cannot enable reminder
          return;
        }
      }

      final updated = _reminders[idx].copyWith(isEnabled: isEnabled);
      _reminders[idx] = updated;
      await _saveReminders();

      if (isEnabled) {
        await _reminderService.scheduleReminder(updated);
      } else {
        await _reminderService.cancelReminder(reminderId);
      }
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
    await _reminderService.releaseReminderId(reminderId);
    notifyListeners();
  }

  // Panchangam Date Suggestion (Non-authoritative, informational only)
  Map<String, String> getInformationalPanchangamContext(
    VratType type,
    DailyPanchangamData? data,
  ) {
    if (data == null) {
      return {
        'status': 'Panchangam calculation currently unavailable offline',
        'suggestion': 'Select your intended observance date manually according to your family tradition.',
        'notice': 'Vedam does not invent fasting dates. Please consult your local temple or regional panchangam.',
      };
    }

    final tithi = data.tithi.name;
    final paksha = data.paksha;
    final nakshatra = data.nakshatra.name;

    String observationNote;
    switch (type) {
      case VratType.ekadashi:
        observationNote = tithi.toLowerCase().contains('ekadashi')
            ? 'Today\'s calculated astronomical tithi is $tithi ($paksha). Smartha and Vaishnava fasting traditions may calculate Arunodaya differently.'
            : 'Today is $tithi ($paksha). Ekadashi falls on the 11th tithi of each lunar fortnight.';
        break;
      case VratType.pradosham:
        observationNote = tithi.toLowerCase().contains('trayodashi')
            ? 'Today\'s calculated tithi is $tithi ($paksha). Pradosha Puja is traditionally observed at sunset during Trayodashi.'
            : 'Today is $tithi ($paksha). Pradosham occurs on the 13th lunar day (Trayodashi).';
        break;
      case VratType.purnima:
        observationNote = tithi.toLowerCase().contains('purnima')
            ? 'Today is the full moon ($tithi). Ideal for Satyanarayana and Mahalakshmi contemplation.'
            : 'Today is $tithi ($paksha). Purnima is the 15th day of the waxing moon (Shukla Paksha).';
        break;
      case VratType.amavasya:
        observationNote = tithi.toLowerCase().contains('amavasya')
            ? 'Today is the new moon ($tithi). Dedicated to ancestor remembrance and quiet prayer.'
            : 'Today is $tithi ($paksha). Amavasya concludes the waning fortnight (Krishna Paksha).';
        break;
      case VratType.sankashtiChaturthi:
        observationNote = (tithi.toLowerCase().contains('chaturthi') && paksha.toLowerCase().contains('krishna'))
            ? 'Today is Krishna Chaturthi ($tithi). Auspicious for evening moonrise Sankashti adoration.'
            : 'Today is $tithi ($paksha). Sankashti Chaturthi is observed on Krishna Paksha Chaturthi.';
        break;
      case VratType.custom:
        observationNote = 'Today\'s calculated celestial state: $tithi, $nakshatra Nakshatra.';
        break;
    }

    return {
      'status': 'Astronomical calculation active for ${data.location.name}',
      'tithi': '$tithi ($paksha)',
      'nakshatra': nakshatra,
      'suggestion': observationNote,
      'notice': 'Informational astronomical notice. Fasting rules and Parana timings differ across sampradayas.',
    };
  }
}
