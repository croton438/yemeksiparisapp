import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _sb = Supabase.instance.client;

  /// Sends an email OTP / magic link (depends on Supabase project settings)
  Future<void> sendOtp(String email) async {
    await _sb.auth.signInWithOtp(email: email);
  }

  /// Verify OTP token (if using OTP) — token is the 6-digit code user received
  Future<void> verifyOtp(String email, String token) async {
    // Use verifyOTP to validate a code sent via email/phone
    await _sb.auth.verifyOTP(type: OtpType.email, token: token, email: email);
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  User? get currentUser => _sb.auth.currentUser;

  /// Listen to auth changes: returns a stream of auth change events
  Stream<dynamic> authStateChanges() => _sb.auth.onAuthStateChange;

  /// Upsert profile row on first login
  Future<void> upsertProfile({required String id, String? email, String? fullName}) async {
    final Map<String, dynamic> row = {'id': id, 'email': email};
    if (fullName != null) row['full_name'] = fullName;
    await _sb.from('profiles').upsert(row);
  }
}
