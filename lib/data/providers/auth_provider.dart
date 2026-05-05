import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get currentUser => _supabase.auth.currentUser;

  // FUNGSI REGISTER (Ditambah parameter phone)
  // FUNGSI REGISTER (Support multi-role)
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // Dinamis: 'client', 'kontraktor', 'arsitek'
    String? companyName, // Khusus Kontraktor
    String? picName, // Khusus Kontraktor
    String? npwp, // Khusus Kontraktor
    String? straNumber, // Khusus Arsitek
    String? experienceYears, // Khusus Arsitek
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final metadata = <String, dynamic>{
        'name': name,
        'phone': phone,
        'role': role.toLowerCase(),
      };

      // Tambah field khusus kontraktor
      if (role.toLowerCase() == 'kontraktor') {
        if (companyName != null) metadata['company_name'] = companyName;
        if (picName != null) metadata['pic_name'] = picName;
        if (npwp != null) metadata['npwp'] = npwp;
      } else if (role.toLowerCase() == 'arsitek') {
        if (straNumber != null) metadata['stra_number'] = straNumber;
        if (experienceYears != null) metadata['experience_years'] = experienceYears;
      }

      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      _isLoading = false;
      notifyListeners();
      return null; // Sukses, tidak ada error
    } on AuthException catch (e) {
      debugPrint("AuthException: ${e.message}");
      _isLoading = false;
      notifyListeners();
      if (e.message.toLowerCase().contains('already registered') || 
          e.message.toLowerCase().contains('already exists') ||
          e.message.toLowerCase().contains('user already exists')) {
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      }
      return 'Gagal mendaftar: ${e.message}';
    } catch (e) {
      debugPrint("Error Register: $e");
      _isLoading = false;
      notifyListeners();
      return 'Terjadi kesalahan sistem. Silakan coba lagi.';
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

  // FUNGSI LOGIN GOOGLE
  Future<void> loginWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.buildmatch://login-callback/', // Ganti dengan URL skema aslinya nanti
      );
    } catch (e) {
      debugPrint("Error Google Login: $e");
    }
  }

  // FUNGSI LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}