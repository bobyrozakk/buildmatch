import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/data/models/review_model.dart';
import 'project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Local state cache to prevent data loss across subclass states
  List<ProjectModel> _projects = [];
  List<ProjectModel> _draftProjects = [];
  List<ProjectModel> _availableProjects = [];
  List<BidModel> _incomingBids = [];
  List<BidModel> _architectBids = [];
  List<BidModel> _projectBids = [];
  List<BidModel> _vendorBids = [];
  List<PaymentTermModel> _paymentTerms = [];
  ProjectModel? _selectedProject;
  ReviewModel? _projectReview;

  ProjectCubit({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        super(const ProjectInitial());

  void _emitLoaded() {
    emit(ProjectLoaded(
      projects: _projects,
      draftProjects: _draftProjects,
      availableProjects: _availableProjects,
      incomingBids: _incomingBids,
      architectBids: _architectBids,
      projectBids: _projectBids,
      vendorBids: _vendorBids,
      paymentTerms: _paymentTerms,
      selectedProject: _selectedProject,
      projectReview: _projectReview,
    ));
  }

  void _emitSuccess() {
    emit(ProjectSuccess(
      projects: _projects,
      draftProjects: _draftProjects,
      availableProjects: _availableProjects,
      incomingBids: _incomingBids,
      architectBids: _architectBids,
      projectBids: _projectBids,
      vendorBids: _vendorBids,
      paymentTerms: _paymentTerms,
      selectedProject: _selectedProject,
      projectReview: _projectReview,
    ));
  }

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
    emit(const ProjectLoading());
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
      await fetchProjects(); // Refresh cached list
      _emitSuccess();
      Future.delayed(Duration.zero, () {
        if (!isClosed) _emitLoaded();
      });
      return true;
    } catch (e) {
      debugPrint("Error insert project: $e");
      _isLoading = false;
      _emitLoaded();
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
    emit(const ProjectLoading());
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

      debugPrint("=== [DEBUG] project_cubit.dart saveDraft ===");
      debugPrint("  incoming draftId: $draftId");

      dynamic response;
      if (draftId != null && draftId.isNotEmpty) {
        debugPrint("  Branch: UPDATE");
        response = await _supabase.from('projects').update(data).eq('id', draftId).select();
      } else {
        debugPrint("  Branch: INSERT");
        response = await _supabase.from('projects').insert(data).select();
      }
      debugPrint("  Supabase response: $response");

      _isLoading = false;
      await fetchDraftProjects(); // Refresh cached list
      _emitSuccess();
      Future.delayed(Duration.zero, () {
        if (!isClosed) _emitLoaded();
      });
      return true;
    } catch (e, stack) {
      debugPrint("=== [DEBUG] project_cubit.dart saveDraft FAILED ===");
      debugPrint("  incoming draftId: $draftId");
      debugPrint("  Exception: $e");
      debugPrint("  Stacktrace: $stack");
      debugPrint("==================================================");
      _isLoading = false;
      _emitLoaded();
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
      final list = List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
      _draftProjects = list;
      _emitLoaded();
      return list;
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
      _draftProjects.removeWhere((element) => element.id == draftId);
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint("Error delete draft: $e");
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // BATALKAN PROYEK (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> cancelProject(String projectId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase
          .from('projects')
          .update({'status': 'cancelled'})
          .eq('id', projectId);
      _isLoading = false;
      await fetchProjects();
      return true;
    } catch (e) {
      debugPrint("Error cancel project: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE PROYEK (CLIENT EDIT)
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
    emit(const ProjectLoading());
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
      await fetchProjects();
      _emitSuccess();
      Future.delayed(Duration.zero, () {
        if (!isClosed) _emitLoaded();
      });
      return true;
    } catch (e) {
      debugPrint("Error update project: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS PROYEK (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> deleteProject(String projectId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase.from('projects').delete().eq('id', projectId);
      _isLoading = false;
      await fetchProjects();
      _emitSuccess();
      Future.delayed(Duration.zero, () {
        if (!isClosed) _emitLoaded();
      });
      return true;
    } catch (e) {
      debugPrint("Error delete project: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }


  // ─────────────────────────────────────────────
  // HITUNG SEMUA BID UNTUK SATU PROYEK
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
      final list = List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .where((p) => p.title != 'Konsultasi Desain dengan Arsitek')
          .toList();
      _projects = list;
      _emitLoaded();
      return list;
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
          .neq('title', 'Konsultasi Desain dengan Arsitek')
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(response)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
      _availableProjects = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint("Error fetch available projects: $e");
      return [];
    }
  }

  Future<List<ProjectModel>> fetchVendorActiveProjects() async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) return [];
      final response = await _supabase
          .from('bids')
          .select('projects:project_id(*, profiles:client_id(name))')
          .eq('vendor_id', vendorId)
          .eq('status', 'accepted');
      final list = List<Map<String, dynamic>>.from(response);
      final activeList = list
          .where((e) => e['projects'] is Map)
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e['projects'] as Map)))
          .toList();
      _projects = activeList;
      _emitLoaded();
      return activeList;
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
      final list = List<Map<String, dynamic>>.from(
        response,
      ).map((json) => BidModel.fromJson(json)).toList();
      _vendorBids = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint("Error fetch vendor bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // HITUNG JUMLAH PENAWARAN MASUK
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
  // CEK APAKAH VENDOR SUDAH PERNAH NAWAR
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
  // KIRIM PENAWARAN (BID)
  // ─────────────────────────────────────────────
  Future<bool> submitBid({
    required String projectId,
    required double price,
    required String message,
    required int estimationMonths,
    File? rabFile,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
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
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint("Error submit bid: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL PENAWARAN MASUK UNTUK CLIENT (PROYEK OPEN)
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

      final bidsResponse = await _supabase
          .from('bids')
          .select(
            '*, profiles:vendor_id(name, role, experience_years, avatar_url), projects:project_id(id, title, description, budget, land_size, building_size, floors, bedrooms, bathrooms, house_style, location, latitude, longitude, image_urls, reference_pdf_url, status, progress_percent, created_at, client_id)',
          )
          .inFilter('project_id', projectIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);
      final contractorBids = allBids.where((b) {
        final profiles = b['profiles'] as Map<String, dynamic>?;
        final role = profiles?['role'] as String?;
        return role != 'architect';
      }).toList();

      final vendorIds = contractorBids
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

      final enrichedBids = contractorBids.map((b) {
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

      final list = enrichedBids.map((json) => BidModel.fromJson(json)).toList();
      _incomingBids = list;
      _emitLoaded();
      return list;
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
      final projectsResponse = await _supabase
          .from('projects')
          .select('id')
          .eq('client_id', userId);
      final projectIds = List<Map<String, dynamic>>.from(
        projectsResponse,
      ).map((p) => p['id'] as String).toList();
      if (projectIds.isEmpty) return [];

      final bidsResponse = await _supabase
          .from('bids')
          .select(
            '*, profiles:vendor_id(name, role, avatar_url), projects:project_id(id, title, description, budget, land_size, building_size, floors, bedrooms, bathrooms, house_style, location, latitude, longitude, image_urls, reference_pdf_url, status, progress_percent, created_at, client_id)',
          )
          .inFilter('project_id', projectIds)
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);
      final architectBids = allBids.where((b) {
        final profiles = b['profiles'] as Map<String, dynamic>?;
        final role = profiles?['role'] as String?;
        return role == 'architect';
      }).toList();
      final list = architectBids.map((json) => BidModel.fromJson(json)).toList();
      _architectBids = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint("Error fetch client architect bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA BID UNTUK SATU PROYEK (KONTRAKTOR ONLY)
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchProjectBids(String projectId) async {
    try {
      if (projectId.isEmpty) return [];
      final bidsResponse = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name, experience_years, role, avatar_url)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      final allBids = List<Map<String, dynamic>>.from(bidsResponse);

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

      final list = enrichedBids.map((json) => BidModel.fromJson(json)).toList();
      _projectBids = list;
      _emitLoaded();
      return list;
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
    emit(const ProjectLoading());
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
      await fetchProjects();
      return true;
    } catch (e) {
      debugPrint("Error accept bid: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TOLAK BID (CLIENT)
  // ─────────────────────────────────────────────
  Future<bool> rejectBid({required String bidId}) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase
          .from('bids')
          .update({'status': 'rejected'})
          .eq('id', bidId);
      _isLoading = false;
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint("Error reject bid: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS BID (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> deleteBid({required String bidId}) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase.from('bids').delete().eq('id', bidId);
      _isLoading = false;
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint("Error delete bid: $e");
      _isLoading = false;
      _emitLoaded();
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
      final list = List<Map<String, dynamic>>.from(response)
          .map((json) => PaymentTermModel.fromJson(json))
          .toList();
      _paymentTerms = list;
      _emitLoaded();
      return list;
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
    emit(const ProjectLoading());
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
      await fetchPaymentTerms(projectId);
      return true;
    } catch (e) {
      debugPrint('Error add payment term: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // EDIT TERMIN (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> editPaymentTerm({
    required String termId,
    required String name,
    required double percentage,
    required double dealPrice,
    String? notes,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
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
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error edit payment term: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // HAPUS TERMIN (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> deletePaymentTerm(String termId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase.from('payment_terms').delete().eq('id', termId);
      _isLoading = false;
      _paymentTerms.removeWhere((element) => element.id == termId);
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error delete payment term: $e');
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: TANDAI SUDAH BAYAR + PILIH BANK
  // ─────────────────────────────────────────────
  Future<bool> clientMarkAsPaid({
    required String termId,
    required String paymentMethod,
    required String virtualAccountNumber,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
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
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error client mark as paid: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // KONTRAKTOR: KONFIRMASI TERIMA PEMBAYARAN
  // ─────────────────────────────────────────────
  Future<bool> vendorConfirmPayment(String termId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'confirmed',
            'confirmed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);
      _isLoading = false;
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error vendor confirm payment: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // KONTRAKTOR: KIRIM LAPORAN PROGRES TERMIN
  // ─────────────────────────────────────────────
  Future<bool> submitTermProgress({
    required String termId,
    required String description,
    List<File>? images,
    File? pdfFile,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) throw Exception('Vendor belum login!');

      if (images != null && images.length > 5) {
        throw Exception('Maksimal 5 gambar untuk laporan progres.');
      }

      if (images != null) {
        for (final img in images) {
          final size = await img.length();
          if (size > 5 * 1024 * 1024) {
            throw Exception('Ukuran setiap gambar tidak boleh melebihi 5MB.');
          }
        }
      }

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

      String? pdfUrl;
      if (pdfFile != null) {
        final ext = pdfFile.path.split('.').last.toLowerCase();
        final fileName =
            '${vendorId}_progress_pdf_${termId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('documents').upload(fileName, pdfFile);
        pdfUrl = _supabase.storage.from('documents').getPublicUrl(fileName);
      }

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
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error submit term progress: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: TINJAU & SETUJUI LAPORAN PROGRES
  // ─────────────────────────────────────────────
  Future<bool> clientReviewProgress(String termId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      final termData = await _supabase
          .from('payment_terms')
          .select('project_id, bid_id')
          .eq('id', termId)
          .single();
      final projectId = termData['project_id'] as String;
      final bidId = termData['bid_id'] as String?;

      await _supabase
          .from('payment_terms')
          .update({
            'status': 'completed',
            'progress_reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);

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

      final int progressToUpdate = completedPct.round().clamp(0, 100);
      await _supabase
          .from('projects')
          .update({
            'progress_percent': progressToUpdate,
          })
          .eq('id', projectId);

      _isLoading = false;
      await fetchProjects();
      return true;
    } catch (e) {
      debugPrint('Error client review progress: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT: AJUKAN REVISI / TOLAK PROGRES
  // ─────────────────────────────────────────────
  Future<bool> clientRequestRevision({
    required String termId,
    required String revisionNotes,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
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
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error client request revision: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // DETAIL PROYEK BY ID
  // ─────────────────────────────────────────────
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .eq('id', projectId)
          .single();
      final project = ProjectModel.fromJson(response);
      _selectedProject = project;
      _emitLoaded();
      return project;
    } catch (e) {
      debugPrint("Error fetch project by id: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CLIENT PROYEK + KONTRAKTOR
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // KONTRAKTOR TANDAI PROYEK SELESAI
  // ─────────────────────────────────────────────
  Future<bool> completeProject(String projectId) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      await _supabase
          .from('projects')
          .update({'status': 'completed'})
          .eq('id', projectId);
      _isLoading = false;
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint("Error complete project: $e");
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL REVIEW PROYEK
  // ─────────────────────────────────────────────
  Future<ReviewModel?> fetchProjectReview(String projectId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*')
          .eq('project_id', projectId)
          .maybeSingle();
      if (response == null) return null;
      final review = ReviewModel.fromJson(response);
      _projectReview = review;
      _emitLoaded();
      return review;
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
    emit(const ProjectLoading());
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
      await fetchProjectReview(projectId);
      return true;
    } catch (e) {
      debugPrint("Error add review: $e");
      _isLoading = false;
      _emitLoaded();
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
    emit(const ProjectLoading());
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
      final term = PaymentTermModel.fromJson(response);
      _emitLoaded();
      return term;
    } catch (e) {
      debugPrint('Error create architect payment term: $e');
      _isLoading = false;
      _emitLoaded();
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // ARSITEK: KONFIRMASI TERIMA PEMBAYARAN DESAIN
  // ─────────────────────────────────────────────
  Future<bool> architectConfirmClientPayment({
    required String termId,
    required String bidId,
    required String projectId,
  }) async {
    _isLoading = true;
    emit(const ProjectLoading());
    try {
      final termsResponse = await _supabase
          .from('payment_terms')
          .select('*')
          .eq('bid_id', bidId)
          .order('order_index', ascending: true);

      final List<Map<String, dynamic>> terms = List<Map<String, dynamic>>.from(termsResponse);
      final currentTerm = terms.firstWhere((t) => t['id'] == termId);
      final int orderIndex = currentTerm['order_index'] as int? ?? 1;

      final bool isLastTerm = terms.every((t) => (t['order_index'] as int? ?? 1) <= orderIndex);

      if (isLastTerm && terms.length > 1) {
        await _supabase.from('payment_terms').update({
          'status': 'completed',
          'confirmed_at': DateTime.now().toIso8601String(),
          'progress_reviewed_at': DateTime.now().toIso8601String(),
        }).eq('id', termId);

        await _supabase.from('bids').update({'status': 'accepted'}).eq('id', bidId);

        await _supabase.from('projects').update({
          'status': 'completed',
          'progress_percent': 100,
        }).eq('id', projectId);
      } else {
        await _supabase.from('payment_terms').update({
          'status': 'confirmed',
          'confirmed_at': DateTime.now().toIso8601String(),
        }).eq('id', termId);

        await _supabase.from('bids').update({'status': 'accepted'}).eq('id', bidId);

        await _supabase.from('projects').update({'status': 'in_progress'}).eq('id', projectId);
      }

      _isLoading = false;
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error architect confirm payment: $e');
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // ARSITEK: SUBMIT DESAIN KE CLIENT
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
