import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class AboutContentPage extends StatelessWidget {
  final String title;
  final String content;

  const AboutContentPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc900 : Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              MediaQuery.of(context).padding.top + 16,
              32,
              16,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
