import 'package:flutter/material.dart' show TimeOfDay;

/// Validates reminder times for duplicates across modes.
///
/// Used BEFORE saving to prevent scheduling duplicate notifications.
class NotificationValidator {
  NotificationValidator._();

  /// Checks if [candidateTime] already exists in [existingTimes].
  ///
  /// Returns the matching time string if duplicate found, null otherwise.
  static String? findDuplicate(
    TimeOfDay candidateTime,
    List<TimeOfDay> existingTimes,
  ) {
    for (final existing in existingTimes) {
      if (existing.hour == candidateTime.hour &&
          existing.minute == candidateTime.minute) {
        return _formatTime(existing);
      }
    }
    return null;
  }

  /// Finds ALL duplicate times between two lists.
  ///
  /// Used during save validation to catch cross-mode conflicts.
  /// Returns list of duplicate time strings (e.g., ["15:00", "17:00"]).
  static List<String> findAllDuplicates(
    List<TimeOfDay> listA,
    List<TimeOfDay> listB,
  ) {
    final duplicates = <String>[];
    final setB = <String>{};

    for (final t in listB) {
      setB.add(_formatTime(t));
    }

    for (final t in listA) {
      final key = _formatTime(t);
      if (setB.contains(key)) {
        duplicates.add(key);
      }
    }

    return duplicates;
  }

  /// Checks if a time string already exists in a list of time strings.
  static bool isDuplicateTimeString(
      String timeString, List<String> existingTimeStrings) {
    return existingTimeStrings.contains(timeString);
  }

  /// Deduplicates a list of TimeOfDay instances.
  static List<TimeOfDay> deduplicateTimes(List<TimeOfDay> times) {
    final seen = <String>{};
    final unique = <TimeOfDay>[];
    for (final t in times) {
      final key = _formatTime(t);
      if (seen.add(key)) {
        unique.add(t);
      }
    }
    return unique;
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
