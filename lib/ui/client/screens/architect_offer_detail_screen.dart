import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/providers/project_provider.dart';
import '../../../../data/providers/architect_provider.dart';
import '../../../../data/models/payment_term_model.dart';
import '../../../../core/constants/colors.dart';

class ArchitectOfferDetailScreen extends StatefulWidget {
  final String bidId;
  final String title;
  final double price;
  final String description;
  final int revisions;
  final int durationDays;
  final String architectName;

  const ArchitectOfferDetailScreen({
    super.key,
    required this.bidId,
    required this.title,
    required this.price,
    required this.description,
    required this.revisions,
    required this.durationDays,
    required this.architectName,
  });

  @override
  State<ArchitectOfferDetailScreen> createState() => _ArchitectOfferDetailScreenState();
}

class _ArchitectOfferDetailScreenState extends State<ArchitectOfferDetailScreen> {
  bool _isLoading = false;
  PaymentTermModel? _paymentTerm;
  String? _selectedBank;
  String? _vaNumber;
  Map<String, dynamic>? _bidDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);
    final architectProv = Provider.of<ArchitectProvider>(context, listen: false);

    try {
      _paymentTerm = await projectProv.fetchPaymentTermByBidId(widget.bidId);
      _bidDetails = await architectProv.fetchBidById(widget.bidId);
      
      if (_paymentTerm != null && _paymentTerm!.paymentMethod != null) {
        _selectedBank = _paymentTerm!.paymentMethod;
        _vaNumber = _paymentTerm!.virtualAccountNumber;
      }
    } catch (e) {
      debugPrint('Error loading offer detail data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateVA(String bank) {
    setState(() {
      _selectedBank = bank;
      _vaNumber = ProjectProvider.generateVirtualAccount(bank);
    });
  }

  Future<void> _processPayment() async {
    if (_selectedBank == null || _vaNumber == null) return;
    if (_bidDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan informasi penawaran.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);

    final projectId = _bidDetails!['project_id'] as String;
    final vendorId = _bidDetails!['vendor_id'] as String;

    try {
      final term = await projectProv.createArchitectPaymentTerm(
        bidId: widget.bidId,
        projectId: projectId,
        vendorId: vendorId,
        amount: widget.price,
        paymentMethod: _selectedBank!,
        virtualAccountNumber: _vaNumber!,
      );

      if (term != null) {
        setState(() {
          _paymentTerm = term;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Konfirmasi pembayaran terkirim! Menunggu persetujuan arsitek.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat termin pembayaran.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penawaran Desain',
          style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading && _paymentTerm == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detail Penawaran Card
                  _buildOfferDetailCard(currencyFmt),
                  const SizedBox(height: 24),

                  // Payment Status / Action Section
                  if (_paymentTerm == null) ...[
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildBankGrid(),
                    if (_selectedBank != null && _vaNumber != null) ...[
                      const SizedBox(height: 20),
                      _buildVirtualAccountCard(currencyFmt),
                    ],
                    const SizedBox(height: 30),
                    _buildPayButton(),
                  ] else ...[
                    _buildPaymentStatusSection(currencyFmt),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildOfferDetailCard(NumberFormat currencyFmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 18,
                child: const Icon(Icons.architecture_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.architectName,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.payments_outlined, 'Total Harga', currencyFmt.format(widget.price), isPrice: true),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.loop_rounded, 'Batas Maksimal Revisi', '${widget.revisions} kali revisi'),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.schedule_rounded, 'Estimasi Durasi Pengerjaan', '${widget.durationDays} hari'),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Deskripsi Penawaran:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isPrice ? AppColors.primary : Colors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isPrice ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankGrid() {
    final List<Map<String, dynamic>> banks = [
      {'code': 'bca', 'label': 'BCA', 'color': const Color(0xFF0066AE)},
      {'code': 'bni', 'label': 'BNI', 'color': const Color(0xFFFF6600)},
      {'code': 'mandiri', 'label': 'Mandiri', 'color': const Color(0xFF003087)},
      {'code': 'bri', 'label': 'BRI', 'color': const Color(0xFF00A650)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: banks.map((bank) {
        final isSelected = _selectedBank == bank['code'];
        return GestureDetector(
          onTap: () => _generateVA(bank['code']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? bank['color'].withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? bank['color'] : const Color(0xFFE5DCD3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                bank['label'],
                style: TextStyle(
                  color: isSelected ? bank['color'] : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVirtualAccountCard(NumberFormat currencyFmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor Virtual Account',
            style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.numbers_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _vaNumber!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _vaNumber!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Silakan transfer sebesar ${currencyFmt.format(widget.price)} ke nomor VA diatas. Setelah pembayaran berhasil, klik tombol "Saya Sudah Membayar" di bawah ini.',
            style: const TextStyle(fontSize: 11, color: Colors.black45, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _selectedBank == null ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedBank != null ? const Color(0xFF5C1C08) : Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(Icons.check_circle_outline_rounded, color: _selectedBank != null ? Colors.white : Colors.grey, size: 18),
        label: Text(
          _selectedBank == null ? 'Pilih bank transfer di atas' : 'Saya Sudah Membayar',
          style: TextStyle(
            color: _selectedBank != null ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusSection(NumberFormat currencyFmt) {
    if (_paymentTerm == null) return const SizedBox.shrink();

    Color statusColor = Colors.orange;
    String statusTitle = 'Menunggu Konfirmasi Pembayaran';
    String statusDesc = 'Kamu telah mengklaim pembayaran. Silakan tunggu arsitek menyetujui transaksi ini di chat.';
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (_paymentTerm!.isConfirmed) {
      statusColor = Colors.green;
      statusTitle = 'Pembayaran Diterima';
      statusDesc = 'Pembayaran terkonfirmasi! Arsitek sedang mengerjakan desain Anda. Pantau chat Anda secara berkala.';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (_paymentTerm!.isProgressSubmitted) {
      statusColor = Colors.teal;
      statusTitle = 'Desain Selesai Dikirim';
      statusDesc = 'Arsitek telah menyerahkan draf desain. Silakan tinjau dan tanggapi draf tersebut di chat.';
      statusIcon = Icons.architecture_rounded;
    } else if (_paymentTerm!.isRevisionRequested) {
      statusColor = Colors.orange.shade700;
      statusTitle = 'Revisi Sedang Diproses';
      statusDesc = 'Kamu telah mengajukan revisi. Arsitek sedang memperbaiki berkas desain sesuai masukan kamu.';
      statusIcon = Icons.edit_note_rounded;
    } else if (_paymentTerm!.isCompleted) {
      statusColor = Colors.blue.shade700;
      statusTitle = 'Proyek Selesai';
      statusDesc = 'Selamat! Desain telah disetujui secara formal dan proyek konsultasi ini sudah selesai.';
      statusIcon = Icons.verified_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusDesc,
            style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.85), height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: Colors.black54)),
                Text(
                  'VA ${_paymentTerm!.paymentMethod?.toUpperCase() ?? '-'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
