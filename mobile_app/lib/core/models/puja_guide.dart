// Strongly-typed models for the Vedam Guided Daily Puja experience.
// Represents liturgical guides, ordered steps, mantras, translations,
// and explicit sourcing/variance disclosures.

class PujaStep {
  final String id;
  final int stepNumber;
  final String stepName;
  final String? upacharaName;
  final String actionDescription;
  final String? sanskritMantra;
  final String? transliteration;
  final String? meaning;
  final String? scripturalSource;
  final String? stepProvenance; // 'canonical_verse', 'traditional_grihya_action', 'editorial_guidance'
  final String? linkedMantraId;
  final String? linkedMantraTitle;
  final List<String> expandedInstructions;
  final bool isOptional;
  final int? targetRepetitions;
  final String? stepType;

  const PujaStep({
    String? id,
    required this.stepNumber,
    required this.stepName,
    this.upacharaName,
    required this.actionDescription,
    this.sanskritMantra,
    this.transliteration,
    this.meaning,
    this.scripturalSource,
    this.stepProvenance,
    this.linkedMantraId,
    this.linkedMantraTitle,
    this.expandedInstructions = const [],
    this.isOptional = false,
    this.targetRepetitions,
    this.stepType,
  }) : id = id ?? 'step_$stepNumber';

  Map<String, dynamic> toJson() => {
        'id': id,
        'step_number': stepNumber,
        'step_name': stepName,
        'upachara_name': upacharaName,
        'action_description': actionDescription,
        'sanskrit_mantra': sanskritMantra,
        'transliteration': transliteration,
        'meaning': meaning,
        'scriptural_source': scripturalSource,
        'step_provenance': stepProvenance,
        'linked_mantra_id': linkedMantraId,
        'linked_mantra_title': linkedMantraTitle,
        'expanded_instructions': expandedInstructions,
        'is_optional': isOptional,
        'target_repetitions': targetRepetitions,
        'step_type': stepType,
      };

  factory PujaStep.fromJson(Map<String, dynamic> json) {
    final stepNum = json['step_number'] as int? ?? 1;
    return PujaStep(
      id: json['id'] as String? ?? 'step_$stepNum',
      stepNumber: stepNum,
      stepName: json['step_name'] as String? ?? '',
      upacharaName: json['upachara_name'] as String?,
      actionDescription: json['action_description'] as String? ?? '',
      sanskritMantra: json['sanskrit_mantra'] as String?,
      transliteration: json['transliteration'] as String?,
      meaning: json['meaning'] as String?,
      scripturalSource: json['scriptural_source'] as String?,
      stepProvenance: json['step_provenance'] as String?,
      linkedMantraId: json['linked_mantra_id'] as String?,
      linkedMantraTitle: json['linked_mantra_title'] as String?,
      expandedInstructions: (json['expanded_instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isOptional: json['is_optional'] as bool? ?? false,
      targetRepetitions: json['target_repetitions'] as int?,
      stepType: json['step_type'] as String?,
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
  final List<String> requiredMaterials;
  final List<String> optionalMaterials;
  final List<PujaStep> steps;
  final int estimatedDurationMinutes;
  final String editorialStatus;
  final String contentVerificationStatus; // Explicit provenance status
  final List<String> primarySourceReferences;
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
    List<String>? requiredMaterials,
    this.optionalMaterials = const [],
    required this.steps,
    this.estimatedDurationMinutes = 10,
    this.editorialStatus = 'Verified Editorial Guide',
    this.contentVerificationStatus = 'Curated Traditional Grihya Paddhati',
    this.primarySourceReferences = const [],
    required this.sourceInfo,
    required this.regionalVarianceNote,
    required this.lastReviewedDate,
  }) : requiredMaterials = requiredMaterials ?? materialsList;

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
        'required_materials': requiredMaterials,
        'optional_materials': optionalMaterials,
        'steps': steps.map((s) => s.toJson()).toList(),
        'estimated_duration_minutes': estimatedDurationMinutes,
        'editorial_status': editorialStatus,
        'content_verification_status': contentVerificationStatus,
        'primary_source_references': primarySourceReferences,
        'source_info': sourceInfo,
        'regional_variance_note': regionalVarianceNote,
        'last_reviewed_date': lastReviewedDate,
      };

  factory PujaGuide.fromJson(Map<String, dynamic> json) {
    final matList = (json['materials_list'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final reqMat = (json['required_materials'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        matList;
    final optMat = (json['optional_materials'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

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
      materialsList: matList,
      requiredMaterials: reqMat,
      optionalMaterials: optMat,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => PujaStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 10,
      editorialStatus: json['editorial_status'] as String? ?? 'Verified Editorial Guide',
      contentVerificationStatus: json['content_verification_status'] as String? ?? 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: (json['primary_source_references'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourceInfo: json['source_info'] as String? ?? '',
      regionalVarianceNote: json['regional_variance_note'] as String? ?? '',
      lastReviewedDate: json['last_reviewed_date'] as String? ?? '',
    );
  }
}
