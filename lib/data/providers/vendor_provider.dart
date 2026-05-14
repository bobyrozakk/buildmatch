import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/portfolio_model.dart';
import '../models/certification_model.dart';

/// Provider khusus untuk vendor/kontraktor profile, portofolio, dan sertifikasi.
/// Dipecah dari ProjectProvider agar sesuai Single Responsibility Principle.
class VendorProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // --- AMBIL DAFTAR SEMUA VENDOR ---
  Future<List<ProfileModel>> fetchVendors() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'vendor')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch vendors: $e");
      return [];
    }
  }

  // --- AMBIL DETAIL PROFIL VENDOR SAAT INI ---
  Future<ProfileModel?> fetchVendorProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint("Error fetch profile: $e");
      return null;
    }
  }

  // --- UPDATE PROFIL VENDOR ---
  Future<bool> updateVendorProfile({
    required String name,
    required String companyName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Belum login");

      await _supabase.from('profiles').update({
        'name': name,
        'company_name': companyName,
      }).eq('id', userId);

      await _supabase.auth.updateUser(UserAttributes(data: {
        'name': name,
        'company_name': companyName,
      }));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error update profile: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- AMBIL DAFTAR PORTOFOLIO ---
  Future<List<PortfolioModel>> fetchPortfolios() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('portfolios')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => PortfolioModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- TAMBAH PORTOFOLIO BARU ---
  Future<bool> addPortfolio({
    required String title,
    required String year,
    File? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Belum login");

      String? imageUrl;

      if (imageFile != null) {
        final ext = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('portfolios').upload(fileName, imageFile);
        imageUrl = _supabase.storage.from('portfolios').getPublicUrl(fileName);
      }

      await _supabase.from('portfolios').insert({
        'vendor_id': userId,
        'title': title,
        'year': year,
        'image_url': imageUrl,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error add portfolio: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- AMBIL DAFTAR SERTIFIKASI ---
  Future<List<CertificationModel>> fetchCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('certifications')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => CertificationModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- TAMBAH SERTIFIKASI BARU ---
  Future<bool> addCertification({
    required String title,
    required String issuer,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Belum login");

      await _supabase.from('certifications').insert({
        'vendor_id': userId,
        'title': title,
        'issuer': issuer,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error add certification: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
