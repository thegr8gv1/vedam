/// Status of a guided devotional Sadhana practice session.
enum SadhanaSessionStatus {
  active,
  paused,
  completed,
  abandoned;

  String get displayName {
    switch (this) {
      case SadhanaSessionStatus.active:
        return 'Active';
      case SadhanaSessionStatus.paused:
        return 'Paused';
      case SadhanaSessionStatus.completed:
        return 'Completed';
      case SadhanaSessionStatus.abandoned:
        return 'Concluded Early';
    }
  }
}

/// Persistent, immutable record of an active, paused, or finished guided Sadhana session.
class GuidedSadhanaSession {
  final String id;
  final String sadhanaId;
  final String sadhanaTitle;
  final DateTime startTime;
  final DateTime lastUpdatedTime;
  final int currentStepIndex;
  final List<String> completedStepIds;
  final List<String> skippedStepIds;
  final SadhanaSessionStatus status;
  final String? japaSessionId;
  final int durationSeconds;

  const GuidedSadhanaSession({
    required this.id,
    required this.sadhanaId,
    required this.sadhanaTitle,
    required this.startTime,
    required this.lastUpdatedTime,
    this.currentStepIndex = 0,
    this.completedStepIds = const [],
    this.skippedStepIds = const [],
    this.status = SadhanaSessionStatus.active,
    this.japaSessionId,
    this.durationSeconds = 0,
  });

  bool get isActive => status == SadhanaSessionStatus.active;
  bool get isPaused => status == SadhanaSessionStatus.paused;
  bool get isCompleted => status == SadhanaSessionStatus.completed;
  bool get isAbandoned => status == SadhanaSessionStatus.abandoned;

  Duration get duration => Duration(seconds: durationSeconds);

  GuidedSadhanaSession copyWith({
    String? id,
    String? sadhanaId,
    String? sadhanaTitle,
    DateTime? startTime,
    DateTime? lastUpdatedTime,
    int? currentStepIndex,
    List<String>? completedStepIds,
    List<String>? skippedStepIds,
    SadhanaSessionStatus? status,
    String? japaSessionId,
    int? durationSeconds,
  }) {
    return GuidedSadhanaSession(
      id: id ?? this.id,
      sadhanaId: sadhanaId ?? this.sadhanaId,
      sadhanaTitle: sadhanaTitle ?? this.sadhanaTitle,
      startTime: startTime ?? this.startTime,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      skippedStepIds: skippedStepIds ?? this.skippedStepIds,
      status: status ?? this.status,
      japaSessionId: japaSessionId ?? this.japaSessionId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sadhana_id': sadhanaId,
        'sadhana_title': sadhanaTitle,
        'start_time': startTime.toIso8601String(),
        'last_updated_time': lastUpdatedTime.toIso8601String(),
        'current_step_index': currentStepIndex,
        'completed_step_ids': completedStepIds,
        'skipped_step_ids': skippedStepIds,
        'status': status.name,
        'japa_session_id': japaSessionId,
        'duration_seconds': durationSeconds,
      };

  factory GuidedSadhanaSession.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return GuidedSadhanaSession(
      id: json['id'] as String? ?? 'sadhana-session-fallback',
      sadhanaId: json['sadhana_id'] as String? ?? 'sadhana_default',
      sadhanaTitle: json['sadhana_title'] as String? ?? 'Daily Sadhana',
      startTime: parseDate(json['start_time']),
      lastUpdatedTime: parseDate(json['last_updated_time']),
      currentStepIndex: json['current_step_index'] as int? ?? 0,
      completedStepIds: (json['completed_step_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skippedStepIds: (json['skipped_step_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: SadhanaSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SadhanaSessionStatus.active,
      ),
      japaSessionId: json['japa_session_id'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }
}
