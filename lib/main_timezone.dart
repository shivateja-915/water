import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Native timezone initialization — uses flutter_timezone plugin.
Future<void> initializeTimezone() async {
  try {
    tz_data.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      var tzName = timeZoneInfo.identifier;

      // Common IANA legacy alias mapping (Windows/Chrome in India returns Asia/Calcutta)
      if (tzName == 'Asia/Calcutta') {
        tzName = 'Asia/Kolkata';
      }

      try {
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  } catch (e) {
    debugPrint('Timezone initialization warning: $e');
  }
}
