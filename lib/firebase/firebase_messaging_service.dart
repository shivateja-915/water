import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_constants.dart';
import 'firebase_notification_handler.dart';
import 'firebase_token_repository.dart';

class FirebaseMessagingService {
  final FirebaseTokenRepository _tokenRepository = FirebaseTokenRepository();
  StreamSubscription<String>? _tokenStreamSubscription;

  /// Initializes messaging handlers: token fetching, message listeners, tap listeners.
  Future<void> initializeMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Get current FCM Token & print in debug mode
    try {
      final token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('====================================================');
          debugPrint('${FirebaseConstants.logTag} 🔑 CURRENT FCM TOKEN:');
          debugPrint(token);
          debugPrint('====================================================');
        }
        await _tokenRepository.saveToken(token);
      } else {
        debugPrint('${FirebaseConstants.logTag} ⚠️ FCM Token retrieved as null.');
      }
    } catch (e) {
      debugPrint('${FirebaseConstants.logTag} ⚠️ Failed to fetch FCM token: $e');
    }

    // 2. Listen to token refresh
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('${FirebaseConstants.logTag} 🔄 FCM Token refreshed: $newToken');
      await _tokenRepository.saveToken(newToken);
    });

    // 3. Foreground message listener (app is in active view)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
          '${FirebaseConstants.logTag} 📩 Foreground message received: ${message.notification?.title ?? 'No title'}');
      await FirebaseNotificationHandler.showForegroundNotification(message);
    });

    // 4. Background notification tap listener (app was running in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint(
          '${FirebaseConstants.logTag} 👆 Notification tapped while app in background: ${message.notification?.title}');
      await FirebaseNotificationHandler.logNotificationTap(
        title: message.notification?.title ?? message.data['title'] ?? 'Remote Notification',
        body: message.notification?.body ?? message.data['body'] ?? '',
        payload: message.data,
        source: 'Background Notification Tap (onMessageOpenedApp)',
      );
    });

    // 5. Terminated notification tap listener (app was completely closed)
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '${FirebaseConstants.logTag} 🚀 App opened from terminated state via notification tap: ${initialMessage.notification?.title}');
        await FirebaseNotificationHandler.logNotificationTap(
          title: initialMessage.notification?.title ?? initialMessage.data['title'] ?? 'Remote Notification',
          body: initialMessage.notification?.body ?? initialMessage.data['body'] ?? '',
          payload: initialMessage.data,
          source: 'Terminated Notification Tap (getInitialMessage)',
        );
      }
    } catch (e) {
      debugPrint('${FirebaseConstants.logTag} Error checking initial message: $e');
    }
  }

  void dispose() {
    _tokenStreamSubscription?.cancel();
  }
}
