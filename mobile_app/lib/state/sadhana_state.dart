import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/puja_guide.dart';
import '../core/models/sadhana_practice.dart';
import '../data/fixtures/default_sadhana_practices_data.dart';

/// State management for the Daily Sadhana dashboard and Guided Puja experience.
/// Handles personal routine customization, reordering, local date tracking,
/// daily completion resets, and step-by-step puja navigation with pause/resume.
class SadhanaState extends ChangeNotifier {
  static const String _keyRoutineIds = 'vedam_sadhana_routine_ids';
  static const String _keyLastDate = 'vedam_sadhana_last_date';
  static const String _keyCompletedIds = 'vedam_sadhana_completed_ids';

  final SharedPreferences? _injectedPrefs;
  SharedPreferences? _prefs;

  final List<SadhanaPractice> _allCatalogPractices = List.from(DefaultSadhanaPracticesData.allCatalogPractices);
  List<SadhanaPractice> _activeRoutine = [];
  final Set<String> _completedPracticeIds = {};
  DateTime _currentDate = DateTime.now();

  // Active Guided Puja Session
  PujaGuide? _activeGuide;
  int _activeGuideStepIndex = 0;
  bool _isGuidePaused = false;
  bool _isGuideCompleted = false;

  SadhanaState({
    SharedPreferences? prefs,
    DateTime? initialDate,
  })  : _injectedPrefs = prefs,
        _currentDate = initialDate ?? DateTime.now() {
    _initialize();
  }

  // Getters
  List<SadhanaPractice> get activeRoutine => List.unmodifiable(_activeRoutine);
  List<SadhanaPractice> get allCatalogPractices => List.unmodifiable(_allCatalogPractices);
  Set<String> get completedPracticeIds => Set.unmodifiable(_completedPracticeIds);
  DateTime get currentDate => _currentDate;

  int get totalRoutineCount => _activeRoutine.length;
  int get completedRoutineCount => _activeRoutine.where((p) => _completedPracticeIds.contains(p.id)).length;
  double get completionProgress => totalRoutineCount > 0 ? (completedRoutineCount / totalRoutineCount).clamp(0.0, 1.0) : 0.0;

  PujaGuide? get activeGuide => _activeGuide;
  int get activeGuideStepIndex => _activeGuideStepIndex;
  bool get isGuidePaused => _isGuidePaused;
  bool get isGuideCompleted => _isGuideCompleted;
  bool get hasActiveGuideSession => _activeGuide != null && !_isGuideCompleted;

  PujaStep? get currentGuideStep {
    if (_activeGuide == null || _activeGuide!.steps.isEmpty) return null;
    if (_activeGuideStepIndex < 0 || _activeGuideStepIndex >= _activeGuide!.steps.length) return null;
    return _activeGuide!.steps[_activeGuideStepIndex];
  }

  String _formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _initialize() async {
    _prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    if (_prefs == null) {
      _applyDefaultRoutine();
      return;
    }

    final savedIds = _prefs!.getStringList(_keyRoutineIds);
    if (savedIds != null && savedIds.isNotEmpty) {
      _activeRoutine = savedIds
          .map((id) => _findPracticeById(id))
          .whereType<SadhanaPractice>()
          .toList();
    }
    if (_activeRoutine.isEmpty) {
      _applyDefaultRoutine();
    }

    final todayKey = _formatDateKey(_currentDate);
    final lastDateKey = _prefs!.getString(_keyLastDate);

    if (lastDateKey == todayKey) {
      final completed = _prefs!.getStringList(_keyCompletedIds) ?? [];
      _completedPracticeIds.clear();
      _completedPracticeIds.addAll(completed);
    } else {
      // Date has changed / rolled over: reset daily completion
      _completedPracticeIds.clear();
      _prefs!.setString(_keyLastDate, todayKey);
      _prefs!.setStringList(_keyCompletedIds, []);
    }

    notifyListeners();
  }

  void _applyDefaultRoutine() {
    _activeRoutine = DefaultSadhanaPracticesData.defaultActiveRoutineIds
        .map((id) => _findPracticeById(id))
        .whereType<SadhanaPractice>()
        .toList();
  }

