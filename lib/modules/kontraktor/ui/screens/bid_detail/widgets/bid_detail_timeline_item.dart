import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class BidDetailTimelineItem extends StatelessWidget {
  final bool active;
  final String title;

  const BidDetailTimelineItem({
    super.key,
    required this.active,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.black87 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
