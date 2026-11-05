import 'package:flutter/material.dart';
import 'panchangam_data.dart';
import 'verse.dart';

/// Authentic Hindu Devotional Deity / Practice Focus representation.
class DevotionalDeity {
  final String id;
  final String name;
  final String sanskritName;
  final String description;
  final IconData icon;
  final int? primaryScriptureId;
  final String? primaryPujaId;
  final String? primaryMantraId;

  const DevotionalDeity({
    required this.id,
    required this.name,
    required this.sanskritName,
    required this.description,
    required this.icon,
    this.primaryScriptureId,
    this.primaryPujaId,
    this.primaryMantraId,
  });

  /// The 10 authentic devotional interest options specified by Vedam tradition.
  static const List<DevotionalDeity> allDeities = [
    DevotionalDeity(
      id: 'ganesha',
      name: 'Lord Ganesha',
      sanskritName: 'श्री गणेश',
      description: 'Vighnaharta, wisdom, auspicious beginnings, and remover of obstacles.',
      icon: Icons.filter_vintage,
      primaryScriptureId: 1, // Ganesha Pancharatnam
      primaryPujaId: 'guide_ganesh_puja',
      primaryMantraId: 'VEDA-MTR-0454',
    ),
    DevotionalDeity(
      id: 'shiva',
      name: 'Lord Shiva',
      sanskritName: 'श्री शिव',
      description: 'Mahadeva, inner stillness, ascetic contemplation, and infinite grace.',
      icon: Icons.brightness_low,
      primaryScriptureId: 2, // Shiva Tandava Stotram
      primaryPujaId: 'guide_shiva_puja',
      primaryMantraId: 'VEDA-MTR-0429',
    ),
    DevotionalDeity(
      id: 'vishnu',
      name: 'Lord Vishnu',
      sanskritName: 'श्री विष्णु',
      description: 'Narayana, cosmic preservation, dharma, righteousness, and pure bhakti.',
      icon: Icons.spa,
      primaryScriptureId: 4, // Madhurashtakam
      primaryPujaId: 'guide_vishnu_puja',
      primaryMantraId: 'VEDA-MTR-0442',
    ),
    DevotionalDeity(
      id: 'venkateswara',
      name: 'Lord Venkateswara',
      sanskritName: 'श्री वेङ्कटेश्वर',
      description: 'Balaji of Tirumala, refuge in Kali Yuga, compassion, and divine protection.',
      icon: Icons.temple_hindu,
      primaryScriptureId: 4,
      primaryMantraId: 'VEDA-MTR-0450',
    ),
    DevotionalDeity(
      id: 'lakshmi',
      name: 'Goddess Lakshmi',
      sanskritName: 'श्री महालक्ष्मी',
      description: 'Mother of the universe, spiritual and material abundance, inner radiance, and purity.',
      icon: Icons.star,
      primaryScriptureId: 7, // Sri Suktam
      primaryPujaId: 'guide_lakshmi_puja',
      primaryMantraId: 'VEDA-MTR-0437',
    ),
    DevotionalDeity(
      id: 'durga',
      name: 'Goddess Durga',
      sanskritName: 'श्री दुर्गा',
      description: 'Divine Mother Bhavani, supreme courage, protection, and destruction of adharma.',
      icon: Icons.shield_outlined,
      primaryMantraId: 'VEDA-MTR-0433',
    ),
    DevotionalDeity(
      id: 'surya',
      name: 'Lord Surya',
      sanskritName: 'श्री सूर्य नारायण',
      description: 'Solar vitality, Gayatri illumination, pratyaksha devata, and radiant intellect.',
      icon: Icons.wb_sunny_outlined,
      primaryScriptureId: 3, // Aditya Hrudayam
      primaryPujaId: 'guide_morning_prayer',
      primaryMantraId: 'VEDA-MTR-0399',
    ),
    DevotionalDeity(
      id: 'hanuman',
      name: 'Lord Hanuman',
      sanskritName: 'श्री हनुमान',
      description: 'Param Bhakta, selfless service, physical vigor, spiritual courage, and devotion.',
      icon: Icons.bolt_outlined,
      primaryScriptureId: 8, // Hanuman Chalisa
      primaryPujaId: 'guide_hanuman_puja',
      primaryMantraId: 'VEDA-MTR-0447',
    ),
    DevotionalDeity(
      id: 'subrahmanya',
      name: 'Lord Subrahmanya',
      sanskritName: 'श्री सुब्रह्मण्य / मुरुगन्',
      description: 'Kartikeya, commander of celestial virtues, wisdom, and victory over ignorance.',
      icon: Icons.military_tech_outlined,
      primaryMantraId: 'VEDA-MTR-0448',
    ),
    DevotionalDeity(
      id: 'general',
      name: 'Universal / General Practice',
      sanskritName: 'सर्वदेव वन्दना',
      description: 'Upanishadic philosophy, universal Vedic sadhana, and non-sectarian contemplation.',
      icon: Icons.auto_stories_outlined,
      primaryScriptureId: 6, // Gayatri Vedic Mantra
      primaryPujaId: 'guide_morning_prayer',
      primaryMantraId: 'VEDA-MTR-0399',
    ),
  ];