  SadhanaPractice? _findPracticeById(String id) {
    try {
      return _allCatalogPractices.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveRoutineToStorage() async {
    if (_prefs == null) return;
    final ids = _activeRoutine.map((p) => p.id).toList();
    await _prefs!.setStringList(_keyRoutineIds, ids);
  }

  Future<void> _saveCompletionToStorage() async {
    if (_prefs == null) return;
    final todayKey = _formatDateKey(_currentDate);
    await _prefs!.setString(_keyLastDate, todayKey);
    await _prefs!.setStringList(_keyCompletedIds, _completedPracticeIds.toList());
  }

  // --- Routine Customization & Ordering ---

  bool isPracticeCompleted(String practiceId) => _completedPracticeIds.contains(practiceId);

  void togglePracticeCompletion(String practiceId) {
    if (_completedPracticeIds.contains(practiceId)) {
      _completedPracticeIds.remove(practiceId);
    } else {
      _completedPracticeIds.add(practiceId);
    }
    _saveCompletionToStorage();
    notifyListeners();
  }

  void markPracticeCompleted(String practiceId) {
    if (!_completedPracticeIds.contains(practiceId)) {
      _completedPracticeIds.add(practiceId);
      _saveCompletionToStorage();
      notifyListeners();
    }
  }

  void addPracticeToRoutine(String practiceId) {
    if (_activeRoutine.any((p) => p.id == practiceId)) return;
    final p = _findPracticeById(practiceId);
    if (p != null) {
      _activeRoutine.add(p);
      _saveRoutineToStorage();
      notifyListeners();
    }
  }

  void removePracticeFromRoutine(String practiceId) {
    _activeRoutine.removeWhere((p) => p.id == practiceId);
    _saveRoutineToStorage();
    notifyListeners();
  }

  void reorderRoutine(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _activeRoutine.length) return;
    if (newIndex < 0 || newIndex > _activeRoutine.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _activeRoutine.removeAt(oldIndex);
    _activeRoutine.insert(newIndex, item);
    _saveRoutineToStorage();
    notifyListeners();
  }

  void resetTodayCompletion() {
    _completedPracticeIds.clear();
    _saveCompletionToStorage();
    notifyListeners();
  }

  void checkDateRollOver({DateTime? now}) {
    final checkTime = now ?? DateTime.now();
    final todayKey = _formatDateKey(checkTime);
    final currentKey = _formatDateKey(_currentDate);

    if (todayKey != currentKey) {
      _currentDate = checkTime;
      _completedPracticeIds.clear();
      _saveCompletionToStorage();
      notifyListeners();
    }
  }

  // --- Guided Puja Session Management ---

  void startGuide(PujaGuide guide, {int stepIndex = 0}) {
    _activeGuide = guide;
    _activeGuideStepIndex = stepIndex.clamp(0, guide.steps.isNotEmpty ? guide.steps.length - 1 : 0);
    _isGuidePaused = false;
    _isGuideCompleted = false;
    notifyListeners();
  }

  void nextGuideStep() {
    if (_activeGuide == null) return;
    if (_activeGuideStepIndex < _activeGuide!.steps.length - 1) {
      _activeGuideStepIndex++;
      _isGuidePaused = false;
      notifyListeners();
    } else {
      completeGuide();
    }
  }

  void previousGuideStep() {
    if (_activeGuide == null) return;
    if (_activeGuideStepIndex > 0) {
      _activeGuideStepIndex--;
      _isGuidePaused = false;
      _isGuideCompleted = false;
      notifyListeners();
    }
  }

  void goToStep(int index) {
    if (_activeGuide == null) return;
    if (index >= 0 && index < _activeGuide!.steps.length) {
      _activeGuideStepIndex = index;
      _isGuidePaused = false;
      notifyListeners();
    }
  }

  void pauseGuide() {
    if (_activeGuide != null) {
      _isGuidePaused = true;
      notifyListeners();
    }
  }

  void resumeGuide() {
    if (_activeGuide != null) {
      _isGuidePaused = false;
      notifyListeners();
    }
  }

  void completeGuide() {
    if (_activeGuide != null) {
      _isGuideCompleted = true;
      _isGuidePaused = false;

      // Automatically link to corresponding practice completion if present
      final matchingPractice = _activeRoutine.firstWhere(
        (p) => p.pujaGuideId == _activeGuide!.id,
        orElse: () => _allCatalogPractices.firstWhere(
          (p) => p.pujaGuideId == _activeGuide!.id,
          orElse: () => _activeRoutine.first,
        ),
      );
      if (matchingPractice.pujaGuideId == _activeGuide!.id) {
        markPracticeCompleted(matchingPractice.id);
      }

      notifyListeners();
    }
  }

  void exitGuide() {
    _activeGuide = null;
    _activeGuideStepIndex = 0;
    _isGuidePaused = false;
    _isGuideCompleted = false;
    notifyListeners();
  }
}
