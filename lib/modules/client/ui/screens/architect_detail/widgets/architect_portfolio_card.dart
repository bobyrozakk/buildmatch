import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ArchitectPortfolioCard extends StatelessWidget {
  final String title;
  final String? imgUrl;
  final String style;
  final double area;

  const ArchitectPortfolioCard({
    super.key,
    required this.title,
    required this.imgUrl,
    required this.style,
    required this.area,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: imgUrl != null
                ? Image.network(
                    imgUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.cardCream,
                      child: const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                    ),
                  )
                : Container(
                    color: AppColors.cardCream,
                    child: const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (style.isNotEmpty)
                      Flexible(
                        child: Text(
                          style,
                          style: const TextStyle(fontSize: 10, color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (style.isNotEmpty && area > 0)
                      const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.black38)),
                    if (area > 0)
                      Text('${area.toInt()} m²', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
