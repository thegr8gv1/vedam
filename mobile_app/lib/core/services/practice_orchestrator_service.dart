import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/devotional_journal_entry.dart';
import '../models/orchestrator_session.dart';
import '../models/panchangam_data.dart';
import '../models/practice_sequence.dart';

/// Contextual, non-mandatory daily devotional practice suggestion based on verified calendar facts.
class PanchangamRecommendation {
  final String title;
  final String description;
  final String? suggestedResourceId;
  final PracticeStepType? suggestedStepType;
  final bool isLive;

  const PanchangamRecommendation({
    required this.title,
    required this.description,
    this.suggestedResourceId,
    this.suggestedStepType,
    required this.isLive,
  });

  bool get isOfflineFallback => !isLive;
  String get reasoning => description;
  String get suggestedPractice =>
      suggestedStepType == PracticeStepType.sankalpa ? 'Vedic Sankalpa' : 'Daily Devotion';
}

/// Core persistence and orchestration service for the Nitya Sadhana Flow.
///
/// Features:
/// 1. Sequence management (Morning, Evening, Custom sequences).
/// 2. Active session state tracking and resumability.
/// 3. Private, local-only journal of completed practices.
/// 4. Pure, timezone-safe streak and practice-day calculation.
/// 5. Conservative, provenance-aware contextual suggestions.
class PracticeOrchestratorService {
  static const String keySequences = 'vedam_orchestrator_sequences_v1';
  static const String keyActiveSession = 'vedam_orchestrator_active_session_v1';
  static const String keyJournal = 'vedam_orchestrator_journal_v1';
  static const String keyDismissedRecommendation = 'vedam_orchestrator_dismissed_rec_date';

  final SharedPreferences? _injectedPrefs;

  PracticeOrchestratorService({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _injectedPrefs ?? await SharedPreferences.getInstance();
  }

  // --- Sequences CRUD ---

  Future<List<PracticeSequence>> loadSequences() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(keySequences);
    if (raw == null || raw.trim().isEmpty) {
      final defaults = [
        PracticeSequence.defaultMorning(),
        PracticeSequence.defaultEvening(),
      ];
      await saveAllSequences(defaults);
      return defaults;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final sequences = list
          .map((e) => PracticeSequence.fromJson(e as Map<String, dynamic>))
          .toList();
      if (sequences.isEmpty) {
        final defaults = [
          PracticeSequence.defaultMorning(),
          PracticeSequence.defaultEvening(),
        ];
        await saveAllSequences(defaults);
        return defaults;
      }
      return sequences;
    } catch (_) {
      // Corruption resilience: restore default sequences on parse error
      final defaults = [
        PracticeSequence.defaultMorning(),
        PracticeSequence.defaultEvening(),
      ];
      await saveAllSequences(defaults);
      return defaults;
    }
  }

  Future<void> saveAllSequences(List<PracticeSequence> sequences) async {
    final prefs = await _getPrefs();
    final raw = jsonEncode(sequences.map((s) => s.toJson()).toList());
    await prefs.setString(keySequences, raw);
  }

  Future<void> saveSequence(PracticeSequence sequence) async {
    final sequences = await loadSequences();
    final idx = sequences.indexWhere((s) => s.id == sequence.id);
    if (idx >= 0) {
      sequences[idx] = sequence.copyWith(lastModified: DateTime.now());
    } else {
      sequences.add(sequence);
    }
    await saveAllSequences(sequences);
  }

  Future<void> deleteSequence(String sequenceId) async {
    final sequences = await loadSequences();
    sequences.removeWhere((s) => s.id == sequenceId);
    await saveAllSequences(sequences);
  }

