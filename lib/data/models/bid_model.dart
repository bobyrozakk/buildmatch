import 'package:equatable/equatable.dart';
import 'project_model.dart';

/// Data model for contractor bids on projects.
class BidModel extends Equatable {
  final String? id;
  final String projectId;
  final String vendorId;
  final double price;
  final String? message;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime? createdAt;
  final ProjectModel? project; // joined project (optional)
  final String? vendorName;    // joined from profiles table

  // ── Field lama ──
  final int? estimationMonths;
  final String? rabUrl;

  // ── Field baru untuk Filter ──
  final int? vendorExperienceYears;
  final double? vendorRating;

  const BidModel({
    this.id,
    required this.projectId,
    required this.vendorId,
    required this.price,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.project,
    this.vendorName,
    this.estimationMonths,
    this.rabUrl,
    this.vendorExperienceYears,
    this.vendorRating,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    String? vendorName;
    int? experienceYears;
    double? vendorRating;

    if (json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      vendorName = profile['name'] as String?;

      // profiles.experience_years bertipe text di DB -> parse aman ke int
      final expRaw = profile['experience_years'];
      if (expRaw != null) {
        experienceYears = int.tryParse(expRaw.toString());
      }

      // avg_rating di-inject dari query provider
      final ratingRaw = profile['avg_rating'];
      if (ratingRaw != null) {
        vendorRating = double.tryParse(ratingRaw.toString());
      }
    }

    return BidModel(
      id: json['id'] as String?,
      projectId: json['project_id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      project: json['projects'] is Map
          ? ProjectModel.fromJson(Map<String, dynamic>.from(json['projects'] as Map))
          : null,
      vendorName: vendorName,
      estimationMonths: json['estimation_months'] as int?,
      rabUrl: json['rab_url'] as String?,
      vendorExperienceYears: experienceYears,
      vendorRating: vendorRating,
    );
  }

  BidModel copyWith({
    String? id,
    String? projectId,
    String? vendorId,
    double? price,
    String? message,
    String? status,
    DateTime? createdAt,
    ProjectModel? project,
    String? vendorName,
    int? estimationMonths,
    String? rabUrl,
    int? vendorExperienceYears,
    double? vendorRating,
  }) {
    return BidModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      vendorId: vendorId ?? this.vendorId,
      price: price ?? this.price,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      project: project ?? this.project,
      vendorName: vendorName ?? this.vendorName,
      estimationMonths: estimationMonths ?? this.estimationMonths,
      rabUrl: rabUrl ?? this.rabUrl,
      vendorExperienceYears: vendorExperienceYears ?? this.vendorExperienceYears,
      vendorRating: vendorRating ?? this.vendorRating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        vendorId,
        price,
        message,
        status,
        createdAt,
        project,
        vendorName,
        estimationMonths,
        rabUrl,
        vendorExperienceYears,
        vendorRating,
      ];
}