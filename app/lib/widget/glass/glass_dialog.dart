import 'dart:ui';

import 'package:flutter/material.dart';

/// 毛玻璃弹窗包装器
///
/// 为AlertDialog提供毛玻璃背景效果
/// 使用BackdropFilter实现背景模糊
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;

  const GlassDialog({
    required this.child,
    this.blurSigma = 10,
    this.opacity = 0.85,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃卡片包装器
///
/// 为Card组件提供毛玻璃背景效果
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.blurSigma = 10,
    this.opacity = 0.7,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}
