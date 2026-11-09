// Strongly-typed model representing an active or completed Guided Puja session.
// Persists local session state, step completion, checklist selections,
// and Japa linkages for uninterrupted devotional practice.

enum PujaSessionStatus {
  active,
  paused,
  completed,
  abandoned,
}

class PujaSession {
  final String id;
  final String guideId;
  final DateTime startTime;
  final DateTime lastUpdatedTime;
  final int currentStepIndex;
  final List<String> completedStepIds;
  final List<String> skippedStepIds;
  final List<String> preparedMaterials;
  final PujaSessionStatus status;
  final String? linkedJapaSessionId;
  final int durationSeconds;

  const PujaSession({
    required this.id,
    required this.guideId,
    required this.startTime,
    required this.lastUpdatedTime,
    this.currentStepIndex = 0,
    this.completedStepIds = const [],
    this.skippedStepIds = const [],
    this.preparedMaterials = const [],
    this.status = PujaSessionStatus.active,
    this.linkedJapaSessionId,
    this.durationSeconds = 0,
  });

  bool get isActive => status == PujaSessionStatus.active;
  bool get isPaused => status == PujaSessionStatus.paused;
  bool get isCompleted => status == PujaSessionStatus.completed;
  bool get isAbandoned => status == PujaSessionStatus.abandoned;

  bool isStepCompleted(String stepId) => completedStepIds.contains(stepId);
  bool isStepSkipped(String stepId) => skippedStepIds.contains(stepId);
  bool isMaterialPrepared(String material) => preparedMaterials.contains(material);

  PujaSession copyWith({
    String? id,
    String? guideId,
    DateTime? startTime,
    DateTime? lastUpdatedTime,
    int? currentStepIndex,
    List<String>? completedStepIds,
    List<String>? skippedStepIds,
    List<String>? preparedMaterials,
    PujaSessionStatus? status,
    String? linkedJapaSessionId,
    int? durationSeconds,
  }) {
    return PujaSession(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      startTime: startTime ?? this.startTime,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedStepIds: completedStepIds ?? List.from(this.completedStepIds),
      skippedStepIds: skippedStepIds ?? List.from(this.skippedStepIds),
      preparedMaterials: preparedMaterials ?? List.from(this.preparedMaterials),
      status: status ?? this.status,
      linkedJapaSessionId: linkedJapaSessionId ?? this.linkedJapaSessionId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'guide_id': guideId,
        'start_time': startTime.toIso8601String(),
        'last_updated_time': lastUpdatedTime.toIso8601String(),
        'current_step_index': currentStepIndex,
        'completed_step_ids': completedStepIds,
        'skipped_step_ids': skippedStepIds,
        'prepared_materials': preparedMaterials,
        'status': status.name,
        'linked_japa_session_id': linkedJapaSessionId,
        'duration_seconds': durationSeconds,
      };

  factory PujaSession.fromJson(Map<String, dynamic> json) {
    PujaSessionStatus parsedStatus;
    try {
      parsedStatus = PujaSessionStatus.values.byName(json['status'] as String? ?? 'active');
    } catch (_) {
      parsedStatus = PujaSessionStatus.active;
    }

    return PujaSession(
      id: json['id'] as String? ?? 'puja_session_${DateTime.now().millisecondsSinceEpoch}',
      guideId: json['guide_id'] as String? ?? '',
      startTime: DateTime.tryParse(json['start_time'] as String? ?? '') ?? DateTime.now(),
      lastUpdatedTime: DateTime.tryParse(json['last_updated_time'] as String? ?? '') ?? DateTime.now(),
      currentStepIndex: json['current_step_index'] as int? ?? 0,
      completedStepIds: (json['completed_step_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skippedStepIds: (json['skipped_step_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preparedMaterials: (json['prepared_materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: parsedStatus,
      linkedJapaSessionId: json['linked_japa_session_id'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }

  static PujaSession? tryParse(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        return PujaSession.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
