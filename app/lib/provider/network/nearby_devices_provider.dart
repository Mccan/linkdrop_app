import 'dart:async';

import 'package:collection/collection.dart';
import 'package:common/isolate.dart';
import 'package:common/model/device.dart';
import 'package:linkdrop_app/model/persistence/favorite_device.dart';
import 'package:linkdrop_app/model/state/nearby_devices_state.dart';
import 'package:linkdrop_app/provider/favorites_provider.dart';
import 'package:linkdrop_app/provider/logging/discovery_logs_provider.dart';
import 'package:linkdrop_app/provider/local_ip_provider.dart';
import 'package:linkdrop_app/provider/security_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/util/discovery_filter.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// This provider is responsible for:
/// - Scanning the network for other LocalSend instances
/// - Keeping track of all found devices (they are only stored in RAM)
///
/// Use [scanProvider] to have a high-level API to perform discovery operations.
final nearbyDevicesProvider = ReduxProvider<NearbyDevicesService, NearbyDevicesState>((ref) {
  return NearbyDevicesService(
    isolateController: ref.notifier(parentIsolateProvider),
    favoriteService: ref.notifier(favoritesProvider),
    discoveryLogs: ref.notifier(discoveryLoggerProvider),
    getLocalAlias: () => ref.read(settingsProvider).alias,
    getLocalIps: () => ref.read(localIpProvider).localIps,
    getLocalPort: () => ref.read(settingsProvider).port,
    getLocalFingerprint: () => ref.read(securityProvider).certificateHash,
  );
});

class NearbyDevicesService extends ReduxNotifier<NearbyDevicesState> {
  final IsolateController _isolateController;
  final FavoritesService _favoriteService;
  final DiscoveryLogger _discoveryLogger;
  final String Function() _getLocalAlias;
  final Iterable<String> Function() _getLocalIps;
  final int Function() _getLocalPort;
  final String Function() _getLocalFingerprint;

  NearbyDevicesService({
    required IsolateController isolateController,
    required FavoritesService favoriteService,
    required DiscoveryLogger discoveryLogs,
     required String Function() getLocalAlias,
    required Iterable<String> Function() getLocalIps,
    required int Function() getLocalPort,
     required String Function() getLocalFingerprint,
  }) : _discoveryLogger = discoveryLogs,
       _isolateController = isolateController,
       _favoriteService = favoriteService,
       _getLocalAlias = getLocalAlias,
       _getLocalIps = getLocalIps,
       _getLocalPort = getLocalPort,
       _getLocalFingerprint = getLocalFingerprint;

  @override
  NearbyDevicesState init() => const NearbyDevicesState(
    runningFavoriteScan: false,
    runningIps: {},
    devices: {},
    signalingDevices: {},
  );
}

/// Binds the UDP port and listens for incoming announcements.
/// This should run forever as long as the app is running.
class StartMulticastListener extends AsyncReduxAction<NearbyDevicesService, NearbyDevicesState> {
  @override
  Future<NearbyDevicesState> reduce() async {
    await for (final device in notifier._isolateController.state.multicastDiscovery!.receiveFromIsolate) {
      await dispatchAsync(RegisterDeviceAction(device));
      notifier._discoveryLogger.addLog('[DISCOVER/UDP] ${device.alias} (${device.ip}, model: ${device.deviceModel})');
    }
    return state;
  }
}

/// Removes all found devices from the state.
class ClearFoundDevicesAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  @override
  NearbyDevicesState reduce() {
    return state.copyWith(
      devices: {},
      signalingDevices: {},
    );
  }
}

/// Registers a device in the state.
/// It will override any existing device with the same IP.
class RegisterDeviceAction extends AsyncReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final Device device;

  RegisterDeviceAction(this.device);

  @override
  bool get trackOrigin => false;

  @override
  Future<NearbyDevicesState> reduce() async {
    assert(device.ip?.isNotEmpty ?? false, 'IP must not be empty');

    // Guardrail: this is the final defensive filter before mutating state.
    // Do not bypass this check in callers; multiple discovery paths converge here.
    final selfMatchReason = detectSelfDeviceMatchReason(
      localFingerprint: notifier._getLocalFingerprint(),
      deviceFingerprint: device.fingerprint,
      localAlias: notifier._getLocalAlias(),
      deviceAlias: device.alias,
      localIps: notifier._getLocalIps(),
      deviceIp: device.ip,
      localPort: notifier._getLocalPort(),
      devicePort: device.port,
    );
    if (selfMatchReason != null) {
      notifier._discoveryLogger.addLog(
        '[DISCOVER/FILTER] Skip self device ${device.alias} (${device.ip}) via ${selfMatchReason.name}',
      );
      return state;
    }

    final favoriteDevice = notifier._favoriteService.state.firstWhereOrNull((e) => e.fingerprint == device.fingerprint);
    if (favoriteDevice != null && !favoriteDevice.customAlias) {
      // Update existing favorite with new alias
      await external(notifier._favoriteService).dispatchAsync(UpdateFavoriteAction(favoriteDevice.copyWith(alias: device.alias)));
    } else {
      await Future.microtask(() {});
    }
    return state.copyWith(
      devices: {...state.devices}..update(device.ip!, (_) => device, ifAbsent: () => device),
    );
  }
}

