import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 二维码显示组件
///
/// 显示支付二维码，带有金棕色主题边框装饰和扫描动画
class QRCodeDisplay extends StatefulWidget {
  final String qrCode;
  final double size;
  final bool isPolling;

  const QRCodeDisplay({
    required this.qrCode,
    this.size = 200,
    this.isPolling = false,
    super.key,
  });

  @override
  State<QRCodeDisplay> createState() => _QRCodeDisplayState();
}

class _QRCodeDisplayState extends State<QRCodeDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _scanAnimationReverse;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scanAnimationReverse = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isPolling) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(QRCodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPolling && !oldWidget.isPolling) {
      _animationController.repeat();
    } else if (!widget.isPolling && oldWidget.isPolling) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc700 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LinkDropColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: LinkDropColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 二维码
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: widget.qrCode,
                  version: QrVersions.auto,
                  size: widget.size,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: LinkDropColors.primaryDark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: LinkDropColors.zinc900,
                  ),
                ),
                if (widget.isPolling) ...[
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: _ScanLinePainter(
                              progress: _scanAnimation.value,
                              color: LinkDropColors.primary,
                            ),
                          ),
                          CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: _ScanLinePainter(
                              progress: _scanAnimationReverse.value,
                              color: LinkDropColors.primary,
                              opacity: 0.7,
                            ),
                          ),
                          Positioned(
                            top: -8,
                            left: -8,
                            child: _CornerDecoration(corner: _Corner.topLeft),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: _CornerDecoration(corner: _Corner.topRight),
                          ),
                          Positioned(
                            bottom: -8,
                            left: -8,
                            child: _CornerDecoration(corner: _Corner.bottomLeft),
                          ),
                          Positioned(
                            bottom: -8,
                            right: -8,
                            child: _CornerDecoration(corner: _Corner.bottomRight),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 支付宝标识
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: LinkDropColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payment,
                  size: 16,
                  color: LinkDropColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '支付宝扫码支付',
                  style: TextStyle(
                    fontSize: 12,
                    color: LinkDropColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 扫描线Painter
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacity;

  _ScanLinePainter({
    required this.progress,
    required this.color,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.3 * opacity),
          color.withOpacity(opacity),
          color.withOpacity(0.3 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final lineHeight = 3.0;
    final y = progress * (size.height - lineHeight);

    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, lineHeight),
      paint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, lineHeight),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerDecoration extends StatelessWidget {
  final _Corner corner;

  const _CornerDecoration({required this.corner});

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const borderWidth = 3.0;
    const color = LinkDropColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          corner: corner,
          borderWidth: borderWidth,
          color: color,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  final double borderWidth;
  final Color color;

  _CornerPainter({
    required this.corner,
    required this.borderWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case _Corner.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
