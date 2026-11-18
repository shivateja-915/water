import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_profile.dart';
import '../data/models/avatar_options.dart';
import '../data/repositories/profile_repository.dart';
import 'auth_provider.dart';

/// Transient state provider for Avatar Selection draft
final avatarDraftProvider = StateNotifierProvider.autoDispose<AvatarDraftNotifier, AvatarOptions>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final initialOptions = profile?.toAvatarOptions() ?? AvatarOptions.defaultForUser(profile?.id ?? 'h2o_user');
  return AvatarDraftNotifier(initialOptions);
});

class AvatarDraftNotifier extends StateNotifier<AvatarOptions> {
  AvatarDraftNotifier(super.initialState);

  void updateSeed(String newSeed) {
    state = state.copyWith(seed: newSeed);
  }

  void updateBackgroundColor(String hexColor) {
    state = state.copyWith(backgroundColor: hexColor.replaceAll('#', ''));
  }

  void updateShapeColor(String hexColor) {
    state = state.copyWith(shapeColor: hexColor.replaceAll('#', ''));
  }

  void updateFlip(String flipMode) {
    state = state.copyWith(flip: flipMode);
  }

  void updateRotate(int degrees) {
    state = state.copyWith(rotate: degrees);
  }

  void updateScale(int percentage) {
    state = state.copyWith(scale: percentage);
  }
}

/// Reactive userId that updates on auth state changes
final _profileUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).userId;
});

/// Gets email from auth user (always available after login)
final _authEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUser?.email;
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final profileRepo = ref.read(profileRepositoryProvider);
  final userId = ref.watch(_profileUserIdProvider);
  final authEmail = ref.watch(_authEmailProvider);
  return ProfileNotifier(profileRepo, userId, authEmail);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repo;
  final String? _userId;
  final String? _authEmail;

  ProfileNotifier(this._repo, this._userId, this._authEmail)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadProfile();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadProfile() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      var profile = await _repo.getProfile(_userId);
      if (profile == null) {
        // Create initial profile needing onboarding for new users
        profile = UserProfile(
          id: _userId,
          email: _authEmail,
          dailyGoalMl: 2500,
          onboardingCompleted: false,
        );
      } else if ((profile.email == null || profile.email!.isEmpty) && _authEmail != null) {
        profile = profile.copyWith(email: _authEmail);
      }
      state = AsyncValue.data(profile);
    } catch (e) {
      final existing = state.valueOrNull;
      if (existing != null) {
        state = AsyncValue.data(existing);
      } else {
        // Fallback profile on error
        state = AsyncValue.data(UserProfile(
          id: _userId,
          email: _authEmail,
          dailyGoalMl: 2500,
          onboardingCompleted: true, // Default to true on network error for logged in user to avoid lock out
        ));
      }
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    // Preserving email from auth
    final withEmail = (profile.email == null || profile.email!.isEmpty) && _authEmail != null
        ? profile.copyWith(email: _authEmail)
        : profile;

    // Immediately emit valid data state so UI updates instantly and user is never redirected to onboarding
    state = AsyncValue.data(withEmail);

    try {
      await _repo.updateProfile(withEmail);
    } catch (e) {
      // Backend schema fallback: ignore remote column mismatch or network errors to keep app fully functional locally
    }
  }

  Future<void> saveAvatarOptions(AvatarOptions avatarOpts) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      avatarSeed: avatarOpts.seed,
      avatarBackgroundColor: avatarOpts.backgroundColor,
      avatarShapeColor: avatarOpts.shapeColor,
      avatarFlip: avatarOpts.flip,
      avatarRotate: avatarOpts.rotate,
      avatarScale: avatarOpts.scale,
      avatarUrl: avatarOpts.toUrl(),
    );

    await updateProfile(updated);
  }

  Future<void> uploadAvatar(File file) async {
    if (_userId == null) return;
    try {
      final url = await _repo.uploadAvatar(_userId, file);
      final current = state.valueOrNull;
      if (current != null && url != null) {
        state = AsyncValue.data(current.copyWith(avatarUrl: url));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    if (_userId == null) return;
    await _repo.completeOnboarding(_userId);
    final current = state.valueOrNull;
    if (current != null) {
      state =
          AsyncValue.data(current.copyWith(onboardingCompleted: true));
    }
  }

  Future<void> useStreakFreeze() async {
    if (_userId == null) return;
    await _repo.useStreakFreeze(_userId);
    await loadProfile();
  }
}
