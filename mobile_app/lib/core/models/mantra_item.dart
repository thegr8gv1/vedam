/// Unambiguous devotional audio availability states for mobile and web.
enum AudioAvailabilityState {
  /// Actual audio is bundled in the mobile package and playable offline without internet.
  availableOffline,

  /// Metadata, text, and liturgical meaning exist in catalog, but no playable audio asset is bundled in this app release.
  catalogedNotAvailableInApp,

  /// Recording failed voice-check or verification is pending; quarantined from worship.
  quarantinedPendingVerification,

  /// No audio recording or catalog entry exists.
  unavailable,
}

extension AudioAvailabilityStateX on AudioAvailabilityState {
  String get displayName {
    switch (this) {
      case AudioAvailabilityState.availableOffline:
        return 'Available Offline';
      case AudioAvailabilityState.catalogedNotAvailableInApp:
        return 'Cataloged (Archive Only)';
      case AudioAvailabilityState.quarantinedPendingVerification:
        return 'Quarantined / Verification Pending';
      case AudioAvailabilityState.unavailable:
        return 'Unavailable';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AudioAvailabilityState.availableOffline:
        return 'Offline Audio';
      case AudioAvailabilityState.catalogedNotAvailableInApp:
        return 'Manual Japa (Archive)';
      case AudioAvailabilityState.quarantinedPendingVerification:
        return 'Quarantined';
      case AudioAvailabilityState.unavailable:
        return 'Text Only';
    }
  }

  bool get isPlayableInApp => this == AudioAvailabilityState.availableOffline;
}

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

  /// Number of authentic chant repetitions represented by this audio recording clip (1 repetition).
  int get repetitionCount => 1;

  /// Devotional repetition representation label.
  String get repetitionRepresentationLabel => '$repetitionCount Chant';

  /// Unambiguous audio availability state for this mantra item.
  AudioAvailabilityState get audioAvailabilityState {
    if (isBundled && bundledAssetPath != null && bundledAssetPath!.isNotEmpty) {
      return AudioAvailabilityState.availableOffline;
    }
    return AudioAvailabilityState.catalogedNotAvailableInApp;
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
