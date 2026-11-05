/// Represents an authentic devotional mantra recording and metadata.
/// Verified from 455 WAV recordings in Phase 13B.
class MantraItem {
  final String id;
  final String collection;
  final String deity;
  final String title;
  final String filename;
  final String mantraText;
  final String significance;
  final String form;
  final double durationSeconds;
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final int fileSizeBytes;
  final String sha256;
  final String sourceTxt;
  final bool isBundled;
  final String? bundledAssetPath;

  const MantraItem({
    required this.id,
    required this.collection,
    required this.deity,
    required this.title,
    required this.filename,
    required this.mantraText,
    required this.significance,
    required this.form,
    required this.durationSeconds,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.fileSizeBytes,
    required this.sha256,
    required this.sourceTxt,
    required this.isBundled,
    this.bundledAssetPath,
  });

  /// Duration as a standard Dart [Duration].
  Duration get duration => Duration(milliseconds: (durationSeconds * 1000).round());

  /// Formatted duration string (e.g. "0:05", "0:25").
  String get formattedDuration {
    final totalSec = durationSeconds.round();
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Copy with changes.
  MantraItem copyWith({
    String? id,
    String? collection,
    String? deity,
    String? title,
    String? filename,
    String? mantraText,
    String? significance,
    String? form,
    double? durationSeconds,
    int? sampleRate,
    int? bitDepth,
    int? channels,
    int? fileSizeBytes,
    String? sha256,
    String? sourceTxt,
    bool? isBundled,
    String? bundledAssetPath,
  }) {
    return MantraItem(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      deity: deity ?? this.deity,
      title: title ?? this.title,
      filename: filename ?? this.filename,
      mantraText: mantraText ?? this.mantraText,
      significance: significance ?? this.significance,
      form: form ?? this.form,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      channels: channels ?? this.channels,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      sha256: sha256 ?? this.sha256,
      sourceTxt: sourceTxt ?? this.sourceTxt,
      isBundled: isBundled ?? this.isBundled,
      bundledAssetPath: bundledAssetPath ?? this.bundledAssetPath,
    );
  }
}
