import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../firebase/firebase_token_repository.dart';
import 'developer_mode_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.read(authRepositoryProvider).currentUser;
});

// Auth state notifier for login/signup actions
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  final Ref _ref;

  AuthNotifier(this._authRepo, this._profileRepo, this._ref)
      : super(AsyncValue.data(_authRepo.currentUser));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response =
          await _authRepo.signIn(email: email, password: password);
      final user = response.user;
      if (user != null) {
        _syncFcmToken(user.id);
        _ref.read(developerModeProvider.notifier).lockDeveloperMode();
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response =
          await _authRepo.signUp(email: email, password: password);
      final user = response.user;
      if (user != null) {
        _ref.read(developerModeProvider.notifier).lockDeveloperMode();
        // Create profile row — ignore errors if profile already exists
        try {
          await _profileRepo.createProfile(UserProfile(
            id: user.id,
            email: email,
            onboardingCompleted: false,
          ));
        } catch (_) {
          // Profile may already exist (re-signup) — that's fine
        }
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final userId = _authRepo.userId;
      if (userId != null) {
        // Delete all user data from Supabase
        await _profileRepo.deleteAllUserData(userId);
      }
      
      // Delete the user from Supabase Auth via RPC
      await Supabase.instance.client.rpc('delete_user');
      
      await _authRepo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _ref.read(developerModeProvider.notifier).lockDeveloperMode();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    await _authRepo.resetPassword(email);
  }

  void _syncFcmToken(String userId) async {
    try {
      final repo = FirebaseTokenRepository();
      final token = await repo.getCachedToken();
      if (token != null) {
        await repo.syncTokenToSupabase(userId, token);
      }
    } catch (_) {}
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(profileRepositoryProvider),
    ref,
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
