import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';

class ContractorTabContent extends StatefulWidget {
  const ContractorTabContent({super.key});

  @override
  State<ContractorTabContent> createState() => _ContractorTabContentState();
}

class _ContractorTabContentState extends State<ContractorTabContent> {
  final _searchContractorController = TextEditingController();
  String _searchContractor = '';

  @override
  void dispose() {
    _searchContractorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: IOSGlassCard(
            blur: 15,
            child: TextField(
              controller: _searchContractorController,
              onChanged: (v) => setState(() => _searchContractor = v),
              decoration: const InputDecoration(
                hintText: "Cari nama kontraktor...",
                hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryDark),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: BlocBuilder<VendorCubit, VendorState>(
            builder: (context, state) {
              if (state is VendorInitial || state is VendorLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
              }

              if (state is VendorError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Gagal memuat data: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (state is VendorLoaded) {
                final all = state.vendors;
                final filtered = _searchContractor.isEmpty
                    ? all
                    : all.where((v) => v.name.toLowerCase().contains(_searchContractor.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyContractors();
                }

                return RefreshIndicator(
                  color: AppColors.primaryDark,
                  onRefresh: () async => context.read<VendorCubit>().fetchVendors(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final vendor = filtered[index];
                      return _buildVendorCard(vendor);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(ProfileModel vendor) {
    return IOSGlassCard(
      blur: 20,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(vendor.name)}&background=B53D1B&color=fff&size=128',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor.name.isNotEmpty ? vendor.name : 'Kontraktor Tanpa Nama',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Spesialis Konstruksi & Renovasi", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Text(
                        " ${vendor.avgRating?.toStringAsFixed(1) ?? '0.0'}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.phone, color: Colors.black38, size: 14),
                      Text(" ${vendor.phone ?? 'Tidak ada No. HP'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContractors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada Mitra Kontraktor", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
          const Text("Sistem sedang menunggu kontraktor bergabung.", style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}
