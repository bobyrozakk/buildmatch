import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/providers/vendor_provider.dart';
import 'package:buildmatch/data/providers/architect_provider.dart';

// Extracted Tab Content Widgets
import 'widgets/contractor_tab_content.dart';
import 'widgets/architect_tab_content.dart';

class MitraTab extends StatefulWidget {
  final int initialTab;
  const MitraTab({super.key, this.initialTab = 0});

  @override
  State<MitraTab> createState() => _MitraTabState();
}

class _MitraTabState extends State<MitraTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ProfileModel>> _vendorsFuture;
  late Future<List<Map<String, dynamic>>> _architectsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTab,
    );
    _vendorsFuture = Provider.of<VendorProvider>(context, listen: false).fetchVendors();
    _architectsFuture = Provider.of<ArchitectProvider>(context, listen: false).fetchAllArchitects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshVendors() async {
    setState(() {
      _vendorsFuture = Provider.of<VendorProvider>(context, listen: false).fetchVendors();
    });
    await _vendorsFuture;
  }

  Future<void> _refreshArchitects() async {
    setState(() {
      _architectsFuture = Provider.of<ArchitectProvider>(context, listen: false).fetchAllArchitects();
    });
    await _architectsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mitra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black45,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Kontraktor'),
            Tab(text: 'Arsitek'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)], // Pastel gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            ContractorTabContent(
              vendorsFuture: _vendorsFuture,
              onRefresh: _refreshVendors,
            ),
            ArchitectTabContent(
              architectsFuture: _architectsFuture,
              onRefresh: _refreshArchitects,
            ),
          ],
        ),
      ),
    );
  }
}
