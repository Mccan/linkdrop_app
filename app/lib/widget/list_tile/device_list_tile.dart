import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/util/device_type_ext.dart';
import 'package:linkdrop_app/util/ip_helper.dart';
import 'package:linkdrop_app/widget/custom_progress_bar.dart';
import 'package:linkdrop_app/widget/device_bage.dart';
import 'package:linkdrop_app/widget/list_tile/custom_list_tile.dart';

/// 获取设备的显示名称
/// 优先使用 IP 尾号，如果没有 IP 则使用别名
String _getDeviceDisplayName(Device device) {
  if (device.ip != null && device.ip!.isNotEmpty) {
    return device.ip!.visualId;
  }
  return device.alias;
}

class DeviceListTile extends StatelessWidget {
  final Device device;
  final bool isFavorite;

  /// If not null, this name is used instead of [Device.alias].
  /// This is the case when the device is marked as favorite.
  final String? nameOverride;

  final String? info;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const DeviceListTile({
    required this.device,
    this.isFavorite = false,
    this.nameOverride,
    this.info,
    this.progress,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color.lerp(Theme.of(context).colorScheme.secondaryContainer, Colors.white, 0.3)!;
    return CustomListTile(
      icon: Icon(device.deviceType.icon, size: 46),
      title: Text(nameOverride ?? _getDeviceDisplayName(device), style: const TextStyle(fontSize: 20)),
      trailing: onFavoriteTap != null
          ? IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: onFavoriteTap,
            )
          : null,
      subTitle: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          if (info != null)
            Text(info!, style: const TextStyle(color: Colors.grey))
          else if (progress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: CustomProgressBar(progress: progress!),
            )
          else ...[
            if (device.ip != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: 'LAN • HTTP',
              )
            else
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: 'WebRTC',
              ),
            if (device.deviceModel != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: device.deviceModel!,
              ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
