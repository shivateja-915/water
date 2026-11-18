import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_service.dart';
import 'notification_boot.dart';
import 'notification_constants.dart';
import 'notification_diagnostics.dart';
import 'notification_models.dart';
import 'notification_permissions.dart';
import 'notification_repository.dart';
import 'notification_service.dart';
import 'notification_timezone.dart';

final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager(ref);
});

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        (ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  final NotificationRepository _repository = NotificationRepository();

  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _repository.getPreferences();
    state = prefs;
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    state = newPrefs;
    await _repository.savePreferences(newPrefs);
  }
}

class NotificationManager {
  final Ref ref;
  final NotificationRepository repository = NotificationRepository();

  NotificationManager(this.ref);

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Main entry point to initialize the unified Notification Platform.
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('${NotificationConstants.logTag} Platform already initialized.');
      return;
    }

    debugPrint('====================================================');
    debugPrint('${NotificationConstants.logTag} 🚀 Initializing Unified Notification Platform');
    debugPrint('====================================================');

    // 1. Timezone Setup
    NotificationTimezone.logStatus();

    // 2. Initialize Local Notification Service (5 Android Channels)
    try {
      await NotificationService.initialize();
      debugPrint('${NotificationConstants.logTag} ✅ Local notification engine initialized.');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} ⚠️ Local notification engine init warning: $e');
    }

    // 3. Request Runtime Permissions
    try {
      final perms = await NotificationPermissions.requestAll();
      debugPrint('${NotificationConstants.logTag} 🔑 Permissions: $perms');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} ⚠️ Permission request warning: $e');
    }

    // 4. Verify Boot Completion & Alarm Restoration
    try {
      await NotificationBoot.verifyBootRestoration();
      debugPrint('${NotificationConstants.logTag} ✅ Boot restoration verified.');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} ⚠️ Boot verification warning: $e');
    }

    // 5. Initialize Firebase Cloud Messaging (FCM)
    try {
      await FirebaseService.initialize();
      debugPrint('${NotificationConstants.logTag} ✅ Firebase Cloud Messaging initialized.');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} ⚠️ Firebase init warning: $e');
    }

    _initialized = true;
    debugPrint('${NotificationConstants.logTag} 🎉 Notification Platform initialized successfully.');
    debugPrint('====================================================');
  }

  /// Sends a local test notification on specified channel
  Future<void> sendTestNotification({
    required String channelId,
    required String title,
    required String body,
  }) async {
    final id = (DateTime.now().millisecondsSinceEpoch % 90000) + 1000;
    await NotificationService.showNotificationNow(
      id: id,
      title: title,
      body: body,
      channelId: channelId,
    );
  }

  /// Collects platform diagnostics data
  Future<NotificationDiagnosticsData> getDiagnostics() async {
    return await NotificationDiagnostics.collect();
  }
}
