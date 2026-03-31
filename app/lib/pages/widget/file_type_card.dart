import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class FileTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onTap;
  final bool isDark;

  const FileTypeCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.isDark,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDark ? LinkDropColors.zinc500 : LinkDropColors.zinc500,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? LinkDropColors.zinc200 : LinkDropColors.zinc900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count files',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
