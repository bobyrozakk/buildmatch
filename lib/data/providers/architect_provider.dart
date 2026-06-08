import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/certification_model.dart';

class ArchitectProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // =========================================================
  // PROFILE MANAGEMENT (PERSISTENT VIA 'NIB' COLUMN JSON)
  // =========================================================

  Future<ProfileModel?> fetchProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetch architect profile: $e');
      return null;
    }
  }

  /// Fetch all architects with their portfolios for client discovery
  Future<List<Map<String, dynamic>>> fetchAllArchitects() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'architect')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> result = [];
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final profile = ProfileModel.fromJson(row);
        Map<String, dynamic> specializations = {};
        String bio = '';
        String location = '';

        if (profile.nib != null && profile.nib!.startsWith('{')) {
          try {
            final data = jsonDecode(profile.nib!);
            bio = data['bio'] ?? '';
            location = data['location'] ?? '';
            specializations = Map<String, dynamic>.from(data['specializations'] ?? {});
          } catch (_) {}
        }

        result.add({
          'profile': profile,
          'bio': bio,
          'location': location,
          'specializations': specializations,
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error fetch all architects: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchArchitectDetails(String architectId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', architectId)
          .single();

      final profile = ProfileModel.fromJson(response);
      Map<String, dynamic> specializations = {};
      String bio = "";
      String location = "";
      String status = "Tersedia untuk Proyek";
      if (profile.nib != null && profile.nib!.startsWith('{')) {
        try {
          final data = jsonDecode(profile.nib!);
          bio = data['bio'] ?? "";
          location = data['location'] ?? "";
          status = data['status'] ?? "Tersedia untuk Proyek";
          specializations = Map<String, dynamic>.from(data['specializations'] ?? {});
        } catch (_) {}
      }

      return {
        'profile': profile,
        'bio': bio,
        'specializations': specializations,
        'location': location,
        'status': status,
      };
    } catch (e) {
      debugPrint('Error fetch architect details: $e');
      return null;
    }
  }

  Future<String?> updateProfile({
    required String name,
    required String studioName,
    required String bio,
    required String experience,
    required String location,
    String status = 'Tersedia untuk Proyek',
    required List<String> styles,
    required List<String> projectTypes,
    required List<String> technicalSkills,
    File? avatarFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Belum login');

      String? avatarUrl;
      if (avatarFile != null) {
        final ext = avatarFile.path.split('.').last;
        final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('project-renders').upload(fileName, avatarFile);
        avatarUrl = _supabase.storage.from('project-renders').getPublicUrl(fileName);
      }

      // Pack Bio + Specializations into 'nib' column as JSON
      final nibJson = jsonEncode({
        'bio': bio,
        'specializations': {
          'styles': styles,
          'project_types': projectTypes,
          'technical_skills': technicalSkills,
        },
        'location': location,
        'status': status,
      });

      final updateData = {
        'name': name,
        'company_name': studioName, // studio name in company_name
        'experience_years': experience,
        'nib': nibJson,
      };

      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updateData).eq('id', userId);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'company_name': studioName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error update architect profile: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // =========================================================
  // PORTFOLIO MANAGEMENT (COMPLEX FIELDS PACKED IN 'TITLE')
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchPortfolios(String architectId) async {
    try {
      final response = await _supabase
          .from('portfolios')
          .select('*, portfolio_reviews(rating)')
          .eq('vendor_id', architectId)
          .order('created_at', ascending: false);

      final result = <Map<String, dynamic>>[];
      for (final row in response) {
        final rawTitle = row['title'] as String? ?? "";
        String title = rawTitle;
        String style = "Modern";
        String projectType = "Rumah Tinggal";
        double area = 120.0;
        double cost = 100000000.0;
        String description = "";
        List<String> imageUrls = [];

        if (rawTitle.startsWith('{')) {
          try {
            final data = jsonDecode(rawTitle);
            title = data['title'] ?? "Desain Tanpa Judul";
            style = data['style'] ?? "Modern";
            projectType = data['project_type'] ?? "Rumah Tinggal";
            area = (data['area'] as num?)?.toDouble() ?? 120.0;
            cost = (data['cost'] as num?)?.toDouble() ?? 100000000.0;
            description = data['description'] ?? "";
            imageUrls = List<String>.from(data['image_urls'] ?? []);
          } catch (_) {}
        }

        final singleImage = row['image_url'] as String? ?? (imageUrls.isNotEmpty ? imageUrls.first : null);

        // Calculate average rating
        final reviews = row['portfolio_reviews'] as List<dynamic>? ?? [];
        double avgRating = 0.0;
        if (reviews.isNotEmpty) {
          int totalRating = 0;
          for (var rev in reviews) {
            totalRating += (rev['rating'] as int? ?? 0);
          }
          avgRating = totalRating / reviews.length;
        }

        result.add({
          'id': row['id'] as String,
          'title': title,
          'year': row['year'] as String? ?? "2026",
          'image_url': singleImage,
          'image_urls': imageUrls.isEmpty && singleImage != null ? [singleImage] : imageUrls,
          'style': style,
          'project_type': projectType,
          'area': area,
          'cost': cost,
          'description': description,
          'avg_rating': avgRating,
          'review_count': reviews.length,
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error fetch portfolios: $e');
      return [];
    }
  }

  Future<bool> addPortfolio({
    required String title,
    required String style,
    required String projectType,
    required double area,
    required double cost,
    required String description,
    required List<File> imageFiles,
    required String year,
    bool isPublic = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Belum login');

      final List<String> imageUrls = [];
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final ext = file.path.split('.').last;
        final fileName = '${userId}_porto_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

        await _supabase.storage.from('portfolios').upload(fileName, file);
        final url = _supabase.storage.from('portfolios').getPublicUrl(fileName);
        imageUrls.add(url);
      }

      final String mainImageUrl = imageUrls.isNotEmpty ? imageUrls.first : "";

      // Pack extra details into title column as JSON
      final packedTitle = jsonEncode({
        'title': title,
        'style': style,
        'project_type': projectType,
        'area': area,
        'cost': cost,
        'description': description,
        'image_urls': imageUrls,
        'is_public': isPublic,
      });

      await _supabase.from('portfolios').insert({
        'vendor_id': userId,
        'title': packedTitle,
        'year': year,
        'image_url': mainImageUrl.isEmpty ? null : mainImageUrl,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error add portfolio: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePortfolio(String id) async {
    try {
      await _supabase.from('portfolios').delete().eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error delete portfolio: $e');
      return false;
    }
  }

  Future<bool> updatePortfolio({
    required String id,
    required String title,
    required String style,
    required String projectType,
    required double area,
    required double cost,
    required String description,
    required List<String> imageUrls,
    required String year,
    bool isPublic = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String mainImageUrl = imageUrls.isNotEmpty ? imageUrls.first : "";

      // Pack extra details into title column as JSON
      final packedTitle = jsonEncode({
        'title': title,
        'style': style,
        'project_type': projectType,
        'area': area,
        'cost': cost,
        'description': description,
        'image_urls': imageUrls,
        'is_public': isPublic,
      });

      await _supabase.from('portfolios').update({
        'title': packedTitle,
        'year': year,
        'image_url': mainImageUrl.isEmpty ? null : mainImageUrl,
      }).eq('id', id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error update portfolio: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =========================================================
  // CERTIFICATION MANAGEMENT
  // =========================================================

  Future<List<CertificationModel>> fetchCertifications(String userId) async {
    try {
      final response = await _supabase
          .from('certifications')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((e) => CertificationModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetch certifications: $e');
      return [];
    }
  }

  Future<bool> addCertification({
    required String title,
    required String registrationNumber,
    required String issuedDate,
    required String expiryDate,
    File? documentFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Belum login');

      String? documentUrl;
      if (documentFile != null) {
        final ext = documentFile.path.split('.').last;
        final fileName = 'cert_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from('portfolios').upload(fileName, documentFile);
        documentUrl = _supabase.storage.from('portfolios').getPublicUrl(fileName);
      }

      final packedIssuer = jsonEncode({
        'registration_number': registrationNumber,
        'issued_date': issuedDate,
        'expiry_date': expiryDate,
        'document_url': documentUrl ?? '',
      });

      await _supabase.from('certifications').insert({
        'vendor_id': userId,
        'title': title,
        'issuer': packedIssuer,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error add certification: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCertification(String id) async {
    try {
      await _supabase.from('certifications').delete().eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error delete certification: $e');
      return false;
    }
  }


  // =========================================================
  // ALL PORTFOLIOS (FROM ALL ARCHITECTS, INCLUDING SELF)
  // =========================================================

  /// Fetch all portfolios from all architects (including current user).
  /// Used by both "Eksplorasi Ide" (tab Desain) and "Desain Populer" (tab Home).
  Future<List<Map<String, dynamic>>> fetchAllPortfolios() async {
    try {
      final response = await _supabase
          .from('portfolios')
          .select('*, profiles:vendor_id(id, name, avatar_url, company_name), portfolio_reviews(rating)')
          .order('created_at', ascending: false);

      final result = <Map<String, dynamic>>[];
      for (final row in response) {
        final rawTitle = row['title'] as String? ?? "";
        String title = rawTitle;
        String style = "Modern";
        String projectType = "Rumah Tinggal";
        double area = 120.0;
        double cost = 100000000.0;
        String description = "";
        List<String> imageUrls = [];

        if (rawTitle.startsWith('{')) {
          try {
            final data = jsonDecode(rawTitle);
            title = data['title'] ?? "Desain Tanpa Judul";
            style = data['style'] ?? "Modern";
            projectType = data['project_type'] ?? "Rumah Tinggal";
            area = (data['area'] as num?)?.toDouble() ?? 120.0;
            cost = (data['cost'] as num?)?.toDouble() ?? 100000000.0;
            description = data['description'] ?? "";
            imageUrls = List<String>.from(data['image_urls'] ?? []);
          } catch (_) {}
        }

        final singleImage = row['image_url'] as String? ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
        final profileData = row['profiles'] as Map<String, dynamic>?;
        final architectName = profileData?['name'] as String? ?? profileData?['company_name'] as String? ?? 'Arsitek';
        final architectAvatar = profileData?['avatar_url'] as String?;
        final studioName = profileData?['company_name'] as String? ?? '';

        // Calculate average rating
        final reviews = row['portfolio_reviews'] as List<dynamic>? ?? [];
        double avgRating = 0.0;
        if (reviews.isNotEmpty) {
          int totalRating = 0;
          for (var rev in reviews) {
            totalRating += (rev['rating'] as int? ?? 0);
          }
          avgRating = totalRating / reviews.length;
        }

        result.add({
          'id': row['id'] as String,
          'vendor_id': row['vendor_id'] as String,
          'title': title,
          'year': row['year'] as String? ?? "2026",
          'image_url': singleImage,
          'image_urls': imageUrls.isEmpty && singleImage != null ? [singleImage] : imageUrls,
          'style': style,
          'project_type': projectType,
          'area': area,
          'cost': cost,
          'description': description,
          'architect_name': architectName,
          'architect_avatar': architectAvatar,
          'studio_name': studioName,
          'avg_rating': avgRating,
          'review_count': reviews.length,
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error fetch all portfolios: $e');
      return [];
    }
  }

  // =========================================================
  // COLLABORATION REQUESTS (OPEN CLIENT PROJECTS)
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchCollaborationRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch open projects from clients
      final projects = await _supabase
          .from('projects')
          .select('*, profiles:client_id(name, avatar_url)')
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(5);

      // Filter out projects where this architect already bid
      final bids = await _supabase
          .from('bids')
          .select('project_id')
          .eq('vendor_id', userId);

      final biddedProjectIds = (bids as List)
          .map((b) => b['project_id'] as String)
          .toSet();

      final result = <Map<String, dynamic>>[];
      for (final p in projects) {
        final projectId = p['id'] as String;
        if (biddedProjectIds.contains(projectId)) continue;

        final clientProfile = p['profiles'] as Map<String, dynamic>?;
        result.add({
          'project_id': projectId,
          'title': p['title'] as String? ?? 'Proyek Tanpa Judul',
          'description': p['description'] as String? ?? '',
          'budget': (p['budget'] as num?)?.toDouble() ?? 0.0,
          'location': p['location'] as String? ?? '',
          'client_name': clientProfile?['name'] as String? ?? 'Client',
          'client_avatar': clientProfile?['avatar_url'] as String?,
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error fetch collaboration requests: $e');
      return [];
    }
  }

  // =========================================================
  // FETCH ARCHITECT REVIEWS
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, profiles:user_id(name, avatar_url), projects:project_id(title)')
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetch architect reviews: $e');
      return [];
    }
  }

  // =========================================================
  // PORTFOLIO REVIEWS (ARCHITECT TO ARCHITECT)
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchPortfolioReviews(String portfolioId) async {
    try {
      final response = await _supabase
          .from('portfolio_reviews')
          .select('*, reviewer:reviewer_id(name, avatar_url)')
          .eq('portfolio_id', portfolioId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetch portfolio reviews: $e');
      return [];
    }
  }

  Future<bool> addPortfolioReview({
    required String portfolioId,
    required String reviewerId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _supabase.from('portfolio_reviews').insert({
        'portfolio_id': portfolioId,
        'reviewer_id': reviewerId,
        'rating': rating,
        'comment': comment,
      });
      return true;
    } catch (e) {
      debugPrint('Error add portfolio review: $e');
      return false;
    }
  }

  // =========================================================
  // ARCHITECT STATS (REAL DATA)
  // =========================================================

  Future<Map<String, dynamic>> fetchArchitectStats(String userId) async {
    try {
      // Count portfolios
      final portfolios = await _supabase
          .from('portfolios')
          .select('id')
          .eq('vendor_id', userId);
      final portfolioCount = (portfolios as List).length;

      // Count active bids (accepted)
      final activeBids = await _supabase
          .from('bids')
          .select('id')
          .eq('vendor_id', userId)
          .eq('status', 'accepted');
      final activeCollabs = (activeBids as List).length;

      // Count certifications
      final certs = await _supabase
          .from('certifications')
          .select('id')
          .eq('vendor_id', userId);
      final certCount = (certs as List).length;

      // Fetch profile for experience years
      final profile = await _supabase
          .from('profiles')
          .select('experience_years')
          .eq('id', userId)
          .maybeSingle();
      final experience = profile?['experience_years'] as String? ?? '0';

      return {
        'portfolio_count': portfolioCount,
        'active_collabs': activeCollabs,
        'cert_count': certCount,
        'experience_years': experience,
      };
    } catch (e) {
      debugPrint('Error fetch architect stats: $e');
      return {
        'portfolio_count': 0,
        'active_collabs': 0,
        'cert_count': 0,
        'experience_years': '0',
      };
    }
  }

  // =========================================================
  // BIDS & DEALS (DYNAMIC REAL-TIME CYCLES)
  // =========================================================

  Future<String?> submitArchitectOffer({
    required String clientId,
    required double price,
    required String title,
    required String description,
    required int revisions,
    required int durationDays,
    bool isSplitPayment = false,
    int dpPercentage = 50,
    String? chatId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 1. Dapatkan project_id dari chat jika sudah ada.
      // Jika belum ada, buat project konsultasi khusus baru dan asosiasikan ke chat tersebut.
      String projectId = "";
      if (chatId != null) {
        final chatRow = await _supabase
            .from('chats')
            .select('project_id')
            .eq('id', chatId)
            .maybeSingle();
        if (chatRow != null && chatRow['project_id'] != null) {
          projectId = chatRow['project_id'] as String;
        }
      }

      if (projectId.isNotEmpty) {
        final projRow = await _supabase
            .from('projects')
            .select('status')
            .eq('id', projectId)
            .maybeSingle();
        if (projRow != null) {
          final projStatus = projRow['status'] as String? ?? 'open';
          if (projStatus == 'completed' || projStatus == 'cancelled') {
            projectId = "";
          }
        }
      }

      if (projectId.isEmpty) {
        // Buat project placeholder konsultasi baru
        final response = await _supabase.from('projects').insert({
          'title': 'Konsultasi Desain dengan Arsitek',
          'description': 'Proyek konsultasi dan desain perumahan',
          'budget': price,
          'client_id': clientId,
          'status': 'open',
          'location': 'Jakarta, Indonesia',
          'latitude': -6.2088,
          'longitude': 106.8456,
        }).select('id').single();
        projectId = response['id'] as String;

        // Hubungkan chat dengan project konsultasi baru ini
        if (chatId != null) {
          await _supabase.from('chats').update({
            'project_id': projectId,
          }).eq('id', chatId);
        }
      }

      // 2. Pack title, revisions count and description into bid's message as JSON
      final packedMessage = jsonEncode({
        'title': title,
        'description': description,
        'revisions': revisions,
        'duration_days': durationDays,
        'is_split_payment': isSplitPayment,
        'dp_percentage': dpPercentage,
      });

      // 3. Insert into bids table
      final bidResponse = await _supabase.from('bids').insert({
        'project_id': projectId,
        'vendor_id': userId,
        'price': price,
        'message': packedMessage,
        'status': 'pending',
        'estimation_months': (durationDays / 30).ceil(), // fallback mapping
      }).select('id').single();

      final bidId = bidResponse['id'] as String;

      // 4. Automatically create payment term(s) from the arsitek side!
      // This bypasses client-side RLS insert constraints.
      if (isSplitPayment) {
        final dpAmount = price * dpPercentage / 100;
        final pelunasanAmount = price - dpAmount;

        await _supabase.from('payment_terms').insert([
          {
            'project_id': projectId,
            'bid_id': bidId,
            'vendor_id': userId,
            'name': 'DP ($dpPercentage%)',
            'percentage': dpPercentage.toDouble(),
            'amount': dpAmount,
            'status': 'pending',
            'order_index': 1,
            'notes': 'DP awal sebelum pengerjaan proyek dimulai',
          },
          {
            'project_id': projectId,
            'bid_id': bidId,
            'vendor_id': userId,
            'name': 'Pelunasan',
            'percentage': (100 - dpPercentage).toDouble(),
            'amount': pelunasanAmount,
            'status': 'pending',
            'order_index': 2,
            'notes': 'Pelunasan sisa pembayaran setelah desain disetujui',
          }
        ]);
      } else {
        await _supabase.from('payment_terms').insert({
          'project_id': projectId,
          'bid_id': bidId,
          'vendor_id': userId,
          'name': 'Pembayaran Desain',
          'percentage': 100.0,
          'amount': price,
          'status': 'pending',
          'order_index': 1,
          'notes': 'Pembayaran penuh untuk jasa desain arsitektur',
        });
      }

      return bidId;
    } catch (e) {
      debugPrint('Error submit architect offer: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchBidOfferDetails(String bidId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*, projects(*, profiles:client_id(name))')
          .eq('id', bidId)
          .single();

      final rawMessage = response['message'] as String? ?? "";
      String title = "Desain Rumah Minimalis 2 Lantai";
      String description = "Layanan desain lengkap...";
      int revisions = 2;
      int durationDays = 14;

      if (rawMessage.startsWith('{')) {
        try {
          final data = jsonDecode(rawMessage);
          title = data['title'] ?? title;
          description = data['description'] ?? description;
          revisions = data['revisions'] ?? revisions;
          durationDays = data['duration_days'] ?? durationDays;
        } catch (_) {}
      }

      return {
        'id': response['id'] as String,
        'project_id': response['project_id'] as String,
        'vendor_id': response['vendor_id'] as String,
        'price': (response['price'] as num?)?.toDouble() ?? 0.0,
        'status': response['status'] as String? ?? 'pending',
        'created_at': DateTime.parse(response['created_at']),
        'title': title,
        'description': description,
        'revisions': revisions,
        'duration_days': durationDays,
        'project': response['projects'],
      };
    } catch (e) {
      debugPrint('Error fetch bid offer details: $e');
      return null;
    }
  }

  Future<bool> updateOfferStatus(String bidId, String status) async {
    try {
      await _supabase.from('bids').update({'status': status}).eq('id', bidId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error update offer status: $e');
      return false;
    }
  }

  /// Edit penawaran — hanya boleh jika belum ada payment_term yang dibuat (belum dibayar)
  Future<bool> editArchitectOffer({
    required String bidId,
    required double price,
    required String title,
    required String description,
    required int revisions,
    required int durationDays,
    bool isSplitPayment = false,
    int dpPercentage = 50,
  }) async {
    try {
      final packedMessage = jsonEncode({
        'title': title,
        'description': description,
        'revisions': revisions,
        'duration_days': durationDays,
        'is_split_payment': isSplitPayment,
        'dp_percentage': dpPercentage,
      });

      // 1. Ambil detail bid yang ada untuk mendapatkan project_id dan vendor_id
      final bidData = await _supabase
          .from('bids')
          .select('project_id, vendor_id')
          .eq('id', bidId)
          .single();
      final projectId = bidData['project_id'] as String;
      final vendorId = bidData['vendor_id'] as String;

      // 2. Update data bid
      await _supabase.from('bids').update({
        'price': price,
        'message': packedMessage,
      }).eq('id', bidId);

      // 3. Hapus dan buat kembali payment terms
      await _supabase.from('payment_terms').delete().eq('bid_id', bidId);

      if (isSplitPayment) {
        final dpAmount = price * dpPercentage / 100;
        final pelunasanAmount = price - dpAmount;

        await _supabase.from('payment_terms').insert([
          {
            'project_id': projectId,
            'bid_id': bidId,
            'vendor_id': vendorId,
            'name': 'DP ($dpPercentage%)',
            'percentage': dpPercentage.toDouble(),
            'amount': dpAmount,
            'status': 'pending',
            'order_index': 1,
            'notes': 'DP awal sebelum pengerjaan proyek dimulai',
          },
          {
            'project_id': projectId,
            'bid_id': bidId,
            'vendor_id': vendorId,
            'name': 'Pelunasan',
            'percentage': (100 - dpPercentage).toDouble(),
            'amount': pelunasanAmount,
            'status': 'pending',
            'order_index': 2,
            'notes': 'Pelunasan sisa pembayaran setelah desain disetujui',
          }
        ]);
      } else {
        await _supabase.from('payment_terms').insert({
          'project_id': projectId,
          'bid_id': bidId,
          'vendor_id': vendorId,
          'name': 'Pembayaran Desain',
          'percentage': 100.0,
          'amount': price,
          'status': 'pending',
          'order_index': 1,
          'notes': 'Pembayaran penuh untuk jasa desain arsitektur',
        });
      }

      // 4. Update the chat message content in messages table
      final newContent = jsonEncode({
        'type': 'offer',
        'bid_id': bidId,
        'title': title,
        'price': price,
        'revisions': revisions,
        'duration_days': durationDays,
        'is_split_payment': isSplitPayment,
        'dp_percentage': dpPercentage,
        'status': 'pending',
      });

      // Try updating via bid_id first
      final res = await _supabase
          .from('messages')
          .update({'content': newContent})
          .eq('bid_id', bidId)
          .select('id');

      if (res == null || res.isEmpty) {
        // Fallback for older messages without bid_id column set
        await _supabase
            .from('messages')
            .update({'content': newContent, 'bid_id': bidId})
            .like('content', '%$bidId%');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error edit architect offer: $e');
      return false;
    }
  }

  /// Batalkan penawaran — update status ke 'cancelled'
  Future<bool> cancelArchitectOffer(String bidId) async {
    try {
      await _supabase.from('bids').update({'status': 'cancelled'}).eq('id', bidId);
      // Clean up the associated payment term if cancelled
      await _supabase.from('payment_terms').delete().eq('bid_id', bidId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error cancel architect offer: $e');
      return false;
    }
  }

  /// Hapus penawaran secara permanen (bids, payment_terms, dan message di chat)
  Future<bool> deleteArchitectOffer(String bidId) async {
    try {
      // 1. Delete referencing messages first to avoid foreign key violations
      await _supabase.from('messages').delete().eq('bid_id', bidId);
      // Fallback for older messages
      await _supabase.from('messages').delete().like('content', '%$bidId%');
      
      // 2. Delete associated payment terms
      await _supabase.from('payment_terms').delete().eq('bid_id', bidId);
      
      // 3. Delete associated contracts (if any exists, just in case)
      await _supabase.from('contracts').delete().eq('bid_id', bidId);
      
      // 4. Finally delete the bid itself
      await _supabase.from('bids').delete().eq('id', bidId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error delete architect offer: $e');
      return false;
    }
  }

  /// Ambil bid aktif berdasarkan bidId (untuk refresh status di chat)
  Future<Map<String, dynamic>?> fetchBidById(String bidId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('*')
          .eq('id', bidId)
          .maybeSingle();
      if (response == null) return null;
      final rawMessage = response['message'] as String? ?? '';
      String title = '';
      String description = '';
      int revisions = 2;
      int durationDays = 14;
      if (rawMessage.startsWith('{')) {
        try {
          final data = jsonDecode(rawMessage);
          title = data['title'] ?? '';
          description = data['description'] ?? '';
          revisions = data['revisions'] ?? 2;
          durationDays = data['duration_days'] ?? 14;
        } catch (_) {}
      }
      return {
        'id': response['id'],
        'price': (response['price'] as num?)?.toDouble() ?? 0.0,
        'status': response['status'] as String? ?? 'pending',
        'project_id': response['project_id'],
        'vendor_id': response['vendor_id'],
        'title': title,
        'description': description,
        'revisions': revisions,
        'duration_days': durationDays,
        'created_at': response['created_at'],
      };
    } catch (e) {
      debugPrint('Error fetch bid by id: $e');
      return null;
    }
  }
}
