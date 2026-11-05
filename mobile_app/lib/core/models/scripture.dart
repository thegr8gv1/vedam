import 'verse.dart';

class Scripture {
  final int id;
  final String contentId;
  final String canonicalTitle;
  final String devanagariTitle;
  final String category;
  final String deity;
  final String composer;
  final String rishi;
  final String chandas;
  final String devata;
  final String sourceScripture;
  final String traditionalUsage;
  final int verseCount;
  final List<Verse> verses;
  final String? coverageStatus;
  final int? totalCanonicalVerses;
  final List<String> availableSections;

  const Scripture({
    required this.id,
    required this.contentId,
    required this.canonicalTitle,
    required this.devanagariTitle,
    required this.category,
    required this.deity,
    required this.composer,
    required this.rishi,
    required this.chandas,
    required this.devata,
    required this.sourceScripture,
    required this.traditionalUsage,
    required this.verseCount,
    this.verses = const [],
    this.coverageStatus,
    this.totalCanonicalVerses,
    this.availableSections = const [],
  });

  /// Transparent, honest coverage label indicating whether the text is complete or an excerpt.
  String get displayCoverageStatus {
    if (coverageStatus != null && coverageStatus!.isNotEmpty) {
      return coverageStatus!;
    }
    if (totalCanonicalVerses != null && totalCanonicalVerses! > verseCount) {
      return 'Representative Excerpt ($verseCount of $totalCanonicalVerses verses)';
    }
    return 'Complete Canonical Text ($verseCount of $verseCount verses)';
  }

  /// Whether the scripture contains the complete traditional text.
  bool get hasFullCanonicalCoverage {
    if (totalCanonicalVerses != null) {
      return verseCount >= totalCanonicalVerses!;
    }
    return true;
  }

  String get firstVerseDevanagari {
    if (verses.isNotEmpty) {
      return verses.first.devanagariText;
    }
    return '';
  }

  String get firstVerseIast {
    if (verses.isNotEmpty) {
      return verses.first.iastText;
    }
    return '';
  }

  /// Finds a verse by its verse number (1-based).
  Verse? getVerseByNumber(int number) {
    try {
      return verses.firstWhere((v) => v.verseNumber == number);
    } catch (_) {
      return null;
    }
  }

  /// Finds a verse by its stable global ID or local stable ID.
  Verse? getVerseById(String id) {
    try {
      return verses.firstWhere((v) => v.stableId == id || v.globalId(contentId) == id);
    } catch (_) {
      return null;
    }
  }
}
