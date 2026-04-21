import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // --- FUNGSI 1: BUAT BIKIN PROYEK BARU ---
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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

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
        'client_id': userId,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error inserting project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- FUNGSI 2: BUAT NGAMBIL DATA PROYEK (Punya User Sendiri) ---
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*')
          .eq('client_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch: $e");
      return [];
    }
  }

  // --- FUNGSI 3: TARIK DATA KONTRAKTOR / VENDOR ---
  Future<List<Map<String, dynamic>>> fetchVendors() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'vendor') // Cuma ambil yang role-nya vendor
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch vendors: $e");
      return [];
    }
  }
}