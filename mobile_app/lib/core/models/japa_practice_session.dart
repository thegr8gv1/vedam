import 'package:flutter/foundation.dart';

/// Counting mode for a Japa practice session.
enum JapaCountingMode {
  /// Devotee tapped the manual bead / screen counter.
  manual,

  /// Repetitions counted automatically upon genuine audio completion.
  audio,

  /// Both manual and audio counting were used in the session.
  mixed,
}

extension JapaCountingModeX on JapaCountingMode {
  String get displayName {
    switch (this) {
      case JapaCountingMode.manual:
        return 'Manual Bead Chanting';
      case JapaCountingMode.audio:
        return 'Audio-Assisted Chanting';
      case JapaCountingMode.mixed:
        return 'Combined Bead & Audio';
    }
  }

  String get shortLabel {
    switch (this) {
      case JapaCountingMode.manual:
        return 'Manual';
      case JapaCountingMode.audio:
        return 'Audio';
      case JapaCountingMode.mixed:
        return 'Mixed';
    }
  }
}

/// Status of a Japa practice session.
enum JapaSessionStatus {
  active,
  paused,
  completed,
  abandoned,
}

extension JapaSessionStatusX on JapaSessionStatus {
  String get displayName {
    switch (this) {
      case JapaSessionStatus.active:
        return 'In Progress';
      case JapaSessionStatus.paused:
        return 'Paused';
      case JapaSessionStatus.completed:
        return 'Completed';
      case JapaSessionStatus.abandoned:
        return 'Concluded Early';
    }
  }
}

/// Immutable data model representing an active, paused, or completed Japa practice session.
///
/// Designed for local offline persistence without requiring cloud sync or database writes.
@immutable
class JapaPracticeSession {
  final String id;
  final String mantraId;
  final String mantraTitle;
  final String? deity;
  final int targetRepetitions;
  final int completedRepetitions;
  final JapaCountingMode countingMode;
  final DateTime startTime;
  final DateTime lastUpdatedTime;
  final JapaSessionStatus status;

  const JapaPracticeSession({
    required this.id,
    required this.mantraId,
    required this.mantraTitle,
    this.deity,
    required this.targetRepetitions,
    required this.completedRepetitions,
    required this.countingMode,
    required this.startTime,
    required this.lastUpdatedTime,
    required this.status,
  });

  bool get isCompleted =>
      status == JapaSessionStatus.completed || completedRepetitions >= targetRepetitions;

  bool get isTargetReached => completedRepetitions >= targetRepetitions;

  int get remainingRepetitions =>
      targetRepetitions > completedRepetitions ? targetRepetitions - completedRepetitions : 0;

  double get progressFraction => targetRepetitions > 0
      ? (completedRepetitions / targetRepetitions).clamp(0.0, 1.0)
      : 0.0;

  Duration get sessionDuration => lastUpdatedTime.difference(startTime);

  JapaPracticeSession copyWith({
    String? id,
    String? mantraId,
    String? mantraTitle,
    String? deity,
    int? targetRepetitions,
    int? completedRepetitions,
    JapaCountingMode? countingMode,
    DateTime? startTime,
    DateTime? lastUpdatedTime,
    JapaSessionStatus? status,
  }) {
    return JapaPracticeSession(
      id: id ?? this.id,
      mantraId: mantraId ?? this.mantraId,
      mantraTitle: mantraTitle ?? this.mantraTitle,
      deity: deity ?? this.deity,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      completedRepetitions: completedRepetitions ?? this.completedRepetitions,
      countingMode: countingMode ?? this.countingMode,
      startTime: startTime ?? this.startTime,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mantraId': mantraId,
      'mantraTitle': mantraTitle,
      if (deity != null) 'deity': deity,
      'targetRepetitions': targetRepetitions,
      'completedRepetitions': completedRepetitions,
      'countingMode': countingMode.name,
      'startTime': startTime.toIso8601String(),
      'lastUpdatedTime': lastUpdatedTime.toIso8601String(),
      'status': status.name,
    };
  }

  factory JapaPracticeSession.fromJson(Map<String, dynamic> json) {
    JapaCountingMode mode = JapaCountingMode.manual;
    final modeStr = json['countingMode'] as String?;
    if (modeStr != null) {
      for (final m in JapaCountingMode.values) {
        if (m.name == modeStr) {
          mode = m;
          break;
        }
      }
    }

    JapaSessionStatus sessionStatus = JapaSessionStatus.active;
    final statusStr = json['status'] as String?;
    if (statusStr != null) {
      for (final s in JapaSessionStatus.values) {
        if (s.name == statusStr) {
          sessionStatus = s;
          break;
        }
      }
    }

    DateTime parsedStartTime = DateTime.now();
    final startStr = json['startTime'] as String?;
    if (startStr != null) {
      parsedStartTime = DateTime.tryParse(startStr) ?? DateTime.now();
    }

    DateTime parsedUpdatedTime = parsedStartTime;
    final updatedStr = json['lastUpdatedTime'] as String?;
    if (updatedStr != null) {
      parsedUpdatedTime = DateTime.tryParse(updatedStr) ?? parsedStartTime;
    }

    final target = (json['targetRepetitions'] as num?)?.toInt() ?? 108;
    final completed = (json['completedRepetitions'] as num?)?.toInt() ?? 0;

    return JapaPracticeSession(
      id: json['id'] as String? ?? 'japa_${DateTime.now().millisecondsSinceEpoch}',
      mantraId: json['mantraId'] as String? ?? 'VEDA-MTR-0001',
      mantraTitle: json['mantraTitle'] as String? ?? 'Mantra Chanting',
      deity: json['deity'] as String?,
      targetRepetitions: target > 0 ? target : 108,
      completedRepetitions: completed >= 0 ? completed : 0,
      countingMode: mode,
      startTime: parsedStartTime,
      lastUpdatedTime: parsedUpdatedTime,
      status: sessionStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JapaPracticeSession &&
        other.id == id &&
        other.mantraId == mantraId &&
        other.targetRepetitions == targetRepetitions &&
        other.completedRepetitions == completedRepetitions &&
        other.countingMode == countingMode &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mantraId,
        targetRepetitions,
        completedRepetitions,
        countingMode,
        status,
      );
}
