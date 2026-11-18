import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const String _cacheKeyPrefix = 'cached_user_profile_';

  Future<UserProfile?> getProfile(String userId) async {
    UserProfile? cachedProfile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('$_cacheKeyPrefix$userId');
      if (rawJson != null && rawJson.isNotEmpty) {
        cachedProfile = UserProfile.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
      }
    } catch (_) {}

    try {
      final response = await _client
          .from('users_profile')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        var remoteProfile = UserProfile.fromJson(response);
        // If remote profile is missing extended fields or personal info, merge from local cache
        if (cachedProfile != null) {
          remoteProfile = remoteProfile.copyWith(
            name: remoteProfile.name ?? cachedProfile.name,
            phone: remoteProfile.phone ?? cachedProfile.phone,
            country: remoteProfile.country ?? cachedProfile.country,
            dateOfBirth: remoteProfile.dateOfBirth ?? cachedProfile.dateOfBirth,
            weight: remoteProfile.weight ?? cachedProfile.weight,
            height: remoteProfile.height ?? cachedProfile.height,
            gender: remoteProfile.gender ?? cachedProfile.gender,
            wakeTime: remoteProfile.wakeTime ?? cachedProfile.wakeTime,
            sleepTime: remoteProfile.sleepTime ?? cachedProfile.sleepTime,
            avatarSeed: remoteProfile.avatarSeed ?? cachedProfile.avatarSeed,
            avatarBackgroundColor:
                remoteProfile.avatarBackgroundColor ?? cachedProfile.avatarBackgroundColor,
            avatarShapeColor:
                remoteProfile.avatarShapeColor ?? cachedProfile.avatarShapeColor,
            avatarFlip: remoteProfile.avatarFlip ?? cachedProfile.avatarFlip,
            avatarRotate: remoteProfile.avatarRotate ?? cachedProfile.avatarRotate,
            avatarScale: remoteProfile.avatarScale ?? cachedProfile.avatarScale,
            avatarUrl: remoteProfile.avatarUrl ?? cachedProfile.avatarUrl,
          );
        }
        await _cacheProfileLocally(remoteProfile);
        return remoteProfile;
      }
    } catch (_) {
      // Fallback to local cached profile on network or database failure
      if (cachedProfile != null) return cachedProfile;
    }

    return cachedProfile;
  }

  Future<void> _cacheProfileLocally(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(profile.toLocalJson());
      await prefs.setString('$_cacheKeyPrefix${profile.id}', jsonStr);
    } catch (_) {}
  }

  Future<UserProfile> createProfile(UserProfile profile) async {
    await _cacheProfileLocally(profile);
    try {
      await _client.from('users_profile').insert(profile.toCoreSupabaseJson());
    } catch (_) {
      try {
        await _client.from('users_profile').insert({
          'id': profile.id,
          'onboarding_completed': profile.onboardingCompleted,
          'daily_goal_ml': profile.dailyGoalMl,
        });
      } catch (_) {}
    }
    return profile;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    await _cacheProfileLocally(profile);
    try {
      await _client
          .from('users_profile')
          .upsert(profile.toCoreSupabaseJson());
    } catch (e) {
      // Fallback: update core essential columns if remote schema rejects optional fields
      try {
        final coreMap = <String, dynamic>{
          'id': profile.id,
          'onboarding_completed': profile.onboardingCompleted,
        };
        if (profile.name != null) coreMap['name'] = profile.name;
        if (profile.email != null) coreMap['email'] = profile.email;
        if (profile.weight != null) coreMap['weight'] = profile.weight;
        if (profile.dailyGoalMl != 0) coreMap['daily_goal_ml'] = profile.dailyGoalMl;
        if (profile.dateOfBirth != null) {
          coreMap['date_of_birth'] =
              "${profile.dateOfBirth!.year.toString().padLeft(4, '0')}-${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-${profile.dateOfBirth!.day.toString().padLeft(2, '0')}";
        }
        if (profile.wakeTime != null) coreMap['wake_time'] = profile.wakeTime;
        if (profile.sleepTime != null) coreMap['sleep_time'] = profile.sleepTime;
        if (profile.avatarSeed != null) coreMap['avatar_seed'] = profile.avatarSeed;
        if (profile.avatarBackgroundColor != null) coreMap['avatar_background_color'] = profile.avatarBackgroundColor;
        if (profile.avatarShapeColor != null) coreMap['avatar_shape_color'] = profile.avatarShapeColor;
        if (profile.avatarFlip != null) coreMap['avatar_flip'] = profile.avatarFlip;
        if (profile.avatarRotate != null) coreMap['avatar_rotate'] = profile.avatarRotate;
        if (profile.avatarScale != null) coreMap['avatar_scale'] = profile.avatarScale;
        await _client.from('users_profile').upsert(coreMap);
      } catch (_) {}
    }
    return profile;
  }

  Future<void> updateField(String userId, String field, dynamic value) async {
    try {
      await _client
          .from('users_profile')
          .update({field: value}).eq('id', userId);
    } catch (_) {}
  }

  Future<String?> uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final publicUrl =
        _client.storage.from('avatars').getPublicUrl(filePath);

    await updateField(userId, 'avatar_url', publicUrl);
    return publicUrl;
  }

  Future<void> deleteAllUserData(String userId) async {
    // Delete local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$userId');
    } catch (_) {}

    // Delete hydration logs
    await _client.from('hydration_logs').delete().eq('user_id', userId);
    // Delete reminder settings
    await _client.from('reminder_settings').delete().eq('user_id', userId);
    // Delete container presets
    await _client.from('container_presets').delete().eq('user_id', userId);
    // Delete drink types
    await _client.from('drink_types').delete().eq('user_id', userId);
    // Delete profile
    await _client.from('users_profile').delete().eq('id', userId);
  }

  Future<void> completeOnboarding(String userId) async {
    await updateField(userId, 'onboarding_completed', true);
  }

  Future<void> updateStreak(
      String userId, int current, int longest) async {
    await _client.from('users_profile').update({
      'streak_current': current,
      'streak_longest': longest,
    }).eq('id', userId);
  }

  Future<void> useStreakFreeze(String userId) async {
    final profile = await getProfile(userId);
    if (profile == null) return;
    if (profile.streakFreezesAvailable <= 0) return;

    final updated = profile.copyWith(
      streakFreezesAvailable: profile.streakFreezesAvailable - 1,
      streakFreezesUsedThisMonth: profile.streakFreezesUsedThisMonth + 1,
    );
    await updateProfile(updated);
  }
}
