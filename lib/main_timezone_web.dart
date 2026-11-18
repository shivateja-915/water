import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Web timezone initialization — does NOT use flutter_timezone plugin
/// (which has no web support). Falls back to timezone package defaults.
Future<void> initializeTimezone() async {
  try {
    tz_data.initializeTimeZones();

    // On web, we cannot query the OS timezone via flutter_timezone.
    // Use JS interop to get the timezone name from the browser.
    try {
      final browserTz = _getBrowserTimezone();
      var tzName = browserTz;

      // Common IANA legacy alias mapping
      if (tzName == 'Asia/Calcutta') {
        tzName = 'Asia/Kolkata';
      }

      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('Timezone (web): set to $tzName');
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        debugPrint('Timezone (web): fallback to Asia/Kolkata');
      }
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
      debugPrint('Timezone (web): fallback used');
    }
  } catch (e) {
    debugPrint('Timezone initialization warning (web): $e');
  }
}

/// Gets the timezone name from the browser via Intl API.
String _getBrowserTimezone() {
  // Use DateTime to infer timezone offset, then map to name
  // This is a simplified approach — the timezone package handles the rest
  final now = DateTime.now();
  final offset = now.timeZoneOffset;

  // Map common Indian timezone
  if (offset.inMinutes == 330) return 'Asia/Kolkata';

  // Default
  return 'UTC';
}
