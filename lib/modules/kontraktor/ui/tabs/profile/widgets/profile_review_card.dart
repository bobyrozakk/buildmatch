import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ProfileReviewCard({
    super.key,
    required this.review,
  });

  String _formatReviewDate(DateTime? date) {
    if (date == null) return "Baru saja";
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (diff.inDays > 0) {
      return "${diff.inDays} hari lalu";
    } else if (diff.inHours > 0) {
      return "${diff.inHours} jam lalu";
    } else {
      return "Baru saja";
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProfile = review['profiles'] as Map<String, dynamic>?;
    final project = review['projects'] as Map<String, dynamic>?;
    final clientName = clientProfile?['name'] as String? ?? 'Klien';
    final projectName = project?['title'] as String? ?? 'Proyek';
    final ratingVal = review['rating'] as int? ?? 5;
    final commentText = review['comment'] as String? ?? '';
    final createdAtStr = review['created_at'] != null
        ? _formatReviewDate(DateTime.tryParse(review['created_at'] as String))
        : 'Baru saja';
    final initials = clientName.isNotEmpty ? clientName[0].toUpperCase() : 'K';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.cardCream,
                radius: 18,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            clientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < ratingVal ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.orange,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Proyek: $projectName', style: const TextStyle(color: Colors.black45, fontSize: 10)),
                  ],
                ),
              ),
              Text(createdAtStr, style: const TextStyle(color: Colors.black38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$commentText"',
            style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
