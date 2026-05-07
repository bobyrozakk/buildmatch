import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // --- FUNGSI 1: BUAT BIKIN PROYEK BARU (DENGAN UPLOAD FILE) ---
  Future<bool> createProject({
    required String title,
    required String description,
    required double budget,
    required double landSize,
    required double buildingSize,
    required int floors,
    required int bedrooms,
    required int bathrooms,
    required String houseStyle,
    required String location,
    required double latitude, 
    required double longitude,
    File? imageFile,
    File? pdfFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

      String? imageUrl;
      String? pdfUrl;

      // 1. UPLOAD GAMBAR INSPIRASI JIKA ADA
      if (imageFile != null) {
        final imageExt = imageFile.path.split('.').last;
        final imageName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$imageExt';
        
        await _supabase.storage.from('project-renders').upload(imageName, imageFile);
        imageUrl = _supabase.storage.from('project-renders').getPublicUrl(imageName);
      }

      // 2. UPLOAD PDF REFERENSI KLIEN JIKA ADA
      if (pdfFile != null) {
        final pdfExt = pdfFile.path.split('.').last;
        final pdfName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_Reference.$pdfExt';
        
        await _supabase.storage.from('documents').upload(pdfName, pdfFile);
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(pdfName);
      }

      // 3. INSERT KE DATABASE POSTGRESQL
      await _supabase.from('projects').insert({
        'title': title,
        'description': description,
        'budget': budget,
        'land_size': landSize,
        'building_size': buildingSize,
        'floors': floors,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'house_style': houseStyle,
        'location': location, 
        'latitude': latitude,
        'longitude': longitude, 
        'client_id': userId,
        'image_urls': imageUrl != null ? [imageUrl] : [], 
        'reference_pdf_url': pdfUrl, 
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error insert project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- FUNGSI 2: BUAT NGAMBIL DATA PROYEK (KLIEN) ---
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.from('projects').select('*').eq('client_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch: $e");
      return [];
    }
  }

  // --- FUNGSI 3: TARIK DATA KONTRAKTOR ---
  Future<List<Map<String, dynamic>>> fetchVendors() async {
    try {
      final response = await _supabase.from('profiles').select('*').eq('role', 'vendor').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch vendors: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .eq('status', 'open')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch available projects: $e");
      return [];
    }
  }

  // --- FUNGSI BARU: KIRIM PENAWARAN (BID) ---
  Future<bool> submitBid({
    required String projectId,
    required double price,
    required String message,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception("Vendor belum login!");

      await _supabase.from('bids').insert({
        'project_id': projectId,
        'vendor_id': vendorId,
        'price': price,
        'message': message,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error submit bid: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- AMBIL DETAIL PROFIL VENDOR ---
  Future<Map<String, dynamic>?> fetchVendorProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint("Error fetch profile: $e");
      return null;
    }
  }

  // --- AMBIL DAFTAR PORTOFOLIO ---
  Future<List<Map<String, dynamic>>> fetchPortfolios() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return []; // <-- PERBAIKAN: NULL CHECKER AMAN

      final response = await _supabase
          .from('portfolios')
          .select()
          .eq('vendor_id', userId) // <-- PERBAIKAN: Hapus tanda "!" yang bikin crash
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- AMBIL DAFTAR SERTIFIKASI ---
  Future<List<Map<String, dynamic>>> fetchCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return []; // <-- PERBAIKAN: NULL CHECKER AMAN

      final response = await _supabase
          .from('certifications')
          .select()
          .eq('vendor_id', userId) // <-- PERBAIKAN: Hapus tanda "!" yang bikin crash
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- FUNGSI UPDATE PROFIL VENDOR ---
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

  // --- FUNGSI NAMBAH PORTOFOLIO BARU ---
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
      debugPrint("Error add porto: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- FUNGSI NAMBAH SERTIFIKASI BARU ---
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
      debugPrint("Error add sertif: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}