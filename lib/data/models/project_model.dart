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
  final String? clientPhone; // Joined client phone
  final String? clientEmail; // Client email (joined or generated)
  final double? landCustomPanjang; // Dimensi custom tanah: panjang (meter)
  final double? landCustomLebar;   // Dimensi custom tanah: lebar (meter)

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
    this.clientPhone,
    this.clientEmail,
    this.landCustomPanjang,
    this.landCustomLebar,
  });

  // ────────────────────────────────────────────────────
  // Factory: dari JSON (Supabase / Firebase response)
  // ────────────────────────────────────────────────────

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profiles data for client name & contact
    String? clientName;
    String? clientPhone;
    String? clientEmail;
    if (json['profiles'] is Map) {
      final profilesMap = json['profiles'] as Map;
      clientName = profilesMap['name'] as String?;
      clientPhone = profilesMap['phone'] as String?;
      clientEmail = profilesMap['email'] as String? ?? 
          (clientName != null ? '${clientName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}@gmail.com' : null);
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
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      landCustomPanjang: (json['land_custom_panjang'] as num?)?.toDouble(),
      landCustomLebar: (json['land_custom_lebar'] as num?)?.toDouble(),
    );
  }

  // ────────────────────────────────────────────────────
  // toJson: untuk upload ke Supabase / Firebase
  // ────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'budget': budget,
      'land_size': landSize,
      'building_size': buildingSize,
      'floors': floors,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'house_style': houseStyle,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (clientId != null) 'client_id': clientId,
      'image_urls': imageUrls,
      if (referencePdfUrl != null) 'reference_pdf_url': referencePdfUrl,
      if (status != null) 'status': status,
      'progress_percent': progressPercent,
      if (landCustomPanjang != null) 'land_custom_panjang': landCustomPanjang,
      if (landCustomLebar != null) 'land_custom_lebar': landCustomLebar,
    };
  }

  // ────────────────────────────────────────────────────
  // copyWith: untuk update sebagian field tanpa mutasi
  // (berguna di Provider saat update status/progress)
  // ────────────────────────────────────────────────────

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    double? budget,
    double? landSize,
    double? buildingSize,
    int? floors,
    int? bedrooms,
    int? bathrooms,
    String? houseStyle,
    String? location,
    double? latitude,
    double? longitude,
    String? clientId,
    List<String>? imageUrls,
    String? referencePdfUrl,
    String? status,
    int? progressPercent,
    DateTime? createdAt,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    double? landCustomPanjang,
    double? landCustomLebar,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      landSize: landSize ?? this.landSize,
      buildingSize: buildingSize ?? this.buildingSize,
      floors: floors ?? this.floors,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      houseStyle: houseStyle ?? this.houseStyle,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      clientId: clientId ?? this.clientId,
      imageUrls: imageUrls ?? this.imageUrls,
      referencePdfUrl: referencePdfUrl ?? this.referencePdfUrl,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      createdAt: createdAt ?? this.createdAt,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      landCustomPanjang: landCustomPanjang ?? this.landCustomPanjang,
      landCustomLebar: landCustomLebar ?? this.landCustomLebar,
    );
  }

  // ────────────────────────────────────────────────────
  // Computed helpers (baca-saja, tidak disimpan ke DB)
  // ────────────────────────────────────────────────────

  /// Apakah proyek masih menunggu penawaran kontraktor?
  bool get isPending => status == 'pending' || status == null;

  /// Apakah proyek sedang berjalan?
  bool get isOngoing => status == 'ongoing';

  /// Apakah proyek selesai?
  bool get isCompleted => status == 'completed';

  @override
  String toString() =>
      'ProjectModel(id: $id, title: $title, floors: $floors, '
      'bedrooms: $bedrooms, bathrooms: $bathrooms, status: $status)';
}