  Future<void> reorderSteps(String sequenceId, int oldIndex, int newIndex) async {
    final sequences = await loadSequences();
    final seqIdx = sequences.indexWhere((s) => s.id == sequenceId);
    if (seqIdx < 0) return;

    final seq = sequences[seqIdx];
    final steps = List<PracticeStep>.from(seq.steps);

    if (oldIndex < 0 || oldIndex >= steps.length) return;
    if (newIndex < 0 || newIndex > steps.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = steps.removeAt(oldIndex);
    steps.insert(newIndex, item);

    sequences[seqIdx] = seq.copyWith(steps: steps, lastModified: DateTime.now());
    await saveAllSequences(sequences);
  }

  // --- Active Session Management ---

  Future<OrchestratorSession?> loadActiveSession() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(keyActiveSession);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = OrchestratorSession.fromJson(json);
      if (session.isCompleted || session.isAbandoned) {
        await clearActiveSession();
        return null;
      }
      return session;
    } catch (_) {
      await clearActiveSession();
      return null;
    }
  }

  Future<void> saveActiveSession(OrchestratorSession session) async {
    final prefs = await _getPrefs();
    final raw = jsonEncode(session.toJson());
    await prefs.setString(keyActiveSession, raw);
  }

  Future<void> clearActiveSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyActiveSession);
  }

  // --- Private Journal & History ---

  Future<List<DevotionalJournalEntry>> loadJournalEntries() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(keyJournal);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => DevotionalJournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> recordCompletedSession({
    required OrchestratorSession session,
    required PracticeSequence sequence,
  }) async {
    // Only record if at least one step was legitimately completed
    if (session.completedStepsCount < 1) return;

    final entries = await loadJournalEntries();

    // Prevent duplicate entries for the same sessionId
    if (entries.any((e) => e.sessionId == session.sessionId)) return;

    final completedTitles = <String>[];
    for (int i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      if (session.stepStatuses[i.toString()] == StepExecutionStatus.completed ||
          session.stepStatuses[step.id] == StepExecutionStatus.completed) {
        completedTitles.add(step.title);
      }
    }

    final localDate = _formatLocalDate(session.completedAt ?? DateTime.now());
    final duration = (session.completedAt ?? DateTime.now())
        .difference(session.startedAt)
        .inMinutes;

    final entry = DevotionalJournalEntry(
      id: 'journal_${session.sessionId}',
      sessionId: session.sessionId,
      sequenceId: session.sequenceId,
      sequenceName: session.sequenceName,
      localDate: localDate,
      completedAt: session.completedAt ?? DateTime.now(),
      completedStepCount: session.completedStepsCount,
      totalStepCount: sequence.steps.length,
      completedStepTitles: completedTitles,
      durationMinutes: duration > 0 ? duration : 1,
    );

    entries.insert(0, entry);
    final prefs = await _getPrefs();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(keyJournal, raw);
  }

  Future<void> clearJournal() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyJournal);
  }

  Future<DevotionalStreakReport> getStreakReport({DateTime? now}) async {
    final entries = await loadJournalEntries();
    return calculateStreak(entries, referenceNow: now);
  }

  Future<void> resetToDefaultSequences() async {
    final prefs = await _getPrefs();
    await prefs.remove(keySequences);
    await loadSequences();
  }

  // --- Pure Streak & Habit Calculation Engine ---

  DevotionalStreakReport calculateStreak(
    List<DevotionalJournalEntry> entries, {
    DateTime? referenceNow,
    DateTime? now,
  }) {
    if (entries.isEmpty) return DevotionalStreakReport.empty();

    final ref = now ?? referenceNow ?? DateTime.now();

    // Extract unique local dates where at least one step was completed
    final uniqueDatesSet = <String>{};
    for (final e in entries) {
      if (e.completedStepCount >= 1 && e.localDate.isNotEmpty) {
        uniqueDatesSet.add(e.localDate);
      }
    }

    if (uniqueDatesSet.isEmpty) return DevotionalStreakReport.empty();

    final dateObjs = uniqueDatesSet
        .map((str) => _parseLocalDate(str))
        .where((d) => d != null)
        .map((d) => d!)
        .toList();

    dateObjs.sort();

    final totalPracticeDays = dateObjs.length;
    final lastPracticeDate = dateObjs.last;

    // Calculate longest consecutive streak using UTC calendar space
    int longest = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (final d in dateObjs) {
      if (prevDate == null) {
        currentRun = 1;
      } else {
        final diff = d.difference(prevDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1;
        }
      }
      if (currentRun > longest) {
        longest = currentRun;
      }
      prevDate = d;
    }

    // Calculate current streak relative to referenceNow (today) in UTC calendar space
    final today = DateTime.utc(ref.year, ref.month, ref.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int current = 0;
    final lastDateNormalized =
        DateTime.utc(lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);

    // Active streak requires practice today or yesterday
    if (lastDateNormalized == today || lastDateNormalized == yesterday) {
      current = 1;
      DateTime targetPrev = lastDateNormalized.subtract(const Duration(days: 1));

      for (int i = dateObjs.length - 2; i >= 0; i--) {
        final d = dateObjs[i];
        final dNorm = DateTime.utc(d.year, d.month, d.day);
        if (dNorm == targetPrev) {
          current++;
          targetPrev = targetPrev.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return DevotionalStreakReport(
      currentStreak: current,
      longestStreak: longest,
      totalPracticeDays: totalPracticeDays,
      lastPracticeDate:
          DateTime(lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day),
    );
  }

  // --- Conservative Panchangam Recommendations ---

  Future<PanchangamRecommendation?> getRecommendation({
    DailyPanchangamData? panchangam,
    DateTime? referenceNow,
  }) async {
    final prefs = await _getPrefs();
    final now = referenceNow ?? DateTime.now();
    final todayKey = _formatLocalDate(now);

    final dismissedDate = prefs.getString(keyDismissedRecommendation);
    if (dismissedDate == todayKey) {
      return null;
    }

    // If live panchangam data is present and has documented observances, surface it
    if (panchangam != null && panchangam.observances.isNotEmpty) {
      final validObservances =
          panchangam.observances.where((o) => o.name.trim().isNotEmpty).toList();
      if (validObservances.isNotEmpty) {
        final obs = validObservances.first;
        return PanchangamRecommendation(
          title: 'Today’s Observance: ${obs.name}',
          description: obs.description.trim().isNotEmpty
              ? obs.description
              : 'Consider aligning your Sankalpa and daily prayer with today’s sacred observance.',
          suggestedStepType: PracticeStepType.sankalpa,
          isLive: true,
        );
      }
    }

    // Transparent fallback when panchangam is approximate or offline
    final isLive = panchangam != null;
    final varaName =
        (panchangam?.vara.name != null && panchangam!.vara.name.trim().isNotEmpty)
            ? panchangam.vara.name
            : _weekdayName(now.weekday);

    return PanchangamRecommendation(
      title: 'Daily Practice • $varaName',
      description: isLive
          ? 'Begin your morning or evening contemplation aligned with today’s astronomical coordinates.'
          : 'Panchangam is currently offline (approximate coordinates). Begin your daily practice with calm presence.',
      suggestedStepType: PracticeStepType.sankalpa,
      isLive: isLive,
    );
  }

  Future<void> dismissRecommendation({DateTime? referenceNow}) async {
    await dismissRecommendationForToday(referenceNow: referenceNow);
  }

  Future<void> dismissRecommendationForToday({DateTime? referenceNow}) async {
    final prefs = await _getPrefs();
    final now = referenceNow ?? DateTime.now();
    await prefs.setString(keyDismissedRecommendation, _formatLocalDate(now));
  }

  // --- Date Helpers ---

  String _formatLocalDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseLocalDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Somavara (Monday)';
      case DateTime.tuesday:
        return 'Mangalavara (Tuesday)';
      case DateTime.wednesday:
        return 'Budhavara (Wednesday)';
      case DateTime.thursday:
        return 'Guruvara (Thursday)';
      case DateTime.friday:
        return 'Shukravara (Friday)';
      case DateTime.saturday:
        return 'Shanivara (Saturday)';
      case DateTime.sunday:
        return 'Ravivara (Sunday)';
      default:
        return 'Today';
    }
  }
}
