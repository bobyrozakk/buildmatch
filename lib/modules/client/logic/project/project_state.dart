import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/data/models/review_model.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

class ProjectLoading extends ProjectState {
  const ProjectLoading();
}

class ProjectLoaded extends ProjectState {
  final List<ProjectModel> projects;
  final List<ProjectModel> draftProjects;
  final List<ProjectModel> availableProjects;
  final List<BidModel> incomingBids;
  final List<BidModel> architectBids;
  final List<BidModel> projectBids;
  final List<BidModel> vendorBids;
  final List<PaymentTermModel> paymentTerms;
  final ProjectModel? selectedProject;
  final ReviewModel? projectReview;

  const ProjectLoaded({
    this.projects = const [],
    this.draftProjects = const [],
    this.availableProjects = const [],
    this.incomingBids = const [],
    this.architectBids = const [],
    this.projectBids = const [],
    this.vendorBids = const [],
    this.paymentTerms = const [],
    this.selectedProject,
    this.projectReview,
  });

  ProjectLoaded copyWith({
    List<ProjectModel>? projects,
    List<ProjectModel>? draftProjects,
    List<ProjectModel>? availableProjects,
    List<BidModel>? incomingBids,
    List<BidModel>? architectBids,
    List<BidModel>? projectBids,
    List<BidModel>? vendorBids,
    List<PaymentTermModel>? paymentTerms,
    ProjectModel? selectedProject,
    ReviewModel? projectReview,
  }) {
    return ProjectLoaded(
      projects: projects ?? this.projects,
      draftProjects: draftProjects ?? this.draftProjects,
      availableProjects: availableProjects ?? this.availableProjects,
      incomingBids: incomingBids ?? this.incomingBids,
      architectBids: architectBids ?? this.architectBids,
      projectBids: projectBids ?? this.projectBids,
      vendorBids: vendorBids ?? this.vendorBids,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      selectedProject: selectedProject ?? this.selectedProject,
      projectReview: projectReview ?? this.projectReview,
    );
  }

  @override
  List<Object?> get props => [
        projects,
        draftProjects,
        availableProjects,
        incomingBids,
        architectBids,
        projectBids,
        vendorBids,
        paymentTerms,
        selectedProject,
        projectReview,
      ];
}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProjectSuccess extends ProjectLoaded {
  const ProjectSuccess({
    super.projects = const [],
    super.draftProjects = const [],
    super.availableProjects = const [],
    super.incomingBids = const [],
    super.architectBids = const [],
    super.projectBids = const [],
    super.vendorBids = const [],
    super.paymentTerms = const [],
    super.selectedProject,
    super.projectReview,
  });
}

