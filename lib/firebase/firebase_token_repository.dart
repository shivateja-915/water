import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/supabase_service.dart';
import 'firebase_constants.dart';

class FirebaseTokenRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Saves token locally and syncs to Supabase users_profile if user is logged in
  Future<void> saveToken(String token) async {
    // 1. Cache token locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(FirebaseConstants.prefsFcmToken, token);
      await prefs.setString('fcm_token_updated_at', DateTime.now().toLocal().toString().split('.').first);
      if (kDebugMode) {
        debugPrint('${FirebaseConstants.logTag} FCM Token cached locally: $token');
      }
    } catch (e) {
      debugPrint('${FirebaseConstants.logTag} Failed to cache FCM token locally: $e');
    }

    // 2. Sync to Supabase if logged in
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      await syncTokenToSupabase(currentUser.id, token);
    }
  }

  /// Syncs given FCM token to Supabase for the specified userId
  Future<void> syncTokenToSupabase(String userId, String token) async {
    try {
      await _client.from('users_profile').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (kDebugMode) {
        debugPrint(
            '${FirebaseConstants.logTag} ✅ FCM Token successfully saved to Supabase profile for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '${FirebaseConstants.logTag} ⚠️ Supabase token sync note: $e (column fcm_token may need to be added to users_profile table if not present)');
      }
    }
  }

  /// Gets cached token from SharedPreferences
  Future<String?> getCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(FirebaseConstants.prefsFcmToken);
    } catch (_) {
      return null;
    }
  }
}
