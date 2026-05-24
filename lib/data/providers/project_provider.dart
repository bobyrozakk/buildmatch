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

  // ─────────────────────────────────────────────
  // BUAT PROYEK BARU (DENGAN UPLOAD FILE)
  // ─────────────────────────────────────────────
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

      // 1. Upload gambar inspirasi jika ada
      if (imageFile != null) {
        final imageExt = imageFile.path.split('.').last;
        final imageName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}.$imageExt';
        await _supabase.storage
            .from('project-renders')
            .upload(imageName, imageFile);
        imageUrl = _supabase.storage
            .from('project-renders')
            .getPublicUrl(imageName);
      }

      // 2. Upload PDF referensi klien jika ada
      if (pdfFile != null) {
        final pdfExt = pdfFile.path.split('.').last;
        final pdfName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_Reference.$pdfExt';
        await _supabase.storage.from('documents').upload(pdfName, pdfFile);
        pdfUrl =
            _supabase.storage.from('documents').getPublicUrl(pdfName);
      }

      // 3. Insert ke database
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

  // ─────────────────────────────────────────────
  // SIMPAN PROYEK SEBAGAI DRAFT
  // ─────────────────────────────────────────────
  Future<bool> saveDraft({
    String? draftId,
    String title = '',
    String description = '',
    double budget = 0,
    double landSize = 0,
    double buildingSize = 0,
    int floors = 1,
    int bedrooms = 0,
    int bathrooms = 0,
    String houseStyle = '',
    String location = '',
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

      final data = {
        'title':
            title.trim().isEmpty ? 'Draft Tanpa Judul' : title.trim(),
        'description': description.trim(),
        'budget': budget,
        'land_size': landSize,
        'building_size': buildingSize,
        'floors': floors,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'house_style': houseStyle,
        'location': location.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'client_id': userId,
        'image_urls': [],
        'status': 'draft',
      };

      if (draftId != null && draftId.isNotEmpty) {
        await _supabase.from('projects').update(data).eq('id', draftId);
      } else {
        await _supabase.from('projects').insert(data);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error save draft: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL PROYEK DRAFT MILIK CLIENT
  // ─────────────────────────────────────────────
  Future<List<ProjectModel>> fetchDraftProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*')
          .eq('client_id', userId)
          .eq('status', 'draft')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch drafts: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS DRAFT
  // ─────────────────────────────────────────────
  Future<bool> deleteDraft(String draftId) async {
    try {
      await _supabase.from('projects').delete().eq('id', draftId);
      return true;
    } catch (e) {
      debugPrint("Error delete draft: $e");
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL PROYEK KLIEN (TANPA DRAFT)
  // ─────────────────────────────────────────────
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*')
          .eq('client_id', userId)
          .neq('status', 'draft')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch projects: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL PROYEK OPEN TENDER (UNTUK KONTRAKTOR)
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // AMBIL PROYEK BERJALAN UNTUK VENDOR
  // ─────────────────────────────────────────────
  Future<List<ProjectModel>> fetchVendorActiveProjects() async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .neq('status', 'open')
          .neq('status', 'draft')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch vendor active projects: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL DAFTAR PENAWARAN VENDOR (BIDS)
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchVendorBids({String? status}) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) return [];

      var query = _supabase
          .from('bids')
          .select(
              '*, projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => BidModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch vendor bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // HITUNG JUMLAH PENAWARAN MASUK UNTUK SEBUAH PROYEK
  // ─────────────────────────────────────────────
  Future<int> fetchProjectBidCount(String projectId) async {
    try {
      if (projectId.isEmpty) return 0;
      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('project_id', projectId);
      return (response as List).length;
    } catch (e) {
      debugPrint("Error fetch bid count: $e");
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // CEK APAKAH VENDOR SUDAH PERNAH NAWAR PROYEK INI
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // KIRIM PENAWARAN (BID) — support RAB upload & estimasi bulan
  // ─────────────────────────────────────────────
  Future<bool> submitBid({
    required String projectId,
    required double price,
    required String message,
    required int estimationMonths,
    File? rabFile, // RAB dari kontraktor (PDF/Excel/Word)
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception("Vendor belum login!");

      String? rabUrl;

      // Upload RAB jika ada
      if (rabFile != null) {
        final ext = rabFile.path.split('.').last;
        final fileName =
            '${vendorId}_RAB_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage
            .from('documents')
            .upload(fileName, rabFile);
        rabUrl =
            _supabase.storage.from('documents').getPublicUrl(fileName);
      }

      await _supabase.from('bids').insert({
        'project_id': projectId,
        'vendor_id': vendorId,
        'price': price,
        'message': message,
        'estimation_months': estimationMonths,
        if (rabUrl != null) 'rab_url': rabUrl,
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

  // ─────────────────────────────────────────────
  // AMBIL PENAWARAN MASUK UNTUK CLIENT (SEMUA PROYEK OPEN)
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchClientIncomingBids() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final projectsResponse = await _supabase
          .from('projects')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'open');

      final projectIds =
          List<Map<String, dynamic>>.from(projectsResponse)
              .map((p) => p['id'] as String)
              .toList();

      if (projectIds.isEmpty) return [];

      final bidsResponse = await _supabase
          .from('bids')
          .select(
              '*, profiles:vendor_id(name), projects:project_id(title, budget, image_urls)')
          .inFilter('project_id', projectIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(bidsResponse)
          .map((json) => BidModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch client incoming bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA BID UNTUK SATU PROYEK (UNTUK CLIENT)
  // Join profil vendor (name, experience_years) + tarik rating manual
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchProjectBids(String projectId) async {
    try {
      if (projectId.isEmpty) return [];

      // 1. Tarik bids + join profil vendor dasar (termasuk experience_years)
      final bidsResponse = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name, experience_years)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      final bids = List<Map<String, dynamic>>.from(bidsResponse);

      // 2. Kumpulkan semua vendor_id unik untuk narik rating
      final vendorIds = bids
          .map((b) => b['vendor_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, double> ratingMap = {};

      // 3. Tarik semua data dari tabel reviews yang match dengan list vendor
      if (vendorIds.isNotEmpty) {
        final reviewsResponse = await _supabase
            .from('reviews')
            .select('vendor_id, rating')
            .inFilter('vendor_id', vendorIds);

        final reviews = List<Map<String, dynamic>>.from(reviewsResponse);

        // Grouping & Hitung rata-rata rating per vendor
        final Map<String, List<int>> ratingGroups = {};
        for (final r in reviews) {
          final vid = r['vendor_id'] as String?;
          final rat = r['rating'] as int?;
          if (vid != null && rat != null) {
            ratingGroups.putIfAbsent(vid, () => []).add(rat);
          }
        }

        ratingGroups.forEach((vid, ratings) {
          ratingMap[vid] = ratings.reduce((a, b) => a + b) / ratings.length;
        });
      }

      // 4. Inject avg_rating ke dalam map profiles sebelum di-parse ke model
      final enrichedBids = bids.map((b) {
        final vendorId = b['vendor_id'] as String?;
        final profiles = Map<String, dynamic>.from((b['profiles'] as Map?) ?? {});

        if (vendorId != null && ratingMap.containsKey(vendorId)) {
          profiles['avg_rating'] = ratingMap[vendorId];
        } else {
          profiles['avg_rating'] = null;
        }

        return {...b, 'profiles': profiles};
      }).toList();

      return enrichedBids.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetch project bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // TERIMA BID (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> acceptBid({
    required String bidId,
    required String projectId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('bids')
          .update({'status': 'accepted'}).eq('id', bidId);

      await _supabase
          .from('projects')
          .update({'status': 'in_progress'}).eq('id', projectId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error accept bid: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TOLAK BID (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> rejectBid({required String bidId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('bids')
          .update({'status': 'rejected'}).eq('id', bidId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error reject bid: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}