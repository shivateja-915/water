import 'package:flutter/material.dart' show TimeOfDay;

/// Pure interval scheduling algorithm.
///
/// Takes DND window boundaries (wake/sleep times) and an interval,
/// generates every reminder time in the active window.
///
/// ZERO side effects. ZERO platform dependencies.
/// Same input → always same output.
class IntervalScheduler {
  IntervalScheduler._();

  /// Generates a sorted list of reminder times.
  ///
  /// [wakeTime] = DND end (e.g., "07:00")
  /// [sleepTime] = DND start (e.g., "23:00")
  /// [intervalMinutes] = gap between reminders (e.g., 120)
  /// [deletedTimes] = times the user manually removed (e.g., ["13:00"])
  ///
  /// Returns sorted [TimeOfDay] list with deleted times excluded.
  static List<TimeOfDay> generate({
    required String wakeTime,
    required String sleepTime,
    required int intervalMinutes,
    List<String> deletedTimes = const [],
  }) {
    final wake = _parseTime(wakeTime);
    final sleep = _parseTime(sleepTime);

    if (intervalMinutes <= 0) return [];

    final activeMinutes = _minutesBetween(wake, sleep);
    if (activeMinutes <= 0) return [];

    final deletedSet = deletedTimes.toSet();
    final times = <TimeOfDay>[];

    for (var elapsed = 0; elapsed < activeMinutes; elapsed += intervalMinutes) {
      final totalMinutes =
          ((wake.hour * 60 + wake.minute) + elapsed) % (24 * 60);
      final time =
          TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);

      // Skip user-deleted times
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!deletedSet.contains(timeStr)) {
        times.add(time);
      }
    }

    return times;
  }

  /// Generates ALL times (including deleted) — used for chip display
  /// where deleted chips need to be shown as removed.
  static List<TimeOfDay> generateAll({
    required String wakeTime,
    required String sleepTime,
    required int intervalMinutes,
  }) {
    return generate(
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      intervalMinutes: intervalMinutes,
      deletedTimes: const [],
    );
  }

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  static int _minutesBetween(TimeOfDay from, TimeOfDay to) {
    final fromMin = from.hour * 60 + from.minute;
    final toMin = to.hour * 60 + to.minute;
    return ((toMin - fromMin) + 24 * 60) % (24 * 60);
  }
}
