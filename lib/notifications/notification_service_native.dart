import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/timezone.dart' as tz;
import 'notification_constants.dart';
import 'notification_history.dart';
import 'notification_models.dart';
import 'notification_actions.dart';

// ═══════════════════════════════════════════════════════════════════════
// BACKGROUND HANDLER — top-level entry point
// ═══════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  debugPrint('${NotificationConstants.logTag} BG Tap Handler: actionId=${response.actionId}');
  if (response.actionId != null) {
    NotificationActions.handleAction(response.actionId!, response.payload);
  }
}

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

class NotificationServiceNative {
  NotificationServiceNative._();
  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}

// ═══════════════════════════════════════════════════════════════════════
// INITIALIZE PLUGIN & 5 ANDROID CHANNELS
// ═══════════════════════════════════════════════════════════════════════
Future<Map<String, String>> initializePlugin() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await _plugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('${NotificationConstants.logTag} FG Tap Handler: actionId=${response.actionId}');
      if (response.actionId != null) {
        NotificationActions.handleAction(response.actionId!, response.payload);
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
  );

  // Create 5 Android Notification Channels
  final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    // 1. Water Reminder
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelWaterReminderId,
        NotificationConstants.channelWaterReminderName,
        description: NotificationConstants.channelWaterReminderDescription,
        importance: NotificationConstants.channelWaterReminderImportance,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    // 2. Hydration Tips
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelHydrationTipsId,
        NotificationConstants.channelHydrationTipsName,
        description: NotificationConstants.channelHydrationTipsDescription,
        importance: NotificationConstants.channelHydrationTipsImportance,
        playSound: true,
      ),
    );

    // 3. Achievements
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelAchievementsId,
        NotificationConstants.channelAchievementsName,
        description: NotificationConstants.channelAchievementsDescription,
        importance: NotificationConstants.channelAchievementsImportance,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );

    // 4. General Updates
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelGeneralUpdatesId,
        NotificationConstants.channelGeneralUpdatesName,
        description: NotificationConstants.channelGeneralUpdatesDescription,
        importance: NotificationConstants.channelGeneralUpdatesImportance,
        playSound: true,
      ),
    );

    // 5. Background Sync (Silent)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelBackgroundSyncId,
        NotificationConstants.channelBackgroundSyncName,
        description: NotificationConstants.channelBackgroundSyncDescription,
        importance: NotificationConstants.channelBackgroundSyncImportance,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  final tzName = tz.local.name;
  debugPrint('${NotificationConstants.logTag} Native plugin initialized with 5 channels, tz=$tzName');
  return {'timezone': tzName};
}

// ═══════════════════════════════════════════════════════════════════════
// PERMISSIONS
// ═══════════════════════════════════════════════════════════════════════
Future<Map<String, String>> requestAllPermissions() async {
  final result = <String, String>{};

  final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // POST_NOTIFICATIONS
  final notifGranted = await androidPlugin?.requestNotificationsPermission();
  result['notification'] = notifGranted == true ? 'Granted' : 'Denied';

  // SCHEDULE_EXACT_ALARM
  final exactGranted = await androidPlugin?.requestExactAlarmsPermission();
  result['exactAlarm'] = exactGranted == true ? 'Granted' : 'Denied';

  // IGNORE_BATTERY_OPTIMIZATIONS
  try {
    final batteryStatus = await ph.Permission.ignoreBatteryOptimizations.status;
    if (batteryStatus.isDenied) {
      final batteryResult = await ph.Permission.ignoreBatteryOptimizations.request();
      result['battery'] = batteryResult.isGranted ? 'Granted' : 'Denied';
    } else {
      result['battery'] = batteryStatus.isGranted ? 'Granted' : 'Denied';
    }
  } catch (e) {
    result['battery'] = 'Error';
  }

  return result;
}

// ═══════════════════════════════════════════════════════════════════════
// SCHEDULING OPERATIONS
// ═══════════════════════════════════════════════════════════════════════
Future<void> scheduleDailyReminder({
  required int id,
  required int hour,
  required int minute,
  required String title,
  required String body,
  String channelId = NotificationConstants.channelWaterReminderId,
}) async {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  const androidDetails = AndroidNotificationDetails(
    NotificationConstants.channelWaterReminderId,
    NotificationConstants.channelWaterReminderName,
    channelDescription: NotificationConstants.channelWaterReminderDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        NotificationConstants.actionDrink250ml,
        '💧 Drink 250ml',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        NotificationConstants.actionDrink500ml,
        '💧 Drink 500ml',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        NotificationConstants.actionSnooze15m,
        '⏰ Snooze',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        NotificationConstants.actionDismiss,
        '❌ Dismiss',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ],
  );

  try {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e) {
    debugPrint('Native Notification Warning: Exact alarm permission denied ($e). Falling back to inexact mode.');
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

Future<void> scheduleSingleNotification({
  required int id,
  required DateTime dateTime,
  required String title,
  required String body,
  String channelId = NotificationConstants.channelWaterReminderId,
  String? payload,
}) async {
  final scheduled = tz.TZDateTime.from(dateTime, tz.local);

  const actionsList = <AndroidNotificationAction>[
    AndroidNotificationAction(
      NotificationConstants.actionDrink250ml,
      '💧 Drink 250ml',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionDrink500ml,
      '💧 Drink 500ml',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionSnooze15m,
      '⏰ Snooze',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionDismiss,
      '❌ Dismiss',
      showsUserInterface: false,
      cancelNotification: true,
    ),
  ];

  const androidDetails = AndroidNotificationDetails(
    NotificationConstants.channelWaterReminderId,
    NotificationConstants.channelWaterReminderName,
    channelDescription: NotificationConstants.channelWaterReminderDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    actions: actionsList,
  );

  try {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  } catch (e) {
    debugPrint('Native Notification Warning: Single alarm exact mode denied ($e). Falling back to inexact mode.');
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}

Future<void> showNotificationNow({
  required int id,
  required String title,
  required String body,
  String channelId = NotificationConstants.channelWaterReminderId,
  String? payload,
}) async {
  const actionsList = <AndroidNotificationAction>[
    AndroidNotificationAction(
      NotificationConstants.actionDrink250ml,
      '💧 Drink 250ml',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionDrink500ml,
      '💧 Drink 500ml',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionSnooze15m,
      '⏰ Snooze',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationConstants.actionDismiss,
      '❌ Dismiss',
      showsUserInterface: false,
      cancelNotification: true,
    ),
  ];

  const androidDetails = AndroidNotificationDetails(
    NotificationConstants.channelWaterReminderId,
    NotificationConstants.channelWaterReminderName,
    channelDescription: NotificationConstants.channelWaterReminderDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    actions: actionsList,
  );

  try {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  } catch (e) {
    debugPrint('Native Notification Warning (Test Environment?): $e');
  }

  await NotificationHistoryNotifier.logToPrefs(
    title: title,
    body: body,
    type: NotificationType.system,
    channelId: channelId,
  );
}

Future<void> cancelAllNotifications() async {
  await _plugin.cancelAll();
}

Future<void> cancelNotification(int id) async {
  await _plugin.cancel(id);
}

Future<int> getPendingNotificationCount() async {
  try {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  } catch (e) {
    debugPrint('Native Notification Warning: pendingNotificationRequests query ($e)');
    return 0;
  }
}

Future<List<PendingNotificationRequest>> getPendingNotifications() async {
  try {
    return await _plugin.pendingNotificationRequests();
  } catch (e) {
    debugPrint('Native Notification Warning: pendingNotificationRequests list query ($e)');
    return [];
  }
}
