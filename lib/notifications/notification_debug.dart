import 'package:shared_preferences/shared_preferences.dart';
import 'notification_constants.dart';
import 'notification_diagnostics.dart';

class NotificationDebug {
  NotificationDebug._();

  /// Compiles a comprehensive plain text / markdown report for copying to clipboard
  static Future<String> generateReport() async {
    final diagnostics = await NotificationDiagnostics.collect();
    final buffer = StringBuffer();

    buffer.writeln('====================================================');
    buffer.writeln('  H2O DASH NOTIFICATION PLATFORM DIAGNOSTIC REPORT');
    buffer.writeln('====================================================');
    buffer.writeln('Generated At: ${DateTime.now().toLocal()}');
    buffer.writeln('Platform: ${diagnostics.platform}');
    buffer.writeln('OS Notifications Supported: ${diagnostics.osNotificationsSupported}');
    buffer.writeln('Timezone: ${diagnostics.timezone}');
    buffer.writeln();

    buffer.writeln('--- PERMISSIONS ---');
    buffer.writeln('Notification Permission (POST_NOTIFICATIONS): ${diagnostics.notificationPermission}');
    buffer.writeln('Exact Alarms Permission (SCHEDULE_EXACT_ALARM): ${diagnostics.exactAlarmPermission}');
    buffer.writeln('Battery Optimization Exemption: ${diagnostics.batteryOptPermission}');
    buffer.writeln();

    buffer.writeln('--- CHANNELS (5) ---');
    buffer.writeln('1. ${NotificationConstants.channelWaterReminderName} [${NotificationConstants.channelWaterReminderId}] - HIGH');
    buffer.writeln('2. ${NotificationConstants.channelHydrationTipsName} [${NotificationConstants.channelHydrationTipsId}] - DEFAULT');
    buffer.writeln('3. ${NotificationConstants.channelAchievementsName} [${NotificationConstants.channelAchievementsId}] - HIGH');
    buffer.writeln('4. ${NotificationConstants.channelGeneralUpdatesName} [${NotificationConstants.channelGeneralUpdatesId}] - DEFAULT');
    buffer.writeln('5. ${NotificationConstants.channelBackgroundSyncName} [${NotificationConstants.channelBackgroundSyncId}] - LOW');
    buffer.writeln();

    buffer.writeln('--- SYSTEM STATUS ---');
    buffer.writeln('Pending Local OS Notifications: ${diagnostics.pendingLocalCount}');
    buffer.writeln('Boot Restoration Status: ${diagnostics.bootStatus}');
    buffer.writeln('Firebase Initialized: ${diagnostics.firebaseInitialized}');
    buffer.writeln();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReceived = prefs.getString('fcm_last_notification_received');
      if (lastReceived != null) {
        buffer.writeln('--- LAST RECEIVED FCM NOTIFICATION ---');
        buffer.writeln(lastReceived);
        buffer.writeln();
      }
    } catch (_) {}

    buffer.writeln('====================================================');
    return buffer.toString();
  }
}
