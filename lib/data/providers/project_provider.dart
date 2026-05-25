import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/bid_model.dart';
import '../models/payment_term_model.dart';

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
      final response = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name)')
          .neq('status', 'open')
          .neq('status', 'draft')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        response,
      ).map((json) => ProjectModel.fromJson(json)).toList();
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
      final bidsResponse = await _supabase
          .from('bids')
          .select(
            '*, profiles:vendor_id(name), projects:project_id(title, budget, image_urls)',
          )
          .inFilter('project_id', projectIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        bidsResponse,
      ).map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetch client incoming bids: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // AMBIL SEMUA BID UNTUK SATU PROYEK (UNTUK CLIENT)
  // ─────────────────────────────────────────────
  Future<List<BidModel>> fetchProjectBids(String projectId) async {
    try {
      if (projectId.isEmpty) return [];
      final bidsResponse = await _supabase
          .from('bids')
          .select('*, profiles:vendor_id(name, experience_years)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      final bids = List<Map<String, dynamic>>.from(bidsResponse);

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
      await _supabase
          .from('payment_terms')
          .update({
            'status': 'completed',
            'progress_reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', termId);
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
