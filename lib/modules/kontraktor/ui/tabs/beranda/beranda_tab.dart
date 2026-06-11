// lib/modules/kontraktor/ui/tabs/beranda/beranda_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/profile_edit/profile_edit_screen.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/detail_proyek/detail_proyek_screen.dart';

import 'widgets/beranda_app_bar.dart';
import 'widgets/beranda_welcome_card.dart';
import 'widgets/beranda_stats_row.dart';
import 'widgets/beranda_penawaran_list.dart';
import 'widgets/beranda_penawaran_diajukan_list.dart';
import 'widgets/beranda_proyek_berjalan.dart';

class BerandaTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const BerandaTab({super.key, this.onSwitchTab});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final vendor = context.read<VendorCubit>();
    final project = context.read<ContractorProjectCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatCubit>().fetchChats();
      }
    });

    vendor.fetchVendorProfile();
    project.fetchAvailableProjects();
    project.fetchVendorActiveProjects();
    project.fetchVendorBids(status: 'pending');
    vendor.fetchReviews(userId);
  }

  Future<void> _refresh() async {
    final vendor = context.read<VendorCubit>();
    final project = context.read<ContractorProjectCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    
    await Future.wait([
      vendor.fetchVendorProfile(),
      project.fetchAvailableProjects(),
      project.fetchVendorActiveProjects(),
      project.fetchVendorBids(status: 'pending'),
      vendor.fetchReviews(userId),
    ]);
  }

  // --- ACTIONS ---

  Future<void> _openEditProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    _loadData();
  }

  Future<void> _openProjectDetail(ProjectModel project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailProyekScreen(project: project)),
    );
    _refresh();
  }

  void _goToProyekTab() {
    widget.onSwitchTab?.call(1);
  }

  void _goToProgressTab() {
    widget.onSwitchTab?.call(3);
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: BlocBuilder<VendorCubit, VendorState>(
            builder: (context, vendorState) {
              return BlocBuilder<ContractorProjectCubit, ContractorProjectState>(
                builder: (context, projectState) {
                  if (vendorState is VendorLoading ||
                      vendorState is VendorInitial ||
                      projectState is ContractorProjectLoading ||
                      projectState is ContractorProjectInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  ProfileModel? profile;
                  List<Map<String, dynamic>> reviews = [];
                  if (vendorState is VendorLoaded) {
                    profile = vendorState.vendorProfile;
                    reviews = vendorState.reviews;
                  }

                  List<ProjectModel> tenders = [];
                  List<ProjectModel> activeProjects = [];
                  List<BidModel> submittedBids = [];
                  if (projectState is ContractorProjectLoaded) {
                    tenders = projectState.availableProjects;
                    activeProjects = projectState.activeProjects;
                    submittedBids = projectState.myBids;
                  }

                  double avgRating = 0.0;
                  if (reviews.isNotEmpty) {
                    final totalRating = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num? ?? 0.0));
                    avgRating = totalRating / reviews.length;
                  }
                  final ratingStr = reviews.isEmpty ? '0.0' : avgRating.toStringAsFixed(1);

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BerandaAppBar(
                          profile: profile,
                          onAvatarTap: _openEditProfile,
                        ),
                        const SizedBox(height: 20),
                        BerandaWelcomeCard(
                          profile: profile,
                          onTap: _openEditProfile,
                        ),
                        const SizedBox(height: 24),
                        BerandaStatsRow(
                          activeProjects: activeProjects,
                          ratingStr: ratingStr,
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader('Penawaran Masuk', onTap: _goToProyekTab),
                        const SizedBox(height: 12),
                        BerandaPenawaranList(
                          tenders: tenders,
                          onProjectTap: _openProjectDetail,
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader('Penawaran Diajukan', onTap: _goToProyekTab),
                        const SizedBox(height: 12),
                        BerandaPenawaranDiajukanList(
                          bids: submittedBids,
                          onProjectTap: _openProjectDetail,
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader('Proyek Berjalan', onTap: _goToProgressTab),
                        const SizedBox(height: 12),
                        BerandaProyekBerjalan(
                          activeProjects: activeProjects,
                          onProjectTap: _openProjectDetail,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- SECTION HEADER ---

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ],
    );
  }
}
