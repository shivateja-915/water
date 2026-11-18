import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_constants.dart';
import '../notifications/notification_history.dart';
import '../notifications/notification_models.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with @pragma('vm:entry-point') so it can run when app is killed or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('${FirebaseConstants.logTag} 🌙 Background message received: ${message.messageId}');
  debugPrint('${FirebaseConstants.logTag} Title: ${message.notification?.title}');
  debugPrint('${FirebaseConstants.logTag} Body: ${message.notification?.body}');
  debugPrint('${FirebaseConstants.logTag} Data: ${message.data}');

  try {
    final prefs = await SharedPreferences.getInstance();
    final logData = {
      'messageId': message.messageId,
      'title': message.notification?.title ?? message.data['title'] ?? 'Remote Notification',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
      'handler': 'background',
    };
    await prefs.setString(
        FirebaseConstants.prefsLastReceived, jsonEncode(logData));
    await prefs.setString(FirebaseConstants.prefsBgHandlerStatus,
        'Active - Last triggered at ${DateTime.now().toLocal()}');
  } catch (e) {
    debugPrint('${FirebaseConstants.logTag} Error saving background log: $e');
  }
}

class FirebaseNotificationHandler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initializes the local notifications display for FCM.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        logNotificationTap(
          title: 'Tapped Notification',
          body: response.payload ?? '',
          payload: {'payload': response.payload},
          source: 'Foreground Notification Tap',
        );
      },
    );

    _initialized = true;
    debugPrint('${FirebaseConstants.logTag} Local Notification display handler initialized.');
  }

  /// Displays foreground FCM notification using flutter_local_notifications
  static Future<void> showForegroundNotification(RemoteMessage message) async {
    await initialize();

    final title =
        message.notification?.title ?? message.data['title'] ?? 'Siply';
    final body =
        message.notification?.body ?? message.data['body'] ?? 'Drink water to stay hydrated!';

    // Save to last received log
    await logReceivedNotification(
      title: title,
      body: body,
      data: message.data,
      source: 'Foreground FCM',
    );

    const androidDetails = AndroidNotificationDetails(
      FirebaseConstants.channelId,
      FirebaseConstants.channelName,
      channelDescription: FirebaseConstants.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final id = message.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch.hashCode;

    await _notificationsPlugin.show(
      id.abs() % 100000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    debugPrint('${FirebaseConstants.logTag} 🔔 Displayed foreground FCM notification: $title - $body');
  }

  /// Logs received notification details for debug UI inspection
  static Future<void> logReceivedNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String source,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final record = {
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
      };
      await prefs.setString(
          FirebaseConstants.prefsLastReceived, jsonEncode(record));

      await NotificationHistoryNotifier.logToPrefs(
        title: title,
        body: body,
        type: NotificationType.update,
        channelId: FirebaseConstants.channelId,
        payload: {'source': source, ...data},
      );
    } catch (e) {
      debugPrint('${FirebaseConstants.logTag} Failed to log received notification: $e');
    }
  }

  /// Logs notification tap details for debug UI inspection
  static Future<void> logNotificationTap({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    required String source,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final record = {
        'title': title,
        'body': body,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
      };
      await prefs.setString(
          FirebaseConstants.prefsLastTapped, jsonEncode(record));
      debugPrint('${FirebaseConstants.logTag} 👆 Logged notification tap event from: $source');
    } catch (e) {
      debugPrint('${FirebaseConstants.logTag} Failed to log notification tap: $e');
    }
  }
}
