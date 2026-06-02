import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Stream<AuthState> get onAuthStateChange => _supabaseClient.auth.onAuthStateChange;

  User? get currentUser => _supabaseClient.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signIn({required String email, required String password}) async {
    await _supabaseClient.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
