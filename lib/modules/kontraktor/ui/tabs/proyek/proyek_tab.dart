// lib/modules/kontraktor/ui/tabs/proyek/proyek_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/detail_proyek/detail_proyek_screen.dart';
import 'package:buildmatch/ui/shared/widgets/location_picker_sheet.dart';
import 'package:buildmatch/core/constants/colors.dart';

import 'widgets/proyek_header.dart';
import 'widgets/proyek_search_row.dart';
import 'widgets/proyek_filter_chips.dart';
import 'widgets/proyek_project_card.dart';
import 'widgets/proyek_bid_card.dart';
import 'widgets/proyek_empty_state.dart';

class ProyekTab extends StatefulWidget {
  const ProyekTab({super.key});

  @override
  State<ProyekTab> createState() => _ProyekTabState();
}

class _ProyekTabState extends State<ProyekTab> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  LocationResult _location = const LocationResult();

  static const _filters = ['Semua', 'Baru', 'Penawaran Diajukan', 'Penawaran Diterima', 'Budget Tinggi'];

  bool get _isBidFilter => _selectedFilter == 'Penawaran Diajukan' || _selectedFilter == 'Penawaran Diterima';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final p = context.read<ContractorProjectCubit>();
    p.fetchAvailableProjects();
    p.fetchVendorBids();
  }

  Future<void> _refresh() async {
    final p = context.read<ContractorProjectCubit>();
    await Future.wait([p.fetchAvailableProjects(), p.fetchVendorBids()]);
  }

  void _openDetail(ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailProyekScreen(project: p)),
    ).then((_) => _refresh());
  }

  Future<void> _showLocationPicker() async {
    final result = await LocationPickerSheet.show(context, initial: _location);
    if (result != null) setState(() => _location = result);
  }

  bool _matchesSearchAndLocation(ProjectModel? p) {
    if (p == null) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final ok = p.title.toLowerCase().contains(q) ||
          (p.location?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false);
      if (!ok) return false;
    }
    final locFilter = _location.city ?? _location.province;
    if (locFilter != null) {
      if (!(p.location?.toLowerCase().contains(locFilter.toLowerCase()) ?? false)) return false;
    }
    return true;
  }

  List<ProjectModel> _applyProjectFilters(List<ProjectModel> projects) {
    var filtered = projects.where(_matchesSearchAndLocation).toList();
    if (_selectedFilter == 'Baru') {
      filtered = filtered.where((p) =>
          p.createdAt != null && DateTime.now().difference(p.createdAt!).inDays <= 3).toList();
    } else if (_selectedFilter == 'Budget Tinggi') {
      filtered.sort((a, b) => b.budget.compareTo(a.budget));
    }
    return filtered;
  }

  List<BidModel> _applyBidFilters(List<BidModel> bids) {
    final wantStatus = _selectedFilter == 'Penawaran Diajukan' ? 'pending' : 'accepted';
    return bids
        .where((b) => b.status == wantStatus)
        .where((b) => _matchesSearchAndLocation(b.project))
        .toList();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: BlocBuilder<ContractorProjectCubit, ContractorProjectState>(
          builder: (context, state) {
            if (state is ContractorProjectLoading || state is ContractorProjectInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is ContractorProjectError) {
              return Center(child: Text(state.message));
            }
            if (state is ContractorProjectLoaded) {
              final allProjects = state.availableProjects;
              final allBids = state.myBids;

              final filteredProjects = _isBidFilter ? const <ProjectModel>[] : _applyProjectFilters(allProjects);
              final filteredBids = _isBidFilter ? _applyBidFilters(allBids) : const <BidModel>[];
              final itemCount = _isBidFilter ? filteredBids.length : filteredProjects.length;
              final headerCount = _isBidFilter ? allBids.where((b) => b.status == (_selectedFilter == 'Penawaran Diajukan' ? 'pending' : 'accepted')).length : allProjects.length;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: ProyekHeader(
                          isBidFilter: _isBidFilter,
                          selectedFilter: _selectedFilter,
                          totalCount: headerCount,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: ProyekSearchRow(
                          searchQuery: _searchQuery,
                          onSearchChanged: (v) => setState(() => _searchQuery = v),
                          location: _location,
                          onLocationTap: _showLocationPicker,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProyekFilterChips(
                        filters: _filters,
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (f) => setState(() => _selectedFilter = f),
                      ),
                    ),
                    if (itemCount == 0)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: ProyekEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _isBidFilter
                                  ? ProyekBidCard(
                                      bid: filteredBids[i],
                                      onTap: filteredBids[i].project == null
                                          ? () {}
                                          : () => _openDetail(filteredBids[i].project!),
                                    )
                                  : ProyekProjectCard(
                                      project: filteredProjects[i],
                                      hasBid: allBids.any((b) => b.projectId == filteredProjects[i].id),
                                      onTap: () => _openDetail(filteredProjects[i]),
                                      onBidTap: () => _openDetail(filteredProjects[i]),
                                    ),
                            ),
                            childCount: itemCount,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
