import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

/// LinkDrop 统一卡片组件
///
/// 支持三种状态：默认、悬停、选中
/// - 默认: 白色背景 + #e8e8e8 边框
/// - 悬停: 边框变 #d4a574 + 微弱阴影
/// - 选中: 渐变背景 #fdfbf8 → #f9f5f0 + #d4a574 边框
class LinkDropCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isHoverable;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final double borderWidth;

  const LinkDropCard({
    required this.child,
    this.isSelected = false,
    this.isHoverable = true,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.borderWidth = 1,
    super.key,
  });

  @override
  State<LinkDropCard> createState() => _LinkDropCardState();
}

class _LinkDropCardState extends State<LinkDropCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: widget.isHoverable ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.isHoverable ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // 选中状态使用渐变背景
            gradient: widget.isSelected && !isDark
                ? LinkDropColors.primaryGradientVertical
                : null,
            color: widget.backgroundColor ??
                (widget.isSelected
                    ? (isDark ? LinkDropColors.zinc800 : null)
                    : (isDark ? LinkDropColors.zinc900 : LinkDropColors.white)),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _getBorderColor(isDark),
              width: widget.isSelected ? 2 : widget.borderWidth,
            ),
            boxShadow: _isHovered || widget.isSelected
                ? [
                    BoxShadow(
                      color: LinkDropColors.shadowPrimary,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Color _getBorderColor(bool isDark) {
    if (widget.isSelected) {
      return LinkDropColors.primary;
    }
    if (_isHovered && widget.isHoverable) {
      return LinkDropColors.primary;
    }
    return isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight;
  }
}

/// 紧凑型卡片变体
///
/// 用于列表项、设备节点等场景
class LinkDropCardCompact extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LinkDropCardCompact({
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  State<LinkDropCardCompact> createState() => _LinkDropCardCompactState();
}

class _LinkDropCardCompactState extends State<LinkDropCardCompact> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? LinkDropColors.primary
                  : _isHovered
                      ? LinkDropColors.primary
                      : (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _isHovered || widget.isSelected
                ? [
                    BoxShadow(
                      color: LinkDropColors.shadowPrimary,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
