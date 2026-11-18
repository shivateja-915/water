import 'package:shared_preferences/shared_preferences.dart';

class DeveloperPreferencesRepository {
  static const String _unlockedKey = 'h2o_developer_mode_unlocked';

  Future<bool> getIsUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_unlockedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setIsUnlocked(bool unlocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_unlockedKey, unlocked);
    } catch (_) {}
  }
}
