import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/bid_model.dart';
import '../../../data/providers/project_provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<List<BidModel>> _bidsFuture;
  late ProjectModel _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadBids();
  }

  void _loadBids() {
    _bidsFuture = Provider.of<ProjectProvider>(context, listen: false)
        .fetchProjectBids(_project.id ?? '');
  }

  void _refresh() {
    setState(() => _loadBids());
  }

  Future<void> _onAccept(BidModel bid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terima Penawaran?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Anda akan menerima penawaran dari ${bid.vendorName ?? 'kontraktor'} '
          'sebesar ${AppFormatters.formatRupiah(bid.price)}.\n\n'
          'Proyek akan berubah status menjadi "Berjalan".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final ok = await provider.acceptBid(
      bidId: bid.id ?? '',
      projectId: _project.id ?? '',
    );

    if (!mounted) return;
    if (ok) {
      // Update status proyek lokal
      setState(() {
        _project = ProjectModel(
          id: _project.id,
          title: _project.title,
          description: _project.description,
          budget: _project.budget,
          landSize: _project.landSize,
          buildingSize: _project.buildingSize,
          floors: _project.floors,
          bedrooms: _project.bedrooms,
          bathrooms: _project.bathrooms,
          houseStyle: _project.houseStyle,
          location: _project.location,
          latitude: _project.latitude,
          longitude: _project.longitude,
          clientId: _project.clientId,
          imageUrls: _project.imageUrls,
          referencePdfUrl: _project.referencePdfUrl,
          status: 'in_progress',
          progressPercent: _project.progressPercent,
          createdAt: _project.createdAt,
          clientName: _project.clientName,
        );
      });
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Penawaran diterima! Proyek mulai berjalan.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menerima penawaran, coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onReject(BidModel bid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Penawaran?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Penawaran dari ${bid.vendorName ?? 'kontraktor'} akan ditolak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final ok = await provider.rejectBid(bidId: bid.id ?? '');

    if (!mounted) return;
    if (ok) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penawaran ditolak.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menolak penawaran, coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _project.status == 'in_progress';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Proyek',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BANNER PROYEK ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                image: _project.imageUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_project.imageUrls[0]),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4), BlendMode.darken),
                      )
                    : null,
              ),
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInProgress ? Colors.blue : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isInProgress ? 'BERJALAN' : 'LIVE TENDER',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_project.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ${AppFormatters.formatRupiah(_project.budget)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Informasi Bangunan',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoChip(Icons.square_foot,
                    '${_project.buildingSize.toStringAsFixed(0)} m²'),
                const SizedBox(width: 12),
                _buildInfoChip(
                    Icons.layers, '${_project.floors} Lantai'),
                const SizedBox(width: 12),
                _buildInfoChip(
                    Icons.bed, '${_project.bedrooms} Kamar'),
              ],
            ),

            const SizedBox(height: 32),

            // --- DAFTAR BID REAL ---
            Row(
              children: [
                const Text('Daftar Penawaran (Bids)',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isInProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Proyek Berjalan',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<BidModel>>(
              future: _bidsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }

                final bids = snapshot.data ?? [];

                if (bids.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: Colors.black26),
                          SizedBox(height: 12),
                          Text('Belum ada penawaran masuk',
                              style: TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: bids
                      .map((bid) => _buildBidItem(bid, isInProgress))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBidItem(BidModel bid, bool projectInProgress) {
    final isPending = bid.status == 'pending';
    final isAccepted = bid.status == 'accepted';
    final isRejected = bid.status == 'rejected';

    Color statusColor = Colors.orange;
    String statusLabel = 'Menunggu';
    if (isAccepted) {
      statusColor = Colors.green;
      statusLabel = 'Diterima';
    } else if (isRejected) {
      statusColor = Colors.red;
      statusLabel = 'Ditolak';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAccepted
            ? Border.all(color: Colors.green.shade200, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: nama + status
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.cardCream,
                child: Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.vendorName ?? 'Kontraktor',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatRupiah(bid.price),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Pesan kontraktor
          if (bid.message != null && bid.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bid.message!,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4),
              ),
            ),
          ],

          // Tombol Terima/Tolak (hanya jika proyek masih open & bid masih pending)
          if (!projectInProgress && isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onReject(bid),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tolak',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onAccept(bid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terima',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}