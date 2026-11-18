// Constants for Firebase Cloud Messaging (FCM) integration.

class FirebaseConstants {
  FirebaseConstants._();

  static const String channelId = 'water_reminder_channel';
  static const String channelName = 'Water Reminders';
  static const String channelDescription =
      'Hydration reminders and remote notifications';

  // SharedPreferences Keys
  static const String prefsFcmToken = 'fcm_token_cache';
  static const String prefsLastReceived = 'fcm_last_notification_received';
  static const String prefsLastTapped = 'fcm_last_notification_tapped';
  static const String prefsBgHandlerStatus = 'fcm_bg_handler_status';
  static const String prefsInitStatus = 'fcm_init_status';

  // Logging Prefix
  static const String logTag = '[FCM]';
}
