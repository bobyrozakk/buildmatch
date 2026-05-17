import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/bid_model.dart';

/// Provider khusus untuk CRUD proyek dan penawaran (bid).
/// Vendor-related functions sudah dipindah ke VendorProvider.
class ProjectProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // --- BUAT PROYEK BARU (DENGAN UPLOAD FILE) ---
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

      // 3. INSERT KE DATABASE
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
        'status': 'open',
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

  // --- AMBIL PROYEK KLIEN ---
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*')
          .eq('client_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch projects: $e");
      return [];
    }
  }

  // --- AMBIL PROYEK OPEN TENDER (UNTUK KONTRAKTOR) ---
  Future<List<ProjectModel>> fetchAvailableProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .eq('status', 'open')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch available projects: $e");
      return [];
    }
  }

  // --- AMBIL PROYEK BERJALAN UNTUK VENDOR ---
  /// Mengambil proyek yang dimiliki/dikerjakan vendor saat ini (status != 'open' atau progress > 0).
  /// Saat ini menggunakan filter status != 'open' dari semua proyek.
  Future<List<ProjectModel>> fetchVendorActiveProjects() async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) return [];

      // Ambil proyek yang sudah tidak open (in_progress/completed) dengan join client name
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .neq('status', 'open')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch vendor active projects: $e");
      return [];
    }
  }

  // --- AMBIL DAFTAR PENAWARAN VENDOR (BIDS) ---
  /// Mengambil semua bid yang diajukan vendor login. Optional filter status.
  /// Setiap bid sudah join ke tabel `projects` (+ profil klien) untuk display.
  Future<List<BidModel>> fetchVendorBids({String? status}) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) return [];

      var query = _supabase
          .from('bids')
          .select('*, projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId);
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => BidModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch vendor bids: $e");
      return [];
    }
  }

  // --- CEK APAKAH VENDOR SUDAH PERNAH NAWAR PROYEK INI ---
  Future<bool> hasVendorBidOnProject(String projectId) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null || projectId.isEmpty) return false;
      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('project_id', projectId)
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint("Error check vendor bid: $e");
      return false;
    }
  }

  // --- KIRIM PENAWARAN (BID) ---
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
}