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
    required double latitude,   // <-- TAMBAHAN BARU
    required double longitude,
    File? imageFile, // <-- Data File Fisik Gambar Inspirasi
    File? pdfFile,   // <-- Data File Fisik PDF Referensi Klien
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

      // 2. UPLOAD PDF REFERENSI KLIEN JIKA ADA (Bukan RAB)
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
        'location': location, // Nama daerah ketikan user
        'latitude': latitude, // <-- Kordinat asli dari peta
        'longitude': longitude, // <-- Kordinat asli dari peta
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

  // --- FUNGSI 2: BUAT NGAMBIL DATA PROYEK ---
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
}