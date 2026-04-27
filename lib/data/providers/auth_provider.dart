import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get currentUser => _supabase.auth.currentUser;

  // FUNGSI REGISTER (Ditambah parameter phone)
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone, // <-- Tambahan dari Figma
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone, // <-- Dikirim ke trigger SQL
          'role': 'client' // Default sesuai MVP kita
        },
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error Register: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // FUNGSI LOGIN
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error Login: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // FUNGSI LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}