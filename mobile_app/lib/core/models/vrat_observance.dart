// Strongly-typed domain models for Vedam Personal Vrat and Observance Tracking.
// Devotees can plan, customize, and track their own religious observances
// with transparent calendar conventions and respectful non-authoritative notices.

enum VratType {
  ekadashi,
  pradosham,
  purnima,
  amavasya,
  sankashtiChaturthi,
  monthlyShivaratri,
  navaratri,
  custom,
}

enum ObservanceStatus {
  planned,
  inProgress,
  completed,
  skipped,
  cancelled,
}

enum CalendarConvention {
  amanta, // Month ends on Amavasya (common in South and Western India)
  purnimanta, // Month ends on Purnima (common in North India)
  solarDrik, // Solar astronomical calculations (Tamil, Bengali, Malayalam, etc.)
  traditionalRegional,
  custom,
}

class VratChecklistItem {
  final String id;
  final String title;
  final bool isDone;
  final String category; // 'preparation', 'ritual', 'fasting', 'contemplation'

  const VratChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.category = 'preparation',
  });

  VratChecklistItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? category,
  }) {
    return VratChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_done': isDone,
        'category': category,
      };

  factory VratChecklistItem.fromJson(Map<String, dynamic> json) {
    return VratChecklistItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isDone: json['is_done'] as bool? ?? false,
      category: json['category'] as String? ?? 'preparation',
    );
  }
}

class VratPanchangamSnapshot {
  final String tithiName;
  final String paksha;
  final String? nakshatraName;
  final String? transitionTime;
  final String calendarConvention;
  final String calculationSource;
  final String informationalNotice;

  const VratPanchangamSnapshot({
    required this.tithiName,
    required this.paksha,
    this.nakshatraName,
    this.transitionTime,
    required this.calendarConvention,
    this.calculationSource = 'Live Astronomical Panchangam Engine',
    this.informationalNotice =
        'Informational calculation only. Fasting rules, Arunodaya Tithi, and Parana times differ by sampradaya and regional lineage.',
  });

  Map<String, dynamic> toJson() => {
        'tithi_name': tithiName,
        'paksha': paksha,
        'nakshatra_name': nakshatraName,
        'transition_time': transitionTime,
        'calendar_convention': calendarConvention,
        'calculation_source': calculationSource,
        'informational_notice': informationalNotice,
      };

  factory VratPanchangamSnapshot.fromJson(Map<String, dynamic> json) {
    return VratPanchangamSnapshot(
      tithiName: json['tithi_name'] as String? ?? '',
      paksha: json['paksha'] as String? ?? '',
      nakshatraName: json['nakshatra_name'] as String?,
      transitionTime: json['transition_time'] as String?,
      calendarConvention: json['calendar_convention'] as String? ?? 'Drik Ganita',
      calculationSource: json['calculation_source'] as String? ?? 'Astronomical Panchangam Engine',
      informationalNotice: json['informational_notice'] as String? ??
          'Informational calculation only. Fasting rules differ by sampradaya.',
    );
  }
}

class VratObservance {
  final String id;
  final VratType type;
  final String title;
  final String sanskritTitle;
  final String targetDate; // YYYY-MM-DD
  final String location;
  final String tradition;
  final CalendarConvention calendarConvention;
  final ObservanceStatus status;
  final String personalIntention;
  final String personalNotes;
  final String? associatedPujaGuideId;
  final String? associatedMantraId;
  final List<VratChecklistItem> checklist;
  final VratPanchangamSnapshot? panchangamSnapshot;
  final String createdAt;
  final String? completedAt;
  final bool isManuallyCreated;
  final String? sourceAttribution;
  final String fastingNotice;
  final String? timingNotes;

  const VratObservance({
    required this.id,
    required this.type,
    required this.title,
    required this.sanskritTitle,
    required this.targetDate,
    required this.location,
    required this.tradition,
    this.calendarConvention = CalendarConvention.traditionalRegional,
    this.status = ObservanceStatus.planned,
    this.personalIntention = '',
    this.personalNotes = '',
    this.associatedPujaGuideId,
    this.associatedMantraId,
    this.checklist = const [],
    this.panchangamSnapshot,
    required this.createdAt,
    this.completedAt,
    this.isManuallyCreated = false,
    this.sourceAttribution,
    this.fastingNotice =
        'Fasting and dietary restrictions are traditional options. Devotees managing health conditions, taking medication, elderly devotees, pregnant individuals, and children should prioritize nourishment and health. Observance is fulfilled through devotion and right action (Dharma), not bodily affliction.',
    this.timingNotes,
  });

