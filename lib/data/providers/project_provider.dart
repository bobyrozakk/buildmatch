import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

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