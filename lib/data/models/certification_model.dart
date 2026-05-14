/// Data model for vendor certifications.
class CertificationModel {
  final String? id;
  final String vendorId;
  final String title;
  final String issuer;
  final DateTime? createdAt;

  const CertificationModel({
    this.id,
    required this.vendorId,
    required this.title,
    required this.issuer,
    this.createdAt,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'] as String?,
      vendorId: json['vendor_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
