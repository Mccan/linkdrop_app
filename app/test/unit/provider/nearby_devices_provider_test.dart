import 'package:common/isolate.dart';
import 'package:common/model/device.dart';
import 'package:common/model/device_info_result.dart';
import 'package:common/model/dto/multicast_dto.dart';
import 'package:common/model/stored_security_context.dart';
import 'package:linkdrop_app/model/persistence/favorite_device.dart';
import 'package:linkdrop_app/provider/favorites_provider.dart';
import 'package:linkdrop_app/provider/logging/discovery_logs_provider.dart';
import 'package:linkdrop_app/provider/network/nearby_devices_provider.dart';
import 'package:linkdrop_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:test/test.dart';

void main() {
  late PersistenceService persistenceService;

  setUp(() {
    persistenceService = _FakePersistenceService();
  });

  test('Should ignore self device when fingerprint is missing but ip and port match local device', () async {
    final favoriteService = FavoritesService(persistenceService);
    ReduxNotifier.test(
      redux: favoriteService,
      initialState: const <FavoriteDevice>[],
    );

    final service = ReduxNotifier.test(
      redux: NearbyDevicesService(
        isolateController: IsolateController(initialState: ParentIsolateState.initial(_syncState())),
        favoriteService: favoriteService,
        discoveryLogs: _NoopDiscoveryLogger(),
        getLocalAlias: () => 'This Device',
        getLocalIps: () => const ['192.168.1.23'],
        getLocalPort: () => 53317,
        getLocalFingerprint: () => 'local-fp',
      ),
    );

    await service.dispatchAsync(
      RegisterDeviceAction(
        _device(
          ip: '192.168.1.23',
          port: 53317,
          fingerprint: '',
          alias: 'This Device',
        ),
      ),
    );

    expect(service.state.devices, isEmpty);
  });

  test('Should ignore self signaling device when signaling id matches local peer id', () {
    final service = ReduxNotifier.test(
      redux: NearbyDevicesService(
        isolateController: IsolateController(initialState: ParentIsolateState.initial(_syncState())),
        favoriteService: FavoritesService(_FakePersistenceService()),
        discoveryLogs: _NoopDiscoveryLogger(),
        getLocalAlias: () => 'This Device',
        getLocalIps: () => const ['192.168.1.23'],
        getLocalPort: () => 53317,
        getLocalFingerprint: () => 'local-fp',
      ),
    );

    service.dispatch(
      RegisterSignalingDeviceAction(
        device: _signalingDevice(signalingId: 'peer-self', fingerprint: 'other-fp'),
        localSignalingPeerId: 'peer-self',
      ),
    );

    expect(service.state.signalingDevices, isEmpty);
  });
}

Device _device({
  required String ip,
  required int port,
  required String fingerprint,
  required String alias,
}) {
  return Device(
    signalingId: null,
    ip: ip,
    version: '1.0.0',
    port: port,
    https: false,
    fingerprint: fingerprint,
    alias: alias,
    deviceModel: 'Windows',
    deviceType: DeviceType.desktop,
    download: false,
    discoveryMethods: {const MulticastDiscovery()},
  );
}

Device _signalingDevice({
  required String signalingId,
  required String fingerprint,
}) {
  return Device(
    signalingId: signalingId,
    ip: null,
    version: '1.0.0',
    port: -1,
    https: false,
    fingerprint: fingerprint,
    alias: 'Peer Device',
    deviceModel: 'Windows',
    deviceType: DeviceType.desktop,
    download: false,
    discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://public.localsend.org/v1/ws')},
  );
}

SyncState _syncState() {
  return SyncState(
    init: () async {},
    rootIsolateToken: Object(),
    httpClientFactory: _unsupportedHttpClientFactory,
    securityContext: const StoredSecurityContext(
      privateKey: '',
      publicKey: '',
      certificate: '',
      certificateHash: 'local-fp',
    ),
    deviceInfo: DeviceInfoResult(
      deviceType: DeviceType.desktop,
      deviceModel: 'Windows',
      androidSdkInt: null,
    ),
    alias: 'This Device',
    port: 53317,
    networkWhitelist: null,
    networkBlacklist: null,
    protocol: ProtocolType.http,
    multicastGroup: '224.0.0.167',
    discoveryTimeout: 3,
    serverRunning: true,
    download: false,
  );
}

Never _unsupportedHttpClientFactory(Duration _, StoredSecurityContext __) {
  throw UnimplementedError('HTTP client should not be used in nearby devices provider unit tests.');
}

class _FakePersistenceService implements PersistenceService {
  @override
  List<FavoriteDevice> getFavorites() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopDiscoveryLogger extends DiscoveryLogger {
  @override
  void addLog(String log) {
    // no-op for unit tests
  }
}