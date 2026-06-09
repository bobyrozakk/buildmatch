import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/portfolio_model.dart';
import 'package:buildmatch/data/models/certification_model.dart';

abstract class VendorState extends Equatable {
  const VendorState();

  @override
  List<Object?> get props => [];
}

class VendorInitial extends VendorState {
  const VendorInitial();
}

class VendorLoading extends VendorState {
  const VendorLoading();
}

class VendorLoaded extends VendorState {
  final List<Map<String, dynamic>> topVendors;
  final List<ProfileModel> vendors;
  final ProfileModel? vendorProfile;
  final List<PortfolioModel> portfolios;
  final List<CertificationModel> certifications;
  final List<Map<String, dynamic>> reviews;

  const VendorLoaded({
    this.topVendors = const [],
    this.vendors = const [],
    this.vendorProfile,
    this.portfolios = const [],
    this.certifications = const [],
    this.reviews = const [],
  });

  VendorLoaded copyWith({
    List<Map<String, dynamic>>? topVendors,
    List<ProfileModel>? vendors,
    ProfileModel? vendorProfile,
    List<PortfolioModel>? portfolios,
    List<CertificationModel>? certifications,
    List<Map<String, dynamic>>? reviews,
  }) {
    return VendorLoaded(
      topVendors: topVendors ?? this.topVendors,
      vendors: vendors ?? this.vendors,
      vendorProfile: vendorProfile ?? this.vendorProfile,
      portfolios: portfolios ?? this.portfolios,
      certifications: certifications ?? this.certifications,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [
        topVendors,
        vendors,
        vendorProfile,
        portfolios,
        certifications,
        reviews,
      ];
}

class VendorError extends VendorState {
  final String message;

  const VendorError(this.message);

  @override
  List<Object?> get props => [message];
}
