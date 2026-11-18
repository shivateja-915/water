import 'package:flutter/material.dart';
import '../data/models/reminder_config.dart';
import 'interval_scheduler.dart';
import 'fixed_time_scheduler.dart';
import 'notification_validator.dart';

class NotificationScheduler {
  NotificationScheduler._();

  /// Computes active reminder daily schedule times (as TimeOfDay) considering DND and deleted times.
  static List<TimeOfDay> computeDailySchedule(ReminderConfig config) {
    if (!config.enabled) return [];

    List<TimeOfDay> computed = [];

    if (config.mode == ReminderMode.interval || config.mode == ReminderMode.both) {
      computed = IntervalScheduler.generate(
        wakeTime: config.dndEnd,
        sleepTime: config.dndStart,
        intervalMinutes: config.intervalMinutes,
      );
      // Filter out manually deleted times for interval mode
      if (config.deletedTimes.isNotEmpty) {
        final deletedSet = config.deletedTimes.toSet();
        computed = computed.where((t) {
          final timeStr =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          return !deletedSet.contains(timeStr);
        }).toList();
      }
    }
    
    if (config.mode == ReminderMode.fixed || config.mode == ReminderMode.both) {
      computed.addAll(FixedTimeScheduler.parseList(config.fixedTimes));
    }

    return NotificationValidator.deduplicateTimes(computed);
  }

  /// Calculates upcoming DateTime targets for scheduling local notifications over [daysAhead] days.
  static List<DateTime> computeNotificationDateTimes(
    ReminderConfig config, {
    int daysAhead = 7,
    DateTime? nowOverride,
  }) {
    final dailyTimes = computeDailySchedule(config);
    if (dailyTimes.isEmpty) return [];

    final now = nowOverride ?? DateTime.now();
    final List<DateTime> targets = [];

    for (int day = 0; day < daysAhead; day++) {
      final targetDate = now.add(Duration(days: day));

      for (final tod in dailyTimes) {
        final targetDt = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          tod.hour,
          tod.minute,
        );

        if (targetDt.isAfter(now)) {
          targets.add(targetDt);
        }
      }
    }

    targets.sort();
    return targets;
  }

  /// Computes a single snooze target DateTime (5, 15, 30 minutes from now)
  /// without modifying or clearing the main reminder schedule.
  static DateTime computeSnoozeTarget(int snoozeMinutes) {
    return DateTime.now().add(Duration(minutes: snoozeMinutes));
  }
}
