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

  // --- SIMPAN PROYEK SEBAGAI DRAFT ---
  /// Menyimpan data form yang sudah diisi sebagai draft (status = 'draft').
  /// Semua parameter opsional — tidak ada validasi ketat, simpan apa adanya.
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
        'image_urls': [],
        'status': 'draft',
      };

      if (draftId != null && draftId.isNotEmpty) {
        // Update draft yang sudah ada
        await _supabase.from('projects').update(data).eq('id', draftId);
      } else {
        // Buat draft baru
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

  // --- AMBIL PROYEK DRAFT MILIK CLIENT ---
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

  // --- HAPUS DRAFT ---
  Future<bool> deleteDraft(String draftId) async {
    try {
      await _supabase.from('projects').delete().eq('id', draftId);
      return true;
    } catch (e) {
      debugPrint("Error delete draft: $e");
      return false;
    }
  }

  // --- AMBIL PROYEK KLIEN (TANPA DRAFT) ---
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*')
          .eq('client_id', userId)
          .neq('status', 'draft')         // <-- draft tidak muncul di sini
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
          .eq('status', 'open')           // hanya 'open', draft otomatis excluded
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
      // Draft juga tidak diikutsertakan karena filter neq 'open' tapi kita tambah neq 'draft'
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .neq('status', 'open')
          .neq('status', 'draft')         // <-- pastikan draft tidak muncul di vendor
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

  // --- HITUNG JUMLAH PENAWARAN MASUK UNTUK SEBUAH PROYEK ---
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

  // --- AMBIL PENAWARAN MASUK UNTUK CLIENT (SEMUA PROYEK OPEN) ---
  /// Fetches all pending bids across all open projects owned by the current client.
  /// Each bid includes joined project info and vendor name.
  Future<List<BidModel>> fetchClientIncomingBids() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get all open project IDs for this client
      final projectsResponse = await _supabase
          .from('projects')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'open');

      final projectIds = List<Map<String, dynamic>>.from(projectsResponse)
          .map((p) => p['id'] as String)
          .toList();

      if (projectIds.isEmpty) return [];

      // Get pending bids for those projects, join vendor name + project info
      final bidsResponse = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name), projects:project_id(title, budget, image_urls)')
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

  // --- AMBIL SEMUA BID UNTUK SATU PROYEK (UNTUK CLIENT) ---
  /// Mengambil semua bid yang masuk pada proyek tertentu, join profil vendor.
  Future<List<BidModel>> fetchProjectBids(String projectId) async {
    try {
      if (projectId.isEmpty) return [];
      final response = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map((json) => BidModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetch project bids: $e");
      return [];
    }
  }

  // --- TERIMA BID (CLIENT) ---
  /// Update bid menjadi 'accepted', update proyek menjadi 'in_progress'.
  Future<bool> acceptBid({
    required String bidId,
    required String projectId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Ubah bid yang dipilih ke accepted
      await _supabase
          .from('bids')
          .update({'status': 'accepted'})
          .eq('id', bidId);

      // 2. Ubah status proyek ke in_progress
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

  // --- TOLAK BID (CLIENT) ---
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
}