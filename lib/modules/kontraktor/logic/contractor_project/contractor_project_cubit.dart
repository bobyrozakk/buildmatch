// lib/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'contractor_project_state.dart';

class ContractorProjectCubit extends Cubit<ContractorProjectState> {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ProjectModel> _availableProjects = [];
  List<ProjectModel> _activeProjects = [];
  List<BidModel> _myBids = [];
  List<PaymentTermModel> _paymentTerms = [];
  ProjectModel? _selectedProject;

  ContractorProjectCubit({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        super(const ContractorProjectInitial());

  void _emitLoaded() {
    emit(ContractorProjectLoaded(
      availableProjects: _availableProjects,
      activeProjects: _activeProjects,
      myBids: _myBids,
      paymentTerms: _paymentTerms,
      selectedProject: _selectedProject,
    ));
  }

  // ─────────────────────────────────────────────
  // AMBIL PROYEK OPEN TENDER (UNTUK KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<List<ProjectModel>> fetchAvailableProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name, phone)')
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
          .select('projects:project_id(*, profiles:client_id(name, phone))')
          .eq('vendor_id', vendorId)
          .eq('status', 'accepted');
      final list = List<Map<String, dynamic>>.from(response);
      final activeList = list
          .where((e) => e['projects'] is Map)
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e['projects'] as Map)))
          .toList();
      _activeProjects = activeList;
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
          .select('*, projects:project_id(*, profiles:client_id(name, phone))')
          .eq('vendor_id', vendorId);
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(
        response,
      ).map((json) => BidModel.fromJson(json)).toList();
      _myBids = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint("Error fetch vendor bids: $e");
      return [];
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
          .select('*, projects:project_id(*, profiles:client_id(name, phone))')
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
    emit(const ContractorProjectLoading());
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
  // HAPUS BID (KONTRAKTOR)
  // ─────────────────────────────────────────────
  Future<bool> deleteBid({required String bidId}) async {
    _isLoading = true;
    emit(const ContractorProjectLoading());
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
    emit(const ContractorProjectLoading());
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
    emit(const ContractorProjectLoading());
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
    emit(const ContractorProjectLoading());
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
  // KONTRAKTOR: KONFIRMASI TERIMA PEMBAYARAN
  // ─────────────────────────────────────────────
  Future<bool> vendorConfirmPayment(String termId) async {
    _isLoading = true;
    emit(const ContractorProjectLoading());
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
    emit(const ContractorProjectLoading());
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
  // KONTRAKTOR TANDAI PROYEK SELESAI
  // ─────────────────────────────────────────────
  Future<bool> completeProject(String projectId) async {
    _isLoading = true;
    emit(const ContractorProjectLoading());
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
  // AMBIL SEMUA TERMIN PEMBAYARAN UNTUK SATU PROYEK (SHARED)
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
  // DETAIL PROYEK BY ID (SHARED)
  // ─────────────────────────────────────────────
  Future<ProjectModel?> fetchProjectById(String projectId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name, phone)')
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
}
