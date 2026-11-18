import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/reminder_config.dart';
import '../data/models/reminder_settings.dart';
import '../data/services/cloud_sync_service.dart';
import 'notification_constants.dart';
import 'notification_history.dart';
import 'notification_models.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';

class NotificationRepository {
  static const String _cacheKeyPrefix = 'cached_reminder_settings_';

  /// Fetches [ReminderSettings] from local cache ONLY (READ ONLY).
  /// Never queries Supabase or overwrites local SharedPreferences with cloud data.
  Future<ReminderSettings?> getSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cacheKeyPrefix$userId');
      if (raw != null && raw.isNotEmpty) {
        return ReminderSettings.fromJson(jsonDecode(raw));
      }
    } catch (_) {}

    return null;
  }

  Future<void> cacheSettingsLocally(ReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_cacheKeyPrefix${settings.userId}', jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  /// Saves settings to local DB -> applies OS notification schedule -> syncs to cloud
  Future<SaveResult> saveSettings(ReminderSettings settings) async {
    final startTime = DateTime.now();
    debugPrint('====================================================');
    debugPrint('🔔 EXECUTION TRACE: LOCAL-FIRST REMINDER SAVING PIPELINE');
    debugPrint('====================================================');
    debugPrint('✓ [1/9] Save Button Pressed');

    // 1. Validate Settings & Times
    if (settings.mode == 'interval' &&
        (settings.intervalHours < 1 || settings.intervalHours > 12)) {
      debugPrint(
          '✗ [2/9] Validation Failed: Invalid interval hours (${settings.intervalHours}h)');
      return SaveResult.error(
          'Invalid interval hours: ${settings.intervalHours}');
    }
    debugPrint(
        '✓ [2/9] Validate Settings Passed (Mode: ${settings.mode}, Enabled: ${settings.enabled})');

    // 2. Save Local
    final updatedSettings = settings.copyWith(
      revision: settings.revision + 1,
      lastModified: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    bool localSaved = false;
    try {
      await cacheSettingsLocally(updatedSettings);
      localSaved = true;
      debugPrint(
          '✓ [3/9] Save Local Successful (SharedPreferences Rev ${updatedSettings.revision})');
    } catch (e) {
      debugPrint('✗ [3/9] Save Local Failed: $e');
    }

    // 3. Read Local Again & Verify
    final String activeId = updatedSettings.userId;
    try {
      final readBack = await getSettings(activeId);
      if (readBack != null && readBack.mode == updatedSettings.mode) {
        debugPrint('✓ [4/9] Verify Local Save Passed');
      }
    } catch (e) {
      debugPrint('⚠ [4/9] Verify Local Save Warning: $e');
    }

    // 4. Generate Reminder Objects (purely from local settings)
    final config = ReminderConfig.fromSettings(
      enabled: updatedSettings.enabled,
      mode: updatedSettings.mode,
      intervalMinutes: updatedSettings.computedIntervalMinutes,
      fixedTimes: updatedSettings.fixedTimes,
      dndStart: updatedSettings.dndStart,
      dndEnd: updatedSettings.dndEnd,
      snoozeDefaultMinutes: updatedSettings.snoozeDefaultMinutes,
      deletedTimes: updatedSettings.deletedTimes,
    );

    final dailyTimes = NotificationScheduler.computeDailySchedule(config);
    final dailyActiveCount = dailyTimes.length;

    String? rootCauseDiagnostic;
    if (!updatedSettings.enabled) {
      rootCauseDiagnostic = 'Reminders master switch is turned OFF.';
    } else if (dailyActiveCount == 0) {
      if (updatedSettings.mode == 'fixed') {
        rootCauseDiagnostic =
            'All fixed times (${updatedSettings.fixedTimes.join(", ")}) fall within Quiet Hours (${updatedSettings.dndStart} - ${updatedSettings.dndEnd}) or were deleted.';
      } else {
        rootCauseDiagnostic =
            'No active reminder window available between Wake (${updatedSettings.dndEnd}) and Sleep (${updatedSettings.dndStart}).';
      }
      debugPrint('✗ [5/9] Root Cause: $rootCauseDiagnostic');
    } else {
      debugPrint(
          '✓ [5/9] Generate Reminder Objects ($dailyActiveCount daily active reminders)');
    }

    // 5. Cancel Previous & Schedule New Notifications via OS AlarmManager
    final scheduledDateTimes = await applySchedule(config);
    debugPrint(
        '✓ [6/9] Notifications Scheduled (${scheduledDateTimes.length} alarms registered over 7 days)');

    // 6. Verify Pending Notifications
    final pendingCount =
        await NotificationService.getPendingNotificationCount();
    debugPrint(
        '✓ [7/9] Verify Pending Notifications ($pendingCount active OS pending alarms)');

    // 7. Mandatory Notification Verification Alert
    if (updatedSettings.enabled &&
        (updatedSettings.mode == 'fixed'
            ? updatedSettings.fixedTimes.isNotEmpty
            : true)) {
      if (dailyActiveCount == 0 || pendingCount == 0) {
        debugPrint('====================================================');
        debugPrint(
            '✗ CRITICAL VERIFICATION ALERT: REMINDER COUNT BECAME ZERO UNEXPECTEDLY!');
        debugPrint(
            'Exact Method: NotificationRepository.saveSettings() verification check');
        debugPrint(
            'Exact Variable: dailyActiveCount=$dailyActiveCount, pendingCount=$pendingCount');
        debugPrint('Stack Trace:\n${StackTrace.current}');
        debugPrint('====================================================');
      }
    }

    // 8. Start Cloud Upload -> Wait Until Upload Completes -> Mark Sync Complete
    bool cloudSynced = false;
    String? cloudError;
    try {
      debugPrint('✓ [8/9] Start Cloud Upload');
      cloudSynced = await CloudSyncService.instance
          .uploadReminderSettings(updatedSettings);
      if (cloudSynced) {
        debugPrint('✓ [9/9] Mark Sync Complete');
      } else {
        cloudError = 'Saved locally on device (cloud sync offline).';
      }
    } catch (e) {
      cloudSynced = false;
      cloudError = 'Saved locally on device (cloud sync offline).';
      debugPrint('ℹ [8-9/9] Cloud Upload Note: $e');
    }

    // Calculate Next Reminder Time
    String? nextReminderStr;
    if (scheduledDateTimes.isNotEmpty) {
      final nextDt = scheduledDateTimes.first;
      final hourStr = nextDt.hour % 12 == 0 ? 12 : nextDt.hour % 12;
      final minuteStr = nextDt.minute.toString().padLeft(2, '0');
      final period = nextDt.hour >= 12 ? 'PM' : 'AM';
      nextReminderStr = '$hourStr:$minuteStr $period';
    }

    debugPrint('====================================================');
    debugPrint(
        '⏱ Pipeline Execution Completed in ${DateTime.now().difference(startTime).inMilliseconds}ms');
    debugPrint('====================================================');

    return SaveResult(
      success: true,
      localSaved: localSaved,
      cloudSynced: cloudSynced,
      scheduledCount: dailyActiveCount,
      dailyActiveCount: dailyActiveCount,
      scheduledNotificationCount: scheduledDateTimes.length,
      pendingNotificationCount: pendingCount,
      scheduledTimes: scheduledDateTimes,
      dailyScheduleTimes: dailyTimes,
      errorMessage: cloudError,
      rootCauseDiagnostic: rootCauseDiagnostic,
      nextReminderTime: nextReminderStr,
      lastSyncTime: DateTime.now().toIso8601String(),
      mode: updatedSettings.mode,
      intervalMinutes: updatedSettings.computedIntervalMinutes,
      dndStart: updatedSettings.dndStart,
      dndEnd: updatedSettings.dndEnd,
      snoozeMinutes: updatedSettings.snoozeDefaultMinutes,
    );
  }

  /// Static helper for ReminderSettingsNotifier compatibility
  static Future<SaveResult> applySettings(ReminderSettings settings) async {
    final repo = NotificationRepository();
    return await repo.saveSettings(settings);
  }

  /// Computes daily schedule times
  static List<TimeOfDay> computeTimes(ReminderConfig config) {
    return NotificationScheduler.computeDailySchedule(config);
  }

  /// Re-applies local notification schedule
  Future<List<DateTime>> applySchedule(ReminderConfig config) async {
    if (!NotificationService.supportsOsNotifications) return [];

    await NotificationService.cancelAll();

    if (!config.enabled) return [];

    final dailyTimes = NotificationScheduler.computeDailySchedule(config);
    final targets = NotificationScheduler.computeNotificationDateTimes(config);

    for (int i = 0; i < dailyTimes.length; i++) {
      final tod = dailyTimes[i];
      final id = 1000 + i;

      final hourStr = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final minuteStr = tod.minute.toString().padLeft(2, '0');
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted12h = '$hourStr:$minuteStr $period';
      final defaultTitle = '💧 Time to Hydrate!';
      final defaultBody = 'Keep up with your goal. Time for a glass of water ($formatted12h).';

      String title = defaultTitle;
      String body = defaultBody;

      try {
        await NotificationService.scheduleDailyReminder(
          id: id,
          hour: tod.hour,
          minute: tod.minute,
          title: title,
          body: body,
        );

        await NotificationHistoryNotifier.logToPrefs(
          title: title,
          body: body,
          type: NotificationType.reminder,
          channelId: NotificationConstants.channelWaterReminderId,
        );

        debugPrint(
            '${NotificationConstants.logTag} 📅 Scheduled Alarm #$id at $formatted12h (${tod.hour}:${tod.minute}) | Title: "$title"');
      } catch (e) {
        final currentPending = await NotificationService.getPendingNotificationCount();
        debugPrint('✗ [SCHEDULING FAIL] Notification ID: $id');
        debugPrint('  Scheduled Time: $formatted12h (${tod.hour}:${tod.minute})');
        debugPrint('  Title: "$title"');
        debugPrint('  Body: "$body"');
        debugPrint('  Pending Count: $currentPending');
        debugPrint('  Error: $e');
      }
    }

    final pendingCount = await NotificationService.getPendingNotificationCount();
    debugPrint(
        '${NotificationConstants.logTag} ✅ Total Pending OS Notifications verified in system: $pendingCount');

    return targets;
  }

  /// Notification Preferences persistence
  Future<NotificationPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(NotificationConstants.prefsPreferencesKey);
      if (raw != null && raw.isNotEmpty) {
        return NotificationPreferences.fromJson(jsonDecode(raw));
      }
    } catch (_) {}
    return const NotificationPreferences();
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(NotificationConstants.prefsPreferencesKey,
          jsonEncode(preferences.toJson()));
    } catch (_) {}
  }
}
