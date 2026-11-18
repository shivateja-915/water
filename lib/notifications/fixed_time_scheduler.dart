import 'package:flutter/material.dart' show TimeOfDay;

/// Pure fixed-time scheduling algorithm.
///
/// Takes a list of user-specified times, filters out DND times,
/// and returns a sorted list.
///
/// ZERO side effects. ZERO platform dependencies.
class FixedTimeScheduler {
  FixedTimeScheduler._();

  /// Returns sorted [TimeOfDay] list from user-specified time strings.
  ///
  /// [fixedTimes] = user-selected times (e.g., ["08:00", "10:30", "14:15"])
  /// [dndStart] = start of DND window (e.g., "23:00")
  /// [dndEnd] = end of DND window (e.g., "07:00")
  static List<TimeOfDay> generate({
    required List<String> fixedTimes,
    required String dndStart,
    required String dndEnd,
  }) {
    final times = fixedTimes
        .map(_parseTime)
        .where((t) => !_isWithinDnd(t, dndStart, dndEnd))
        .toList();
    times.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return times;
  }

  /// Helper to convert a list of HH:mm strings to [TimeOfDay] list.
  static List<TimeOfDay> parseList(List<String> fixedTimes) {
    final list = fixedTimes.map(_parseTime).toList();
    list.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return list;
  }

  static TimeOfDay _parseTime(String timeStr) {
    final clean = timeStr.trim();
    final isPm = clean.toUpperCase().contains('PM');
    final isAm = clean.toUpperCase().contains('AM');
    final numericOnly = clean.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = numericOnly.split(':');

    int hour = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return TimeOfDay(hour: hour % 24, minute: minute % 60);
  }

  /// Returns true if [t] falls within the DND window.
  /// Handles overnight wrapping (e.g., 23:00 → 07:00).
  static bool _isWithinDnd(TimeOfDay t, String dndStart, String dndEnd) {
    final start = _parseTime(dndStart);
    final end = _parseTime(dndEnd);
    final tMin = t.hour * 60 + t.minute;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;

    if (startMin <= endMin) {
      // Daytime DND (e.g., 09:00–17:00)
      return tMin >= startMin && tMin < endMin;
    } else {
      // Overnight DND (e.g., 23:00–07:00)
      return tMin >= startMin || tMin < endMin;
    }
  }
}
