import 'vrat_observance.dart';

/// Categories of authentic Hindu festivals and observances.
enum FestivalCategory {
  majorFestival,
  ekadashi,
  pradosham,
  purnima,
  amavasya,
  sankashtiChaturthi,
  regionalObservance,
}

extension FestivalCategoryExtension on FestivalCategory {
  String get displayName {
    switch (this) {
      case FestivalCategory.majorFestival:
        return 'Major Festival';
      case FestivalCategory.ekadashi:
        return 'Ekadashi';
      case FestivalCategory.pradosham:
        return 'Pradosham';
      case FestivalCategory.purnima:
        return 'Purnima';
      case FestivalCategory.amavasya:
        return 'Amavasya';
      case FestivalCategory.sankashtiChaturthi:
        return 'Sankashti Chaturthi';
      case FestivalCategory.regionalObservance:
        return 'Regional Observance';
    }
  }
}

/// Strongly-typed domain model for an authentic Hindu festival or observance.
/// Every event is grounded in traditional astronomical calculations and source-backed literature.
class FestivalEvent {
  final String id;
  final String name;
  final String sanskritName;
  final FestivalCategory category;
  final String targetDate; // YYYY-MM-DD
  final String deity;
  final String masa; // Hindu lunar month
  final String paksha; // Shukla or Krishna
  final String tithi; // Tithi name
  final String? nakshatra;
  final String timingRule; // e.g., 'Udaya Tithi', 'Nishita Kala', 'Madhyahna'
  final String timingWindow; // e.g., '11:45 PM - 12:35 AM'
  final String significance;
  final String calculationConvention;
  final String sourceName;
  final String sourceReference;
  final String regionalVariations;
  final String? associatedPujaGuideId;
  final String? associatedMantraId;
  final VratType? suggestedVratType;
  final List<VratChecklistItem> suggestedChecklist;
  final bool isEstablishedFestival;

  const FestivalEvent({
    required this.id,
    required this.name,
    required this.sanskritName,
    required this.category,
    required this.targetDate,
    required this.deity,
    required this.masa,
    required this.paksha,
    required this.tithi,
    this.nakshatra,
    this.timingRule = 'Udaya Tithi (Sunrise)',
    this.timingWindow = 'All day based on prevailing Tithi',
    required this.significance,
    this.calculationConvention = 'Drik Ganita / Lahiri Ayanamsa',
    required this.sourceName,
    required this.sourceReference,
    required this.regionalVariations,
    this.associatedPujaGuideId,
    this.associatedMantraId,
    this.suggestedVratType,
    this.suggestedChecklist = const [],
    this.isEstablishedFestival = true,
  });

  FestivalEvent copyWith({
    String? id,
    String? name,
    String? sanskritName,
    FestivalCategory? category,
    String? targetDate,
    String? deity,
    String? masa,
    String? paksha,
    String? tithi,
    String? nakshatra,
    String? timingRule,
    String? timingWindow,
    String? significance,
    String? calculationConvention,
    String? sourceName,
    String? sourceReference,
    String? regionalVariations,
    String? associatedPujaGuideId,
    String? associatedMantraId,
    VratType? suggestedVratType,
    List<VratChecklistItem>? suggestedChecklist,
    bool? isEstablishedFestival,
  }) {
    return FestivalEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      sanskritName: sanskritName ?? this.sanskritName,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      deity: deity ?? this.deity,
      masa: masa ?? this.masa,
      paksha: paksha ?? this.paksha,
      tithi: tithi ?? this.tithi,
      nakshatra: nakshatra ?? this.nakshatra,
      timingRule: timingRule ?? this.timingRule,
      timingWindow: timingWindow ?? this.timingWindow,
      significance: significance ?? this.significance,
      calculationConvention: calculationConvention ?? this.calculationConvention,
      sourceName: sourceName ?? this.sourceName,
      sourceReference: sourceReference ?? this.sourceReference,
      regionalVariations: regionalVariations ?? this.regionalVariations,
      associatedPujaGuideId: associatedPujaGuideId ?? this.associatedPujaGuideId,
      associatedMantraId: associatedMantraId ?? this.associatedMantraId,
      suggestedVratType: suggestedVratType ?? this.suggestedVratType,
      suggestedChecklist: suggestedChecklist ?? this.suggestedChecklist,
      isEstablishedFestival: isEstablishedFestival ?? this.isEstablishedFestival,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sanskrit_name': sanskritName,
        'category': category.name,
        'target_date': targetDate,
        'deity': deity,
        'masa': masa,
        'paksha': paksha,
        'tithi': tithi,
        'nakshatra': nakshatra,
        'timing_rule': timingRule,
        'timing_window': timingWindow,
        'significance': significance,
        'calculation_convention': calculationConvention,
        'source_name': sourceName,
        'source_reference': sourceReference,
        'regional_variations': regionalVariations,
        'associated_puja_guide_id': associatedPujaGuideId,
        'associated_mantra_id': associatedMantraId,
        'suggested_vrat_type': suggestedVratType?.name,
        'suggested_checklist': suggestedChecklist.map((c) => c.toJson()).toList(),
        'is_established_festival': isEstablishedFestival,
      };

  factory FestivalEvent.fromJson(Map<String, dynamic> json) {
    FestivalCategory cat = FestivalCategory.majorFestival;
    for (final c in FestivalCategory.values) {
      if (c.name == json['category']) {
        cat = c;
        break;
      }
    }

    VratType? vType;
    if (json['suggested_vrat_type'] != null) {
      for (final v in VratType.values) {
        if (v.name == json['suggested_vrat_type']) {
          vType = v;
          break;
        }
      }
    }

    final rawChecklist = json['suggested_checklist'] as List<dynamic>? ?? [];
    final checklist = rawChecklist
        .map((e) => VratChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FestivalEvent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sanskritName: json['sanskrit_name'] as String? ?? '',
      category: cat,
      targetDate: json['target_date'] as String? ?? '',
      deity: json['deity'] as String? ?? '',
      masa: json['masa'] as String? ?? '',
      paksha: json['paksha'] as String? ?? '',
      tithi: json['tithi'] as String? ?? '',
      nakshatra: json['nakshatra'] as String?,
      timingRule: json['timing_rule'] as String? ?? 'Udaya Tithi (Sunrise)',
      timingWindow: json['timing_window'] as String? ?? 'All day',
      significance: json['significance'] as String? ?? '',
      calculationConvention: json['calculation_convention'] as String? ?? 'Drik Ganita',
      sourceName: json['source_name'] as String? ?? '',
      sourceReference: json['source_reference'] as String? ?? '',
      regionalVariations: json['regional_variations'] as String? ?? '',
      associatedPujaGuideId: json['associated_puja_guide_id'] as String?,
      associatedMantraId: json['associated_mantra_id'] as String?,
      suggestedVratType: vType,
      suggestedChecklist: checklist,
      isEstablishedFestival: json['is_established_festival'] as bool? ?? true,
    );
  }
}
