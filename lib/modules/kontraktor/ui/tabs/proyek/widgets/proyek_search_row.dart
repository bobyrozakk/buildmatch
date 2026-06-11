import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/ui/shared/widgets/location_picker_sheet.dart';

class ProyekSearchRow extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final LocationResult location;
  final VoidCallback onLocationTap;

  const ProyekSearchRow({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.location,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Cari proyek...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onLocationTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(location.short, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
