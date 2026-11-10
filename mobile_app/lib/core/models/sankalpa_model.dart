import 'panchangam_data.dart';

/// Devotional purposes for which a Vedic Sankalpa is traditionally recited.
enum SankalpaPurpose {
  dailySadhana,
  japaPractice,
  shodashopacharaPuja,
  vratObservance,
  sandhyavandanam,
  custom,
}

extension SankalpaPurposeExtension on SankalpaPurpose {
  String get displayName {
    switch (this) {
      case SankalpaPurpose.dailySadhana:
        return 'Daily Sadhana (नित्य साधना)';
      case SankalpaPurpose.japaPractice:
        return 'Mantra Japa (जप साधना)';
      case SankalpaPurpose.shodashopacharaPuja:
        return 'Puja Worship (षोडशोपचार पूजा)';
      case SankalpaPurpose.vratObservance:
        return 'Vrat / Upavasa (व्रत / उपवास)';
      case SankalpaPurpose.sandhyavandanam:
        return 'Sandhyavandanam (सन्ध्यावन्दनम्)';
      case SankalpaPurpose.custom:
        return 'Personal Prayer (सङ्कल्प)';
    }
  }

  String get shortCode {
    switch (this) {
      case SankalpaPurpose.dailySadhana:
        return 'Sadhana';
      case SankalpaPurpose.japaPractice:
        return 'Japa';
      case SankalpaPurpose.shodashopacharaPuja:
        return 'Puja';
      case SankalpaPurpose.vratObservance:
        return 'Vrat';
      case SankalpaPurpose.sandhyavandanam:
        return 'Sandhya';
      case SankalpaPurpose.custom:
        return 'Custom';
    }
  }
}

/// Traditional sacred river basin or geographic kshetra for Desha Sankalpa.
enum RiverBasinOption {
  ganga,
  godavari, // Maintained for backward compatibility, designates South Bank
  godavariDakshine,
  godavariUttare,
  kaveri,
  krishna,
  narmada,
  yamuna,
  pavitraDeshe,
}

extension RiverBasinOptionExtension on RiverBasinOption {
  String get displayName {
    switch (this) {
      case RiverBasinOption.ganga:
        return 'Ganga Basin (गङ्गा तीरे)';
      case RiverBasinOption.godavari:
      case RiverBasinOption.godavariDakshine:
        return 'Godavari (South Bank / दक्षिणे तीरे)';
      case RiverBasinOption.godavariUttare:
        return 'Godavari (North Bank / उत्तरे तीरे)';
      case RiverBasinOption.kaveri:
        return 'Kaveri Basin (कावेरी तीरे)';
      case RiverBasinOption.krishna:
        return 'Krishna Basin (कृष्णा तीरे)';
      case RiverBasinOption.narmada:
        return 'Narmada Basin (नर्मदा तीरे)';
      case RiverBasinOption.yamuna:
        return 'Yamuna Basin (यमुना तीरे)';
      case RiverBasinOption.pavitraDeshe:
        return 'Sacred Abode / Universal (पुण्यदेशे)';
    }
  }

  String get sanskritPhrase {
    switch (this) {
      case RiverBasinOption.ganga:
        return 'गङ्गातीरे';
      case RiverBasinOption.godavari:
      case RiverBasinOption.godavariDakshine:
        return 'गोदावर्याः दक्षिणे तीरे';
      case RiverBasinOption.godavariUttare:
        return 'गोदावर्याः उत्तरे तीरे';
      case RiverBasinOption.kaveri:
        return 'कावेर्याः तीरे';
      case RiverBasinOption.krishna:
        return 'कृष्णावेण्योः तीरे';
      case RiverBasinOption.narmada:
        return 'नर्मदातीरे';
      case RiverBasinOption.yamuna:
        return 'यमुनातीरे';
      case RiverBasinOption.pavitraDeshe:
        return 'पुण्यदेशे';
    }
  }

