import 'package:equatable/equatable.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';

abstract class BerandaState extends Equatable {
  const BerandaState();

  @override
  List<Object?> get props => [];
}

class BerandaInitial extends BerandaState {
  const BerandaInitial();
}

class BerandaLoading extends BerandaState {
  const BerandaLoading();
}

class BerandaLoaded extends BerandaState {
  final List<ProjectModel> projects;
  final List<Map<String, dynamic>> topVendors;
  final List<BidModel> incomingBids;
  final ProfileModel? profile;

  const BerandaLoaded({
    this.projects = const [],
    this.topVendors = const [],
    this.incomingBids = const [],
    this.profile,
  });

  BerandaLoaded copyWith({
    List<ProjectModel>? projects,
    List<Map<String, dynamic>>? topVendors,
    List<BidModel>? incomingBids,
    ProfileModel? profile,
  }) {
    return BerandaLoaded(
      projects: projects ?? this.projects,
      topVendors: topVendors ?? this.topVendors,
      incomingBids: incomingBids ?? this.incomingBids,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [projects, topVendors, incomingBids, profile];
}

class BerandaError extends BerandaState {
  final String message;

  const BerandaError(this.message);

  @override
  List<Object?> get props => [message];
}
