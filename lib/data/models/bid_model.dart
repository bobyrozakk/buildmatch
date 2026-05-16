import 'project_model.dart';

/// Data model for contractor bids on projects.
class BidModel {
  final String? id;
  final String projectId;
  final String vendorId;
  final double price;
  final String? message;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime? createdAt;
  final ProjectModel? project; // joined project (optional)

  const BidModel({
    this.id,
    required this.projectId,
    required this.vendorId,
    required this.price,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.project,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