  static DevotionalDeity? getById(String id) {
    try {
      return allDeities.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Devotee Daily Sadhana practice targets.
class DailySadhanaGoals {
  final bool hasJapaGoal;
  final int japaTarget;
  final bool hasScriptureGoal;
  final int scriptureMinutes;
  final bool hasPujaGoal;
  final bool hasMeditationGoal;
  final int meditationMinutes;
  final bool hasVratGoal;

  const DailySadhanaGoals({
    this.hasJapaGoal = true,
    this.japaTarget = 108,
    this.hasScriptureGoal = true,
    this.scriptureMinutes = 15,
    this.hasPujaGoal = true,
    this.hasMeditationGoal = false,
    this.meditationMinutes = 10,
    this.hasVratGoal = true,
  });

  DailySadhanaGoals copyWith({
    bool? hasJapaGoal,
    int? japaTarget,
    bool? hasScriptureGoal,
    int? scriptureMinutes,
    bool? hasPujaGoal,
    bool? hasMeditationGoal,
    int? meditationMinutes,
    bool? hasVratGoal,
  }) {
    return DailySadhanaGoals(
      hasJapaGoal: hasJapaGoal ?? this.hasJapaGoal,
      japaTarget: japaTarget ?? this.japaTarget,
      hasScriptureGoal: hasScriptureGoal ?? this.hasScriptureGoal,
      scriptureMinutes: scriptureMinutes ?? this.scriptureMinutes,
      hasPujaGoal: hasPujaGoal ?? this.hasPujaGoal,
      hasMeditationGoal: hasMeditationGoal ?? this.hasMeditationGoal,
      meditationMinutes: meditationMinutes ?? this.meditationMinutes,
      hasVratGoal: hasVratGoal ?? this.hasVratGoal,
    );
  }

  Map<String, dynamic> toJson() => {
    'has_japa_goal': hasJapaGoal,
    'japa_target': japaTarget,
    'has_scripture_goal': hasScriptureGoal,
    'scripture_minutes': scriptureMinutes,
    'has_puja_goal': hasPujaGoal,
    'has_meditation_goal': hasMeditationGoal,
    'meditation_minutes': meditationMinutes,
    'has_vrat_goal': hasVratGoal,
  };

  factory DailySadhanaGoals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailySadhanaGoals();
    return DailySadhanaGoals(
      hasJapaGoal: json['has_japa_goal'] as bool? ?? true,
      japaTarget: (json['japa_target'] as num?)?.toInt() ?? 108,
      hasScriptureGoal: json['has_scripture_goal'] as bool? ?? true,
      scriptureMinutes: (json['scripture_minutes'] as num?)?.toInt() ?? 15,
      hasPujaGoal: json['has_puja_goal'] as bool? ?? true,
      hasMeditationGoal: json['has_meditation_goal'] as bool? ?? false,
      meditationMinutes: (json['meditation_minutes'] as num?)?.toInt() ?? 10,
      hasVratGoal: json['has_vrat_goal'] as bool? ?? true,
    );
  }
}

/// Comprehensive devotee personalization profile model.
class DevoteePreferences {
  final Set<String> selectedDeityIds;
  final String interfaceLanguage;
  final ScriptOption scriptureScript;
  final DailySadhanaGoals sadhanaGoals;
  final PanchangamLocation panchangamLocation;
  final bool remindersEnabled;
  final int morningReminderHour;
  final int morningReminderMinute;
  final int eveningReminderHour;
  final int eveningReminderMinute;
  final bool onboardingCompleted;

  const DevoteePreferences({
    this.selectedDeityIds = const {'ganesha', 'shiva'},
    this.interfaceLanguage = 'en',
    this.scriptureScript = ScriptOption.devanagari,
    this.sadhanaGoals = const DailySadhanaGoals(),
    this.panchangamLocation = PanchangamLocation.varanasi,
    this.remindersEnabled = false,
    this.morningReminderHour = 6,
    this.morningReminderMinute = 0,
    this.eveningReminderHour = 18,
    this.eveningReminderMinute = 30,
    this.onboardingCompleted = false,
  });

  DevoteePreferences copyWith({
    Set<String>? selectedDeityIds,
    String? interfaceLanguage,
    ScriptOption? scriptureScript,
    DailySadhanaGoals? sadhanaGoals,
    PanchangamLocation? panchangamLocation,
    bool? remindersEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    int? eveningReminderHour,
    int? eveningReminderMinute,
    bool? onboardingCompleted,
  }) {
    return DevoteePreferences(
      selectedDeityIds: selectedDeityIds ?? this.selectedDeityIds,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      scriptureScript: scriptureScript ?? this.scriptureScript,
      sadhanaGoals: sadhanaGoals ?? this.sadhanaGoals,
      panchangamLocation: panchangamLocation ?? this.panchangamLocation,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      morningReminderHour: morningReminderHour ?? this.morningReminderHour,
      morningReminderMinute: morningReminderMinute ?? this.morningReminderMinute,
      eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
      eveningReminderMinute: eveningReminderMinute ?? this.eveningReminderMinute,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'selected_deity_ids': selectedDeityIds.toList(),
    'interface_language': interfaceLanguage,
    'scripture_script': scriptureScript.name,
    'sadhana_goals': sadhanaGoals.toJson(),
    'panchangam_location': panchangamLocation.toJson(),
    'reminders_enabled': remindersEnabled,
    'morning_reminder_hour': morningReminderHour,
    'morning_reminder_minute': morningReminderMinute,
    'evening_reminder_hour': eveningReminderHour,
    'evening_reminder_minute': eveningReminderMinute,
    'onboarding_completed': onboardingCompleted,
  };

  factory DevoteePreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DevoteePreferences();

    ScriptOption script = ScriptOption.devanagari;
    final scriptName = json['scripture_script'] as String?;
    if (scriptName != null) {
      try {
        script = ScriptOption.values.firstWhere((s) => s.name == scriptName);
      } catch (_) {}
    }

    Set<String> deities = const {'ganesha', 'shiva'};
    if (json['selected_deity_ids'] is List) {
      deities = (json['selected_deity_ids'] as List)
          .map((e) => e.toString())
          .toSet();
    }

    PanchangamLocation location = PanchangamLocation.varanasi;
    if (json['panchangam_location'] is Map) {
      try {
        location = PanchangamLocation.fromJson(
          Map<String, dynamic>.from(json['panchangam_location'] as Map),
        );
      } catch (_) {}
    }

    DailySadhanaGoals goals = const DailySadhanaGoals();
    if (json['sadhana_goals'] is Map) {
      goals = DailySadhanaGoals.fromJson(
        Map<String, dynamic>.from(json['sadhana_goals'] as Map),
      );
    }

    return DevoteePreferences(
      selectedDeityIds: deities,
      interfaceLanguage: json['interface_language'] as String? ?? 'en',
      scriptureScript: script,
      sadhanaGoals: goals,
      panchangamLocation: location,
      remindersEnabled: json['reminders_enabled'] as bool? ?? false,
      morningReminderHour: (json['morning_reminder_hour'] as num?)?.toInt() ?? 6,
      morningReminderMinute: (json['morning_reminder_minute'] as num?)?.toInt() ?? 0,
      eveningReminderHour: (json['evening_reminder_hour'] as num?)?.toInt() ?? 18,
      eveningReminderMinute: (json['evening_reminder_minute'] as num?)?.toInt() ?? 30,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }
}
