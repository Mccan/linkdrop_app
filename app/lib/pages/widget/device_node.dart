import 'dart:math' as math;

import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/ip_helper.dart';

class DeviceNode extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback? onEditAlias;
  final bool isDark;
  final bool isFavorite;
  final String? displayNameOverride;

  const DeviceNode({
    required this.device,
    required this.onTap,
    this.onEditAlias,
    required this.isDark,
    this.isFavorite = false,
    this.displayNameOverride,
    super.key,
  });

  String _formatDisplayName(Device device) {
    final override = displayNameOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }

    final alias = device.alias;
    if (alias.isNotEmpty && !alias.contains(' ')) {
      return alias;
    }

    final ip = device.ip;
    if (ip == null || ip.isEmpty) {
      // 对于 WebRTC 设备且没有别名，使用指纹的一部分
      return device.fingerprint.substring(0, math.min(8, device.fingerprint.length));
    }
    return '${ip.visualId}（别人）';
  }

  @override
  Widget build(BuildContext context) {
    final icon = device.deviceType == DeviceType.mobile
        ? Icons.smartphone
        : device.deviceType == DeviceType.desktop
        ? Icons.computer
        : Icons.laptop;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onEditAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc800 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc500,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: LinkDropColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? LinkDropColors.zinc900 : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDisplayName(device),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? LinkDropColors.zinc200 : LinkDropColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFavorite) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        device.ip != null && device.ip!.isNotEmpty
                            ? '${device.deviceType.name} • ${device.ip}'
                            : device.deviceModel != null && device.deviceModel!.isNotEmpty
                            ? '${device.deviceType.name} • ${device.deviceModel}'
                            : device.deviceType.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: LinkDropColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SignalStrengthIndicator(isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
            if (onEditAlias != null)
              GestureDetector(
                onTap: onEditAlias,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignalStrengthIndicator extends StatelessWidget {
  final bool isDark;

  const _SignalStrengthIndicator({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < 3;
        return Container(
          width: 3,
          height: 4.0 + (index * 2.5),
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: isActive
                ? LinkDropColors.primary
                : isDark
                ? LinkDropColors.zinc700
                : LinkDropColors.zinc300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
