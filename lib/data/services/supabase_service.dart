import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool isInitialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://wckssjfghmwcagndvhjs.supabase.co',
      publishableKey:
          'sb_publishable_GNIgjJlZtnGj9_e3oxWgOw_pHiYz3oh',
    );
    isInitialized = true;
  }

  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
