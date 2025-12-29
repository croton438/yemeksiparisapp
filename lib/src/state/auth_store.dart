import 'package:flutter/material.dart';
import '../models/models.dart';


class AuthStore extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<String?> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    if (fullName.trim().isEmpty) return 'Ad soyad zorunlu.';
    if (phone.trim().length < 10) return 'Telefon numarası geçersiz.';
    if (password.trim().length < 4) return 'Şifre en az 4 karakter olmalı.';

    final u = await fakeDb.register(fullName: fullName.trim(), phone: phone.trim(), password: password.trim());
    _user = u;
    notifyListeners();
    return null;
  }

  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    final u = await fakeDb.login(phone: phone.trim(), password: password.trim());
    if (u == null) return 'Giriş başarısız. (Mock: önce kayıt olman lazım)';
    _user = u;
    notifyListeners();
    return null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
