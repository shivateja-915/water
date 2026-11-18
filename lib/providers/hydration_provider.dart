import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/hydration_log.dart';
import '../data/models/drink_type.dart';
import '../data/repositories/hydration_log_repository.dart';
import '../data/repositories/profile_repository.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

final hydrationLogRepositoryProvider =
    Provider<HydrationLogRepository>((ref) => HydrationLogRepository());

final selectedHistoryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Reactive userId provider that updates when auth state changes
final _userIdProvider = Provider<String?>((ref) {
  // Watch the auth state stream so this updates on login/logout
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).userId;
});

final todayLogsProvider =
    StateNotifierProvider<TodayLogsNotifier, AsyncValue<List<HydrationLog>>>(
        (ref) {
  final repo = ref.read(hydrationLogRepositoryProvider);
  final userId = ref.watch(_userIdProvider);
  final profileRepo = ref.read(profileRepositoryProvider);
  return TodayLogsNotifier(repo, profileRepo, userId, onStreakUpdated: () {
    ref.invalidate(profileProvider);
  });
});

class TodayLogsNotifier
    extends StateNotifier<AsyncValue<List<HydrationLog>>> {
  final HydrationLogRepository _repo;
  final ProfileRepository _profileRepo;
  final String? _userId;
  final VoidCallback? onStreakUpdated;

  TodayLogsNotifier(this._repo, this._profileRepo, this._userId, {this.onStreakUpdated})
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadTodayLogs();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadTodayLogs() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final logs = await _repo.getLogsForDate(_userId, DateTime.now());
      state = AsyncValue.data(logs);
      await _validateStreak(logs.isNotEmpty);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<HydrationLog?> addLog({
    required int amountMl,
    required DrinkType drinkType,
    DateTime? loggedAt,
  }) async {
    if (_userId == null) return null;
    final hydratedMl =
        (amountMl * drinkType.hydrationMultiplier).round();
    final now = loggedAt ?? DateTime.now();
    final log = HydrationLog(
      id: const Uuid().v4(),
      userId: _userId,
      drinkTypeId: drinkType.id,
      amountMl: amountMl,
      hydratedMl: hydratedMl,
      loggedAt: now,
      drinkTypeName: drinkType.name,
      drinkTypeIcon: drinkType.icon,
      drinkTypeColor: drinkType.color,
    );

    try {
      // Check if this is the first log of the day (before adding)
      final existingLogs = state.valueOrNull ?? [];
      final isFirstLogToday = existingLogs.isEmpty;

      await _repo.addLog(log);
      await loadTodayLogs();

      // Update streak if this is the first log today
      if (isFirstLogToday) {
        await _updateStreak();
      }

      return log;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateStreak() async {
    if (_userId == null) return;
    try {
      final profile = await _profileRepo.getProfile(_userId);
      if (profile == null) return;

      // Check if the user logged anything yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayLogs = await _repo.getLogsForDate(_userId, yesterday);

      int newStreak;
      if (yesterdayLogs.isNotEmpty) {
        // Continue the streak
        newStreak = profile.streakCurrent + 1;
      } else {
        // Start a new streak
        newStreak = 1;
      }

      final newLongest = newStreak > profile.streakLongest
          ? newStreak
          : profile.streakLongest;

      await _profileRepo.updateStreak(_userId, newStreak, newLongest);
      onStreakUpdated?.call();
    } catch (_) {
      // Don't break adding logs if streak update fails
    }
  }

  Future<void> updateLog(HydrationLog log) async {
    try {
      await _repo.updateLog(log);
      await loadTodayLogs();
    } catch (_) {}
  }

  Future<void> deleteLog(String logId) async {
    try {
      await _repo.deleteLog(logId);
      final userId = _userId;
      if (userId != null) {
        final logs = await _repo.getLogsForDate(userId, DateTime.now());
        if (logs.isEmpty) {
          await _revertStreak();
        }
      }
      await loadTodayLogs();
    } catch (_) {}
  }

  Future<void> _validateStreak(bool hasLogsToday) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final profile = await _profileRepo.getProfile(userId);
      if (profile == null) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayLogs = await _repo.getLogsForDate(userId, yesterday);
      
      int correctStreak = profile.streakCurrent;
      
      if (!hasLogsToday && yesterdayLogs.isEmpty) {
        // No logs today, and missed yesterday. Streak is dead.
        correctStreak = 0;
      }
      
      if (correctStreak == 0 && profile.streakCurrent > 0) {
        await _profileRepo.updateStreak(userId, 0, profile.streakLongest);
        onStreakUpdated?.call();
      }
    } catch (_) {}
  }

  Future<void> _revertStreak() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final profile = await _profileRepo.getProfile(userId);
      if (profile == null) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayLogs = await _repo.getLogsForDate(userId, yesterday);
      
      int revertedStreak = 0;
      if (yesterdayLogs.isNotEmpty) {
        revertedStreak = (profile.streakCurrent - 1).clamp(0, 9999);
      }
      
      await _profileRepo.updateStreak(userId, revertedStreak, profile.streakLongest);
      onStreakUpdated?.call();
    } catch (_) {}
  }

  int get todayTotal {
    final logs = state.valueOrNull ?? [];
    return logs.fold<int>(0, (sum, log) => sum + log.hydratedMl);
  }

  int get todayRawTotal {
    final logs = state.valueOrNull ?? [];
    return logs.fold<int>(0, (sum, log) => sum + log.amountMl);
  }
}

/// Provider for logs of a specific date (for History screen)
final dateLogsProvider = FutureProvider.family<List<HydrationLog>, DateTime>(
    (ref, date) async {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (isToday) {
    final todayLogs = ref.watch(todayLogsProvider);
    return todayLogs.valueOrNull ?? [];
  }
  ref.watch(todayLogsProvider);
  final repo = ref.read(hydrationLogRepositoryProvider);
  final userId = ref.watch(_userIdProvider);
  if (userId == null) return [];
  return repo.getLogsForDate(userId, date);
});

/// Provider for logs within a date range (for Stats)
final dateRangeLogsProvider = FutureProvider.family<List<HydrationLog>,
    ({DateTime start, DateTime end})>((ref, range) async {
  ref.watch(todayLogsProvider);
  final repo = ref.read(hydrationLogRepositoryProvider);
  final userId = ref.watch(_userIdProvider);
  if (userId == null) return [];
  return repo.getLogsForDateRange(userId, range.start, range.end);
});
