import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthCubit({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        super(const AuthInitial()) {
    // Listen to Supabase auth state changes to dynamically emit state
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });

    // Check initial user session
    final initialUser = _supabase.auth.currentUser;
    if (initialUser != null) {
      emit(AuthAuthenticated(initialUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // FUNGSI LOGIN
  Future<String?> login({required String email, required String password}) async {
    _isLoading = true;
    emit(const AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      _isLoading = false;
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthUnauthenticated());
      }
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      emit(AuthError(e.message));
      return e.message;
    } catch (e) {
      _isLoading = false;
      emit(AuthError(e.toString()));
      return e.toString();
    }
  }

  // FUNGSI LOGOUT
  Future<void> logout() async {
    _isLoading = true;
    emit(const AuthLoading());
    try {
      await _supabase.auth.signOut();
      _isLoading = false;
      emit(const AuthUnauthenticated());
    } catch (e) {
      _isLoading = false;
      emit(AuthError(e.toString()));
    }
  }

  // FUNGSI REGISTER
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
    String? nib,
    File? nibFile,
    String? straNumber,
    String? experienceYears,
    File? straFile,
  }) async {
    _isLoading = true;
    emit(const AuthLoading());

    try {
      String dbRole = 'client';
      if (role.toLowerCase() == 'kontraktor') dbRole = 'vendor';
      if (role.toLowerCase() == 'arsitek') dbRole = 'architect';

      final metadata = <String, dynamic>{
        'name': name,
        'phone': phone,
        'role': dbRole,
      };
      if (dbRole == 'vendor') {
        if (companyName != null) metadata['company_name'] = companyName;
        if (picName != null) metadata['pic_name'] = picName;
        if (npwp != null) metadata['npwp'] = npwp;
        if (nib != null) metadata['nib'] = nib;
      } else if (dbRole == 'architect') {
        if (straNumber != null) metadata['stra_number'] = straNumber;
        if (experienceYears != null) metadata['experience_years'] = experienceYears;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      final user = response.user;
      if (user != null) {
        try {
          if (npwpFile != null) {
            final ext = npwpFile.path.split('.').last;
            final fileName = '${user.id}_npwp.$ext';
            await _supabase.storage.from('verifications').upload(fileName, npwpFile);
          }

          if (nibFile != null) {
            final ext = nibFile.path.split('.').last;
            final fileName = '${user.id}_nib.$ext';
            await _supabase.storage.from('verifications').upload(fileName, nibFile);
          }

          if (straFile != null) {
            final ext = straFile.path.split('.').last;
            final fileName = '${user.id}_stra.$ext';
            await _supabase.storage.from('verifications').upload(fileName, straFile);
          }
        } catch (storageError) {
          debugPrint("Storage upload error: $storageError");
        }

        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'name': dbRole == 'vendor' ? picName : name,
            'phone': phone,
            'role': dbRole,
            'company_name': companyName,
            'npwp': npwp,
            'nib': nib,
            'stra_number': straNumber,
            'experience_years': experienceYears,
            'is_verified': false,
          });
        } catch (dbError) {
          debugPrint("Db upsert error: $dbError");
          _isLoading = false;
          emit(AuthError("Akun terbuat, tapi gagal menyimpan profil. Hubungi Admin."));
          return "Akun terbuat, tapi gagal menyimpan profil. Hubungi Admin.";
        }

        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }

      _isLoading = false;
      return null;
    } on AuthException catch (e) {
      _isLoading = false;
      emit(AuthError(e.message));
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      }
      return 'Gagal mendaftar: ${e.message}';
    } catch (e) {
      _isLoading = false;
      emit(AuthError(e.toString()));
      return 'Terjadi kesalahan sistem saat menyimpan ke database.';
    }
  }

  // FUNGSI UPDATE PROFILE
  Future<bool> updateProfile({required String name, required String phone}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    emit(const AuthLoading());

    try {
      await _supabase.auth.updateUser(UserAttributes(data: {'name': name, 'phone': phone}));
      await _supabase.from('profiles').update({'name': name, 'phone': phone}).eq('id', user.id);
      
      // Re-fetch current user and emit updated state
      final updatedUser = _supabase.auth.currentUser;
      if (updatedUser != null) {
        emit(AuthAuthenticated(updatedUser));
      }
      _isLoading = false;
      return true;
    } catch (e) {
      debugPrint("Update profile error: $e");
      _isLoading = false;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
      return false;
    }
  }

  // FUNGSI UPDATE PASSWORD
  Future<bool> updatePassword({required String newPassword}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    emit(const AuthLoading());

    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _isLoading = false;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
      return true;
    } catch (e) {
      debugPrint("Update password error: $e");
      _isLoading = false;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
      return false;
    }
  }

  // FUNGSI LOGIN GOOGLE
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
