import 'package:flutter/material.dart';

class ArchitectOfferBankGrid extends StatelessWidget {
  final String? selectedBank;
  final ValueChanged<String> onBankSelected;

  const ArchitectOfferBankGrid({
    super.key,
    required this.selectedBank,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
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
        final isSelected = selectedBank == bank['code'];
        return GestureDetector(
          onTap: () => onBankSelected(bank['code']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? bank['color'].withValues(alpha: 0.08) : Colors.white,
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
}
