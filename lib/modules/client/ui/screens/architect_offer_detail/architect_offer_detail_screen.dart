import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/data/providers/architect_provider.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/providers/chat_provider.dart';
import 'widgets/architect_offer_detail_card.dart';
import 'widgets/architect_offer_bank_grid.dart';
import 'widgets/architect_offer_va_card.dart';
import 'widgets/architect_offer_payment_status.dart';

class ArchitectOfferDetailScreen extends StatefulWidget {
  final String bidId;
  final String title;
  final double price;
  final String description;
  final int revisions;
  final int durationDays;
  final String architectName;
  final String? chatId;

  const ArchitectOfferDetailScreen({
    super.key,
    required this.bidId,
    required this.title,
    required this.price,
    required this.description,
    required this.revisions,
    required this.durationDays,
    required this.architectName,
    this.chatId,
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

    setState(() => _isLoading = true);
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);

    try {
      if (_paymentTerm == null) {
        if (_bidDetails == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendapatkan informasi penawaran.'), backgroundColor: Colors.red),
          );
          return;
        }

        final projectId = _bidDetails!['project_id'] as String;
        final vendorId = _bidDetails!['vendor_id'] as String;

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
          if (widget.chatId != null) {
            final chatProv = Provider.of<ChatProvider>(context, listen: false);
            final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            final percentage = term.percentage.round();
            if (percentage < 100) {
              await chatProv.sendMessage(
                widget.chatId!,
                '💸 Client telah melakukan pembayaran awal (DP $percentage%) sebesar ${formatter.format(term.amount)}! Menunggu konfirmasi arsitek.',
                bidId: widget.bidId,
              );
            } else {
              await chatProv.sendMessage(
                widget.chatId!,
                '💸 Client telah melakukan pembayaran penuh (100%) sebesar ${formatter.format(term.amount)}! Menunggu konfirmasi arsitek.',
                bidId: widget.bidId,
              );
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Konfirmasi pembayaran terkirim! Menunggu persetujuan arsitek.'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat termin pembayaran. Silakan minta arsitek untuk mengirim penawaran baru.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final success = await projectProv.clientMarkAsPaid(
          termId: _paymentTerm!.id!,
          paymentMethod: _selectedBank!,
          virtualAccountNumber: _vaNumber!,
        );

        if (success) {
          if (widget.chatId != null && _paymentTerm != null) {
            final chatProv = Provider.of<ChatProvider>(context, listen: false);
            final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            final orderIndex = _paymentTerm!.orderIndex;
            if (orderIndex > 1) {
              await chatProv.sendMessage(
                widget.chatId!,
                '💸 Client telah membayar pelunasan desain sebesar ${formatter.format(_paymentTerm!.amount)}! Menunggu konfirmasi arsitek.',
                bidId: widget.bidId,
              );
            } else {
              final percentage = _paymentTerm!.percentage.round();
              await chatProv.sendMessage(
                widget.chatId!,
                '💸 Client telah membayar pembayaran desain sebesar ${formatter.format(_paymentTerm!.amount)} ($percentage%)! Menunggu konfirmasi arsitek.',
                bidId: widget.bidId,
              );
            }
          }
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Konfirmasi pembayaran terkirim! Menunggu persetujuan arsitek.'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal melakukan konfirmasi pembayaran.'), backgroundColor: Colors.red),
          );
        }
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

    final actualStatus = _bidDetails?['status'] as String? ?? 'pending';
    final createdAtData = _bidDetails?['created_at'];
    DateTime? createdAt;
    if (createdAtData is DateTime) {
      createdAt = createdAtData;
    } else if (createdAtData is String) {
      createdAt = DateTime.tryParse(createdAtData);
    }
    
    final isCancelled = actualStatus == 'cancelled';
    final isExpired = actualStatus == 'expired' || 
        (actualStatus == 'pending' && 
         (_paymentTerm == null || _paymentTerm!.isPending) && 
         createdAt != null && 
         DateTime.now().difference(createdAt).inHours >= 24);

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
                  ArchitectOfferDetailCard(
                    architectName: widget.architectName,
                    title: widget.title,
                    price: widget.price,
                    description: widget.description,
                    revisions: widget.revisions,
                    durationDays: widget.durationDays,
                    paymentTerm: _paymentTerm,
                  ),
                  const SizedBox(height: 24),

                  if (isCancelled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Penawaran Dibatalkan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Penawaran ini telah dibatalkan oleh arsitek. Hubungi arsitek melalui chat untuk meminta penawaran baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isExpired) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade100, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: Colors.red.shade700, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Penawaran Kadaluarsa',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Batas waktu pembayaran untuk penawaran ini (24 jam) telah habis. Anda tidak dapat melakukan pembayaran. Hubungi arsitek melalui chat untuk meminta penawaran baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_paymentTerm == null || _paymentTerm!.isPending) ...[
                    const Text(
                      'Pilih Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ArchitectOfferBankGrid(
                      selectedBank: _selectedBank,
                      onBankSelected: _generateVA,
                    ),
                    if (_selectedBank != null && _vaNumber != null) ...[
                      const SizedBox(height: 20),
                      ArchitectOfferVaCard(
                        vaNumber: _vaNumber!,
                        amount: _paymentTerm?.amount ?? widget.price,
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildPayButton(),
                  ] else ...[
                    ArchitectOfferPaymentStatus(paymentTerm: _paymentTerm!),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
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
}
