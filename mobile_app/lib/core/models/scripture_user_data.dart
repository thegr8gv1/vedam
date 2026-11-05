import 'verse.dart';

/// A devotee's saved bookmark on a specific verse.
class VerseBookmark {
  final String verseId;
  final int scriptureId;
  final String scriptureContentId;
  final String scriptureTitle;
  final int verseNumber;
  final String verseSnippet;
  final String bookmarkedAt;

  const VerseBookmark({
    required this.verseId,
    required this.scriptureId,
    required this.scriptureContentId,
    required this.scriptureTitle,
    required this.verseNumber,
    required this.verseSnippet,
    required this.bookmarkedAt,
  });

  Map<String, dynamic> toJson() => {
        'verseId': verseId,
        'scriptureId': scriptureId,
        'scriptureContentId': scriptureContentId,
        'scriptureTitle': scriptureTitle,
        'verseNumber': verseNumber,
        'verseSnippet': verseSnippet,
        'bookmarkedAt': bookmarkedAt,
      };

  factory VerseBookmark.fromJson(Map<String, dynamic> json) => VerseBookmark(
        verseId: json['verseId'] as String,
        scriptureId: json['scriptureId'] as int,
        scriptureContentId: json['scriptureContentId'] as String? ?? '',
        scriptureTitle: json['scriptureTitle'] as String? ?? 'Scripture',
        verseNumber: json['verseNumber'] as int,
        verseSnippet: json['verseSnippet'] as String? ?? '',
        bookmarkedAt: json['bookmarkedAt'] as String? ?? '',
      );
}

/// A devotee's personal study note attached to a specific verse.
class VerseNote {
  final String verseId;
  final int scriptureId;
  final String scriptureContentId;
  final String scriptureTitle;
  final int verseNumber;
  final String noteText;
  final String updatedAt;

  const VerseNote({
    required this.verseId,
    required this.scriptureId,
    required this.scriptureContentId,
    required this.scriptureTitle,
    required this.verseNumber,
    required this.noteText,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'verseId': verseId,
        'scriptureId': scriptureId,
        'scriptureContentId': scriptureContentId,
        'scriptureTitle': scriptureTitle,
        'verseNumber': verseNumber,
        'noteText': noteText,
        'updatedAt': updatedAt,
      };

  factory VerseNote.fromJson(Map<String, dynamic> json) => VerseNote(
        verseId: json['verseId'] as String,
        scriptureId: json['scriptureId'] as int,
        scriptureContentId: json['scriptureContentId'] as String? ?? '',
        scriptureTitle: json['scriptureTitle'] as String? ?? 'Scripture',
        verseNumber: json['verseNumber'] as int,
        noteText: json['noteText'] as String,
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}

/// Tracks reading progress per scripture.
class ReadingProgress {
  final int scriptureId;
  final String scriptureContentId;
  final int lastReadVerseNumber;
  final String lastReadVerseId;
  final int totalVerses;
  final Set<int> completedVerseNumbers;
  final String lastReadAt;

  const ReadingProgress({
    required this.scriptureId,
    required this.scriptureContentId,
    required this.lastReadVerseNumber,
    required this.lastReadVerseId,
    required this.totalVerses,
    required this.completedVerseNumbers,
    required this.lastReadAt,
  });

  double get percentCompleted =>
      totalVerses > 0 ? (completedVerseNumbers.length / totalVerses).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => totalVerses > 0 && completedVerseNumbers.length >= totalVerses;

  Map<String, dynamic> toJson() => {
        'scriptureId': scriptureId,
        'scriptureContentId': scriptureContentId,
        'lastReadVerseNumber': lastReadVerseNumber,
        'lastReadVerseId': lastReadVerseId,
        'totalVerses': totalVerses,
        'completedVerseNumbers': completedVerseNumbers.toList(),
        'lastReadAt': lastReadAt,
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) => ReadingProgress(
        scriptureId: json['scriptureId'] as int,
        scriptureContentId: json['scriptureContentId'] as String? ?? '',
        lastReadVerseNumber: json['lastReadVerseNumber'] as int? ?? 1,
        lastReadVerseId: json['lastReadVerseId'] as String? ?? '',
        totalVerses: json['totalVerses'] as int? ?? 1,
        completedVerseNumbers: ((json['completedVerseNumbers'] as List<dynamic>?) ?? [])
            .map((e) => e as int)
            .toSet(),
        lastReadAt: json['lastReadAt'] as String? ?? '',
      );
}

/// Devotee reading layout, script, and typography preferences.
class ReadingPreferences {
  final double sanskritFontSize;
  final double transliterationFontSize;
  final double translationFontSize;
  final double lineSpacing;
  final ScriptOption preferredScript;
  final bool showTransliteration;
  final bool showTranslation;

  const ReadingPreferences({
    this.sanskritFontSize = 20.0,
    this.transliterationFontSize = 15.0,
    this.translationFontSize = 14.0,
    this.lineSpacing = 1.6,
    this.preferredScript = ScriptOption.devanagari,
    this.showTransliteration = true,
    this.showTranslation = true,
  });

  ReadingPreferences copyWith({
    double? sanskritFontSize,
    double? transliterationFontSize,
    double? translationFontSize,
    double? lineSpacing,
    ScriptOption? preferredScript,
    bool? showTransliteration,
    bool? showTranslation,
  }) =>
      ReadingPreferences(
        sanskritFontSize: sanskritFontSize ?? this.sanskritFontSize,
        transliterationFontSize: transliterationFontSize ?? this.transliterationFontSize,
        translationFontSize: translationFontSize ?? this.translationFontSize,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        preferredScript: preferredScript ?? this.preferredScript,
        showTransliteration: showTransliteration ?? this.showTransliteration,
        showTranslation: showTranslation ?? this.showTranslation,
      );

  Map<String, dynamic> toJson() => {
        'sanskritFontSize': sanskritFontSize,
        'transliterationFontSize': transliterationFontSize,
        'translationFontSize': translationFontSize,
        'lineSpacing': lineSpacing,
        'preferredScript': preferredScript.name,
        'showTransliteration': showTransliteration,
        'showTranslation': showTranslation,
      };

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) => ReadingPreferences(
        sanskritFontSize: (json['sanskritFontSize'] as num?)?.toDouble() ?? 20.0,
        transliterationFontSize: (json['transliterationFontSize'] as num?)?.toDouble() ?? 15.0,
        translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? 14.0,
        lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.6,
        preferredScript: ScriptOption.values.firstWhere(
          (s) => s.name == json['preferredScript'],
          orElse: () => ScriptOption.devanagari,
        ),
        showTransliteration: json['showTransliteration'] as bool? ?? true,
        showTranslation: json['showTranslation'] as bool? ?? true,
      );
}
