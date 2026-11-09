import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/app_settings.dart';
import '../core/models/devotee_preferences.dart';
import '../core/models/devotional_reminder.dart';
import '../core/models/panchangam_data.dart';
import '../core/models/verse.dart';
import '../core/services/reminder_service.dart';
import 'app_state.dart';
import 'audio_state.dart';
import 'panchangam_state.dart';

/// State management for Devotee Onboarding, Personalization, and Spiritual Goals.
///
/// Coordinates devotee preferences across AppState, PanchangamState, AudioState,
/// and local notification services while ensuring user privacy and local persistence.
class PersonalizationState extends ChangeNotifier {
  static const String _keyPreferences = 'vedam_devotee_preferences_v1';
  static const String _keyOnboardingCompleted = 'vedam_onboarding_completed';
  static const String _keyFirstLaunchPrompted = 'vedam_first_launch_prompted';

  final SharedPreferences? _injectedPrefs;
  SharedPreferences? _prefs;
  final ReminderService? _reminderService;

  AppState? _appState;
  PanchangamState? _panchangamState;
  AudioState? _audioState;

  DevoteePreferences _preferences = const DevoteePreferences();
  bool _isInitialized = false;
  bool _isReturningUser = false;
  bool _showOnboardingFlow = false;

  PersonalizationState({
    SharedPreferences? prefs,
    ReminderService? reminderService,
    AppState? appState,
    PanchangamState? panchangamState,
    AudioState? audioState,
    bool forceShowOnboarding = false,
  })  : _injectedPrefs = prefs,
        _reminderService = reminderService,
        _appState = appState,
        _panchangamState = panchangamState,
        _audioState = audioState,
        _showOnboardingFlow = forceShowOnboarding {
    _init();
  }

  // Getters
  DevoteePreferences get preferences => _preferences;
  bool get isInitialized => _isInitialized;
  bool get onboardingCompleted => _preferences.onboardingCompleted;
  bool get showOnboardingFlow => _showOnboardingFlow;
  bool get isReturningUser => _isReturningUser;

  Set<String> get selectedDeityIds => _preferences.selectedDeityIds;
  List<DevotionalDeity> get selectedDeities => _preferences.selectedDeityIds
      .map((id) => DevotionalDeity.getById(id))
      .whereType<DevotionalDeity>()
      .toList();

  DailySadhanaGoals get sadhanaGoals => _preferences.sadhanaGoals;
  ScriptOption get scriptureScript => _preferences.scriptureScript;
  String get interfaceLanguage => _preferences.interfaceLanguage;
  PanchangamLocation get panchangamLocation => _preferences.panchangamLocation;
  bool get remindersEnabled => _preferences.remindersEnabled;
  int get japaTarget => _preferences.sadhanaGoals.japaTarget;

  void attachDependencies({
    AppState? appState,
    PanchangamState? panchangamState,
    AudioState? audioState,
  }) {
    if (appState != null) _appState = appState;
    if (panchangamState != null) _panchangamState = panchangamState;
    if (audioState != null) _audioState = audioState;

    // Synchronize initial preferences to attached dependencies
    if (_isInitialized) {
      _syncToDependencies();
    }
  }

