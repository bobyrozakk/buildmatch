import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/project_model.dart';

class DetailProyekTechnicalSpecs extends StatefulWidget {
  final ProjectModel project;

  const DetailProyekTechnicalSpecs({
    super.key,
    required this.project,
  });

  @override
  State<DetailProyekTechnicalSpecs> createState() => _DetailProyekTechnicalSpecsState();
}

class _DetailProyekTechnicalSpecsState extends State<DetailProyekTechnicalSpecs> {
  bool _specExpanded = false;

  Widget _specChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _specExpanded = !_specExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.architecture_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Spesifikasi Teknis Lengkap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  Icon(
                    _specExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_specExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: _specChip(
                        Icons.account_balance_wallet_outlined,
                        'Anggaran',
                        AppFormatters.formatRupiah(widget.project.budget),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(
                        Icons.terrain_outlined,
                        'Luas Tanah',
                        '${widget.project.landSize.toStringAsFixed(0)} m²',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(
                        Icons.home_outlined,
                        'Luas Bangunan',
                        '${widget.project.buildingSize.toStringAsFixed(0)} m²',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(Icons.layers_outlined, 'Lantai', '${widget.project.floors}'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(Icons.bed_outlined, 'Kamar Tidur', '${widget.project.bedrooms}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(Icons.bathtub_outlined, 'Kamar Mandi', '${widget.project.bathrooms}'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(Icons.style_outlined, 'Gaya', widget.project.houseStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(
                        Icons.location_on_outlined,
                        'Lokasi',
                        widget.project.location ?? '-',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
