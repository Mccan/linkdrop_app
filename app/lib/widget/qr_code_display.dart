import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 二维码显示组件
///
/// 显示支付二维码，带有金棕色主题边框装饰
class QRCodeDisplay extends StatelessWidget {
  final String qrCode;
  final double size;

  const QRCodeDisplay({
    required this.qrCode,
    this.size = 200,
    super.key,
  });

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
            child: QrImageView(
              data: qrCode,
              version: QrVersions.auto,
              size: size,
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
