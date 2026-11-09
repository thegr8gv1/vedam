import 'sadhana_practice.dart';

/// Categories of steps within a guided devotional Sadhana practice.
enum SadhanaStepType {
  preparation,
  scriptureReading,
  japa,
  reflection;

  String get displayName {
    switch (this) {
      case SadhanaStepType.preparation:
        return 'Preparation';
      case SadhanaStepType.scriptureReading:
        return 'Scripture Reading';
      case SadhanaStepType.japa:
        return 'Japa Chanting';
      case SadhanaStepType.reflection:
        return 'Silent Reflection';
    }
  }
}

/// A discrete step within a guided devotional Sadhana flow.
class GuidedSadhanaStep {
  final String id;
  final int stepNumber;
  final String title;
  final String? sanskritTitle;
  final String description;
  final SadhanaStepType stepType;
  final String? sanskritMantra;
  final String? transliteration;
  final String? meaning;
  final String? scripturalSource;
  final String? linkedMantraId;
  final int? targetRepetitions;
  final int? estimatedMinutes;
  final List<String> materials;
  final bool isOptional;

  const GuidedSadhanaStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    this.sanskritTitle,
    required this.description,
    required this.stepType,
    this.sanskritMantra,
    this.transliteration,
    this.meaning,
    this.scripturalSource,
    this.linkedMantraId,
    this.targetRepetitions,
    this.estimatedMinutes,
    this.materials = const [],
    this.isOptional = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'step_number': stepNumber,
        'title': title,
        'sanskrit_title': sanskritTitle,
        'description': description,
        'step_type': stepType.name,
        'sanskrit_mantra': sanskritMantra,
        'transliteration': transliteration,
        'meaning': meaning,
        'scriptural_source': scripturalSource,
        'linked_mantra_id': linkedMantraId,
        'target_repetitions': targetRepetitions,
        'estimated_minutes': estimatedMinutes,
        'materials': materials,
        'is_optional': isOptional,
      };

  factory GuidedSadhanaStep.fromJson(Map<String, dynamic> json) {
    return GuidedSadhanaStep(
      id: json['id'] as String? ?? '',
      stepNumber: json['step_number'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      sanskritTitle: json['sanskrit_title'] as String?,
      description: json['description'] as String? ?? '',
      stepType: SadhanaStepType.values.firstWhere(
        (e) => e.name == json['step_type'],
        orElse: () => SadhanaStepType.preparation,
      ),
      sanskritMantra: json['sanskrit_mantra'] as String?,
      transliteration: json['transliteration'] as String?,
      meaning: json['meaning'] as String?,
      scripturalSource: json['scriptural_source'] as String?,
      linkedMantraId: json['linked_mantra_id'] as String?,
      targetRepetitions: json['target_repetitions'] as int?,
      estimatedMinutes: json['estimated_minutes'] as int?,
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }
}

/// A structured, authentic Sadhana practice plan comprising sequential steps.
class GuidedSadhanaPlan {
  final String id;
  final String title;
  final String sanskritTitle;
  final SadhanaCategory category;
  final String? deity;
  final String shortDescription;
  final String purposeAndContext;
  final int estimatedMinutes;
  final String sourceAttribution;
  final List<String> preparation;
  final List<GuidedSadhanaStep> steps;

  const GuidedSadhanaPlan({
    required this.id,
    required this.title,
    required this.sanskritTitle,
    required this.category,
    this.deity,
    required this.shortDescription,
    required this.purposeAndContext,
    required this.estimatedMinutes,
    required this.sourceAttribution,
    this.preparation = const [],
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sanskrit_title': sanskritTitle,
        'category': category.name,
        'deity': deity,
        'short_description': shortDescription,
        'purpose_and_context': purposeAndContext,
        'estimated_minutes': estimatedMinutes,
        'source_attribution': sourceAttribution,
        'preparation': preparation,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory GuidedSadhanaPlan.fromJson(Map<String, dynamic> json) {
    return GuidedSadhanaPlan(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sanskritTitle: json['sanskrit_title'] as String? ?? '',
      category: SadhanaCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SadhanaCategory.morningPrayer,
      ),
      deity: json['deity'] as String?,
      shortDescription: json['short_description'] as String? ?? '',
      purposeAndContext: json['purpose_and_context'] as String? ?? '',
      estimatedMinutes: json['estimated_minutes'] as int? ?? 15,
      sourceAttribution: json['source_attribution'] as String? ?? '',
      preparation: (json['preparation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => GuidedSadhanaStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
