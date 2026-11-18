import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Session? get currentSession => _client.auth.currentSession;
}