  Future<void> _init() async {
    _prefs = _injectedPrefs ?? await SharedPreferences.getInstance();

    // 1. Detect if this is an existing user prior to Phase 18A
    final completed = _prefs?.getBool(_keyOnboardingCompleted);
    final hasRoutine = _prefs?.containsKey('vedam_sadhana_routine_ids') ?? false;
    final hasVrat = _prefs?.containsKey('vedam_vrat_observances') ?? false;
    final hasJapa = _prefs?.containsKey('vedam_japa_target') ?? false;
    final hasHistory = _prefs?.containsKey('vedam_recently_read_scriptures') ?? false;

    if (completed == true || hasRoutine || hasVrat || hasJapa || hasHistory) {
      _isReturningUser = true;
    }

    // 2. Load stored preferences if present
    final rawJson = _prefs?.getString(_keyPreferences);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        _preferences = DevoteePreferences.fromJson(decoded);
      } catch (e) {
        debugPrint('Personalization preferences parse error: $e');
        _preferences = const DevoteePreferences();
      }
    } else if (_isReturningUser) {
      // Existing user without onboarding profile: Mark onboarding completed with defaults
      _preferences = _preferences.copyWith(onboardingCompleted: true);
    }

    // If explicit completed flag exists, prioritize it
    if (completed != null) {
      _preferences = _preferences.copyWith(onboardingCompleted: completed);
    }

    // Determine if onboarding screen should show
    if (!_preferences.onboardingCompleted && !_isReturningUser) {
      _showOnboardingFlow = true;
    }

    _isInitialized = true;
    _syncToDependencies();
    notifyListeners();
  }

  void _syncToDependencies() {
    _appState?.setActiveScript(_preferences.scriptureScript);
    _appState?.setInterfaceLanguage(InterfaceLanguage.fromCode(_preferences.interfaceLanguage));
    _panchangamState?.setLocation(_preferences.panchangamLocation);
    _audioState?.setTargetRepetitions(_preferences.sadhanaGoals.japaTarget);
  }

  Future<void> _save() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferences, jsonEncode(_preferences.toJson()));
    await prefs.setBool(_keyOnboardingCompleted, _preferences.onboardingCompleted);
    _syncToDependencies();
    notifyListeners();
  }

  Future<void> setDevotionalInterests(Set<String> ids) async {
    if (ids.isEmpty) {
      // Keep at least general practice if all unselected
      ids = {'general'};
    }
    _preferences = _preferences.copyWith(selectedDeityIds: ids);
    await _save();
  }

  Future<void> toggleDevotionalInterest(String id) async {
    final updated = Set<String>.from(_preferences.selectedDeityIds);
    if (updated.contains(id)) {
      if (updated.length > 1) {
        updated.remove(id);
      }
    } else {
      updated.add(id);
    }
    _preferences = _preferences.copyWith(selectedDeityIds: updated);
    await _save();
  }

  Future<void> setScriptureScript(ScriptOption script) async {
    _preferences = _preferences.copyWith(scriptureScript: script);
    _appState?.setActiveScript(script);
    await _save();
  }

  Future<void> setInterfaceLanguage(String lang) async {
    _preferences = _preferences.copyWith(interfaceLanguage: lang);
    _appState?.setInterfaceLanguage(InterfaceLanguage.fromCode(lang));
    await _save();
  }

  Future<void> setSadhanaGoals(DailySadhanaGoals goals) async {
    _preferences = _preferences.copyWith(sadhanaGoals: goals);
    _audioState?.setTargetRepetitions(goals.japaTarget);
    await _save();
  }

  Future<void> setJapaTarget(int target) async {
    if (target <= 0 || target > 100000) return;
    final updatedGoals = _preferences.sadhanaGoals.copyWith(japaTarget: target);
    _preferences = _preferences.copyWith(sadhanaGoals: updatedGoals);
    _audioState?.setTargetRepetitions(target);
    await _save();
  }

  Future<void> setPanchangamLocation(PanchangamLocation loc) async {
    _preferences = _preferences.copyWith(panchangamLocation: loc);
    _panchangamState?.setLocation(loc);
    await _save();
  }

  Future<bool> setRemindersEnabled(bool enabled) async {
    if (enabled && _reminderService != null) {
      final status = await _reminderService.requestPermission();
      if (status == ReminderPermissionStatus.denied) {
        _preferences = _preferences.copyWith(remindersEnabled: false);
        await _save();
        return false;
      }
      await _scheduleDevotionalReminders();
    } else if (!enabled && _reminderService != null) {
      await _cancelDevotionalReminders();
    }

    _preferences = _preferences.copyWith(remindersEnabled: enabled);
    await _save();
    return true;
  }

  Future<void> _scheduleDevotionalReminders() async {
    if (_reminderService == null) return;
    await _reminderService.initialize();

    // 1. Morning Brahma Muhurta / Pratah Smaranam Reminder
    final morning = DevotionalReminder(
      id: 'reminder_morning_sadhana',
      type: ReminderType.morningSadhana,
      title: 'Prātah Smaraṇam • Morning Devotion',
      body: 'Begin your sacred morning with peaceful contemplation and gratitude.',
      hour: _preferences.morningReminderHour,
      minute: _preferences.morningReminderMinute,
      repeatDaily: true,
    );
    await _reminderService.scheduleReminder(morning);

    // 2. Evening Sandhya / Prayer Reminder
    final evening = DevotionalReminder(
      id: 'reminder_evening_prayer',
      type: ReminderType.eveningPrayer,
      title: 'Sāndhya Vandanā • Evening Prayer',
      body: 'Pause for evening prayer, mantra chanting, and sacred peace.',
      hour: _preferences.eveningReminderHour,
      minute: _preferences.eveningReminderMinute,
      repeatDaily: true,
    );
    await _reminderService.scheduleReminder(evening);
  }

  Future<void> _cancelDevotionalReminders() async {
    if (_reminderService == null) return;
    await _reminderService.cancelReminder('reminder_morning_sadhana');
    await _reminderService.cancelReminder('reminder_evening_prayer');
  }

  Future<void> completeOnboarding() async {
    _preferences = _preferences.copyWith(onboardingCompleted: true);
    _showOnboardingFlow = false;
    await _save();
  }

  Future<void> skipOnboarding() async {
    // Skipping onboarding sets onboardingCompleted = true with sensible defaults
    _preferences = _preferences.copyWith(onboardingCompleted: true);
    _showOnboardingFlow = false;
    await _save();
  }

  void restartOnboarding() {
    _showOnboardingFlow = true;
    notifyListeners();
  }

  void dismissOnboardingFlow() {
    _showOnboardingFlow = false;
    notifyListeners();
  }

  /// Resets personalization preferences to default values without deleting
  /// user's bookmarks, study notes, japa history, vrat observances, or routine!
  Future<void> resetPersonalization() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_keyPreferences);
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyFirstLaunchPrompted);

    if (_preferences.remindersEnabled) {
      await _cancelDevotionalReminders();
    }

    _preferences = const DevoteePreferences(onboardingCompleted: true);
    _syncToDependencies();
    notifyListeners();
  }
}
