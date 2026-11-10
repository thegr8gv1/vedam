import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/devotional_journal_entry.dart';
import '../core/models/orchestrator_session.dart';
import '../core/models/panchangam_data.dart';
import '../core/models/practice_sequence.dart';
import '../core/services/practice_orchestrator_service.dart';

/// State management for the Nitya Sadhana (Daily Devotional Practice) Orchestrator.
/// Manages user practice sequences, active in-progress or paused sessions,
/// local private devotional practice journal, streak calculations,
/// and conservative context-aware Panchangam recommendations.
class OrchestratorState extends ChangeNotifier {
  final PracticeOrchestratorService _service;
  bool _isDisposed = false;
  bool _isLoading = true;

  List<PracticeSequence> _sequences = [];
  OrchestratorSession? _activeSession;
  List<DevotionalJournalEntry> _journalEntries = [];
  DevotionalStreakReport _streakReport = const DevotionalStreakReport();
  PanchangamRecommendation? _currentRecommendation;

  OrchestratorState({
    PracticeOrchestratorService? service,
    SharedPreferences? prefs,
  }) : _service = service ?? PracticeOrchestratorService(prefs: prefs) {
    _init();
  }

  bool get isLoading => _isLoading;
  List<PracticeSequence> get sequences => List.unmodifiable(_sequences);
  OrchestratorSession? get activeSession => _activeSession;
  List<DevotionalJournalEntry> get journalEntries => List.unmodifiable(_journalEntries);
  DevotionalStreakReport get streakReport => _streakReport;
  PanchangamRecommendation? get currentRecommendation => _currentRecommendation;

  bool get hasActiveSession =>
      _activeSession != null && !_activeSession!.isCompleted && !_activeSession!.isAbandoned;

  PracticeSequence? get morningSequence {
    try {
      return _sequences.firstWhere((s) => s.type == PracticeSequenceType.morning);
    } catch (_) {
      return null;
    }
  }

  PracticeSequence? get eveningSequence {
    try {
      return _sequences.firstWhere((s) => s.type == PracticeSequenceType.evening);
    } catch (_) {
      return null;
    }
  }

  List<PracticeSequence> get customSequences =>
      _sequences.where((s) => s.type == PracticeSequenceType.custom).toList();

