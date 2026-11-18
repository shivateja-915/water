import 'package:flutter/material.dart';
import '../firebase/firebase_service.dart';
import '../data/services/supabase_service.dart';
import '../notifications/notification_service.dart';
import '../main_timezone.dart' if (dart.library.html) '../main_timezone_web.dart' as tz_init;

class SplashInitializer {
  static Future<void> initializeApp() async {
    // 1. Firebase Core
    try {
      await FirebaseService.initializeCore();
    } catch (e) {
      debugPrint('Startup Error [Firebase Core]: $e');
    }

    // 2. Supabase
    try {
      await SupabaseService.initialize();
    } catch (e) {
      debugPrint('Startup Warning [Supabase]: $e');
    }

    // 3. Timezone
    try {
      await tz_init.initializeTimezone();
    } catch (e) {
      debugPrint('Startup Warning [Timezone]: $e');
    }

    // 4. Notifications
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Startup Warning [NotificationService]: $e');
    }

    // 5. Firebase Messaging
    try {
      await FirebaseService.initializeMessaging();
    } catch (e) {
      debugPrint('Startup Warning [FirebaseMessagingService]: $e');
    }
  }
}

