import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

/// LinkDrop 按钮类型
enum LinkDropButtonType {
  /// 主要按钮: 渐变背景 #d4a574 → #c17f59 + 白色文字
  primary,

  /// 次要按钮: 白色背景 + #e8e8e8 边框 + 悬停变金棕边框
  secondary,

  /// 文字按钮: 透明背景 + #d4a574 文字 + 悬停下划线
  text,
}

/// LinkDrop 统一按钮组件
///
/// 支持三种类型：primary、secondary、text
class LinkDropButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final LinkDropButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LinkDropButton({
    required this.label,
    this.icon,
    this.onTap,
    this.type = LinkDropButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
    this.borderRadius = 12,
    this.padding,
    super.key,
  });

  @override
  State<LinkDropButton> createState() => _LinkDropButtonState();
}

class _LinkDropButtonState extends State<LinkDropButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isInteractive => !widget.isLoading && !widget.isDisabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapDown: _isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isInteractive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: _isInteractive ? () => setState(() => _isPressed = false) : null,
        onTap: _isInteractive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : null,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: _buildDecoration(isDark),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    switch (widget.type) {
      case LinkDropButtonType.primary:
        return BoxDecoration(
          gradient: LinkDropColors.primaryGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: LinkDropColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );

      case LinkDropButtonType.secondary:
        return BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : LinkDropColors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isHovered
                ? LinkDropColors.primary
                : (isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: LinkDropColors.shadowPrimary,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );

      case LinkDropButtonType.text:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        );
    }
  }

  Widget _buildContent(bool isDark) {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.type == LinkDropButtonType.primary
                    ? Colors.white
                    : LinkDropColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    final textColor = _getTextColor(isDark);

    return Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: widget.isDisabled ? LinkDropColors.zinc400 : textColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: widget.isDisabled ? LinkDropColors.zinc400 : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: widget.type == LinkDropButtonType.text && _isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Color _getTextColor(bool isDark) {
    switch (widget.type) {
      case LinkDropButtonType.primary:
        return Colors.white;
      case LinkDropButtonType.secondary:
        return isDark ? Colors.white : LinkDropColors.textPrimary;
      case LinkDropButtonType.text:
        return LinkDropColors.primary;
    }
  }
}

/// 紧凑型图标按钮变体
///
/// 用于工具栏、控制按钮等场景
class LinkDropIconButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isRotating;
  final double size;

  const LinkDropIconButton({
    required this.icon,
    this.label,
    this.onTap,
    this.isSelected = false,
    this.isRotating = false,
    this.size = 20,
    super.key,
  });

  @override
  State<LinkDropIconButton> createState() => _LinkDropIconButtonState();
}

class _LinkDropIconButtonState extends State<LinkDropIconButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_rotationController);
  }

  @override
  void didUpdateWidget(LinkDropIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRotating && !oldWidget.isRotating) {
      _rotationController.repeat();
    } else if (!widget.isRotating && oldWidget.isRotating) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? LinkDropColors.zinc800 : LinkDropColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? LinkDropColors.primary
                        : _isHovered
                            ? LinkDropColors.primary
                            : (isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200),
                    width: widget.isSelected || _isHovered ? 2 : 1,
                  ),
                  boxShadow: _isHovered || widget.isSelected
                      ? [
                          BoxShadow(
                            color: LinkDropColors.shadowPrimary,
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.141592653589793,
                      child: child,
                    );
                  },
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: LinkDropColors.primary,
                  ),
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 12,
                    color: LinkDropColors.zinc500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
