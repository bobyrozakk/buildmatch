import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ArchitectOfferVaCard extends StatelessWidget {
  final String vaNumber;
  final double amount;

  const ArchitectOfferVaCard({
    super.key,
    required this.vaNumber,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

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
                  vaNumber,
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
                  Clipboard.setData(ClipboardData(text: vaNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Silakan transfer sebesar ${currencyFmt.format(amount)} ke nomor VA diatas. Setelah pembayaran berhasil, klik tombol "Saya Sudah Membayar" di bawah ini.',
            style: const TextStyle(fontSize: 11, color: Colors.black45, height: 1.4),
          ),
        ],
      ),
    );
  }
}
