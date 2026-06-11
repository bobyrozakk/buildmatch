import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';

class DetailProyekDescription extends StatelessWidget {
  final ProjectModel project;

  const DetailProyekDescription({
    super.key,
    required this.project,
  });

  Widget _miniSpecTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Deskripsi Proyek', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(
            project.description?.isNotEmpty == true ? project.description! : 'Tidak ada deskripsi rinci.',
            style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniSpecTile('Luas Bangunan', '${project.buildingSize.toStringAsFixed(0)} m²'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniSpecTile('Luas Tanah', '${project.landSize.toStringAsFixed(0)} m²'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniSpecTile('Gaya', project.houseStyle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniSpecTile('Lantai', '${project.floors}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
