import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shared BuildMatch branded AppBar used across auth screens.
/// Replaces the duplicated logo + title Row in 4+ files.
class BuildMatchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const BuildMatchAppBar({
    super.key,
    this.showBack = true,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: (showBack && Navigator.canPop(context))
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hardware_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'Build',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
            ]),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
