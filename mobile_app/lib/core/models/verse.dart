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
  final int verseNumber;
  final String devanagariText;
  final String iastText;
  final String meter;
  final Map<String, String> transliterations;
  final String? draftTranslation;
  final String translationStatus;
  final bool isApproved;
  final String? commentary;

  const Verse({
    required this.verseNumber,
    required this.devanagariText,
    required this.iastText,
    this.meter = '',
    this.transliterations = const {},
    this.draftTranslation,
    this.translationStatus = 'IN_PROGRESS',
    this.isApproved = false,
    this.commentary,
  });

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

  /// True if a draft meaning is available for study.
  bool get hasDraftTranslation =>
      draftTranslation != null && draftTranslation!.trim().isNotEmpty;
}
