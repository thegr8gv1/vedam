// Strongly-typed model for Vedam Devotional Reminders.
// Allows devotees to configure respectful, local, non-cloud notifications
// with exact local timezone scheduling, without guilt-inducing messaging.

enum ReminderType {
  morningSadhana,
  eveningPrayer,
  mantraJapa,
  personalVrat,
  custom,
}

class DevotionalReminder {
  final String id;
  final ReminderType type;
  final String title;
  final String body;
  final int hour; // 0-23
  final int minute; // 0-59
  final int second; // 0-59
  final bool isEnabled;
  final bool repeatDaily;
  final String? scheduledDate; // YYYY-MM-DD for one-off Vrat reminders
  final String? linkedVratId;
  final String? linkedMantraId;

  const DevotionalReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.second = 0,
    this.isEnabled = true,
    this.repeatDaily = true,
    this.scheduledDate,
    this.linkedVratId,
    this.linkedMantraId,
  });

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  DevotionalReminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? body,
    int? hour,
    int? minute,
    int? second,
    bool? isEnabled,
    bool? repeatDaily,
    String? scheduledDate,
    String? linkedVratId,
    String? linkedMantraId,
  }) {
    return DevotionalReminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      second: second ?? this.second,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      linkedVratId: linkedVratId ?? this.linkedVratId,
      linkedMantraId: linkedMantraId ?? this.linkedMantraId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
        'second': second,
        'is_enabled': isEnabled,
        'repeat_daily': repeatDaily,
        'scheduled_date': scheduledDate,
        'linked_vrat_id': linkedVratId,
        'linked_mantra_id': linkedMantraId,
      };

  factory DevotionalReminder.fromJson(Map<String, dynamic> json) {
    ReminderType parseType(String? name) {
      for (final t in ReminderType.values) {
        if (t.name == name) return t;
      }
      return ReminderType.custom;
    }

    return DevotionalReminder(
      id: json['id'] as String,
      type: parseType(json['type'] as String?),
      title: json['title'] as String? ?? 'Devotional Reminder',
      body: json['body'] as String? ?? '',
      hour: json['hour'] as int? ?? 6,
      minute: json['minute'] as int? ?? 0,
      second: json['second'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
      repeatDaily: json['repeat_daily'] as bool? ?? true,
      scheduledDate: json['scheduled_date'] as String?,
      linkedVratId: json['linked_vrat_id'] as String?,
      linkedMantraId: json['linked_mantra_id'] as String?,
    );
  }
}
