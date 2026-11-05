// Strongly-typed models for the Vedam Guided Daily Puja experience.
// Represents liturgical guides, ordered steps, mantras, translations,
// and explicit sourcing/variance disclosures.

class PujaStep {
  final int stepNumber;
  final String stepName;
  final String? upacharaName;
  final String actionDescription;
  final String? sanskritMantra;
  final String? transliteration;
  final String? meaning;
  final String? linkedMantraId;
  final String? linkedMantraTitle;
  final List<String> expandedInstructions;

  const PujaStep({
    required this.stepNumber,
    required this.stepName,
    this.upacharaName,
    required this.actionDescription,
    this.sanskritMantra,
    this.transliteration,
    this.meaning,
    this.linkedMantraId,
    this.linkedMantraTitle,
    this.expandedInstructions = const [],
  });

  Map<String, dynamic> toJson() => {
        'step_number': stepNumber,
        'step_name': stepName,
        'upachara_name': upacharaName,
        'action_description': actionDescription,
        'sanskrit_mantra': sanskritMantra,
        'transliteration': transliteration,
        'meaning': meaning,
        'linked_mantra_id': linkedMantraId,
        'linked_mantra_title': linkedMantraTitle,
        'expanded_instructions': expandedInstructions,
      };

  factory PujaStep.fromJson(Map<String, dynamic> json) {
    return PujaStep(
      stepNumber: json['step_number'] as int? ?? 1,
      stepName: json['step_name'] as String? ?? '',
      upacharaName: json['upachara_name'] as String?,
      actionDescription: json['action_description'] as String? ?? '',
      sanskritMantra: json['sanskrit_mantra'] as String?,
      transliteration: json['transliteration'] as String?,
      meaning: json['meaning'] as String?,
      linkedMantraId: json['linked_mantra_id'] as String?,
      linkedMantraTitle: json['linked_mantra_title'] as String?,
      expandedInstructions: (json['expanded_instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class PujaGuide {
  final String id;
  final String title;
  final String sanskritTitle;
  final String deity;
  final String tradition;
  final String shortIntro;
  final String purposeAndContext;
  final List<String> preparation;
  final List<String> materialsList;
  final List<PujaStep> steps;
  final int estimatedDurationMinutes;
  final String editorialStatus;
  final String sourceInfo;
  final String regionalVarianceNote;
  final String lastReviewedDate;

  const PujaGuide({
    required this.id,
    required this.title,
    required this.sanskritTitle,
    required this.deity,
    required this.tradition,
    required this.shortIntro,
    required this.purposeAndContext,
    required this.preparation,
    required this.materialsList,
    required this.steps,
    this.estimatedDurationMinutes = 10,
    this.editorialStatus = 'Verified Editorial Guide',
    required this.sourceInfo,
    required this.regionalVarianceNote,
    required this.lastReviewedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sanskrit_title': sanskritTitle,
        'deity': deity,
        'tradition': tradition,
        'short_intro': shortIntro,
        'purpose_and_context': purposeAndContext,
        'preparation': preparation,
        'materials_list': materialsList,
        'steps': steps.map((s) => s.toJson()).toList(),
        'estimated_duration_minutes': estimatedDurationMinutes,
        'editorial_status': editorialStatus,
        'source_info': sourceInfo,
        'regional_variance_note': regionalVarianceNote,
        'last_reviewed_date': lastReviewedDate,
      };

  factory PujaGuide.fromJson(Map<String, dynamic> json) {
    return PujaGuide(
      id: json['id'] as String,
      title: json['title'] as String,
      sanskritTitle: json['sanskrit_title'] as String? ?? '',
      deity: json['deity'] as String? ?? 'General',
      tradition: json['tradition'] as String? ?? 'Pancha Upachara',
      shortIntro: json['short_intro'] as String? ?? '',
      purposeAndContext: json['purpose_and_context'] as String? ?? '',
      preparation: (json['preparation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      materialsList: (json['materials_list'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => PujaStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 10,
      editorialStatus: json['editorial_status'] as String? ?? 'Verified Editorial Guide',
      sourceInfo: json['source_info'] as String? ?? '',
      regionalVarianceNote: json['regional_variance_note'] as String? ?? '',
      lastReviewedDate: json['last_reviewed_date'] as String? ?? '',
    );
  }
}
