// lib/services/auth_services.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

class AuthServices {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
      // debug: true,
    );
  }

  static SupabaseClient client() => Supabase.instance.client;

  // returns the response object (dynamic) so UI can inspect session/user
  static Future<dynamic> signIn(String email, String password) async {
    final res = await client().auth.signInWithPassword(
      password: password,
      email: email,
    );
    return res;
  }

  static Future<dynamic> signUp(String email, String password) async {
    final res = await client().auth.signUp(
      email: email,
      password: password,
    );
    return res;
  }

  static User? currentUser() => client().auth.currentUser;

  static Future<void> signOut() async {
    await client().auth.signOut();
  }
}
