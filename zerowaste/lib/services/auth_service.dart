import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthService {
  bool get isDemo;
  String? get currentEmail;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get isDemo => false;

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class DemoAuthService implements AuthService {
  String? _email;

  @override
  bool get isDemo => true;

  @override
  String? get currentEmail => _email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _email = email;
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _email = email;
  }

  @override
  Future<void> signOut() async {
    _email = null;
  }
}