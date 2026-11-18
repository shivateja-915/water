import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_constants.dart';
import 'firebase_messaging_service.dart';
import 'firebase_notification_handler.dart';
import 'firebase_options.dart';

class FirebaseDiagnosticInfo {
  final bool isInitialized;
  final String appName;
  final String projectId;
  final bool isMessagingAvailable;
  final String? token;
  final bool isTokenCached;
  final String lastTokenRefresh;
  final String? lastException;

  const FirebaseDiagnosticInfo({
    required this.isInitialized,
    required this.appName,
    required this.projectId,
    required this.isMessagingAvailable,
    this.token,
    required this.isTokenCached,
    required this.lastTokenRefresh,
    this.lastException,
  });
}

class FirebaseService {
  static bool _coreInitialized = false;
  static bool get isCoreInitialized => _coreInitialized || Firebase.apps.isNotEmpty;
  static bool get isInitialized => isCoreInitialized;

  static String? _lastException;
  static String? get lastException => _lastException;

  static final FirebaseMessagingService _messagingService =
      FirebaseMessagingService();

  /// Step 1 of Startup Sequence: Initialize Firebase Core APP exactly once.
  static Future<void> initializeCore() async {
    if (Firebase.apps.isNotEmpty) {
      _coreInitialized = true;
      _lastException = null;
      debugPrint('${FirebaseConstants.logTag} 📦 Firebase Core app already initialized (${Firebase.app().name}).');
      return;
    }

    debugPrint('${FirebaseConstants.logTag} ----------------------------------------------------');
    debugPrint('${FirebaseConstants.logTag} 🚀 Step 1: Initializing Firebase Core App...');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _coreInitialized = true;
      _lastException = null;
      debugPrint('${FirebaseConstants.logTag} ✅ Firebase Core initialized successfully (${Firebase.app().name}, Project: ${Firebase.app().options.projectId}).');
    } catch (e) {
      _lastException = e.toString();
      _coreInitialized = false;
      debugPrint('${FirebaseConstants.logTag} ⚠️ Firebase Core init error: $e');
    }
  }

  /// Step 5 of Startup Sequence: Initialize FCM Handlers & Token Management
  static Future<void> initializeMessaging() async {
    if (!isCoreInitialized) {
      debugPrint('${FirebaseConstants.logTag} ⚠️ Skipping FCM Messaging init: Firebase Core is not initialized.');
      return;
    }

    try {
      // 1. Set Background Message Handler
      debugPrint('${FirebaseConstants.logTag} 🌙 Registering background message handler...');
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request Notification Permissions
      debugPrint('${FirebaseConstants.logTag} 🔒 Requesting FCM notification permissions...');
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('${FirebaseConstants.logTag} 🔑 FCM Permission status: ${settings.authorizationStatus.name}');

      // 3. Initialize Local Display Handler & Token Repository
      await FirebaseNotificationHandler.initialize();
      await _messagingService.initializeMessaging();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        FirebaseConstants.prefsInitStatus,
        'Initialized on ${DateTime.now().toLocal()} (Permission: ${settings.authorizationStatus.name})',
      );

      debugPrint('${FirebaseConstants.logTag} 🎉 FCM Messaging Service initialized completely.');
      debugPrint('${FirebaseConstants.logTag} ----------------------------------------------------');
    } catch (e) {
      _lastException = e.toString();
      debugPrint('${FirebaseConstants.logTag} ⚠️ FCM Messaging init warning: $e');
    }
  }

  /// Legacy static entrypoint for backwards compatibility
  static Future<void> initialize() async {
    await initializeCore();
    await initializeMessaging();
  }

  /// Collects REAL dynamic runtime diagnostics directly from live Firebase APIs
  static Future<FirebaseDiagnosticInfo> getDiagnostics() async {
    final bool initialized = Firebase.apps.isNotEmpty;
    final String appName = initialized ? Firebase.app().name : 'Disconnected';
    final String projectId = initialized ? Firebase.app().options.projectId : 'None';

    bool messagingAvailable = false;
    String? liveToken;
    bool tokenCached = false;
    String lastRefresh = 'Never';
    String? currentException = _lastException;

    if (initialized) {
      try {
        messagingAvailable = true;
        liveToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        currentException = 'FCM getToken error: $e';
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(FirebaseConstants.prefsFcmToken);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        tokenCached = true;
        liveToken ??= cachedToken;
      }
      lastRefresh = prefs.getString('fcm_token_updated_at') ?? 'Not recorded';
    } catch (_) {}

    return FirebaseDiagnosticInfo(
      isInitialized: initialized,
      appName: appName,
      projectId: projectId,
      isMessagingAvailable: messagingAvailable,
      token: liveToken,
      isTokenCached: tokenCached,
      lastTokenRefresh: lastRefresh,
      lastException: currentException,
    );
  }
}
