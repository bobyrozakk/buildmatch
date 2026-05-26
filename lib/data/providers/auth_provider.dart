import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  User? get currentUser => _supabase.auth.currentUser;

  // FUNGSI REGISTER FULL
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? companyName,
    String? picName,
    String? npwp,
    File? npwpFile,
    String? nib,      // ADDED: NIB 13 digit murni (tanpa spasi)
    File? nibFile,    // ADDED: Foto bukti NIB
    String? straNumber,
    String? experienceYears,
    File? straFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. FILTER ROLE
      String dbRole = 'client';
      if (role.toLowerCase() == 'kontraktor') dbRole = 'vendor';
      if (role.toLowerCase() == 'arsitek') dbRole = 'architect';

      // 2. SIAPIN METADATA AUTH
      final metadata = <String, dynamic>{
        'name': name,
        'phone': phone,
        'role': dbRole,
      };
      if (dbRole == 'vendor') {
        if (companyName != null) metadata['company_name'] = companyName;
        if (picName != null) metadata['pic_name'] = picName;
        if (npwp != null) metadata['npwp'] = npwp;
        if (nib != null) metadata['nib'] = nib; // ADDED
      } else if (dbRole == 'architect') {
        if (straNumber != null) metadata['stra_number'] = straNumber;
        if (experienceYears != null) metadata['experience_years'] = experienceYears;
      }

      // 3. DAFTAR KE SISTEM AUTHENTICATION SUPABASE
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      final user = response.user;
      if (user != null) {
        // ==========================================
        // 4. UPLOAD FOTO (DI BUNGKUS TRY-CATCH AMAN)
        // ==========================================
        try {
          if (npwpFile != null) {
            final ext = npwpFile.path.split('.').last;
            final fileName = '${user.id}_npwp.$ext';
            await _supabase.storage.from('verifications').upload(fileName, npwpFile);
          }

          // ADDED: Upload foto NIB ke bucket verifications
          if (nibFile != null) {
            final ext = nibFile.path.split('.').last;
            final fileName = '${user.id}_nib.$ext'; // path: {userId}_nib.jpg
            await _supabase.storage.from('verifications').upload(fileName, nibFile);
          }

          if (straFile != null) {
            final ext = straFile.path.split('.').last;
            final fileName = '${user.id}_stra.$ext';
            await _supabase.storage.from('verifications').upload(fileName, straFile);
          }
        } catch (storageError) {
          debugPrint("Peringatan: Gagal upload file dokumen: $storageError");
        }

        // ==========================================
        // 5. INSERT DATA LENGKAP KE TABEL 'profiles'
        // ==========================================
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'name': dbRole == 'vendor' ? picName : name,
            'phone': phone,
            'role': dbRole,
            'company_name': companyName,
            'npwp': npwp,
            'nib': nib, // ADDED: simpan 13 digit murni ke kolom nib (VARCHAR)
            'stra_number': straNumber,
            'experience_years': experienceYears,
            'is_verified': false,
          });
        } catch (dbError) {
          debugPrint("Peringatan: Gagal insert ke tabel profiles: $dbError");
          return "Akun terbuat, tapi gagal menyimpan profil. Hubungi Admin.";
        }
      }

      _isLoading = false;
      notifyListeners();
      return null; // Sukses!
    } on AuthException catch (e) {
      debugPrint("AuthException: ${e.message}");
      _isLoading = false;
      notifyListeners();
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      }
      return 'Gagal mendaftar: ${e.message}';
    } catch (e) {
      debugPrint("Error Register Fatal: $e");
      _isLoading = false;
      notifyListeners();
      return 'Terjadi kesalahan sistem saat menyimpan ke database.';
    }
  }

  // FUNGSI LOGIN
  Future<String?> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // FUNGSI LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  // LOGIN GOOGLE
  Future<void> loginWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.buildmatch://login-callback/',
      );
    } catch (e) {
      debugPrint("Error Google Login: $e");
    }
  }
}