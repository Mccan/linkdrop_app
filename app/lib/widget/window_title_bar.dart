import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:window_manager/window_manager.dart';

/// 自定义窗口标题栏
/// 包含拖动区域和窗口控制按钮（最小化、最大化、关闭）
class WindowTitleBar extends StatefulWidget {
  final bool showTitle;
  final String? title;
  final Color? backgroundColor;

  const WindowTitleBar({
    super.key,
    this.showTitle = false,
    this.title,
    this.backgroundColor,
  });

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = isMaximized);
      }
    }
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    // 仅在桌面平台显示
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? (isDark ? LinkDropColors.zinc900 : LinkDropColors.primaryLight);

    return Container(
      height: 40,
      color: bgColor,
      child: Row(
        children: [
          // 拖动区域
          Expanded(
            child: MoveWindow(
              child: widget.showTitle && widget.title != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : LinkDropColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ),
          // 窗口控制按钮
          _WindowControlButton(
            icon: Icons.remove,
            onTap: () => windowManager.minimize(),
            isDark: isDark,
          ),
          _WindowControlButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            onTap: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            isDark: isDark,
          ),
          _WindowControlButton(
            icon: Icons.close,
            onTap: () => windowManager.close(),
            isDark: isDark,
            isClose: true,
          ),
        ],
      ),
    );
  }
}

/// 窗口控制按钮
class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isClose;

  const _WindowControlButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isClose = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    if (widget.isClose) {
      // 关闭按钮特殊样式
      backgroundColor = _isHovered ? Colors.red : Colors.transparent;
      iconColor = _isHovered ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black54);
    } else {
      // 其他按钮样式
      backgroundColor = _isHovered ? (widget.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)) : Colors.transparent;
      iconColor = widget.isDark ? Colors.white70 : Colors.black54;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
