import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthService {
  /// Must also be registered in the Supabase dashboard under
  /// Authentication -> URL Configuration -> Redirect URLs.
  static const nativeRedirectTo = 'io.supabase.cvscreen://login-callback/';

  Session? get session => supabase.auth.currentSession;
  User? get user => supabase.auth.currentUser;
  bool get isSignedIn => session != null;
  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  String get redirectTo => kIsWeb ? Uri.base.origin : nativeRedirectTo;

  String get displayName {
    final meta = user?.userMetadata ?? const {};
    for (final key in ['full_name', 'name', 'first_name']) {
      final value = meta[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final email = user?.email;
    if (email != null && email.trim().isNotEmpty) return email.trim();
    return 'Account';
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) =>
      supabase.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: redirectTo,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'full_name': '${firstName.trim()} ${lastName.trim()}'.trim(),
        },
      );

  Future<AuthResponse> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email.trim(), password: password);

  /// Returns whether the browser was launched, not whether sign-in succeeded.
  /// The result arrives later as an [AuthChangeEvent.signedIn] on [authChanges].
  Future<bool> signInWithGoogle() => supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: {'prompt': 'select_account'},
      );

  Future<void> signOut() => supabase.auth.signOut();

  static String describeError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Incorrect email or password.';
        case 'email_not_confirmed':
          return 'Confirm your email address before signing in.';
        case 'user_already_exists':
        case 'email_exists':
          return 'An account with this email already exists. Try signing in.';
        case 'weak_password':
          return 'Choose a stronger password of at least 8 characters.';
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return 'Too many attempts. Wait a moment and try again.';
        case 'signup_disabled':
          return 'Sign-ups are currently disabled.';
        case 'validation_failed':
          return 'That email address was rejected. Check it and try again.';
      }
      return error.message;
    }
    return 'Could not reach the sign-in service. Check your connection and try again.';
  }
}
