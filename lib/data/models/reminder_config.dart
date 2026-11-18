/// Typed in-app representation of a user's reminder configuration.
///
/// Mirrors the reminder_settings Supabase table without carrying any
/// Supabase or network dependency. This model is the sole input to
/// the scheduling algorithms and NotificationService.
enum ReminderMode { interval, fixed, both }

class ReminderConfig {
  final bool enabled;
  final ReminderMode mode;
  final int intervalMinutes;
  final List<String> fixedTimes; // "HH:mm" 24-hour strings
  final String dndStart; // "HH:mm" - start of the blocked window
  final String dndEnd; // "HH:mm" - end of the blocked window
  final int snoozeMinutesDefault; // 5, 15, or 30
  final List<String> deletedTimes; // interval times user manually removed

  const ReminderConfig({
    required this.enabled,
    required this.mode,
    required this.intervalMinutes,
    required this.fixedTimes,
    required this.dndStart,
    required this.dndEnd,
    required this.snoozeMinutesDefault,
    this.deletedTimes = const [],
  });

  /// Convenience factory: create a [ReminderConfig] from the DB-facing
  /// [ReminderSettings] model that already exists.
  factory ReminderConfig.fromSettings({
    required bool enabled,
    required String mode,
    required int intervalMinutes,
    required List<String> fixedTimes,
    required String dndStart,
    required String dndEnd,
    required int snoozeDefaultMinutes,
    List<String> deletedTimes = const [],
  }) {
    ReminderMode mappedMode;
    final lowercaseMode = mode.toLowerCase();
    if (lowercaseMode == 'both') {
      mappedMode = ReminderMode.both;
    } else if (lowercaseMode.contains('fixed')) {
      mappedMode = ReminderMode.fixed;
    } else {
      mappedMode = ReminderMode.interval;
    }

    return ReminderConfig(
      enabled: enabled,
      mode: mappedMode,
      intervalMinutes: intervalMinutes,
      fixedTimes: fixedTimes,
      dndStart: dndStart,
      dndEnd: dndEnd,
      snoozeMinutesDefault: snoozeDefaultMinutes,
      deletedTimes: deletedTimes,
    );
  }
}
