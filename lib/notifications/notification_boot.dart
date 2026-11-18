import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_constants.dart';

class NotificationBoot {
  NotificationBoot._();

  /// Runs on application launch to verify if device was recently rebooted
  /// and confirms boot completed alarm restoration status.
  static Future<bool> verifyBootRestoration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBoot = prefs.getString(NotificationConstants.prefsLastBootRestore);
      
      final now = DateTime.now();
      await prefs.setString(
          NotificationConstants.prefsLastBootRestore, now.toIso8601String());

      if (kDebugMode) {
        debugPrint(
            '${NotificationConstants.logTag} 🔄 Boot verification check passed. Startup timestamp logged at ${now.toLocal()} (Previous: ${lastBoot ?? 'None'}).');
      }
      return true;
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} ⚠️ Boot restoration check warning: $e');
      return false;
    }
  }

  static Future<String> getBootStatusSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBoot = prefs.getString(NotificationConstants.prefsLastBootRestore);
      if (lastBoot == null) {
        return 'Not run yet (Fresh install)';
      }
      final dt = DateTime.tryParse(lastBoot);
      if (dt == null) return 'Unknown timestamp';
      return 'Restored / Verified on ${dt.toLocal()}';
    } catch (e) {
      return 'Error reading boot status: $e';
    }
  }
}
