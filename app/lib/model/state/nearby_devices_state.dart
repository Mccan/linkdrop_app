import 'package:collection/collection.dart';
import 'package:common/model/device.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'nearby_devices_state.mapper.dart';

@MappableClass()
class NearbyDevicesState with NearbyDevicesStateMappable {
  final bool runningFavoriteScan;
  final Set<String> runningIps; // list of local ips
  final Map<String, Device> devices; // ip -> device

  /// Devices that are discovered via signaling server.
  /// The key is the fingerprint of the device.
  /// We do not trust the fingerprint, so we allow multiple devices with the same fingerprint.
  final Map<String, Set<Device>> signalingDevices;

  const NearbyDevicesState({
    required this.runningFavoriteScan,
    required this.runningIps,
    required this.devices,
    required this.signalingDevices,
  });

  Map<String, Device> get allDevices {
    final mergedDevices = <String, Device>{};

    // 优先写入通过 IP 扫描发现的设备，key 统一使用 IP。
    for (final entry in devices.entries) {
      final device = entry.value;
      final ip = device.ip;
      if (ip == null || ip.isEmpty) {
        continue;
      }
      mergedDevices[ip] = device;
    }

    // 合并信令设备，优先与已有 IP 设备合并，避免同一设备显示两条。
    for (final signalingSet in signalingDevices.values) {
      for (final signalingDevice in signalingSet) {
        final existingEntry = _findExistingEntryForSignaling(
          signalingDevice: signalingDevice,
          mergedDevices: mergedDevices,
        );

        if (existingEntry == null) {
          final key = _fallbackKeyForSignaling(signalingDevice);
          mergedDevices[key] = signalingDevice;
          continue;
        }

        final existingKey = existingEntry.key;
        final existingDevice = existingEntry.value;
        mergedDevices[existingKey] = _preferIpDevice(existing: existingDevice, incoming: signalingDevice);
      }
    }

    return mergedDevices;
  }

  MapEntry<String, Device>? _findExistingEntryForSignaling({
    required Device signalingDevice,
    required Map<String, Device> mergedDevices,
  }) {
    final signalingIp = signalingDevice.ip;

    // 1) 优先按 IP 合并（最可靠）
    if (signalingIp != null && signalingIp.isNotEmpty) {
      final byIp = mergedDevices[signalingIp];
      if (byIp != null) {
        return MapEntry(signalingIp, byIp);
      }
    }

    // 2) 其次按 fingerprint 合并
    final byFingerprint = mergedDevices.entries.where((entry) => entry.value.fingerprint == signalingDevice.fingerprint).firstOrNull;
    if (byFingerprint != null) {
      return byFingerprint;
    }

    // 3) 最后做兜底：
    // - 纯信令设备优先尝试和同名同类型同型号的纯信令设备合并（处理重连/残留导致的重复）
    // - 若失败，再尝试和同名同类型的 IP 设备合并
    final alias = signalingDevice.alias.trim();
    if (alias.isEmpty || (signalingIp != null && signalingIp.isNotEmpty)) {
      return null;
    }

    final byAliasTypeModel = mergedDevices.entries
        .where((entry) {
          final existing = entry.value;
          final existingIp = existing.ip;
          return (existingIp == null || existingIp.isEmpty) &&
              existing.alias == alias &&
              existing.deviceType == signalingDevice.deviceType &&
              existing.deviceModel == signalingDevice.deviceModel;
        })
        .firstOrNull;

    if (byAliasTypeModel != null) {
      return byAliasTypeModel;
    }

    final byAliasAndType = mergedDevices.entries
        .where((entry) {
          final existing = entry.value;
          final existingIp = existing.ip;
          return existingIp != null && existingIp.isNotEmpty && existing.alias == alias && existing.deviceType == signalingDevice.deviceType;
        })
        .firstOrNull;

    return byAliasAndType;
  }

  String _fallbackKeyForSignaling(Device device) {
    final signalingId = device.signalingId;
    if (signalingId != null && signalingId.isNotEmpty) {
      return 'sig:$signalingId';
    }

    final fingerprint = device.fingerprint;
    if (fingerprint.isNotEmpty) {
      return 'fp:$fingerprint';
    }

    final alias = device.alias.trim();
    if (alias.isNotEmpty) {
      return 'alias:$alias';
    }

    return 'unknown:${device.hashCode}';
  }

  Device _preferIpDevice({
    required Device existing,
    required Device incoming,
  }) {
    final existingHasIp = existing.ip != null && existing.ip!.isNotEmpty;
    final incomingHasIp = incoming.ip != null && incoming.ip!.isNotEmpty;

    if (existingHasIp && !incomingHasIp) {
      return existing.merge(incoming);
    }
    if (!existingHasIp && incomingHasIp) {
      return incoming.merge(existing);
    }
    return existing.merge(incoming);
  }
}

extension on Device {
  Device merge(Device other) {
    return Device(
      signalingId: signalingId ?? other.signalingId,
      ip: ip ?? other.ip,
      version: version,
      port: port,
      https: https,
      fingerprint: fingerprint,
      alias: alias,
      deviceModel: deviceModel,
      deviceType: deviceType,
      download: download,
      discoveryMethods: {
        ...discoveryMethods,
        ...other.discoveryMethods,
      },
    );
  }
}
