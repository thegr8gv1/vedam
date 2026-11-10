/// Represents a completed or concluded practice session in the private local journal.
class DevotionalJournalEntry {
  final String id;
  final String sessionId;
  final String sequenceId;
  final String sequenceName;
  final String localDate; // YYYY-MM-DD
  final DateTime completedAt;
  final int completedStepCount;
  final int totalStepCount;
  final List<String> completedStepTitles;
  final int durationMinutes;

  const DevotionalJournalEntry({
    required this.id,
    required this.sessionId,
    required this.sequenceId,
    required this.sequenceName,
    required this.localDate,
    required this.completedAt,
    required this.completedStepCount,
    required this.totalStepCount,
    this.completedStepTitles = const [],
    this.durationMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'sequence_id': sequenceId,
        'sequence_name': sequenceName,
        'local_date': localDate,
        'completed_at': completedAt.toIso8601String(),
        'completed_step_count': completedStepCount,
        'total_step_count': totalStepCount,
        'completed_step_titles': completedStepTitles,
        'duration_minutes': durationMinutes,
      };

  factory DevotionalJournalEntry.fromJson(Map<String, dynamic> json) {
    return DevotionalJournalEntry(
      id: json['id'] as String? ?? 'entry_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: json['session_id'] as String? ?? '',
      sequenceId: json['sequence_id'] as String? ?? '',
      sequenceName: json['sequence_name'] as String? ?? 'Daily Practice',
      localDate: json['local_date'] as String? ?? '',
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedStepCount: json['completed_step_count'] as int? ?? 0,
      totalStepCount: json['total_step_count'] as int? ?? 0,
      completedStepTitles: (json['completed_step_titles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }
}

/// A structured summary report of practice consistency and streaks.
class DevotionalStreakReport {
  final int currentStreak;
  final int longestStreak;
  final int totalPracticeDays;
  final DateTime? lastPracticeDate;

  const DevotionalStreakReport({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPracticeDays = 0,
    this.lastPracticeDate,
  });

  factory DevotionalStreakReport.empty() => const DevotionalStreakReport(
        currentStreak: 0,
        longestStreak: 0,
        totalPracticeDays: 0,
      );
}
