import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class AuthStore extends ChangeNotifier {
  Profile? _profile;
  Profile? get profile => _profile;
  bool get isLoggedIn => _profile != null;

  final _svc = AuthService.instance;
  StreamSubscription<dynamic>? _sub;

  AuthStore() {
    _init();
  }

  void _init() {
    // current user at startup
    final user = _svc.currentUser;
    if (user != null) _fetchProfile(user.id);

    // listen to auth changes
    _sub = _svc.authStateChanges().listen((ev) {
      final session = ev?.session;
      if (session != null && session.user != null) {
        _fetchProfile(session.user!.id);
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchProfile(String uid) async {
    final res = await Supabase.instance.client.from('profiles').select().eq('id', uid).maybeSingle();
    if (res != null && res is Map<String, dynamic>) {
      _profile = Profile.fromMap(res);
    } else {
      // create minimal profile
      final user = _svc.currentUser;
      if (user != null) {
        await _svc.upsertProfile(id: user.id, email: user.email);
        final r = await Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (r is Map<String, dynamic>) _profile = Profile.fromMap(r);
      }
    }
    notifyListeners();
  }

  /// Sends OTP or magic link to email
  Future<String?> signInWithOtp(String email) async {
    try {
      await _svc.sendOtp(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Verify OTP code (if using OTP) — returns null on success or error string
  Future<String?> verifyOtp({required String email, required String token}) async {
    try {
      await _svc.verifyOtp(email, token);
      // on success the auth listener will populate the profile
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _svc.signOut();
    _profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
