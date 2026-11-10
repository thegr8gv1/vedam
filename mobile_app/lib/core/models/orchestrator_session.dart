/// Execution status of an individual step in a practice session.
enum StepExecutionStatus {
  pending,
  inProgress,
  completed,
  skipped,
  unavailable;

  bool get isFinished => this == StepExecutionStatus.completed || this == StepExecutionStatus.skipped;
}

/// Represents an active or paused devotee practice session through a practice sequence.
class OrchestratorSession {
  final String sessionId;
  final String sequenceId;
  final String sequenceName;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final DateTime? completedAt;
  final int currentStepIndex;
  final Map<String, StepExecutionStatus> stepStatuses;
  final bool isPaused;
  final bool isCompleted;
  final bool isAbandoned;

  const OrchestratorSession({
    required this.sessionId,
    required this.sequenceId,
    required this.sequenceName,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.completedAt,
    this.currentStepIndex = 0,
    required this.stepStatuses,
    this.isPaused = false,
    this.isCompleted = false,
    this.isAbandoned = false,
  });

  bool get isActive => !isCompleted && !isAbandoned;

  int get completedStepsCount =>
      stepStatuses.values.where((status) => status == StepExecutionStatus.completed).length;

  int get skippedStepsCount =>
      stepStatuses.values.where((status) => status == StepExecutionStatus.skipped).length;

  OrchestratorSession copyWith({
    String? sessionId,
    String? sequenceId,
    String? sequenceName,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    DateTime? completedAt,
    int? currentStepIndex,
    Map<String, StepExecutionStatus>? stepStatuses,
    bool? isPaused,
    bool? isCompleted,
    bool? isAbandoned,
  }) {
    return OrchestratorSession(
      sessionId: sessionId ?? this.sessionId,
      sequenceId: sequenceId ?? this.sequenceId,
      sequenceName: sequenceName ?? this.sequenceName,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      completedAt: completedAt ?? this.completedAt,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      stepStatuses: stepStatuses ?? this.stepStatuses,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isAbandoned: isAbandoned ?? this.isAbandoned,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'sequence_id': sequenceId,
        'sequence_name': sequenceName,
        'started_at': startedAt.toIso8601String(),
        'last_updated_at': lastUpdatedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'current_step_index': currentStepIndex,
        'step_statuses': stepStatuses.map((k, v) => MapEntry(k, v.name)),
        'is_paused': isPaused,
        'is_completed': isCompleted,
        'is_abandoned': isAbandoned,
      };

  factory OrchestratorSession.fromJson(Map<String, dynamic> json) {
    final rawStatuses = json['step_statuses'] as Map<String, dynamic>? ?? {};
    final parsedStatuses = <String, StepExecutionStatus>{};

    rawStatuses.forEach((k, v) {
      parsedStatuses[k] = StepExecutionStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => StepExecutionStatus.pending,
      );
    });

    return OrchestratorSession(
      sessionId: json['session_id'] as String? ?? 'sess_${DateTime.now().millisecondsSinceEpoch}',
      sequenceId: json['sequence_id'] as String? ?? '',
      sequenceName: json['sequence_name'] as String? ?? 'Practice',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.tryParse(json['last_updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      currentStepIndex: json['current_step_index'] as int? ?? 0,
      stepStatuses: parsedStatuses,
      isPaused: json['is_paused'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      isAbandoned: json['is_abandoned'] as bool? ?? false,
    );
  }
}
