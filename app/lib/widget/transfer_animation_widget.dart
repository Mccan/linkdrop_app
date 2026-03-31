import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

/// 简化的传输动画组件
///
/// 设计：【发送设备】icon、抛物线气泡动画、【接收设备】icon
/// 支持发送和接收两种模式，动画方向相反
/// - 发送模式：本机 → 气泡 → 目标设备
/// - 接收模式：发送设备 → 气泡 → 本机
/// - 等待模式：显示脉冲动画，表示等待对方响应
class TransferAnimationWidget extends StatefulWidget {
  final String? senderName;
  final String? receiverName;
  final bool isSending;
  final double progress;
  final bool isFinished;
  final bool isReceiver; // 是否为接收端视角
  final bool isWaiting; // 是否为等待状态

  const TransferAnimationWidget({
    super.key,
    this.senderName,
    this.receiverName,
    this.isSending = true,
    this.progress = 0.0,
    this.isFinished = false,
    this.isReceiver = false, // 默认为发送端视角
    this.isWaiting = false, // 默认为非等待状态
  });

  @override
  State<TransferAnimationWidget> createState() => _TransferAnimationWidgetState();
}

class _TransferAnimationWidgetState extends State<TransferAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  final List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();
  double _lastSpawnTime = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationController.addListener(_onAnimationUpdate);

    if (widget.isSending) {
      _animationController.repeat();
    }

    if (widget.isWaiting) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _onAnimationUpdate() {
    final currentTime = _animationController.value;

    // 更新所有气泡位置
    for (var bubble in _bubbles) {
      bubble.progress += 0.008;
    }

    // 移除已完成的气泡
    _bubbles.removeWhere((b) => b.progress >= 1.0);

    // 定时生成新气泡
    if (widget.isSending && _bubbles.length < 4 && (currentTime - _lastSpawnTime).abs() > 0.15) {
      _lastSpawnTime = currentTime;
      _bubbles.add(
        _Bubble(
          progress: 0.0,
          size: 6 + _random.nextDouble() * 5,
          opacity: 0.5 + _random.nextDouble() * 0.3,
          parabolaHeight: 15 + _random.nextDouble() * 25,
        ),
      );
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(TransferAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSending && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!widget.isSending && _animationController.isAnimating) {
      _animationController.stop();
    }

    if (widget.isWaiting && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isWaiting && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 根据是否为接收端视角决定设备位置和标签
    final leftDeviceName = widget.isReceiver ? (widget.senderName ?? '发送设备') : '本机';
    final rightDeviceName = widget.isReceiver ? '本机' : (widget.receiverName ?? '目标设备');
    final leftIsSender = !widget.isReceiver;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 设备行：左侧设备 - 动画/完成勾/等待指示器 - 右侧设备
          SizedBox(
            height: 80,
            child: Row(
              children: [
                // 左侧设备
                widget.isWaiting
                    ? _buildPulsingDeviceIcon(isSender: leftIsSender, isDark: isDark)
                    : _buildDeviceIcon(isSender: leftIsSender, isDark: isDark),
                // 传输动画区域或完成勾或等待指示器
                Expanded(
                  child: widget.isFinished
                      ? _buildCompletedIndicator(isDark)
                      : widget.isWaiting
                      ? _buildWaitingIndicator(isDark)
                      : CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: _ParabolaTransferPainter(
                            bubbles: _bubbles,
                            isDark: isDark,
                            isSending: widget.isSending,
                            animationValue: _animationController.value,
                            isReversed: widget.isReceiver, // 接收端反向动画
                          ),
                        ),
                ),
                // 右侧设备
                widget.isWaiting
                    ? _buildPulsingDeviceIcon(isSender: !leftIsSender, isDark: isDark)
                    : _buildDeviceIcon(isSender: !leftIsSender, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 设备名称
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftDeviceName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                ),
              ),
              Text(
                rightDeviceName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon({
    required bool isSender,
    required bool isDark,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSender ? [LinkDropColors.primary, LinkDropColors.primaryDark] : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isSender ? LinkDropColors.primary : const Color(0xFF10B981)).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        isSender ? Icons.smartphone : Icons.devices,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  /// 构建传输完成指示器（绿色勾）
  Widget _buildCompletedIndicator(bool isDark) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// 构建脉冲动画的设备图标（用于等待状态）
  Widget _buildPulsingDeviceIcon({required bool isSender, required bool isDark}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.1);
        final opacity = 0.6 + (_pulseController.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSender ? [LinkDropColors.primary, LinkDropColors.primaryDark] : [const Color(0xFF10B981), const Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isSender ? LinkDropColors.primary : const Color(0xFF10B981)).withValues(alpha: 0.35 * opacity),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isSender ? Icons.smartphone : Icons.devices,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  /// 构建等待状态指示器（中间显示等待图标）
  Widget _buildWaitingIndicator(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final rotation = _pulseController.value * 2 * math.pi;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 旋转的等待图标
              Transform.rotate(
                angle: rotation,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: isDark ? Colors.white60 : LinkDropColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 等待提示文字
              Text(
                '等待中...',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : LinkDropColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 气泡数据类
class _Bubble {
  double progress;
  final double size;
  final double opacity;
  final double parabolaHeight;

  _Bubble({
    required this.progress,
    required this.size,
    required this.opacity,
    required this.parabolaHeight,
  });
}

/// 抛物线传输动画绘制器
class _ParabolaTransferPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final bool isDark;
  final bool isSending;
  final double animationValue;
  final bool isReversed; // 是否反向（接收端视角）

  _ParabolaTransferPainter({
    required this.bubbles,
    required this.isDark,
    required this.isSending,
    required this.animationValue,
    this.isReversed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // 绘制连接线（虚线效果）
    final linePaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 绘制虚线
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 8;
    while (startX < width - 8) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 绘制抛物线轨迹上的气泡
    for (var bubble in bubbles) {
      final t = bubble.progress;
      final easedT = _easeInOutCubic(t);

      // 根据是否反向计算位置
      final x = isReversed
          ? (width - 8) -
                easedT *
                    (width - 16) // 反向：从右到左
          : 8 + easedT * (width - 16); // 正向：从左到右

      // 抛物线公式
      final parabolaY = bubble.parabolaHeight * math.sin(t * math.pi);
      final y = centerY - parabolaY;

      // 气泡透明度随进度变化
      double finalOpacity = bubble.opacity;
      if (t < 0.15) {
        finalOpacity = bubble.opacity * (t / 0.15);
      } else if (t > 0.85) {
        finalOpacity = bubble.opacity * ((1 - t) / 0.15);
      }

      // 绘制气泡光晕
      final glowPaint = Paint()
        ..color = LinkDropColors.primary.withValues(alpha: finalOpacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(
        Offset(x, y),
        bubble.size * 1.8,
        glowPaint,
      );

      // 绘制气泡主体
      final bubblePaint = Paint()
        ..color = LinkDropColors.primary.withValues(alpha: finalOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        bubble.size,
        bubblePaint,
      );

      // 绘制高光
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: finalOpacity * 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x - bubble.size * 0.25, y - bubble.size * 0.25),
        bubble.size * 0.35,
        highlightPaint,
      );
    }

    // 绘制发送端脉冲效果
    if (isSending) {
      final pulseProgress = (animationValue * 2) % 1.0;
      final pulsePaint = Paint()
        ..color = LinkDropColors.primary.withValues(alpha: 0.15 * (1 - pulseProgress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // 脉冲位置根据方向决定
      final pulseX = isReversed ? width - 8.0 : 8.0;
      canvas.drawCircle(
        Offset(pulseX, centerY),
        10 + pulseProgress * 8,
        pulsePaint,
      );
    }
  }

  /// 缓动函数 - easeInOutCubic
  double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      final f = 2 * t - 2;
      return 0.5 * f * f * f + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _ParabolaTransferPainter oldDelegate) {
    return oldDelegate.bubbles != bubbles ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isSending != isSending ||
        oldDelegate.isReversed != isReversed;
  }
}
