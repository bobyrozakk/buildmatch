import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';

class ArchitectOfferDetailCard extends StatelessWidget {
  final String architectName;
  final String title;
  final double price;
  final String description;
  final int revisions;
  final int durationDays;
  final PaymentTermModel? paymentTerm;

  const ArchitectOfferDetailCard({
    super.key,
    required this.architectName,
    required this.title,
    required this.price,
    required this.description,
    required this.revisions,
    required this.durationDays,
    required this.paymentTerm,
  });

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

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 18,
                child: const Icon(Icons.architecture_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      architectName,
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      title,
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
          _buildDetailRow(Icons.payments_outlined, 'Total Harga', currencyFmt.format(price), isPrice: true),
          if (paymentTerm != null) ...[
            const SizedBox(height: 10),
            _buildDetailRow(
              Icons.info_outline,
              'Termin Pembayaran Aktif',
              '${paymentTerm!.name} (${paymentTerm!.percentage.round()}%): ${currencyFmt.format(paymentTerm!.amount)}',
            ),
          ],
          const SizedBox(height: 10),
          _buildDetailRow(Icons.loop_rounded, 'Batas Maksimal Revisi', '$revisions kali revisi'),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.schedule_rounded, 'Estimasi Durasi Pengerjaan', '$durationDays hari'),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Deskripsi Penawaran:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
