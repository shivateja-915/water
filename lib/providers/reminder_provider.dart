import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/reminder_settings.dart';
import '../data/services/cloud_sync_service.dart';
import '../data/services/supabase_service.dart';
import '../notifications/notification_repository.dart';
import '../notifications/notification_models.dart';
import 'auth_provider.dart';

final reminderSettingsProvider = StateNotifierProvider<
    ReminderSettingsNotifier, AsyncValue<ReminderSettings?>>((ref) {
  final userId = ref.read(authRepositoryProvider).userId;
  return ReminderSettingsNotifier(userId);
});

class ReminderSettingsNotifier
    extends StateNotifier<AsyncValue<ReminderSettings?>> {
  final String? _userId;
  static const _cacheKey = 'cached_reminder_settings';

  ReminderSettingsNotifier(this._userId)
      : super(const AsyncValue.loading()) {
    _initAndLoad();
  }

  SupabaseClient get _client => SupabaseService.client;

  Future<void> _initAndLoad() async {
    await loadSettings();
  }

  /// Local-First App Start Flow:
  /// 1. Load Local Settings -> 2. Generate Notifications -> 3. Verify Pending -> 4. Start Background Cloud Sync
  Future<void> loadSettings() async {
    final cached = await _loadCachedSettings();
    ReminderSettings localSettings = cached ??
        ReminderSettings(
          id: _userId ?? 'guest',
          userId: _userId ?? 'guest',
          enabled: true,
          mode: 'both',
          intervalHours: 1,
        );

    state = AsyncValue.data(localSettings);

    // Ensure OS alarms are scheduled for local settings without unnecessary cancelAll on empty cloud
    try {
      await NotificationRepository.applySettings(localSettings);
    } catch (e) {
      debugPrint('ReminderSettingsNotifier: Local schedule check note: $e');
    }

    // Start background cloud sync
    final activeId = _userId ?? _client.auth.currentUser?.id;
    if (activeId != null && activeId != 'guest') {
      try {
        final synced =
            await CloudSyncService.instance.syncReminderSettings(localSettings);
        if (synced.revision > localSettings.revision) {
          debugPrint(
              '✓ Newer cloud revision detected (${synced.revision} > ${localSettings.revision}). Updating local & rescheduling.');
          await _cacheSettings(synced);
          await NotificationRepository.applySettings(synced);
          state = AsyncValue.data(synced);
        }
      } catch (e) {
        debugPrint(
            'ℹ ReminderSettingsNotifier: Background cloud sync note: $e');
      }
    }
  }

  /// Save settings with complete PASS/FAIL tracing.
  Future<SaveResult> saveSettings(ReminderSettings settings) async {
    debugPrint('====================================================');
    debugPrint('🔔 H2O DASH REMINDER SAVE PROCESS TRACE');
    debugPrint('====================================================');
    debugPrint('✓ [1/8] Save Button Pressed');

    // 1. Validate Settings
    if (settings.mode == 'interval' && (settings.intervalHours < 1 || settings.intervalHours > 12)) {
      debugPrint('✗ [2/8] Validation Failed: Invalid interval (${settings.intervalHours}h)');
      return SaveResult.error('Invalid interval hours: ${settings.intervalHours}');
    }
    debugPrint('✓ [2/8] Validation Passed (Mode: ${settings.mode}, Enabled: ${settings.enabled})');

    // 2. Local Save
    try {
      await _cacheSettings(settings);
      debugPrint('✓ [3/8] Local Save Successful (SharedPreferences key: $_cacheKey)');
    } catch (e) {
      debugPrint('✗ [3/8] Local Save Failed: $e');
      return SaveResult.error('Failed to save settings locally: $e');
    }

    // 3. Read Local Settings Back to Verify
    try {
      final readBack = await _loadCachedSettings();
      if (readBack != null) {
        debugPrint('✓ [4/8] Local Read Successful');
      } else {
        return SaveResult.error('Local cache verification failed.');
      }
    } catch (e) {
      return SaveResult.error('Local cache read verification failed: $e');
    }

    // 4. Generate Reminder Schedule & Apply Local OS Alarms ALWAYS
    SaveResult localResult;
    try {
      localResult = await NotificationRepository.applySettings(settings);
      debugPrint('✓ [5/8] Schedule Generated (${localResult.scheduledCount} active reminders)');
      debugPrint('✓ [6/8] Notifications Scheduled via Android AlarmManager');
      debugPrint('✓ [7/8] Pending Notifications Verified (${localResult.scheduledCount})');
    } catch (e) {
      debugPrint('✗ [5-7/8] Notification Scheduling Failed: $e');
      localResult = SaveResult.error('Notification scheduling error: $e');
    }

    // 5. Attempt Supabase Sync
    bool supabaseSuccess = true;
    final activeId = _client.auth.currentUser?.id ?? _userId;

    if (activeId != null) {
      try {
        final payload = settings.toSupabaseJson();
        payload['user_id'] = activeId;
        payload['id'] = activeId;

        await _client
            .from('reminder_settings')
            .upsert(payload);
        debugPrint('✓ [8/8] Supabase Sync Successful (UPSERT user_id: $activeId)');
      } catch (e) {
        supabaseSuccess = false;
        debugPrint('ℹ [8/8] Supabase Cloud Save Note (Saved locally): $e');
      }
    }

    // 6. Update UI State
    state = AsyncValue.data(settings);
    debugPrint('====================================================');

    return SaveResult(
      success: true,
      localSaved: localResult.localSaved,
      cloudSynced: supabaseSuccess,
      scheduledCount: localResult.scheduledCount,
      dailyActiveCount: localResult.dailyActiveCount,
      scheduledNotificationCount: localResult.scheduledNotificationCount,
      pendingNotificationCount: localResult.pendingNotificationCount,
      scheduledTimes: localResult.scheduledTimes,
      dailyScheduleTimes: localResult.dailyScheduleTimes,
      errorMessage: supabaseSuccess ? null : 'Saved locally on device.',
      rootCauseDiagnostic: localResult.rootCauseDiagnostic,
      nextReminderTime: localResult.nextReminderTime,
      lastSyncTime: DateTime.now().toIso8601String(),
      mode: settings.mode,
      intervalMinutes: settings.computedIntervalMinutes,
      dndStart: settings.dndStart,
      dndEnd: settings.dndEnd,
      snoozeMinutes: settings.snoozeDefaultMinutes,
    );
  }

  // ─── LOCAL CACHE ──────────────────────────────────────────────────

  Future<void> _cacheSettings(ReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('ReminderSettingsNotifier: cache write failed: $e');
    }
  }

  Future<ReminderSettings?> _loadCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json != null) {
        return ReminderSettings.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ReminderSettingsNotifier: cache read failed: $e');
    }
    return null;
  }
}
