import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class FilterSortSheet extends StatefulWidget {
  final String selectedSort;
  final bool showProgressSort;
  final ValueChanged<String> onSortApplied;

  const FilterSortSheet({
    super.key,
    required this.selectedSort,
    required this.showProgressSort,
    required this.onSortApplied,
  });

  @override
  State<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<FilterSortSheet> {
  late String _tempSelectedSort;

  @override
  void initState() {
    super.initState();
    _tempSelectedSort = widget.selectedSort;
  }

  Widget _buildRadioOption(String value, String label, IconData icon) {
    final isSelected = _tempSelectedSort == value;
    return InkWell(
      onTap: () {
        setState(() {
          _tempSelectedSort = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : Colors.black54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _tempSelectedSort,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _tempSelectedSort = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Row(
            children: [
              Icon(Icons.sort_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Urutkan Proyek',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Options
          _buildRadioOption('terbaru', 'Terbaru ke Terlama', Icons.calendar_today_rounded),
          _buildRadioOption('terlama', 'Terlama ke Terbaru', Icons.history_rounded),
          _buildRadioOption('termahal', 'Nilai Penawaran Tertinggi', Icons.trending_up_rounded),
          _buildRadioOption('termurah', 'Nilai Penawaran Terendah', Icons.trending_down_rounded),
          if (widget.showProgressSort)
            _buildRadioOption('progress', 'Progress Terbanyak', Icons.align_vertical_bottom_rounded),

          const SizedBox(height: 24),

          // Apply button
          ElevatedButton(
            onPressed: () {
              widget.onSortApplied(_tempSelectedSort);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Terapkan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