  PracticeSequence? get activeSequence {
    if (_activeSession == null) return null;
    try {
      return _sequences.firstWhere((s) => s.id == _activeSession!.sequenceId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await refreshAll();

    _isLoading = false;
    _safeNotify();
  }

  /// Reloads all persisted data: sequences, active session, journal, streak.
  Future<void> refreshAll({DailyPanchangamData? panchangam}) async {
    _sequences = await _service.loadSequences();
    _activeSession = await _service.loadActiveSession();
    _journalEntries = await _service.loadJournalEntries();
    _streakReport = await _service.getStreakReport();
    await checkRecommendation(panchangam: panchangam);
    _safeNotify();
  }

  /// Checks for contextual Panchangam recommendation for today.
  Future<void> checkRecommendation({DailyPanchangamData? panchangam}) async {
    _currentRecommendation = await _service.getRecommendation(panchangam: panchangam);
    _safeNotify();
  }

  /// Dismisses today's recommendation so it won't be shown again until tomorrow.
  Future<void> dismissRecommendation() async {
    await _service.dismissRecommendation();
    _currentRecommendation = null;
    _safeNotify();
  }

  /// Saves or updates a sequence (name, steps, configuration).
  Future<void> saveSequence(PracticeSequence sequence) async {
    await _service.saveSequence(sequence);
    _sequences = await _service.loadSequences();
    _safeNotify();
  }

  /// Deletes a sequence by its unique id.
  Future<void> deleteSequence(String id) async {
    await _service.deleteSequence(id);
    _sequences = await _service.loadSequences();
    _safeNotify();
  }

  /// Resets sequences to default morning and evening routines.
  Future<void> resetToDefaults() async {
    await _service.resetToDefaultSequences();
    _sequences = await _service.loadSequences();
    _safeNotify();
  }

  /// Starts a new devotional practice sequence session.
  /// If there is an existing incomplete session, it is replaced cleanly.
  Future<OrchestratorSession> startSequence(PracticeSequence sequence) async {
    // Determine the first enabled step index
    int firstEnabledIndex = sequence.steps.indexWhere((s) => s.isEnabled);
    if (firstEnabledIndex < 0) {
      firstEnabledIndex = 0;
    }

    final initialStatuses = <String, StepExecutionStatus>{};
    for (int i = 0; i < sequence.steps.length; i++) {
      if (!sequence.steps[i].isEnabled) {
        initialStatuses[i.toString()] = StepExecutionStatus.skipped;
      } else if (i == firstEnabledIndex) {
        initialStatuses[i.toString()] = StepExecutionStatus.inProgress;
      } else {
        initialStatuses[i.toString()] = StepExecutionStatus.pending;
      }
    }

    final session = OrchestratorSession(
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      sequenceId: sequence.id,
      sequenceName: sequence.name,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      currentStepIndex: firstEnabledIndex,
      stepStatuses: initialStatuses,
      isPaused: false,
      isCompleted: false,
      isAbandoned: false,
    );

    _activeSession = session;
    await _service.saveActiveSession(session);
    _safeNotify();
    return session;
  }

  /// Pauses the current active session.
  Future<void> pauseSession() async {
    if (_activeSession == null || _activeSession!.isCompleted) return;

    final updated = _activeSession!.copyWith(
      isPaused: true,
      lastUpdatedAt: DateTime.now(),
    );
    _activeSession = updated;
    await _service.saveActiveSession(updated);
    _safeNotify();
  }

  /// Resumes the current paused session.
  Future<void> resumeSession() async {
    if (_activeSession == null || _activeSession!.isCompleted) return;

    final updated = _activeSession!.copyWith(
      isPaused: false,
      lastUpdatedAt: DateTime.now(),
    );
    _activeSession = updated;
    await _service.saveActiveSession(updated);
    _safeNotify();
  }

  /// Abandons the active session without recording it to journal.
  Future<void> abandonSession() async {
    if (_activeSession == null) return;

    await _service.clearActiveSession();
    _activeSession = null;
    _safeNotify();
  }

  /// Marks current step as completed and either advances to next enabled step
  /// or concludes the session and logs it into the local private journal.
  Future<void> completeStep(int stepIndex, {PracticeSequence? sequence}) async {
    if (_activeSession == null) return;

    final seq = sequence ?? activeSequence;
    final updatedStatuses = Map<String, StepExecutionStatus>.from(_activeSession!.stepStatuses);
    updatedStatuses[stepIndex.toString()] = StepExecutionStatus.completed;

    int nextIndex = -1;
    if (seq != null) {
      for (int i = stepIndex + 1; i < seq.steps.length; i++) {
        if (seq.steps[i].isEnabled) {
          nextIndex = i;
          break;
        }
      }
    }

    if (nextIndex == -1) {
      // All enabled steps completed! Conclude session.
      final completedSession = _activeSession!.copyWith(
        stepStatuses: updatedStatuses,
        isCompleted: true,
        isPaused: false,
        completedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      // Record to private devotional journal
      if (seq != null) {
        await _service.recordCompletedSession(
          session: completedSession,
          sequence: seq,
        );
      }

      await _service.clearActiveSession();
      _activeSession = null;
      _journalEntries = await _service.loadJournalEntries();
      _streakReport = await _service.getStreakReport();
    } else {
      // Advance to next step
      updatedStatuses[nextIndex.toString()] = StepExecutionStatus.inProgress;
      final updatedSession = _activeSession!.copyWith(
        currentStepIndex: nextIndex,
        stepStatuses: updatedStatuses,
        lastUpdatedAt: DateTime.now(),
      );
      _activeSession = updatedSession;
      await _service.saveActiveSession(updatedSession);
    }

    _safeNotify();
  }

  /// Skips the current step (if optional) and advances to next enabled step,
  /// or concludes session if no more steps remain.
  Future<void> skipStep(int stepIndex, {PracticeSequence? sequence}) async {
    if (_activeSession == null) return;

    final seq = sequence ?? activeSequence;
    final updatedStatuses = Map<String, StepExecutionStatus>.from(_activeSession!.stepStatuses);
    updatedStatuses[stepIndex.toString()] = StepExecutionStatus.skipped;

    int nextIndex = -1;
    if (seq != null) {
      for (int i = stepIndex + 1; i < seq.steps.length; i++) {
        if (seq.steps[i].isEnabled) {
          nextIndex = i;
          break;
        }
      }
    }

    if (nextIndex == -1) {
      // All steps done/skipped. Check if at least 1 was actually completed
      final completedStepCount = updatedStatuses.values
          .where((status) => status == StepExecutionStatus.completed)
          .length;

      final completedSession = _activeSession!.copyWith(
        stepStatuses: updatedStatuses,
        isCompleted: true,
        isPaused: false,
        completedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      if (seq != null && completedStepCount > 0) {
        await _service.recordCompletedSession(
          session: completedSession,
          sequence: seq,
        );
      }

      await _service.clearActiveSession();
      _activeSession = null;
      _journalEntries = await _service.loadJournalEntries();
      _streakReport = await _service.getStreakReport();
    } else {
      updatedStatuses[nextIndex.toString()] = StepExecutionStatus.inProgress;
      final updatedSession = _activeSession!.copyWith(
        currentStepIndex: nextIndex,
        stepStatuses: updatedStatuses,
        lastUpdatedAt: DateTime.now(),
      );
      _activeSession = updatedSession;
      await _service.saveActiveSession(updatedSession);
    }

    _safeNotify();
  }

  /// Wipes all local journal history and resets streak report.
  /// (Does not touch Japa or Puja histories).
  Future<void> clearJournalHistory() async {
    await _service.clearJournal();
    _journalEntries = [];
    _streakReport = const DevotionalStreakReport();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
