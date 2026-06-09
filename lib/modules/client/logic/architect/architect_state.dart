import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/certification_model.dart';

abstract class ArchitectState extends Equatable {
  const ArchitectState();

  @override
  List<Object?> get props => [];
}

class ArchitectInitial extends ArchitectState {
  const ArchitectInitial();
}

class ArchitectLoading extends ArchitectState {
  const ArchitectLoading();
}

class ArchitectLoaded extends ArchitectState {
  final List<Map<String, dynamic>> architects;
  final Map<String, dynamic>? selectedArchitectDetails;
  final List<Map<String, dynamic>> portfolios;
  final List<CertificationModel> certifications;
  final List<Map<String, dynamic>> allPortfolios;
  final List<Map<String, dynamic>> collaborationRequests;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> portfolioReviews;
  final Map<String, dynamic> stats;
  final ProfileModel? selfProfile;

  const ArchitectLoaded({
    this.architects = const [],
    this.selectedArchitectDetails,
    this.portfolios = const [],
    this.certifications = const [],
    this.allPortfolios = const [],
    this.collaborationRequests = const [],
    this.reviews = const [],
    this.portfolioReviews = const [],
    this.stats = const {},
    this.selfProfile,
  });

  ArchitectLoaded copyWith({
    List<Map<String, dynamic>>? architects,
    Map<String, dynamic>? selectedArchitectDetails,
    List<Map<String, dynamic>>? portfolios,
    List<CertificationModel>? certifications,
    List<Map<String, dynamic>>? allPortfolios,
    List<Map<String, dynamic>>? collaborationRequests,
    List<Map<String, dynamic>>? reviews,
    List<Map<String, dynamic>>? portfolioReviews,
    Map<String, dynamic>? stats,
    ProfileModel? selfProfile,
  }) {
    return ArchitectLoaded(
      architects: architects ?? this.architects,
      selectedArchitectDetails: selectedArchitectDetails ?? this.selectedArchitectDetails,
      portfolios: portfolios ?? this.portfolios,
      certifications: certifications ?? this.certifications,
      allPortfolios: allPortfolios ?? this.allPortfolios,
      collaborationRequests: collaborationRequests ?? this.collaborationRequests,
      reviews: reviews ?? this.reviews,
      portfolioReviews: portfolioReviews ?? this.portfolioReviews,
      stats: stats ?? this.stats,
      selfProfile: selfProfile ?? this.selfProfile,
    );
  }

  @override
  List<Object?> get props => [
        architects,
        selectedArchitectDetails,
        portfolios,
        certifications,
        allPortfolios,
        collaborationRequests,
        reviews,
        portfolioReviews,
        stats,
        selfProfile,
      ];
}

class ArchitectError extends ArchitectState {
  final String message;

  const ArchitectError(this.message);

  @override
  List<Object?> get props => [message];
}
