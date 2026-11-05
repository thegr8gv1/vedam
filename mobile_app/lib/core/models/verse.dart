enum ScriptOption {
  devanagari('Devanagari', 'संस्कृतम्'),
  iast('IAST (Roman)', 'IAST'),
  telugu('Telugu', 'తెలుగు'),
  tamil('Tamil', 'தமிழ்'),
  kannada('Kannada', 'ಕನ್ನಡ'),
  malayalam('Malayalam', 'മലയാളം');

  final String label;
  final String nativeLabel;
  const ScriptOption(this.label, this.nativeLabel);
}

class Verse {
  final String? id;
  final int verseNumber;
  final String? sectionTitle;
  final String devanagariText;
  final String iastText;
  final String meter;
  final Map<String, String> transliterations;
  final String? draftTranslation;
  final String translationStatus;
  final bool isApproved;
  final String? commentary;
  final String? sourceReference;
  final String? audioMantraId;

  const Verse({
    this.id,
    required this.verseNumber,
    this.sectionTitle,
    required this.devanagariText,
    required this.iastText,
    this.meter = '',
    this.transliterations = const {},
    this.draftTranslation,
    this.translationStatus = 'DRAFT',
    this.isApproved = false,
    this.commentary,
    this.sourceReference,
    this.audioMantraId,
  });

  /// Stable identifier for this verse.
  String get stableId => (id != null && id!.isNotEmpty) ? id! : 'v$verseNumber';

  /// Generates a globally unique stable ID combining scripture content ID and verse number.
  String globalId(String scriptureContentId) => '$scriptureContentId:v$verseNumber';

  /// Returns the text in the requested script, falling back to Devanagari or IAST.
  String getTextInScript(ScriptOption script) {
    switch (script) {
      case ScriptOption.devanagari:
        return devanagariText.isNotEmpty ? devanagariText : iastText;
      case ScriptOption.iast:
        return iastText.isNotEmpty ? iastText : devanagariText;
      case ScriptOption.telugu:
        return transliterations['telugu'] ?? (devanagariText.isNotEmpty ? devanagariText : iastText);
      case ScriptOption.tamil:
        return transliterations['tamil'] ?? (devanagariText.isNotEmpty ? devanagariText : iastText);
      case ScriptOption.kannada:
        return transliterations['kannada'] ?? (devanagariText.isNotEmpty ? devanagariText : iastText);
      case ScriptOption.malayalam:
        return transliterations['malayalam'] ?? (devanagariText.isNotEmpty ? devanagariText : iastText);
    }
  }

  /// Whether a transliteration is available in the requested regional script.
  bool hasTransliterationIn(ScriptOption script) {
    if (script == ScriptOption.devanagari) return devanagariText.isNotEmpty;
    if (script == ScriptOption.iast) return iastText.isNotEmpty;
    final text = transliterations[script.name];
    return text != null && text.isNotEmpty;
  }

  /// True if a draft meaning is available for study.
  bool get hasDraftTranslation =>
      draftTranslation != null && draftTranslation!.trim().isNotEmpty;

  /// True if authorized scholarly commentary exists.
  bool get hasCommentary =>
      commentary != null && commentary!.trim().isNotEmpty;

  /// True if a verified audio mapping exists.
  bool get hasVerifiedAudio =>
      audioMantraId != null && audioMantraId!.trim().isNotEmpty;
}
