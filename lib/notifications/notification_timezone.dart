import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_constants.dart';

class NotificationTimezone {
  NotificationTimezone._();

  /// Ensures timezone database is ready and returns local Location
  static tz.Location get localLocation {
    try {
      return tz.local;
    } catch (_) {
      return tz.getLocation('UTC');
    }
  }

  /// Converts standard DateTime into tz.TZDateTime for exact alarm scheduling
  static tz.TZDateTime toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, localLocation);
  }

  /// Verifies timezone offset and prints log info
  static String getTimezoneInfo() {
    try {
      final loc = tz.local;
      final now = tz.TZDateTime.now(loc);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes % 60).abs();
      final sign = hours >= 0 ? '+' : '-';
      return '${loc.name} (UTC$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')})';
    } catch (e) {
      return 'UTC (Fallback: $e)';
    }
  }

  static void logStatus() {
    debugPrint('${NotificationConstants.logTag} 🌐 Timezone initialized: ${getTimezoneInfo()}');
  }
}
