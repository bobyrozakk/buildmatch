/// Data model for client reviews/ratings on contractors.
class ReviewModel {
  final String? id;
  final String projectId;
  final String vendorId;
  final String clientId;
  final int rating; // 1-5
  final String? comment;
  final DateTime? createdAt;

  const ReviewModel({
    this.id,
    required this.projectId,
    required this.vendorId,
    required this.clientId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String?,
      projectId: json['project_id'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'vendor_id': vendorId,
      'client_id': clientId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}
