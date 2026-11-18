import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hydration_log.dart';
import '../services/supabase_service.dart';

class HydrationLogRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<HydrationLog>> getLogsForDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('hydration_logs')
        .select('*, drink_types(*)')
        .eq('user_id', userId)
        .gte('logged_at', startOfDay.toUtc().toIso8601String())
        .lt('logged_at', endOfDay.toUtc().toIso8601String())
        .order('logged_at', ascending: false);

    return (response as List)
        .map((e) => HydrationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HydrationLog>> getLogsForDateRange(
      String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('hydration_logs')
        .select('*, drink_types(*)')
        .eq('user_id', userId)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: false);

    return (response as List)
        .map((e) => HydrationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HydrationLog>> getAllLogs(String userId) async {
    final response = await _client
        .from('hydration_logs')
        .select('*, drink_types(*)')
        .eq('user_id', userId)
        .order('logged_at', ascending: false);

    return (response as List)
        .map((e) => HydrationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HydrationLog> addLog(HydrationLog log) async {
    await _client.from('hydration_logs').insert(log.toJson());
    return log;
  }

  Future<HydrationLog> updateLog(HydrationLog log) async {
    await _client
        .from('hydration_logs')
        .update(log.toJson())
        .eq('id', log.id);
    return log;
  }

  Future<void> deleteLog(String logId) async {
    await _client.from('hydration_logs').delete().eq('id', logId);
  }

  Future<int> getTotalForDate(String userId, DateTime date) async {
    final logs = await getLogsForDate(userId, date);
    return logs.fold<int>(0, (sum, log) => sum + log.hydratedMl);
  }

  Future<Map<String, int>> getDrinkTypeBreakdown(
      String userId, DateTime start, DateTime end) async {
    final logs = await getLogsForDateRange(userId, start, end);
    final breakdown = <String, int>{};
    for (final log in logs) {
      final name = log.drinkTypeName ?? 'Unknown';
      breakdown[name] = (breakdown[name] ?? 0) + log.amountMl;
    }
    return breakdown;
  }

  /// Get hourly intake pattern (hour -> total ml)
  Future<Map<int, int>> getHourlyPattern(
      String userId, DateTime start, DateTime end) async {
    final logs = await getLogsForDateRange(userId, start, end);
    final pattern = <int, int>{};
    for (final log in logs) {
      final hour = log.loggedAt.hour;
      pattern[hour] = (pattern[hour] ?? 0) + log.amountMl;
    }
    return pattern;
  }
}