/// Registers a new device found via signaling.
class RegisterSignalingDeviceAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final Device device;
  final String? localSignalingPeerId;

  RegisterSignalingDeviceAction({
    required this.device,
    required this.localSignalingPeerId,
  });

  @override
  NearbyDevicesState reduce() {
    // Guardrail: always read local fingerprint at action time (not provider-init snapshot).
    // This prevents stale-value regressions during long-running sessions.
    final signalingMatchReason = detectLocalSignalingPeerMatchReason(
      localSignalingPeerId: localSignalingPeerId,
      localFingerprint: notifier._getLocalFingerprint(),
      peerId: device.signalingId ?? '',
      peerFingerprint: device.fingerprint,
    );
    if (signalingMatchReason != null) {
      notifier._discoveryLogger.addLog(
        '[DISCOVER/FILTER] Skip self signaling device ${device.alias} (${device.signalingId}) via ${signalingMatchReason.name}',
      );
      return state;
    }

    final Set<Device> existingDevices = state.signalingDevices[device.fingerprint]?.toSet() ?? {};
    final existingDevice = existingDevices.firstWhereOrNull((e) => e.signalingId == device.signalingId);
    if (existingDevice != null) {
      existingDevices.remove(existingDevice);
    }
    existingDevices.add(device);

    return state.copyWith(
      signalingDevices: {
        ...state.signalingDevices,
        device.fingerprint: existingDevices,
      },
    );
  }
}

class UnregisterSignalingDeviceAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final String signalingId;

  UnregisterSignalingDeviceAction(this.signalingId);

  @override
  NearbyDevicesState reduce() {
    return state.copyWith(
      signalingDevices: {
        for (final entry in state.signalingDevices.entries) entry.key: entry.value.where((e) => e.signalingId != signalingId).toSet(),
      },
    );
  }
}

class ClearSignalingDevicesByServerAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final String signalingServer;

  ClearSignalingDevicesByServerAction(this.signalingServer);

  @override
  NearbyDevicesState reduce() {
    return state.copyWith(
      signalingDevices: {
        for (final entry in state.signalingDevices.entries)
          entry.key: entry.value
              .where(
                (device) => !device.discoveryMethods.any(
                  (method) => method is SignalingDiscovery && method.signalingServer == signalingServer,
                ),
              )
              .toSet(),
      }..removeWhere((_, devices) => devices.isEmpty),
    );
  }
}

/// It does not really "scan".
/// It just sends an announcement which will cause a response on every other LocalSend member of the network.
class StartMulticastScan extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  @override
  NearbyDevicesState reduce() {
    external(notifier._isolateController).dispatch(IsolateSendMulticastAnnouncementAction());
    return state;
  }
}

/// Scans one particular subnet with traditional HTTP/TCP discovery.
/// This method awaits until the scan is finished.
class StartLegacyScan extends AsyncReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final int port;
  final String localIp;
  final bool https;

  StartLegacyScan({
    required this.port,
    required this.localIp,
    required this.https,
  });

  @override
  Future<NearbyDevicesState> reduce() async {
    if (state.runningIps.contains(localIp)) {
      // already running for the same localIp
      await Future.microtask(() {});
      return state;
    }

    dispatch(_SetRunningIpsAction({...state.runningIps, localIp}));

    final stream = external(notifier._isolateController).dispatchTakeResult(
      IsolateInterfaceHttpDiscoveryAction(
        networkInterface: localIp,
        port: port,
        https: https,
      ),
    );

    await for (final device in stream) {
      notifier._discoveryLogger.addLog('[DISCOVER/TCP] ${device.alias} (${device.ip}, model: ${device.deviceModel})');
      await dispatchAsync(RegisterDeviceAction(device));
    }

    return state.copyWith(
      runningIps: state.runningIps.where((ip) => ip != localIp).toSet(),
    );
  }
}

class StartFavoriteScan extends AsyncReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final List<FavoriteDevice> devices;
  final bool https;

  StartFavoriteScan({
    required this.devices,
    required this.https,
  });

  @override
  Future<NearbyDevicesState> reduce() async {
    if (devices.isEmpty) {
      return state;
    }
    dispatch(_SetRunningFavoriteScanAction(true));

    final stream = external(notifier._isolateController).dispatchTakeResult(
      IsolateFavoriteHttpDiscoveryAction(
        favorites: devices.map((e) => (e.ip, e.port)).toList(),
        https: https,
      ),
    );

    await for (final device in stream) {
      notifier._discoveryLogger.addLog('[DISCOVER/TCP] ${device.alias} (${device.ip}, model: ${device.deviceModel})');
      await dispatchAsync(RegisterDeviceAction(device));
    }

    return state.copyWith(
      runningFavoriteScan: false,
    );
  }
}

class _SetRunningIpsAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final Set<String> runningIps;

  _SetRunningIpsAction(this.runningIps);

  @override
  NearbyDevicesState reduce() {
    return state.copyWith(
      runningIps: runningIps,
    );
  }
}

class _SetRunningFavoriteScanAction extends ReduxAction<NearbyDevicesService, NearbyDevicesState> {
  final bool running;

  _SetRunningFavoriteScanAction(this.running);

  @override
  NearbyDevicesState reduce() {
    return state.copyWith(
      runningFavoriteScan: running,
    );
  }
}
