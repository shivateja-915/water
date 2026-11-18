import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_constants.dart';

import 'notification_service_native.dart'
    if (dart.library.html) 'notification_service_web_stub.dart' as native;

class NotificationService {
  NotificationService._();

  static bool _initialized = false;
  static String _timezone = 'Unknown';

  static bool get isInitialized => _initialized;
  static bool get supportsOsNotifications => !kIsWeb;
  static String get platformName => kIsWeb ? 'Web' : defaultTargetPlatform.name;
  static String get timezone => _timezone;

  /// Initializes the local notification engine.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final res = await native.initializePlugin();
      _timezone = res['timezone'] ?? 'UTC';
      _initialized = true;
      debugPrint('${NotificationConstants.logTag} Engine initialized ($platformName, tz: $_timezone)');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} Engine initialize failed: $e');
    }
  }

  /// Schedules single snooze notification without modifying daily schedule
  static Future<void> scheduleSnoozeNotification({
    required DateTime targetDateTime,
    required int minutes,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final id = (DateTime.now().millisecondsSinceEpoch % 90000) + 10000;
    final title = '💧 Hydration Snooze ($minutes mins)';
    final body = 'Time to drink water! Your $minutes-minute snooze is complete.';

    await native.scheduleSingleNotification(
      id: id,
      dateTime: targetDateTime,
      title: title,
      body: body,
      channelId: NotificationConstants.channelWaterReminderId,
    );
  }

  /// Schedules a single custom notification
  static Future<void> scheduleSingleNotification({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String channelId = NotificationConstants.channelWaterReminderId,
  }) async {
    if (kIsWeb) return;
    await initialize();
    await native.scheduleSingleNotification(
      id: id,
      dateTime: dateTime,
      title: title,
      body: body,
      channelId: channelId,
    );
  }

  /// Schedules a test notification to fire in 3 seconds
  static Future<void> scheduleTestNotification() async {
    if (kIsWeb) return;
    await initialize();

    final id = (DateTime.now().millisecondsSinceEpoch % 90000) + 20000;
    final target = DateTime.now().add(const Duration(seconds: 3));

    await native.scheduleSingleNotification(
      id: id,
      dateTime: target,
      title: '💧 OS Test Notification',
      body: 'If you see this, OS native notifications are working cleanly!',
      channelId: NotificationConstants.channelWaterReminderId,
    );
  }

  /// Schedules a daily repeating reminder
  static Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String channelId = NotificationConstants.channelWaterReminderId,
  }) async {
    if (kIsWeb) return;
    await initialize();

    await native.scheduleDailyReminder(
      id: id,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      channelId: channelId,
    );
  }

  /// Shows notification immediately
  static Future<void> showNotificationNow({
    required int id,
    required String title,
    required String body,
    String channelId = NotificationConstants.channelWaterReminderId,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await initialize();

    await native.showNotificationNow(
      id: id,
      title: title,
      body: body,
      channelId: channelId,
      payload: payload,
    );
  }

  /// Cancels all pending OS notifications
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await native.cancelAllNotifications();
  }

  /// Cancels a specific notification by ID
  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await native.cancelNotification(id);
  }

  /// Returns count of pending OS notifications
  static Future<int> getPendingNotificationCount() async {
    if (kIsWeb) return 0;
    return await native.getPendingNotificationCount();
  }

  /// Returns list of pending OS notification requests
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await native.getPendingNotifications();
  }
}
