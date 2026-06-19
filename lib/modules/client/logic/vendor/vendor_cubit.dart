import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/portfolio_model.dart';
import 'package:buildmatch/data/models/certification_model.dart';
import 'vendor_state.dart';

class VendorCubit extends Cubit<VendorState> {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Local state cache
  List<Map<String, dynamic>> _topVendors = [];
  List<ProfileModel> _vendors = [];
  ProfileModel? _vendorProfile;
  List<PortfolioModel> _portfolios = [];
  List<CertificationModel> _certifications = [];
  List<Map<String, dynamic>> _reviews = [];

  VendorCubit({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        super(const VendorInitial());

  void _emitLoaded() {
    emit(VendorLoaded(
      topVendors: _topVendors,
      vendors: _vendors,
      vendorProfile: _vendorProfile,
      portfolios: _portfolios,
      certifications: _certifications,
      reviews: _reviews,
    ));
  }

  // =========================================================
  // FETCH TOP-RATED VENDORS (for Beranda "Kontraktor Terpopuler")
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchTopVendors({int limit = 5}) async {
    try {
      final reviewsResponse = await _supabase
          .from('reviews')
          .select('vendor_id, rating');

      final Map<String, List<int>> vendorRatings = {};
      for (final row in List<Map<String, dynamic>>.from(reviewsResponse)) {
        final vid = row['vendor_id'] as String?;
        if (vid == null) continue;
        final r = row['rating'] as int? ?? 0;
        vendorRatings.putIfAbsent(vid, () => []).add(r);
      }

      final List<Map<String, dynamic>> result = [];

      if (vendorRatings.isNotEmpty) {
        final ranked = vendorRatings.entries.map((e) {
          final avg = e.value.reduce((a, b) => a + b) / e.value.length;
          return {'vendor_id': e.key, 'avgRating': avg, 'reviewCount': e.value.length};
        }).toList()
          ..sort((a, b) => (b['avgRating'] as double).compareTo(a['avgRating'] as double));

        final List<String> topIds = ranked.map((e) => e['vendor_id'] as String).toList();
        if (topIds.isNotEmpty) {
          final profilesResponse = await _supabase
              .from('profiles')
              .select('*')
              .inFilter('id', topIds)
              .inFilter('role', ['vendor', 'architect']);

          // Fetch bids for accepted/completed projects count for topIds
          final bidsResponse = await _supabase
              .from('bids')
              .select('vendor_id')
              .inFilter('vendor_id', topIds)
              .inFilter('status', ['accepted', 'completed']);

          final Map<String, int> projectCounts = {};
          for (final row in List<Map<String, dynamic>>.from(bidsResponse)) {
            final vid = row['vendor_id'] as String?;
            if (vid != null) {
              projectCounts[vid] = (projectCounts[vid] ?? 0) + 1;
            }
          }

          final profileMap = <String, ProfileModel>{};
          for (final p in List<Map<String, dynamic>>.from(profilesResponse)) {
            var profile = ProfileModel.fromJson(p);
            final int collabCount = projectCounts[profile.id] ?? 0;
            profile = profile.copyWith(collabCount: collabCount);
            profileMap[profile.id] = profile;
          }

          for (final item in ranked) {
            final vid = item['vendor_id'] as String;
            if (profileMap.containsKey(vid)) {
              var prof = profileMap[vid]!;
              prof = prof.copyWith(avgRating: item['avgRating'] as double);
              result.add({
                'profile': prof,
                'avgRating': item['avgRating'] as double,
                'reviewCount': item['reviewCount'] as int,
              });
            }
          }
        }
      }

      // If we don't have enough top partners, fill with other active vendors/architects as fallback
      if (result.length < limit) {
        final existingIds = result.map((e) => (e['profile'] as ProfileModel).id).toList();
        
        final fallbackResponse = await _supabase
            .from('profiles')
            .select('*')
            .inFilter('role', ['vendor', 'architect'])
            .order('created_at', ascending: false)
            .limit(limit * 2);

        final List<String> fallbackIds = List<Map<String, dynamic>>.from(fallbackResponse)
            .map((e) => e['id'] as String)
            .toList();

        final Map<String, int> fallbackProjectCounts = {};
        if (fallbackIds.isNotEmpty) {
          final fallbackBidsResponse = await _supabase
              .from('bids')
              .select('vendor_id')
              .inFilter('vendor_id', fallbackIds)
              .inFilter('status', ['accepted', 'completed']);

          for (final row in List<Map<String, dynamic>>.from(fallbackBidsResponse)) {
            final vid = row['vendor_id'] as String?;
            if (vid != null) {
              fallbackProjectCounts[vid] = (fallbackProjectCounts[vid] ?? 0) + 1;
            }
          }
        }

        for (final p in List<Map<String, dynamic>>.from(fallbackResponse)) {
          if (result.length >= limit) break;
          
          var profile = ProfileModel.fromJson(p);
          if (!existingIds.contains(profile.id)) {
            final int collabCount = fallbackProjectCounts[profile.id] ?? 0;
            profile = profile.copyWith(collabCount: collabCount);
            result.add({
              'profile': profile,
              'avgRating': 0.0,
              'reviewCount': 0,
            });
            existingIds.add(profile.id);
          }
        }
      }

      final finalResult = result.take(limit).toList();
      _topVendors = finalResult;
      _emitLoaded();
      return finalResult;
    } catch (e) {
      debugPrint('Error fetch top vendors: $e');
      return [];
    }
  }

  // =========================================================
  // FETCH ALL VENDORS
  // =========================================================

  Future<List<ProfileModel>> fetchVendors() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'vendor')
          .order('created_at', ascending: false);

      final reviewsResponse = await _supabase
          .from('reviews')
          .select('vendor_id, rating');

      final Map<String, List<int>> ratingMap = {};
      for (final row in List<Map<String, dynamic>>.from(reviewsResponse)) {
        final vid = row['vendor_id'] as String?;
        final r = row['rating'] as int?;
        if (vid != null && r != null) {
          ratingMap.putIfAbsent(vid, () => []).add(r);
        }
      }

      // Fetch bids for accepted/completed projects count
      final bidsResponse = await _supabase
          .from('bids')
          .select('vendor_id')
          .inFilter('status', ['accepted', 'completed']);

      final Map<String, int> projectCounts = {};
      for (final row in List<Map<String, dynamic>>.from(bidsResponse)) {
        final vid = row['vendor_id'] as String?;
        if (vid != null) {
          projectCounts[vid] = (projectCounts[vid] ?? 0) + 1;
        }
      }

      final list = List<Map<String, dynamic>>.from(response).map((e) {
        final id = e['id'] as String;
        double? avgRating;
        if (ratingMap.containsKey(id)) {
          final ratings = ratingMap[id]!;
          avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        }
        return ProfileModel.fromJson(e).copyWith(
          avgRating: avgRating,
          collabCount: projectCounts[id] ?? 0,
        );
      }).toList();

      _vendors = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint('Error fetch vendors: $e');
      return [];
    }
  }

  // =========================================================
  // FETCH CURRENT VENDOR PROFILE
  // =========================================================

  Future<ProfileModel?> fetchVendorProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = ProfileModel.fromJson(response);
      _vendorProfile = profile;
      _emitLoaded();
      return profile;
    } catch (e) {
      debugPrint('Error fetch profile: $e');
      return null;
    }
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<bool> updateVendorProfile({
    required String name,
    required String companyName,
    String? nib,
    String? npwp,
    File? avatarFile,
  }) async {
    _isLoading = true;
    emit(const VendorLoading());

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Belum login');
      }

      String? avatarUrl;
      if (avatarFile != null) {
        final ext = avatarFile.path.split('.').last;
        final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('portfolios').upload(fileName, avatarFile);
        avatarUrl = _supabase.storage.from('portfolios').getPublicUrl(fileName);
      }

      final updateData = {
        'name': name,
        'company_name': companyName,
        if (nib != null) 'nib': nib,
        if (npwp != null) 'npwp': npwp,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'company_name': companyName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );

      _isLoading = false;
      await fetchVendorProfile();
      return true;
    } catch (e) {
      debugPrint('Error update profile: $e');
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // =========================================================
  // FETCH PORTFOLIOS
  // =========================================================

  Future<List<PortfolioModel>> fetchPortfolios() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('portfolios')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response)
          .map((e) => PortfolioModel.fromJson(e))
          .toList();
      _portfolios = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint('Error fetch portfolios: $e');
      return [];
    }
  }

  // =========================================================
  // ADD PORTFOLIO
  // =========================================================

  Future<bool> addPortfolio({
    required String title,
    required String year,
    File? imageFile,
  }) async {
    _isLoading = true;
    emit(const VendorLoading());

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Belum login');
      }

      String? imageUrl;
      if (imageFile != null) {
        final ext = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage.from('portfolios').upload(fileName, imageFile);
        imageUrl = _supabase.storage.from('portfolios').getPublicUrl(fileName);
      }

      await _supabase
          .from('portfolios')
          .insert({
            'vendor_id': userId,
            'title': title,
            'year': year,
            'image_url': imageUrl,
          });

      _isLoading = false;
      await fetchPortfolios();
      return true;
    } catch (e) {
      debugPrint('Error add portfolio: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // =========================================================
  // UPDATE PORTFOLIO
  // =========================================================

  Future<bool> updatePortfolio({
    required String id,
    required String title,
    required String year,
    File? imageFile,
  }) async {
    _isLoading = true;
    emit(const VendorLoading());

    try {
      String? imageUrl;
      if (imageFile != null) {
        final userId = _supabase.auth.currentUser?.id;
        final ext = imageFile.path.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage.from('portfolios').upload(fileName, imageFile);
        imageUrl = _supabase.storage.from('portfolios').getPublicUrl(fileName);
      }

      final data = {
        'title': title,
        'year': year,
      };

      if (imageUrl != null) {
        data['image_url'] = imageUrl;
      }

      await _supabase
          .from('portfolios')
          .update(data)
          .eq('id', id);

      _isLoading = false;
      await fetchPortfolios();
      return true;
    } catch (e) {
      debugPrint('Error update portfolio: $e');
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // =========================================================
  // DELETE PORTFOLIO
  // =========================================================

  Future<bool> deletePortfolio(String id) async {
    try {
      await _supabase.from('portfolios').delete().eq('id', id);
      _portfolios.removeWhere((p) => p.id == id);
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error delete portfolio: $e');
      return false;
    }
  }

  // =========================================================
  // FETCH CERTIFICATIONS
  // =========================================================

  Future<List<CertificationModel>> fetchCertifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('certifications')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response)
          .map((e) => CertificationModel.fromJson(e))
          .toList();
      _certifications = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint('Error fetch certifications: $e');
      return [];
    }
  }

  // =========================================================
  // ADD CERTIFICATION
  // =========================================================

  Future<bool> addCertification({
    required String title,
    required String issuer,
  }) async {
    _isLoading = true;
    emit(const VendorLoading());

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Belum login');
      }

      await _supabase
          .from('certifications')
          .insert({
            'vendor_id': userId,
            'title': title,
            'issuer': issuer,
          });

      _isLoading = false;
      await fetchCertifications();
      return true;
    } catch (e) {
      debugPrint('Error add certification: $e');
      _isLoading = false;
      _emitLoaded();
      rethrow;
    }
  }

  // =========================================================
  // UPDATE CERTIFICATION
  // =========================================================

  Future<bool> updateCertification({
    required String id,
    required String title,
    required String issuer,
  }) async {
    _isLoading = true;
    emit(const VendorLoading());

    try {
      await _supabase
          .from('certifications')
          .update({
            'title': title,
            'issuer': issuer,
          })
          .eq('id', id);

      _isLoading = false;
      await fetchCertifications();
      return true;
    } catch (e) {
      debugPrint('Error update certification: $e');
      _isLoading = false;
      _emitLoaded();
      return false;
    }
  }

  // =========================================================
  // DELETE CERTIFICATION
  // =========================================================

  Future<bool> deleteCertification(String id) async {
    try {
      await _supabase.from('certifications').delete().eq('id', id);
      _certifications.removeWhere((c) => c.id == id);
      _emitLoaded();
      return true;
    } catch (e) {
      debugPrint('Error delete certification: $e');
      return false;
    }
  }

  // =========================================================
  // FETCH VENDOR REVIEWS
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchReviews(String vendorId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, profiles:user_id(name, avatar_url), projects:project_id(title)')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(response);
      _reviews = list;
      _emitLoaded();
      return list;
    } catch (e) {
      debugPrint('Error fetch vendor reviews: $e');
      return [];
    }
  }
}
