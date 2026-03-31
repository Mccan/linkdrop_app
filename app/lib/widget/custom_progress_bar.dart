import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double? progress;
  final double borderRadius;
  final Color? color;
  final bool isWaiting;

  const CustomProgressBar({
    required this.progress,
    this.borderRadius = 10,
    this.color,
    this.isWaiting = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: isWaiting
          ? _WaitingProgressBar(
              borderRadius: borderRadius,
              color: primaryColor,
            )
          : LinearProgressIndicator(
              value: progress,
              color: primaryColor,
              minHeight: 10,
            ),
    );
  }
}

/// 等待状态的进度条 - 显示条纹动画
class _WaitingProgressBar extends StatefulWidget {
  final double borderRadius;
  final Color color;

  const _WaitingProgressBar({
    required this.borderRadius,
    required this.color,
  });

  @override
  State<_WaitingProgressBar> createState() => _WaitingProgressBarState();
}

class _WaitingProgressBarState extends State<_WaitingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 10),
          painter: _StripedProgressPainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// 条纹进度条绘制器
class _StripedProgressPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _StripedProgressPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // 绘制条纹
    final stripeWidth = 10.0;
    final stripeSpacing = 20.0;
    final offset = animationValue * stripeSpacing;

    final stripePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = -stripeSpacing; x < size.width + stripeSpacing; x += stripeSpacing) {
      final path = Path()
        ..moveTo(x + offset, 0)
        ..lineTo(x + offset + stripeWidth, 0)
        ..lineTo(x + offset - 5 + stripeWidth, size.height)
        ..lineTo(x + offset - 5, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripedProgressPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
