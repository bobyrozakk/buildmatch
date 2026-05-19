import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/portfolio_model.dart';
import '../models/certification_model.dart';

class VendorProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

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

      return List<Map<String, dynamic>>.from(response)
          .map((e) => ProfileModel.fromJson(e))
          .toList();
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
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(
        response,
      );
    } catch (e) {
      debugPrint(
        'Error fetch profile: $e',
      );
      return null;
    }
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<bool> updateVendorProfile({
    required String name,
    required String companyName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Belum login');
      }

      await _supabase
          .from('profiles')
          .update({
            'name': name,
            'company_name': companyName,
          })
          .eq('id', userId);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'company_name': companyName,
          },
        ),
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error update profile: $e',
      );

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // FETCH PORTFOLIOS
  // =========================================================

  Future<List<PortfolioModel>>
      fetchPortfolios() async {
    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) return [];

      final response = await _supabase
          .from('portfolios')
          .select()
          .eq('vendor_id', userId)
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(
        response,
      )
          .map(
            (e) => PortfolioModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'Error fetch portfolios: $e',
      );

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
    notifyListeners();

    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Belum login');
      }

      String? imageUrl;

      if (imageFile != null) {
        final ext =
            imageFile.path.split('.').last;

        final fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage
            .from('portfolios')
            .upload(fileName, imageFile);

        imageUrl = _supabase.storage
            .from('portfolios')
            .getPublicUrl(fileName);
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
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error add portfolio: $e',
      );

      _isLoading = false;
      notifyListeners();

      return false;
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
    notifyListeners();

    try {
      String? imageUrl;

      if (imageFile != null) {
        final userId =
            _supabase.auth.currentUser?.id;

        final ext =
            imageFile.path.split('.').last;

        final fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage
            .from('portfolios')
            .upload(fileName, imageFile);

        imageUrl = _supabase.storage
            .from('portfolios')
            .getPublicUrl(fileName);
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
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error update portfolio: $e',
      );

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // DELETE PORTFOLIO
  // =========================================================

  Future<bool> deletePortfolio(
    String id,
  ) async {
    try {
      await _supabase
          .from('portfolios')
          .delete()
          .eq('id', id);

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error delete portfolio: $e',
      );

      return false;
    }
  }

  // =========================================================
  // FETCH CERTIFICATIONS
  // =========================================================

  Future<List<CertificationModel>>
      fetchCertifications() async {
    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) return [];

      final response = await _supabase
          .from('certifications')
          .select()
          .eq('vendor_id', userId)
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(
        response,
      )
          .map(
            (e) =>
                CertificationModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'Error fetch certifications: $e',
      );

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
    notifyListeners();

    try {
      final userId =
          _supabase.auth.currentUser?.id;

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
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error add certification: $e',
      );

      _isLoading = false;
      notifyListeners();

      return false;
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
    notifyListeners();

    try {
      await _supabase
          .from('certifications')
          .update({
            'title': title,
            'issuer': issuer,
          })
          .eq('id', id);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error update certification: $e',
      );

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // DELETE CERTIFICATION
  // =========================================================

  Future<bool> deleteCertification(
    String id,
  ) async {
    try {
      await _supabase
          .from('certifications')
          .delete()
          .eq('id', id);

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error delete certification: $e',
      );

      return false;
    }
  }
}