import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? iconColor;
  final Color? titleColor;

  const SettingsItem({
    required this.icon,
    required this.title,
    required this.isDark,
    this.value,
    this.trailing,
    this.child,
    this.onTap,
    this.iconColor,
    this.titleColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor != null ? iconColor!.withOpacity(0.1) : (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? (isDark ? LinkDropColors.zinc400 : LinkDropColors.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? (isDark ? LinkDropColors.zinc200 : LinkDropColors.textPrimary),
                    ),
                  ),
                  if (child != null) child!,
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14,
                  color: LinkDropColors.textSecondary,
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
