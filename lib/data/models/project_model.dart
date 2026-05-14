/// Data model for construction projects.
class ProjectModel {
  final String? id;
  final String title;
  final String? description;
  final double budget;
  final double landSize;
  final double buildingSize;
  final int floors;
  final int bedrooms;
  final int bathrooms;
  final String houseStyle;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? clientId;
  final List<String> imageUrls;
  final String? referencePdfUrl;
  final String? status;
  final int progressPercent;
  final DateTime? createdAt;
  final String? clientName; // Joined from profiles table

  const ProjectModel({
    this.id,
    required this.title,
    this.description,
    required this.budget,
    this.landSize = 0,
    this.buildingSize = 0,
    this.floors = 1,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.houseStyle = 'Minimalis',
    this.location,
    this.latitude,
    this.longitude,
    this.clientId,
    this.imageUrls = const [],
    this.referencePdfUrl,
    this.status,
    this.progressPercent = 0,
    this.createdAt,
    this.clientName,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profiles data for client name
    String? clientName;
    if (json['profiles'] is Map) {
      clientName = (json['profiles'] as Map)['name'] as String?;
    }

    return ProjectModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      landSize: (json['land_size'] as num?)?.toDouble() ?? 0,
      buildingSize: (json['building_size'] as num?)?.toDouble() ?? 0,
      floors: json['floors'] as int? ?? 1,
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      houseStyle: json['house_style'] as String? ?? 'Minimalis',
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      clientId: json['client_id'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      referencePdfUrl: json['reference_pdf_url'] as String?,
      status: json['status'] as String?,
      progressPercent: json['progress_percent'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      clientName: clientName,
    );
  }
}