  VratObservance copyWith({
    String? id,
    VratType? type,
    String? title,
    String? sanskritTitle,
    String? targetDate,
    String? location,
    String? tradition,
    CalendarConvention? calendarConvention,
    ObservanceStatus? status,
    String? personalIntention,
    String? personalNotes,
    String? associatedPujaGuideId,
    String? associatedMantraId,
    List<VratChecklistItem>? checklist,
    VratPanchangamSnapshot? panchangamSnapshot,
    String? createdAt,
    String? completedAt,
    bool? isManuallyCreated,
    String? sourceAttribution,
    String? fastingNotice,
    String? timingNotes,
  }) {
    return VratObservance(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      sanskritTitle: sanskritTitle ?? this.sanskritTitle,
      targetDate: targetDate ?? this.targetDate,
      location: location ?? this.location,
      tradition: tradition ?? this.tradition,
      calendarConvention: calendarConvention ?? this.calendarConvention,
      status: status ?? this.status,
      personalIntention: personalIntention ?? this.personalIntention,
      personalNotes: personalNotes ?? this.personalNotes,
      associatedPujaGuideId: associatedPujaGuideId ?? this.associatedPujaGuideId,
      associatedMantraId: associatedMantraId ?? this.associatedMantraId,
      checklist: checklist ?? this.checklist,
      panchangamSnapshot: panchangamSnapshot ?? this.panchangamSnapshot,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isManuallyCreated: isManuallyCreated ?? this.isManuallyCreated,
      sourceAttribution: sourceAttribution ?? this.sourceAttribution,
      fastingNotice: fastingNotice ?? this.fastingNotice,
      timingNotes: timingNotes ?? this.timingNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'sanskrit_title': sanskritTitle,
        'target_date': targetDate,
        'location': location,
        'tradition': tradition,
        'calendar_convention': calendarConvention.name,
        'status': status.name,
        'personal_intention': personalIntention,
        'personal_notes': personalNotes,
        'associated_puja_guide_id': associatedPujaGuideId,
        'associated_mantra_id': associatedMantraId,
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'panchangam_snapshot': panchangamSnapshot?.toJson(),
        'created_at': createdAt,
        'completed_at': completedAt,
        'is_manually_created': isManuallyCreated,
        'source_attribution': sourceAttribution,
        'fasting_notice': fastingNotice,
        'timing_notes': timingNotes,
      };

  factory VratObservance.fromJson(Map<String, dynamic> json) {
    VratType parseType(String? name) {
      for (final t in VratType.values) {
        if (t.name == name) return t;
      }
      return VratType.custom;
    }

    ObservanceStatus parseStatus(String? name) {
      for (final s in ObservanceStatus.values) {
        if (s.name == name) return s;
      }
      return ObservanceStatus.planned;
    }

    CalendarConvention parseConvention(String? name) {
      for (final c in CalendarConvention.values) {
        if (c.name == name) return c;
      }
      return CalendarConvention.traditionalRegional;
    }

    return VratObservance(
      id: json['id'] as String,
      type: parseType(json['type'] as String?),
      title: json['title'] as String? ?? 'Personal Observance',
      sanskritTitle: json['sanskrit_title'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      location: json['location'] as String? ?? '',
      tradition: json['tradition'] as String? ?? 'General Devotional',
      calendarConvention: parseConvention(json['calendar_convention'] as String?),
      status: parseStatus(json['status'] as String?),
      personalIntention: json['personal_intention'] as String? ?? '',
      personalNotes: json['personal_notes'] as String? ?? '',
      associatedPujaGuideId: json['associated_puja_guide_id'] as String?,
      associatedMantraId: json['associated_mantra_id'] as String?,
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => VratChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      panchangamSnapshot: json['panchangam_snapshot'] != null
          ? VratPanchangamSnapshot.fromJson(json['panchangam_snapshot'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      isManuallyCreated: json['is_manually_created'] as bool? ?? false,
      sourceAttribution: json['source_attribution'] as String?,
      fastingNotice: json['fasting_notice'] as String? ??
          'Fasting and dietary restrictions are traditional options. Devotees managing health conditions, taking medication, elderly devotees, pregnant individuals, and children should prioritize nourishment and health. Observance is fulfilled through devotion and right action (Dharma), not bodily affliction.',
      timingNotes: json['timing_notes'] as String?,
    );
  }
}
