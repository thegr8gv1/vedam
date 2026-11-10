/// Types of daily practice sequence (Morning, Evening, or Custom devotee sequence).
enum PracticeSequenceType {
  morning,
  evening,
  custom;

  String get displayName {
    switch (this) {
      case PracticeSequenceType.morning:
        return 'Morning Sadhana';
      case PracticeSequenceType.evening:
        return 'Evening Sadhana';
      case PracticeSequenceType.custom:
        return 'Custom Sequence';
    }
  }
}

/// Category of devotional step linking to existing Vedam features.
enum PracticeStepType {
  sankalpa,
  guidedPuja,
  japa,
  mantraAudio,
  scriptureStudy,
  vratObservance,
  personalContemplation;

  String get displayName {
    switch (this) {
      case PracticeStepType.sankalpa:
        return 'Vedic Sankalpa';
      case PracticeStepType.guidedPuja:
        return 'Guided Puja';
      case PracticeStepType.japa:
        return 'Japa Chanting';
      case PracticeStepType.mantraAudio:
        return 'Devotional Audio';
      case PracticeStepType.scriptureStudy:
        return 'Scripture Study';
      case PracticeStepType.vratObservance:
        return 'Vrat & Fasting';
      case PracticeStepType.personalContemplation:
        return 'Personal Contemplation';
    }
  }
}

/// A discrete step within a customizable devotional practice sequence.
class PracticeStep {
  final String id;
  final String title;
  final String description;
  final PracticeStepType stepType;
  final String? resourceId; // e.g. guide_ganesh_puja, VEDA-MTR-0399, etc.
  final int? targetRepetitions; // for Japa
  final int estimatedMinutes;
  final bool isEnabled;
  final bool isOptional;

  const PracticeStep({
    required this.id,
    required this.title,
    this.description = '',
    required this.stepType,
    this.resourceId,
    this.targetRepetitions,
    this.estimatedMinutes = 10,
    this.isEnabled = true,
    this.isOptional = false,
  });

  PracticeStep copyWith({
    String? id,
    String? title,
    String? description,
    PracticeStepType? stepType,
    String? resourceId,
    int? targetRepetitions,
    int? estimatedMinutes,
    bool? isEnabled,
    bool? isOptional,
  }) {
    return PracticeStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      stepType: stepType ?? this.stepType,
      resourceId: resourceId ?? this.resourceId,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      isOptional: isOptional ?? this.isOptional,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'step_type': stepType.name,
        'resource_id': resourceId,
        'target_repetitions': targetRepetitions,
        'estimated_minutes': estimatedMinutes,
        'is_enabled': isEnabled,
        'is_optional': isOptional,
      };

  factory PracticeStep.fromJson(Map<String, dynamic> json) {
    return PracticeStep(
      id: json['id'] as String? ?? 'step_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Practice Step',
      description: json['description'] as String? ?? '',
      stepType: PracticeStepType.values.firstWhere(
        (e) => e.name == json['step_type'],
        orElse: () => PracticeStepType.personalContemplation,
      ),
      resourceId: json['resource_id'] as String?,
      targetRepetitions: json['target_repetitions'] as int?,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 10,
      isEnabled: json['is_enabled'] as bool? ?? true,
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }
}

/// A structured devotional practice sequence (Morning, Evening, or Custom).
class PracticeSequence {
  final String id;
  final String name;
  final PracticeSequenceType type;
  final List<PracticeStep> steps;
  final DateTime createdAt;
  final DateTime lastModified;

  PracticeSequence({
    required this.id,
    required this.name,
    required this.type,
    required this.steps,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  int get totalEstimatedMinutes =>
      steps.where((s) => s.isEnabled).fold(0, (sum, s) => sum + s.estimatedMinutes);

  int get enabledStepCount => steps.where((s) => s.isEnabled).length;

  PracticeSequence copyWith({
    String? id,
    String? name,
    PracticeSequenceType? type,
    List<PracticeStep>? steps,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return PracticeSequence(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'last_modified': lastModified.toIso8601String(),
      };

  factory PracticeSequence.fromJson(Map<String, dynamic> json) {
    return PracticeSequence(
      id: json['id'] as String? ?? 'seq_custom',
      name: json['name'] as String? ?? 'Custom Sequence',
      type: PracticeSequenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PracticeSequenceType.custom,
      ),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => PracticeStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastModified: json['last_modified'] != null
          ? DateTime.tryParse(json['last_modified'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Default canonical Morning Sadhana sequence
  factory PracticeSequence.defaultMorning() {
    final now = DateTime.now();
    return PracticeSequence(
      id: 'seq_morning_default',
      name: 'Morning Sadhana',
      type: PracticeSequenceType.morning,
      createdAt: now,
      lastModified: now,
      steps: const [
        PracticeStep(
          id: 'step_m_sankalpa',
          title: 'Prātaḥ Sankalpa',
          description: 'Set your sacred devotional intention for the day aligned with Panchangam.',
          stepType: PracticeStepType.sankalpa,
          estimatedMinutes: 5,
          isOptional: false,
        ),
        PracticeStep(
          id: 'step_m_puja',
          title: 'Daily Ganesha Puja',
          description: 'Perform Pancha Upachara worship to Lord Ganesha for auspicious beginnings.',
          stepType: PracticeStepType.guidedPuja,
          resourceId: 'guide_ganesh_puja',
          estimatedMinutes: 10,
          isOptional: true,
        ),
        PracticeStep(
          id: 'step_m_japa',
          title: 'Gayatri Mahamantra Japa',
          description: 'Chant 108 repetitions of the sacred Gayatri Mantra for mental clarity.',
          stepType: PracticeStepType.japa,
          resourceId: 'VEDA-MTR-0399',
          targetRepetitions: 108,
          estimatedMinutes: 12,
          isOptional: false,
        ),
        PracticeStep(
          id: 'step_m_scripture',
          title: 'Scripture Study',
          description: 'Contemplate on a verse from the sacred corpus.',
          stepType: PracticeStepType.scriptureStudy,
          estimatedMinutes: 8,
          isOptional: true,
        ),
      ],
    );
  }

  /// Default canonical Evening Sadhana sequence
  factory PracticeSequence.defaultEvening() {
    final now = DateTime.now();
    return PracticeSequence(
      id: 'seq_evening_default',
      name: 'Evening Sadhana',
      type: PracticeSequenceType.evening,
      createdAt: now,
      lastModified: now,
      steps: const [
        PracticeStep(
          id: 'step_e_audio',
          title: 'Evening Chanting & Stotra',
          description: 'Listen to devotional recitation or chant evening prayers.',
          stepType: PracticeStepType.mantraAudio,
          resourceId: 'VEDA-MTR-0429',
          estimatedMinutes: 10,
          isOptional: true,
        ),
        PracticeStep(
          id: 'step_e_japa',
          title: 'Shiva / Mrityunjaya Japa',
          description: 'Meditative japa repetition for inner peace and divine grace.',
          stepType: PracticeStepType.japa,
          resourceId: 'VEDA-MTR-0429',
          targetRepetitions: 54,
          estimatedMinutes: 10,
          isOptional: false,
        ),
        PracticeStep(
          id: 'step_e_contemplation',
          title: 'Silent Gratitude & Peace',
          description: 'Sit in quiet contemplation, surrender the day’s activities, and pray for peace.',
          stepType: PracticeStepType.personalContemplation,
          estimatedMinutes: 5,
          isOptional: false,
        ),
      ],
    );
  }
}
