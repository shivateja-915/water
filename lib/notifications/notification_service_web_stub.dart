// Web stub — all native notification operations are no-ops.
//
// This file is conditionally imported when `dart.library.html` is available.
// It provides the same function signatures as notification_service_native.dart
// so the conditional import compiles cleanly on both platforms.

Future<Map<String, String>> initializePlugin() async {
  return {'timezone': 'Browser'};
}

Future<Map<String, String>> requestAllPermissions() async {
  return {
    'notification': 'N/A (Web)',
    'exactAlarm': 'N/A (Web)',
    'battery': 'N/A (Web)',
  };
}

Future<void> scheduleDailyReminder({
  required int id,
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {}

Future<void> scheduleOneTimeReminder({
  required int id,
  required int delaySeconds,
  required String title,
  required String body,
}) async {}

Future<void> showInstantNotification({
  required int id,
  required String title,
  required String body,
}) async {}

Future<void> cancelNotification(int id) async {}

Future<void> cancelAllNotifications() async {}

Future<int> getPendingCount() async => 0;
