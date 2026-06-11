import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/bid_model.dart';
import '../models/payment_term_model.dart';
import '../models/review_model.dart';


/// Provider khusus untuk CRUD proyek dan penawaran (bid).
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
    List<String>? imageUrls,
    String? referencePdfUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

      String? imageUrl;
      String? pdfUrl;

      // 1. Upload foto sampul jika ada
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
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(pdfName);
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
        'image_urls': imageUrl != null ? [imageUrl] : (imageUrls ?? []),
        'reference_pdf_url': pdfUrl ?? referencePdfUrl,
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
    double? landCustomPanjang,
    double? landCustomLebar,
    File? imageFile,
    File? pdfFile,
    List<String>? imageUrls,
    String? referencePdfUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

      String? imageUrl;
      String? pdfUrl;

      // 1. Upload new image if provided
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

      // 2. Upload new PDF if provided
      if (pdfFile != null) {
        final pdfExt = pdfFile.path.split('.').last;
        final pdfName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_Reference.$pdfExt';
        await _supabase.storage.from('documents').upload(pdfName, pdfFile);
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(pdfName);
      }

      final data = {
        'title': title.trim().isEmpty ? 'Draft Tanpa Judul' : title.trim(),
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
        'image_urls': imageUrl != null ? [imageUrl] : (imageUrls ?? []),
        'reference_pdf_url': pdfUrl ?? referencePdfUrl,
        'status': 'draft',
        if (landCustomPanjang != null) 'land_custom_panjang': landCustomPanjang,
        if (landCustomLebar != null) 'land_custom_lebar': landCustomLebar,
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
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => ProjectModel.fromJson(json)).toList();
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
  // BATALKAN PROYEK (CLIENT) — set status = 'cancelled'
  // Tidak dihapus agar kontraktor bisa melihat keterangan dibatalkan.
  // ─────────────────────────────────────────────
  Future<bool> cancelProject(String projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('projects')
          .update({'status': 'cancelled'})
          .eq('id', projectId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error cancel project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE PROYEK (CLIENT EDIT) — hanya saat status masih 'open' & belum ada bid
  // ─────────────────────────────────────────────
  Future<bool> updateProject({
    required String projectId,
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
    double? latitude,
    double? longitude,
    File? imageFile,
    File? pdfFile,
    List<String>? imageUrls,
    String? referencePdfUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User belum login!");

      String? imageUrl;
      String? pdfUrl;

      // 1. Upload foto sampul jika ada
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
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(pdfName);
      }

      await _supabase.from('projects').update({
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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'image_urls': imageUrl != null ? [imageUrl] : (imageUrls ?? []),
        'reference_pdf_url': pdfUrl ?? referencePdfUrl,
      }).eq('id', projectId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error update project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS PROYEK (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> deleteProject(String projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.from('projects').delete().eq('id', projectId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error delete project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HITUNG SEMUA BID (ANY STATUS) UNTUK SATU PROYEK
  // ─────────────────────────────────────────────
  Future<int> fetchProjectBidCountAll(String projectId) async {
    try {
      if (projectId.isEmpty) return 0;
      final response = await _supabase
          .from('bids')
          .select('id, status')
          .eq('project_id', projectId);
      return (response as List).length;
    } catch (e) {
      debugPrint("Error fetch all bid count: $e");
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // CEK APAKAH ADA BID ACCEPTED UNTUK PROYEK INI
  // ─────────────────────────────────────────────
  Future<bool> hasAcceptedBid(String projectId) async {
    try {
      if (projectId.isEmpty) return false;
      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('project_id', projectId)
          .eq('status', 'accepted')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint("Error check accepted bid: $e");
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
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => ProjectModel.fromJson(json)).toList();
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
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => ProjectModel.fromJson(json)).toList();
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
      // Ambil semua bid yang accepted milik vendor ini, lalu ambil data proyeknya
      final response = await _supabase
          .from('bids')
          .select('projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId)
          .eq('status', 'accepted');
      final list = List<Map<String, dynamic>>.from(response);
      return list
          .where((e) => e['projects'] is Map)
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e['projects'] as Map)))
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
          .select('*, projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId);
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => BidModel.fromJson(json)).toList();
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

  Future<BidModel?> getVendorBidOnProject(String projectId) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null || projectId.isEmpty) return null;
      final response = await _supabase
          .from('bids')
          .select('*, projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId)
          .eq('project_id', projectId)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return BidModel.fromJson(response);
    } catch (e) {
      debugPrint("Error get vendor bid: $e");
      return null;
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
    File? rabFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception("Vendor belum login!");

      String? rabUrl;
      if (rabFile != null) {
        final ext = rabFile.path.split('.').last;
        final fileName =
            '${vendorId}_RAB_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('documents').upload(fileName, rabFile);
        rabUrl = _supabase.storage.from('documents').getPublicUrl(fileName);
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
      final projectIds = List<Map<String, dynamic>>.from(
        projectsResponse,
      ).map((p) => p['id'] as String).toList();
      if (projectIds.isEmpty) return [];
      // Join profiles untuk mendapatkan role, lalu filter hanya kontraktor
      final bidsResponse = await _supabase
          .from('bids')
          .select(
            '*, profiles:vendor_id(name, role), projects:project_id(id, title, description, budget, land_size, building_size, floors, bedrooms, bathrooms, house_style, location, latitude, longitude, image_urls, reference_pdf_url, status, progress_percent, created_at, client_id)',
          )
          .inFilter('project_id', projectIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);
      // Filter: hanya tampilkan bid dari kontraktor (role='vendor'), bukan arsitek
      final contractorBids = allBids.where((b) {
        final profiles = b['profiles'] as Map<String, dynamic>?;
        final role = profiles?['role'] as String?;
        // Jika role null atau bukan 'architect', anggap kontraktor
        return role != 'architect';
      }).toList();
      return contractorBids.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetch client incoming bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL BID ARSITEK (KONSULTASI DESAIN) UNTUK CLIENT
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchClientArchitectBids() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      // Ambil semua proyek milik client (tidak hanya open)
      final projectsResponse = await _supabase
          .from('projects')
          .select('id')
          .eq('client_id', userId);
      final projectIds = List<Map<String, dynamic>>.from(
        projectsResponse,
      ).map((p) => p['id'] as String).toList();
      if (projectIds.isEmpty) return [];
      // Ambil bid yang vendor-nya adalah arsitek
      final bidsResponse = await _supabase
          .from('bids')
          .select(
            '*, profiles:vendor_id(name, role, avatar_url), projects:project_id(id, title, description, budget, land_size, building_size, floors, bedrooms, bathrooms, house_style, location, latitude, longitude, image_urls, reference_pdf_url, status, progress_percent, created_at, client_id)',
          )
          .inFilter('project_id', projectIds)
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);
      // Filter: hanya bid dari arsitek (role='architect')
      final architectBids = allBids.where((b) {
        final profiles = b['profiles'] as Map<String, dynamic>?;
        final role = profiles?['role'] as String?;
        return role == 'architect';
      }).toList();
      return architectBids.map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetch client architect bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA BID UNTUK SATU PROYEK (UNTUK CLIENT)
  // ─────────────────────────────────────────────
  // Ambil semua bid untuk satu proyek - HANYA dari kontraktor (bukan arsitek)
  Future<List<BidModel>> fetchProjectBids(String projectId) async {
    try {
      if (projectId.isEmpty) return [];
      // Sertakan field 'role' dari profiles untuk dapat memfilter arsitek
      final bidsResponse = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name, experience_years, role)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);

      // Filter: hanya kontraktor (role='vendor' atau role bukan 'architect')
      final bids = allBids.where((b) {
        final profiles = b['profiles'] as Map<String, dynamic>?;
        final role = profiles?['role'] as String?;
        return role != 'architect';
      }).toList();

      final vendorIds = bids
          .map((b) => b['vendor_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, double> ratingMap = {};
      if (vendorIds.isNotEmpty) {
        final reviewsResponse = await _supabase
            .from('reviews')
            .select('vendor_id, rating')
            .inFilter('vendor_id', vendorIds);
        final reviews = List<Map<String, dynamic>>.from(reviewsResponse);
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

      final enrichedBids = bids.map((b) {
        final vendorId = b['vendor_id'] as String?;
        final profiles = Map<String, dynamic>.from(
          (b['profiles'] as Map?) ?? {},
        );
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
          .update({'status': 'accepted'})
          .eq('id', bidId);
      await _supabase
          .from('projects')
          .update({'status': 'in_progress'})
          .eq('id', projectId);
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
          .update({'status': 'rejected'})
          .eq('id', bidId);
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

  // ─────────────────────────────────────────────
  // HAPUS BID (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> deleteBid({required String bidId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.from('bids').delete().eq('id', bidId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error delete bid: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA TERMIN PEMBAYARAN UNTUK SATU PROYEK
  // ─────────────────────────────────────────────
  Future<List<PaymentTermModel>> fetchPaymentTerms(String projectId) async {
    try {
      if (projectId.isEmpty) return [];
      final response = await _supabase
          .from('payment_terms')
          .select('*')
          .eq('project_id', projectId)
          .order('order_index', ascending: true);
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => PaymentTermModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetch payment terms: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // TAMBAH SATU TERMIN BARU (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> addPaymentTerm({
    required String projectId,
    required String bidId,
    required String name,
    required double percentage,
    required double dealPrice,
    required int orderIndex,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception('Vendor belum login!');
      final amount = dealPrice * percentage / 100;
      await _supabase.from('payment_terms').insert({
        'project_id': projectId,
        'bid_id': bidId,
        'vendor_id': vendorId,
        'name': name,
        'percentage': percentage,
        'amount': amount,
        'status': 'pending',
        'order_index': orderIndex,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error add payment term: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // EDIT TERMIN (KONTRAKTOR — hanya jika masih pending)
  // ─────────────────────────────────────────────
  Future<bool> editPaymentTerm({
    required String termId,
    required String name,
    required double percentage,
    required double dealPrice,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final amount = dealPrice * percentage / 100;
      await _supabase
          .from('payment_terms')
          .update({
            'name': name,
            'percentage': percentage,
            'amount': amount,
            if (notes != null) 'notes': notes,
          })
          .eq('id', termId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error edit payment term: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS TERMIN (KONTRAKTOR — hanya jika masih pending)
  // ─────────────────────────────────────────────
  Future<bool> deletePaymentTerm(String termId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.from('payment_terms').delete().eq('id', termId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error delete payment term: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: TANDAI SUDAH BAYAR + PILIH BANK
  // Mengupdate status → 'waiting_confirmation'
  // ─────────────────────────────────────────────
  Future<bool> clientMarkAsPaid({
    required String termId,
    required String paymentMethod,
    required String virtualAccountNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'waiting_confirmation',
            'payment_method': paymentMethod,
            'virtual_account_number': virtualAccountNumber,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error client mark as paid: $e');
      _isLoading = false;
      notifyListeners();
      // Propagate error agar UI bisa tampilkan pesan asli
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // KONTRAKTOR: KONFIRMASI TERIMA PEMBAYARAN
  // Mengupdate status → 'confirmed'
  // ─────────────────────────────────────────────
  Future<bool> vendorConfirmPayment(String termId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'confirmed',
            'confirmed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error vendor confirm payment: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // KONTRAKTOR: KIRIM LAPORAN PROGRES TERMIN
  // Upload max 5 gambar ke project-renders, PDF opsional ke documents
  // Mengupdate status → 'progress_submitted'
  //
  // Dependency: pastikan pubspec.yaml sudah include:
  //   image_picker: ^1.0.0
  //   file_picker: ^6.0.0
  // ─────────────────────────────────────────────
  Future<bool> submitTermProgress({
    required String termId,
    required String description,
    List<File>? images, // max 5 file, masing-masing max 5MB
    File? pdfFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception('Vendor belum login!');

      // Validasi jumlah gambar
      if (images != null && images.length > 5) {
        throw Exception('Maksimal 5 gambar untuk laporan progres.');
      }

      // Validasi ukuran setiap gambar (max 5MB)
      if (images != null) {
        for (final img in images) {
          final size = await img.length();
          if (size > 5 * 1024 * 1024) {
            throw Exception('Ukuran setiap gambar tidak boleh melebihi 5MB.');
          }
        }
      }

      // 1. Upload gambar progres ke bucket project-renders
      final List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          final ext = img.path.split('.').last.toLowerCase();
          final fileName =
              '${vendorId}_progress_${termId}_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await _supabase.storage.from('project-renders').upload(fileName, img);
          final url = _supabase.storage
              .from('project-renders')
              .getPublicUrl(fileName);
          imageUrls.add(url);
        }
      }

      // 2. Upload PDF laporan ke bucket documents (opsional)
      String? pdfUrl;
      if (pdfFile != null) {
        final ext = pdfFile.path.split('.').last.toLowerCase();
        final fileName =
            '${vendorId}_progress_pdf_${termId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('documents').upload(fileName, pdfFile);
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(fileName);
      }

      // 3. Update payment_term di database
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'progress_submitted',
            'progress_description': description.trim(),
            'progress_images': imageUrls,
            if (pdfUrl != null) 'progress_pdf_url': pdfUrl,
            'progress_submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submit term progress: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Propagate agar UI tampilkan pesan error asli
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: TINJAU & SETUJUI LAPORAN PROGRES
  // Mengupdate status → 'completed'
  // ─────────────────────────────────────────────
  Future<bool> clientReviewProgress(String termId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Ambil project_id dan bid_id dari payment_term
      final termData = await _supabase
          .from('payment_terms')
          .select('project_id, bid_id')
          .eq('id', termId)
          .single();
      final projectId = termData['project_id'] as String;
      final bidId = termData['bid_id'] as String?;

      // 2. Update status termin tersebut menjadi 'completed'
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'completed',
            'progress_reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);

      // 3. Ambil termin proyek milik bid ini untuk menghitung akumulasi persentase yang selesai (completed)
      var query = _supabase
          .from('payment_terms')
          .select('status, percentage')
          .eq('project_id', projectId);

      if (bidId != null) {
        query = query.eq('bid_id', bidId);
      }

      final termsList = await query;

      double completedPct = 0.0;
      for (final t in termsList) {
        final status = t['status'] as String?;
        final percentage = (t['percentage'] as num?)?.toDouble() ?? 0.0;
        if (status == 'completed') {
          completedPct += percentage;
        }
      }

      // 4. Update progress_percent pada proyek di database dengan clamping maksimal 100%
      final int progressToUpdate = completedPct.round().clamp(0, 100);
      await _supabase
          .from('projects')
          .update({
            'progress_percent': progressToUpdate,
          })
          .eq('id', projectId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error client review progress: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Client mengajukan perubahan / menolak laporan progres kontraktor.
  /// Status termin berubah ke 'revision_requested' agar kontraktor bisa upload ulang.
  Future<bool> clientRequestRevision({
    required String termId,
    required String revisionNotes,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'revision_requested',
            'revision_notes': revisionNotes,
            'revision_requested_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error client request revision: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Mengambil detail satu proyek berdasarkan ID
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .eq('id', projectId)
          .single();
      return ProjectModel.fromJson(response);
    } catch (e) {
      debugPrint("Error fetch project by id: $e");
      return null;
    }
  }

  /// Mengambil daftar proyek milik client beserta nama kontraktornya (jika ada accepted bid)
  Future<List<Map<String, dynamic>>> fetchClientProjectsWithContractor() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final projectsResponse = await _supabase
          .from('projects')
          .select('*, bids(vendor_id, status, profiles:vendor_id(name, company_name))')
          .eq('client_id', userId)
          .neq('status', 'draft')
          .order('created_at', ascending: false);
          
      final projects = List<Map<String, dynamic>>.from(projectsResponse);
      
      List<Map<String, dynamic>> result = [];
      for (final p in projects) {
        String contractorName = 'Belum ada kontraktor';
        final bids = p['bids'] as List?;
        if (bids != null) {
          final acceptedBid = bids.firstWhere(
            (b) => b['status'] == 'accepted',
            orElse: () => null,
          );
          if (acceptedBid != null) {
            final profiles = acceptedBid['profiles'] as Map?;
            if (profiles != null) {
              contractorName = profiles['company_name'] as String? ?? 
                               profiles['name'] as String? ?? 
                               'Kontraktor';
            }
          }
        }
        result.add({
          'project': ProjectModel.fromJson(p),
          'contractorName': contractorName,
        });
      }
      return result;
    } catch (e) {
      debugPrint("Error fetch client projects with contractor: $e");
      return [];
    }
  }

  /// Kontraktor menandai proyek selesai (mengakhiri kontrak kerja)
  Future<bool> completeProject(String projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase
          .from('projects')
          .update({'status': 'completed'})
          .eq('id', projectId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error complete project: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengambil rating/review yang diberikan klien untuk proyek ini
  Future<ReviewModel?> fetchProjectReview(String projectId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*')
          .eq('project_id', projectId)
          .maybeSingle();
      if (response == null) return null;
      return ReviewModel.fromJson(response);
    } catch (e) {
      debugPrint("Error fetch project review: $e");
      return null;
    }
  }

  Future<bool> addReview({
    required String projectId,
    required String vendorId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final clientId = _supabase.auth.currentUser?.id;
      if (clientId == null) throw Exception('Client belum login!');

      final existing = await _supabase
          .from('reviews')
          .select('id')
          .eq('project_id', projectId)
          .eq('user_id', clientId)
          .maybeSingle();
      if (existing != null) {
        throw Exception('Ulasan untuk proyek ini sudah dikirim.');
      }

      await _supabase.from('reviews').insert({
        'project_id': projectId,
        'vendor_id': vendorId,
        'user_id': clientId,
        'rating': rating,
        'comment': comment.trim(),
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error add review: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  // ─────────────────────────────────────────────
  // ARSITEK: AMBIL PAYMENT TERM BERDASARKAN BID ID
  // ─────────────────────────────────────────────
  Future<PaymentTermModel?> fetchPaymentTermByBidId(String bidId) async {
    try {
      final response = await _supabase
          .from('payment_terms')
          .select('*')
          .eq('bid_id', bidId)
          .order('order_index', ascending: true);
      
      if (response == null || (response as List).isEmpty) return null;
      final terms = List<Map<String, dynamic>>.from(response)
          .map((e) => PaymentTermModel.fromJson(e))
          .toList();
      
      // Kembalikan termin pertama yang belum selesai (bukan completed)
      return terms.firstWhere(
        (t) => !t.isCompleted,
        orElse: () => terms.last,
      );
    } catch (e) {
      debugPrint('Error fetch payment term by bid: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: BUAT PAYMENT TERM UNTUK PENAWARAN ARSITEK
  // (Satu termin 100% — untuk desain)
  // ─────────────────────────────────────────────
  Future<PaymentTermModel?> createArchitectPaymentTerm({
    required String bidId,
    required String projectId,
    required String vendorId,
    required double amount,
    required String paymentMethod,
    required String virtualAccountNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('payment_terms').insert({
        'project_id': projectId,
        'bid_id': bidId,
        'vendor_id': vendorId,
        'name': 'Pembayaran Desain',
        'percentage': 100.0,
        'amount': amount,
        'status': 'waiting_confirmation',
        'order_index': 1,
        'payment_method': paymentMethod,
        'virtual_account_number': virtualAccountNumber,
        'paid_at': DateTime.now().toIso8601String(),
        'notes': 'Pembayaran penuh untuk jasa desain arsitektur',
      }).select('*').single();
      _isLoading = false;
      notifyListeners();
      return PaymentTermModel.fromJson(response);
    } catch (e) {
      debugPrint('Error create architect payment term: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // ARSITEK: KONFIRMASI TERIMA PEMBAYARAN DESAIN
  // Update bid status menjadi 'accepted' dan project status ke 'in_progress'
  // ─────────────────────────────────────────────
  Future<bool> architectConfirmClientPayment({
    required String termId,
    required String bidId,
    required String projectId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ambil seluruh payment terms untuk bid ini
      final termsResponse = await _supabase
          .from('payment_terms')
          .select('*')
          .eq('bid_id', bidId)
          .order('order_index', ascending: true);
      
      final List<Map<String, dynamic>> terms = List<Map<String, dynamic>>.from(termsResponse);
      final currentTerm = terms.firstWhere((t) => t['id'] == termId);
      final int orderIndex = currentTerm['order_index'] as int? ?? 1;
      
      // Cek apakah termin ini merupakan termin terakhir
      final bool isLastTerm = terms.every((t) => (t['order_index'] as int? ?? 1) <= orderIndex);

      if (isLastTerm && terms.length > 1) {
        // Ini termin Pelunasan (terakhir dalam split payment)
        // 1. Konfirmasi dan langsung selesaikan termin ini
        await _supabase.from('payment_terms').update({
          'status': 'completed',
          'confirmed_at': DateTime.now().toIso8601String(),
          'progress_reviewed_at': DateTime.now().toIso8601String(),
        }).eq('id', termId);

        // 2. Update bid status ke accepted
        await _supabase.from('bids').update({'status': 'accepted'}).eq('id', bidId);

        // 3. Update status project ke completed
        await _supabase.from('projects').update({
          'status': 'completed',
          'progress_percent': 100,
        }).eq('id', projectId);
      } else {
        // Ini DP awal atau termin tunggal biasa
        // 1. Konfirmasi payment term
        await _supabase.from('payment_terms').update({
          'status': 'confirmed',
          'confirmed_at': DateTime.now().toIso8601String(),
        }).eq('id', termId);

        // 2. Update bid status ke accepted
        await _supabase.from('bids').update({'status': 'accepted'}).eq('id', bidId);

        // 3. Update project status ke in_progress
        await _supabase.from('projects').update({'status': 'in_progress'}).eq('id', projectId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error architect confirm payment: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // ARSITEK: SUBMIT DESAIN KE CLIENT
  // Update payment_term → 'progress_submitted'
  // ─────────────────────────────────────────────
  Future<bool> submitDesignFiles({
    required String termId,
    required String description,
    required List<String> fileUrls,
  }) async {
    try {
      await _supabase.from('payment_terms').update({
        'status': 'progress_submitted',
        'progress_description': description,
        'progress_images': fileUrls,
        'progress_submitted_at': DateTime.now().toIso8601String(),
      }).eq('id', termId);
      return true;
    } catch (e) {
      debugPrint('Error submit design files: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HELPER: GENERATE NOMOR VIRTUAL ACCOUNT ACAK
  // ─────────────────────────────────────────────
  static String generateVirtualAccount(String bankCode) {
    final random = Random();
    final Map<String, String> prefixes = {
      'bca': '70012',
      'bni': '98801',
      'mandiri': '88908',
      'bri': '15009',
    };
    final prefix = prefixes[bankCode] ?? '88888';
    final suffix = List.generate(
      12,
      (_) => random.nextInt(10).toString(),
    ).join();
    return '$prefix$suffix';
  }
}
