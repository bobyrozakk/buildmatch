import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';

class ArchitectOfferPaymentStatus extends StatelessWidget {
  final PaymentTermModel paymentTerm;

  const ArchitectOfferPaymentStatus({
    super.key,
    required this.paymentTerm,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.orange;
    String statusTitle = 'Menunggu Konfirmasi Pembayaran';
    String statusDesc = 'Kamu telah mengklaim pembayaran. Silakan tunggu arsitek menyetujui transaksi ini di chat.';
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (paymentTerm.isConfirmed) {
      statusColor = Colors.green;
      statusTitle = 'Pembayaran Diterima';
      statusDesc = 'Pembayaran terkonfirmasi! Arsitek sedang mengerjakan desain Anda. Pantau chat Anda secara berkala.';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (paymentTerm.isProgressSubmitted) {
      statusColor = Colors.teal;
      statusTitle = 'Desain Selesai Dikirim';
      statusDesc = 'Arsitek telah menyerahkan draf desain. Silakan tinjau dan tanggapi draf tersebut di chat.';
      statusIcon = Icons.architecture_rounded;
    } else if (paymentTerm.isRevisionRequested) {
      statusColor = Colors.orange.shade700;
      statusTitle = 'Revisi Sedang Diproses';
      statusDesc = 'Kamu telah mengajukan revisi. Arsitek sedang memperbaiki berkas desain sesuai masukan kamu.';
      statusIcon = Icons.edit_note_rounded;
    } else if (paymentTerm.isCompleted) {
      statusColor = Colors.blue.shade700;
      statusTitle = 'Proyek Selesai';
      statusDesc = 'Selamat! Desain telah disetujui secara formal dan proyek konsultasi ini sudah selesai.';
      statusIcon = Icons.verified_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
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
            style: TextStyle(fontSize: 12, color: statusColor.withValues(alpha: 0.85), height: 1.4),
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
                  'VA ${paymentTerm.paymentMethod?.toUpperCase() ?? '-'}',
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
