// Unified Notification Constants for H2O Dash
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationConstants {
  NotificationConstants._();

  // ──────────────────────────────────────────────────────────────────────────
  // 5 SEPARATE NOTIFICATION CHANNELS
  // ──────────────────────────────────────────────────────────────────────────

  // 1. Water Reminder (High Importance, Custom Sound, Vibration)
  static const String channelWaterReminderId = 'water_reminder_channel';
  static const String channelWaterReminderName = 'Water Reminder';
  static const String channelWaterReminderDescription =
      'High priority hydration alarms and interval reminders.';
  static const Importance channelWaterReminderImportance = Importance.max;
  static const Priority channelWaterReminderPriority = Priority.high;

  // 2. Hydration Tips (Default Importance, Sound)
  static const String channelHydrationTipsId = 'hydration_tips_channel';
  static const String channelHydrationTipsName = 'Hydration Tips & Advice';
  static const String channelHydrationTipsDescription =
      'Daily wellness tips and hydration guidance.';
  static const Importance channelHydrationTipsImportance = Importance.defaultImportance;
  static const Priority channelHydrationTipsPriority = Priority.defaultPriority;

  // 3. Achievements & Badges (High Importance, Sound, Vibration)
  static const String channelAchievementsId = 'achievements_channel';
  static const String channelAchievementsName = 'Achievements & Badges';
  static const String channelAchievementsDescription =
      'Notifications for streak milestones, goal achievements, and level ups.';
  static const Importance channelAchievementsImportance = Importance.high;
  static const Priority channelAchievementsPriority = Priority.high;

  // 4. General Updates & Offers (Default Importance)
  static const String channelGeneralUpdatesId = 'general_updates_channel';
  static const String channelGeneralUpdatesName = 'General Updates & News';
  static const String channelGeneralUpdatesDescription =
      'App updates, feature announcements, and news.';
  static const Importance channelGeneralUpdatesImportance = Importance.defaultImportance;
  static const Priority channelGeneralUpdatesPriority = Priority.defaultPriority;

  // 5. Background Sync & System (Low Importance / Silent)
  static const String channelBackgroundSyncId = 'background_sync_channel';
  static const String channelBackgroundSyncName = 'Background Sync & System';
  static const String channelBackgroundSyncDescription =
      'Silent background system checks and sync status.';
  static const Importance channelBackgroundSyncImportance = Importance.low;
  static const Priority channelBackgroundSyncPriority = Priority.low;

  // ──────────────────────────────────────────────────────────────────────────
  // NOTIFICATION ACTION BUTTON IDS
  // ──────────────────────────────────────────────────────────────────────────
  static const String actionDrinkNow = 'ACTION_DRINK_NOW';
  static const String actionDrink250ml = 'ACTION_DRINK_250ML';
  static const String actionDrink500ml = 'ACTION_DRINK_500ML';
  static const String actionSnooze5m = 'ACTION_SNOOZE_5M';
  static const String actionSnooze15m = 'ACTION_SNOOZE_15M';
  static const String actionSnooze30m = 'ACTION_SNOOZE_30M';
  static const String actionDismiss = 'ACTION_DISMISS';
  static const String actionOpenStats = 'ACTION_OPEN_STATS';
  static const String actionOpenSettings = 'ACTION_OPEN_SETTINGS';

  // Category ID for Local Notification Actions
  static const String categoryWaterReminder = 'CATEGORY_WATER_REMINDER';

  // ──────────────────────────────────────────────────────────────────────────
  // SHAREDPREFERENCES KEYS
  // ──────────────────────────────────────────────────────────────────────────
  static const String prefsHistoryKey = 'h2o_notification_history_v2';
  static const String prefsPreferencesKey = 'h2o_notification_preferences_v2';
  static const String prefsAnalyticsKey = 'h2o_notification_analytics_v2';
  static const String prefsLastBootRestore = 'h2o_last_boot_restore_timestamp';

  // Default Sound & Icon
  static const String defaultNotificationIcon = '@mipmap/ic_launcher';


  // Logging Tag
  static const String logTag = '[NotificationPlatform]';
}
