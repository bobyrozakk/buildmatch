/// Data model for contractor bids on projects.
class BidModel {
  final String? id;
  final String projectId;
  final String vendorId;
  final double price;
  final String? message;
  final DateTime? createdAt;

  const BidModel({
    this.id,
    required this.projectId,
    required this.vendorId,
    required this.price,
    this.message,
    this.createdAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] as String?,
      projectId: json['project_id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
