// Unified Notification Models for H2O Dash
import 'package:flutter/material.dart' show TimeOfDay;

enum NotificationType {
  reminder,
  tip,
  achievement,
  update,
  system,
  snooze;

  String get displayName {
    switch (this) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.tip:
        return 'Hydration Tip';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.update:
        return 'App Update';
      case NotificationType.system:
        return 'System';
      case NotificationType.snooze:
        return 'Snooze';
    }
  }
}

class NotificationLogItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String channelId;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;
  final bool isRead;
  final bool isTapped;
  final bool isDismissed;

  const NotificationLogItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.channelId,
    this.payload,
    required this.timestamp,
    this.isRead = false,
    this.isTapped = false,
    this.isDismissed = false,
  });

  NotificationLogItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? channelId,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    bool? isRead,
    bool? isTapped,
    bool? isDismissed,
  }) {
    return NotificationLogItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      channelId: channelId ?? this.channelId,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isTapped: isTapped ?? this.isTapped,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'channelId': channelId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isTapped': isTapped,
      'isDismissed': isDismissed,
    };
  }

  factory NotificationLogItem.fromJson(Map<String, dynamic> json) {
    return NotificationLogItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.reminder,
      ),
      channelId: json['channelId'] as String? ?? 'water_reminder_channel',
      payload: json['payload'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isTapped: json['isTapped'] as bool? ?? false,
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}

class NotificationPreferences {
  final bool masterEnabled;
  final bool reminderEnabled;
  final bool tipsEnabled;
  final bool achievementsEnabled;
  final bool updatesEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final double volume;
  final bool previewEnabled;

  const NotificationPreferences({
    this.masterEnabled = true,
    this.reminderEnabled = true,
    this.tipsEnabled = true,
    this.achievementsEnabled = true,
    this.updatesEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.volume = 1.0,
    this.previewEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? reminderEnabled,
    bool? tipsEnabled,
    bool? achievementsEnabled,
    bool? updatesEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    double? volume,
    bool? previewEnabled,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      achievementsEnabled: achievementsEnabled ?? this.achievementsEnabled,
      updatesEnabled: updatesEnabled ?? this.updatesEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      volume: volume ?? this.volume,
      previewEnabled: previewEnabled ?? this.previewEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masterEnabled': masterEnabled,
      'reminderEnabled': reminderEnabled,
      'tipsEnabled': tipsEnabled,
      'achievementsEnabled': achievementsEnabled,
      'updatesEnabled': updatesEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'volume': volume,
      'previewEnabled': previewEnabled,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      tipsEnabled: json['tipsEnabled'] as bool? ?? true,
      achievementsEnabled: json['achievementsEnabled'] as bool? ?? true,
      updatesEnabled: json['updatesEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      previewEnabled: json['previewEnabled'] as bool? ?? true,
    );
  }
}

class NotificationAnalyticsData {
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final int dismissedCount;
  final int snoozedCount;
  final int missedCount;

  const NotificationAnalyticsData({
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.openedCount = 0,
    this.dismissedCount = 0,
    this.snoozedCount = 0,
    this.missedCount = 0,
  });

  NotificationAnalyticsData copyWith({
    int? sentCount,
    int? deliveredCount,
    int? openedCount,
    int? dismissedCount,
    int? snoozedCount,
    int? missedCount,
  }) {
    return NotificationAnalyticsData(
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      openedCount: openedCount ?? this.openedCount,
      dismissedCount: dismissedCount ?? this.dismissedCount,
      snoozedCount: snoozedCount ?? this.snoozedCount,
      missedCount: missedCount ?? this.missedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'openedCount': openedCount,
      'dismissedCount': dismissedCount,
      'snoozedCount': snoozedCount,
      'missedCount': missedCount,
    };
  }

  factory NotificationAnalyticsData.fromJson(Map<String, dynamic> json) {
    return NotificationAnalyticsData(
      sentCount: json['sentCount'] as int? ?? 0,
      deliveredCount: json['deliveredCount'] as int? ?? 0,
      openedCount: json['openedCount'] as int? ?? 0,
      dismissedCount: json['dismissedCount'] as int? ?? 0,
      snoozedCount: json['snoozedCount'] as int? ?? 0,
      missedCount: json['missedCount'] as int? ?? 0,
    );
  }
}

class SaveResult {
  final bool success;
  final bool localSaved;
  final bool cloudSynced;
  final int scheduledCount; // Legacy compatibility
  final int dailyActiveCount;
  final int scheduledNotificationCount;
  final int pendingNotificationCount;
  final List<DateTime> scheduledTimes; // Legacy compatibility
  final List<TimeOfDay> dailyScheduleTimes;
  final String? errorMessage;
  final String? rootCauseDiagnostic;
  final String? nextReminderTime;
  final String lastSyncTime;
  final String mode;
  final int intervalMinutes;
  final String dndStart;
  final String dndEnd;
  final int snoozeMinutes;

  const SaveResult({
    required this.success,
    this.localSaved = true,
    this.cloudSynced = true,
    required this.scheduledCount,
    this.dailyActiveCount = 0,
    this.scheduledNotificationCount = 0,
    this.pendingNotificationCount = 0,
    required this.scheduledTimes,
    this.dailyScheduleTimes = const [],
    this.errorMessage,
    this.rootCauseDiagnostic,
    this.nextReminderTime,
    this.lastSyncTime = '',
    required this.mode,
    required this.intervalMinutes,
    required this.dndStart,
    required this.dndEnd,
    required this.snoozeMinutes,
  });

  factory SaveResult.error(String message) {
    return SaveResult(
      success: false,
      localSaved: false,
      cloudSynced: false,
      scheduledCount: 0,
      dailyActiveCount: 0,
      scheduledNotificationCount: 0,
      pendingNotificationCount: 0,
      scheduledTimes: const [],
      dailyScheduleTimes: const [],
      errorMessage: message,
      rootCauseDiagnostic: message,
      nextReminderTime: null,
      lastSyncTime: DateTime.now().toIso8601String(),
      mode: 'interval',
      intervalMinutes: 120,
      dndStart: '23:00',
      dndEnd: '07:00',
      snoozeMinutes: 15,
    );
  }
}
