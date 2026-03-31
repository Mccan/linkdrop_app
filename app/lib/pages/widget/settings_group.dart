import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const SettingsGroup({
    required this.title,
    required this.children,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LinkDropColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
          ),
          ...children,
        ],
      ),
    );
  }
}