  String get iastPhrase {
    switch (this) {
      case RiverBasinOption.ganga:
        return 'gaṅgātīre';
      case RiverBasinOption.godavari:
      case RiverBasinOption.godavariDakshine:
        return 'godāvaryāḥ dakṣiṇe tīre';
      case RiverBasinOption.godavariUttare:
        return 'godāvaryāḥ uttare tīre';
      case RiverBasinOption.kaveri:
        return 'kāveryāḥ tīre';
      case RiverBasinOption.krishna:
        return 'kṛṣṇāveṇyoḥ tīre';
      case RiverBasinOption.narmada:
        return 'narmadātīre';
      case RiverBasinOption.yamuna:
        return 'yamunātīre';
      case RiverBasinOption.pavitraDeshe:
        return 'puṇyadeśe';
    }
  }
}

/// Gender indicator for traditional Sanskrit declension in Sankalpa.
enum SankalpaGender {
  male,
  female,
  unspecified,
}

/// Input parameters for generating a customized Vedic Sankalpa.
class SankalpaInput {
  final String gotra;
  final String devoteeName;
  final SankalpaGender gender;
  final SankalpaPurpose purpose;
  final RiverBasinOption riverBasin;
  final String deityName;
  final String? customIntention;
  final DateTime date;
  final DailyPanchangamData? panchangam;
  final bool isAnonymous;

  const SankalpaInput({
    this.gotra = 'Vishnu',
    this.devoteeName = 'Devotee',
    this.gender = SankalpaGender.unspecified,
    this.purpose = SankalpaPurpose.dailySadhana,
    this.riverBasin = RiverBasinOption.pavitraDeshe,
    this.deityName = 'Sri Parameshwara',
    this.customIntention,
    required this.date,
    this.panchangam,
    this.isAnonymous = false,
  });

  SankalpaInput copyWith({
    String? gotra,
    String? devoteeName,
    SankalpaGender? gender,
    SankalpaPurpose? purpose,
    RiverBasinOption? riverBasin,
    String? deityName,
    String? customIntention,
    DateTime? date,
    DailyPanchangamData? panchangam,
    bool? isAnonymous,
  }) {
    return SankalpaInput(
      gotra: gotra ?? this.gotra,
      devoteeName: devoteeName ?? this.devoteeName,
      gender: gender ?? this.gender,
      purpose: purpose ?? this.purpose,
      riverBasin: riverBasin ?? this.riverBasin,
      deityName: deityName ?? this.deityName,
      customIntention: customIntention ?? this.customIntention,
      date: date ?? this.date,
      panchangam: panchangam ?? this.panchangam,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

/// Structural breakdown component of the Sankalpa (Desha, Kala, Lineage, Purpose).
class SankalpaComponent {
  final String sectionTitle;
  final String sanskritText;
  final String iastText;
  final String englishMeaning;

  const SankalpaComponent({
    required this.sectionTitle,
    required this.sanskritText,
    required this.iastText,
    required this.englishMeaning,
  });

  Map<String, dynamic> toJson() => {
    'section_title': sectionTitle,
    'sanskrit_text': sanskritText,
    'iast_text': iastText,
    'english_meaning': englishMeaning,
  };
}

/// Full output model returned by the Vedic Sankalpa generator.
class SankalpaOutput {
  final List<SankalpaComponent> components;
  final String sanskritFull;
  final String iastFull;
  final String englishFull;
  final String shortSanskrit;
  final String shortIast;
  final String shortEnglish;
  final String samvatsara;
  final String ayana;
  final String ritu;
  final String masa;
  final String paksha;
  final String tithi;
  final String vara;
  final String nakshatra;
  final DateTime date;
  final bool isApproximateFallback;
  final String scholarlyDisclaimer;

  const SankalpaOutput({
    required this.components,
    required this.sanskritFull,
    required this.iastFull,
    required this.englishFull,
    required this.shortSanskrit,
    required this.shortIast,
    required this.shortEnglish,
    required this.samvatsara,
    required this.ayana,
    required this.ritu,
    required this.masa,
    required this.paksha,
    required this.tithi,
    required this.vara,
    required this.nakshatra,
    required this.date,
    this.isApproximateFallback = false,
    this.scholarlyDisclaimer = 'Traditional Recitation Template: This generated text is a classical Smriti-style recitation aid. Specific phrasing, Gotra pravaras, and Desha formulas naturally vary across sampradayas, Vedic shakhas, and regional traditions. It does not replace personal guidance from a qualified family priest or acharya.',
  });
}
