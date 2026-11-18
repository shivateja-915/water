import 'package:flutter/foundation.dart';

// Conditional import: only pull flutter_local_notifications on native
import 'notification_service_native.dart'
    if (dart.library.html) 'notification_service_web_stub.dart' as native;

/// Handles all Android notification permissions.
///
/// On Web: returns "N/A" for all permissions.
/// On Android: requests POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM,
/// and IGNORE_BATTERY_OPTIMIZATIONS.
class NotificationPermissions {
  NotificationPermissions._();

  static String _notificationPermission = 'Not Checked';
  static String _exactAlarmPermission = 'Not Checked';
  static String _batteryOptPermission = 'Not Checked';

  static String get notificationPermission => _notificationPermission;
  static String get exactAlarmPermission => _exactAlarmPermission;
  static String get batteryOptPermission => _batteryOptPermission;

  /// Request all required permissions.
  /// Returns a map of permission name → status string.
  static Future<Map<String, String>> requestAll() async {
    if (kIsWeb) {
      _notificationPermission = 'N/A (Web)';
      _exactAlarmPermission = 'N/A (Web)';
      _batteryOptPermission = 'N/A (Web)';
      return {
        'notification': _notificationPermission,
        'exactAlarm': _exactAlarmPermission,
        'battery': _batteryOptPermission,
      };
    }

    try {
      final result = await native.requestAllPermissions();
      _notificationPermission = result['notification'] ?? 'Unknown';
      _exactAlarmPermission = result['exactAlarm'] ?? 'Unknown';
      _batteryOptPermission = result['battery'] ?? 'Unknown';
      return result;
    } catch (e) {
      debugPrint('NotificationPermissions.requestAll failed: $e');
      _notificationPermission = 'Error';
      _exactAlarmPermission = 'Error';
      _batteryOptPermission = 'Error';
      return {
        'notification': 'Error',
        'exactAlarm': 'Error',
        'battery': 'Error',
      };
    }
  }
}
