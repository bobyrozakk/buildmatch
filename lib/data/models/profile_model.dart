/// Data model for user profiles (client, vendor, architect).
class ProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String role;
  final String? companyName;
  final String? npwp;
  final String? nib; // ADDED: Nomor Induk Berusaha (13 digit, VARCHAR)
  final String? straNumber;
  final String? experienceYears;
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    this.companyName,
    this.npwp,
    this.nib, // ADDED
    this.straNumber,
    this.experienceYears,
    this.isVerified = false,
    this.avatarUrl,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'client',
      companyName: json['company_name'] as String?,
      npwp: json['npwp'] as String?,
      nib: json['nib'] as String?, // ADDED
      straNumber: json['stra_number'] as String?,
      experienceYears: json['experience_years'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'company_name': companyName,
      'npwp': npwp,
      'nib': nib, // ADDED
      'stra_number': straNumber,
      'experience_years': experienceYears,
      'is_verified': isVerified,
    };
  }
}