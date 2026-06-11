// lib/modules/kontraktor/logic/contractor_project/contractor_project_state.dart
import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';

abstract class ContractorProjectState extends Equatable {
  const ContractorProjectState();

  @override
  List<Object?> get props => [];
}

class ContractorProjectInitial extends ContractorProjectState {
  const ContractorProjectInitial();
}

class ContractorProjectLoading extends ContractorProjectState {
  const ContractorProjectLoading();
}

class ContractorProjectLoaded extends ContractorProjectState {
  final List<ProjectModel> availableProjects;
  final List<ProjectModel> activeProjects;
  final List<BidModel> myBids;
  final List<PaymentTermModel> paymentTerms;
  final ProjectModel? selectedProject;

  const ContractorProjectLoaded({
    this.availableProjects = const [],
    this.activeProjects = const [],
    this.myBids = const [],
    this.paymentTerms = const [],
    this.selectedProject,
  });

  ContractorProjectLoaded copyWith({
    List<ProjectModel>? availableProjects,
    List<ProjectModel>? activeProjects,
    List<BidModel>? myBids,
    List<PaymentTermModel>? paymentTerms,
    ProjectModel? selectedProject,
  }) {
    return ContractorProjectLoaded(
      availableProjects: availableProjects ?? this.availableProjects,
      activeProjects: activeProjects ?? this.activeProjects,
      myBids: myBids ?? this.myBids,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      selectedProject: selectedProject ?? this.selectedProject,
    );
  }

  @override
  List<Object?> get props => [
        availableProjects,
        activeProjects,
        myBids,
        paymentTerms,
        selectedProject,
      ];
}

class ContractorProjectError extends ContractorProjectState {
  final String message;

  const ContractorProjectError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContractorProjectSuccess extends ContractorProjectLoaded {
  const ContractorProjectSuccess({
    super.availableProjects = const [],
    super.activeProjects = const [],
    super.myBids = const [],
    super.paymentTerms = const [],
    super.selectedProject,
  });
}
