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
  });

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
}
