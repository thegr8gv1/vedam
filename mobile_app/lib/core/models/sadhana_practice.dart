import 'package:flutter/material.dart';

/// Categories of personal spiritual practice (Sadhana).
enum SadhanaCategory {
  morningPrayer,
  dailyPuja,
  mantraChanting,
  japaPractice,
  scriptureReading,
  eveningPrayer;

  String get displayName {
    switch (this) {
      case SadhanaCategory.morningPrayer:
        return 'Morning Prayer';
      case SadhanaCategory.dailyPuja:
        return 'Daily Puja';
      case SadhanaCategory.mantraChanting:
        return 'Mantra Chanting';
      case SadhanaCategory.japaPractice:
        return 'Japa Practice';
      case SadhanaCategory.scriptureReading:
        return 'Scripture Reading';
      case SadhanaCategory.eveningPrayer:
        return 'Evening Prayer';
    }
  }

  IconData get icon {
    switch (this) {
      case SadhanaCategory.morningPrayer:
        return Icons.wb_twilight;
      case SadhanaCategory.dailyPuja:
        return Icons.temple_hindu;
      case SadhanaCategory.mantraChanting:
        return Icons.music_note;
      case SadhanaCategory.japaPractice:
        return Icons.fingerprint;
      case SadhanaCategory.scriptureReading:
        return Icons.menu_book;
      case SadhanaCategory.eveningPrayer:
        return Icons.nightlight_round;
    }
  }
}

/// A specific devotional practice item that can be included in a devotee's daily routine.
class SadhanaPractice {
  final String id;
  final String title;
  final String sanskritTitle;
  final SadhanaCategory category;
  final String? deity;
  final String description;
  final int estimatedMinutes;
  final String? pujaGuideId;
  final String? linkedMantraId;
  final bool isCustom;

  const SadhanaPractice({
    required this.id,
    required this.title,
    required this.sanskritTitle,
    required this.category,
    this.deity,
    required this.description,
    this.estimatedMinutes = 10,
    this.pujaGuideId,
    this.linkedMantraId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sanskrit_title': sanskritTitle,
        'category': category.name,
        'deity': deity,
        'description': description,
        'estimated_minutes': estimatedMinutes,
        'puja_guide_id': pujaGuideId,
        'linked_mantra_id': linkedMantraId,
        'is_custom': isCustom,
      };

  factory SadhanaPractice.fromJson(Map<String, dynamic> json) {
    return SadhanaPractice(
      id: json['id'] as String,
      title: json['title'] as String,
      sanskritTitle: json['sanskrit_title'] as String? ?? '',
      category: SadhanaCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SadhanaCategory.dailyPuja,
      ),
      deity: json['deity'] as String?,
      description: json['description'] as String? ?? '',
      estimatedMinutes: json['estimated_minutes'] as int? ?? 10,
      pujaGuideId: json['puja_guide_id'] as String?,
      linkedMantraId: json['linked_mantra_id'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }
}
