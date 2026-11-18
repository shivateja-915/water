class ReminderSettings {
  final String id;
  final String userId;
  final bool enabled;
  final String mode; // 'interval' or 'fixed'
  final int intervalHours;
  final List<String> fixedTimes;
  final String dndStart;
  final String dndEnd;
  final int snoozeDefaultMinutes;
  final String soundPattern;
  final bool weekdayWeekendSplitEnabled;
  final Map<String, dynamic> weekendOverrides;
  final List<String> deletedTimes; // NEW: interval times user manually removed
  final DateTime? createdAt;
  final int revision;
  final String? deviceId;
  final String? lastModified;
  final String? updatedAt;

  const ReminderSettings({
    required this.id,
    required this.userId,
    this.enabled = true,
    this.mode = 'both',
    this.intervalHours = 1,
    this.fixedTimes = const [],
    this.dndStart = '23:00',
    this.dndEnd = '07:00',
    this.snoozeDefaultMinutes = 5,
    this.soundPattern = 'default',
    this.weekdayWeekendSplitEnabled = false,
    this.weekendOverrides = const {},
    this.deletedTimes = const [],
    this.createdAt,
    this.revision = 1,
    this.deviceId,
    this.lastModified,
    this.updatedAt,
  });

  int get computedIntervalMinutes {
    if (weekendOverrides.containsKey('interval_minutes')) {
      return weekendOverrides['interval_minutes'] as int;
    }
    return intervalHours * 60;
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      mode: json['mode'] as String? ?? 'both',
      intervalHours: json['interval_hours'] as int? ?? 1,
      fixedTimes: json['fixed_times'] != null
          ? List<String>.from(json['fixed_times'] as List)
          : [],
      dndStart: json['dnd_start'] as String? ?? '23:00',
      dndEnd: json['dnd_end'] as String? ?? '07:00',
      snoozeDefaultMinutes: json['snooze_default_minutes'] as int? ?? 5,
      soundPattern: json['sound_pattern'] as String? ?? 'default',
      weekdayWeekendSplitEnabled:
          json['weekday_weekend_split_enabled'] as bool? ?? false,
      weekendOverrides: json['weekend_overrides'] != null
          ? Map<String, dynamic>.from(json['weekend_overrides'] as Map)
          : {},
      deletedTimes: json['deleted_times'] != null
          ? List<String>.from(json['deleted_times'] as List)
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      revision: json['revision'] as int? ?? 1,
      deviceId: json['device_id'] as String?,
      lastModified: json['last_modified'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'enabled': enabled,
      'mode': mode,
      'interval_hours': intervalHours,
      'fixed_times': fixedTimes,
      'dnd_start': dndStart,
      'dnd_end': dndEnd,
      'snooze_default_minutes': snoozeDefaultMinutes,
      'sound_pattern': soundPattern,
      'weekday_weekend_split_enabled': weekdayWeekendSplitEnabled,
      'weekend_overrides': weekendOverrides,
      'deleted_times': deletedTimes,
      'revision': revision,
      'device_id': deviceId,
      'last_modified': lastModified,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  /// Safe serialization for Supabase payload excluding non-existent columns
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'enabled': enabled,
      'mode': mode,
      'interval_hours': intervalHours,
      'fixed_times': fixedTimes,
      'dnd_start': dndStart,
      'dnd_end': dndEnd,
      'snooze_default_minutes': snoozeDefaultMinutes,
      'revision': revision,
      'device_id': deviceId,
      'last_modified': lastModified,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  ReminderSettings copyWith({
    String? id,
    String? userId,
    bool? enabled,
    String? mode,
    int? intervalHours,
    List<String>? fixedTimes,
    String? dndStart,
    String? dndEnd,
    int? snoozeDefaultMinutes,
    String? soundPattern,
    bool? weekdayWeekendSplitEnabled,
    Map<String, dynamic>? weekendOverrides,
    List<String>? deletedTimes,
    int? revision,
    String? deviceId,
    String? lastModified,
    String? updatedAt,
  }) {
    return ReminderSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      intervalHours: intervalHours ?? this.intervalHours,
      fixedTimes: fixedTimes ?? this.fixedTimes,
      dndStart: dndStart ?? this.dndStart,
      dndEnd: dndEnd ?? this.dndEnd,
      snoozeDefaultMinutes:
          snoozeDefaultMinutes ?? this.snoozeDefaultMinutes,
      soundPattern: soundPattern ?? this.soundPattern,
      weekdayWeekendSplitEnabled:
          weekdayWeekendSplitEnabled ?? this.weekdayWeekendSplitEnabled,
      weekendOverrides: weekendOverrides ?? this.weekendOverrides,
      deletedTimes: deletedTimes ?? this.deletedTimes,
      revision: revision ?? this.revision,
      deviceId: deviceId ?? this.deviceId,
      lastModified: lastModified ?? this.lastModified,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

