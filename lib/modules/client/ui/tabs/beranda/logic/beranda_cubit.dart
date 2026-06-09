import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'beranda_state.dart';

class BerandaCubit extends Cubit<BerandaState> {
  final ProjectCubit _projectCubit;
  final VendorCubit _vendorCubit;
  final SupabaseClient _supabase;

  BerandaCubit({
    required ProjectCubit projectCubit,
    required VendorCubit vendorCubit,
    SupabaseClient? supabase,
  })  : _projectCubit = projectCubit,
        _vendorCubit = vendorCubit,
        _supabase = supabase ?? Supabase.instance.client,
        super(const BerandaInitial());

  Future<void> loadBerandaData() async {
    emit(const BerandaLoading());
    try {
      final results = await Future.wait([
        _projectCubit.fetchProjects(),
        _vendorCubit.fetchTopVendors(),
        _projectCubit.fetchClientIncomingBids(),
        _fetchCurrentProfile(),
      ]);

      emit(BerandaLoaded(
        projects: results[0] as List<ProjectModel>,
        topVendors: results[1] as List<Map<String, dynamic>>,
        incomingBids: results[2] as List<BidModel>,
        profile: results[3] as ProfileModel?,
      ));
    } catch (e) {
      debugPrint('Error loading beranda data: $e');
      emit(BerandaError(e.toString()));
    }
  }

  Future<ProfileModel?> _fetchCurrentProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetch current client profile: $e');
      return null;
    }
  }
}
