import 'package:flutter/material.dart';

class CreateProjectConstraintInfo extends StatelessWidget {
  final int floors;
  final int maxBedrooms;
  final int bedrooms;
  final int maxBathrooms;
  final double effectiveLandSize;
  final int maxFloors;

  const CreateProjectConstraintInfo({
    super.key,
    required this.floors,
    required this.maxBedrooms,
    required this.bedrooms,
    required this.maxBathrooms,
    required this.effectiveLandSize,
    required this.maxFloors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B2B0F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B2B0F).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8B2B0F),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panduan Spesifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2B0F),
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoLine(
                  '$floors lantai → maks $maxBedrooms kamar tidur '
                  '($floors × 4)',
                ),
                _buildInfoLine(
                  '$bedrooms kamar tidur → maks $maxBathrooms kamar mandi',
                ),
                _buildInfoLine(
                  effectiveLandSize > 0
                      ? 'Tanah ${effectiveLandSize.toStringAsFixed(0)} m² → maks $maxFloors lantai'
                      : 'Pilih template tanah (Step 3) untuk batas lantai',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '• $text',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
