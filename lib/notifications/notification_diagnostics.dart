import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/firebase_service.dart';
import 'notification_boot.dart';
import 'notification_permissions.dart';
import 'notification_service.dart';
import 'notification_timezone.dart';

class NotificationDiagnosticsData {
  final String platform;
  final bool osNotificationsSupported;
  final String notificationPermission;
  final String exactAlarmPermission;
  final String batteryOptPermission;
  final String timezone;
  final int pendingLocalCount;
  final String bootStatus;
  final bool firebaseInitialized;
  final String fcmTokenStatus;

  const NotificationDiagnosticsData({
    required this.platform,
    required this.osNotificationsSupported,
    required this.notificationPermission,
    required this.exactAlarmPermission,
    required this.batteryOptPermission,
    required this.timezone,
    required this.pendingLocalCount,
    required this.bootStatus,
    required this.firebaseInitialized,
    required this.fcmTokenStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'osNotificationsSupported': osNotificationsSupported,
      'notificationPermission': notificationPermission,
      'exactAlarmPermission': exactAlarmPermission,
      'batteryOptPermission': batteryOptPermission,
      'timezone': timezone,
      'pendingLocalCount': pendingLocalCount,
      'bootStatus': bootStatus,
      'firebaseInitialized': firebaseInitialized,
      'fcmTokenStatus': fcmTokenStatus,
    };
  }
}

class NotificationDiagnostics {
  NotificationDiagnostics._();

  static Future<NotificationDiagnosticsData> collect() async {
    final pendingCount = await NotificationService.getPendingNotificationCount();
    final bootSummary = await NotificationBoot.getBootStatusSummary();

    String fcmStatus = 'Not Cached';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null && token.isNotEmpty) fcmStatus = 'Cached';
    } catch (_) {}

    return NotificationDiagnosticsData(
      platform: NotificationService.platformName,
      osNotificationsSupported: NotificationService.supportsOsNotifications,
      notificationPermission: NotificationPermissions.notificationPermission,
      exactAlarmPermission: NotificationPermissions.exactAlarmPermission,
      batteryOptPermission: NotificationPermissions.batteryOptPermission,
      timezone: NotificationTimezone.getTimezoneInfo(),
      pendingLocalCount: pendingCount,
      bootStatus: bootSummary,
      firebaseInitialized: FirebaseService.isCoreInitialized,
      fcmTokenStatus: fcmStatus,
    );
  }
}
