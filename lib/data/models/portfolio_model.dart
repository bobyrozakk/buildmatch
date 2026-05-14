/// Data model for vendor portfolio items.
class PortfolioModel {
  final String? id;
  final String vendorId;
  final String title;
  final String year;
  final String? imageUrl;
  final DateTime? createdAt;

  const PortfolioModel({
    this.id,
    required this.vendorId,
    required this.title,
    required this.year,
    this.imageUrl,
    this.createdAt,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      id: json['id'] as String?,
      vendorId: json['vendor_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      year: json['year'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
