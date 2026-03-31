import 'package:common/model/device.dart';
import 'package:linkdrop_app/model/state/nearby_devices_state.dart';
import 'package:test/test.dart';

void main() {
  test('Should keep one device when signaling and IP discovery represent same peer', () {
    final ipDevice = _device(
      ip: '192.168.0.103',
      fingerprint: 'fp-ip',
      alias: 'Pretty Mango',
      discoveryMethods: {const MulticastDiscovery()},
    );

    final signalingDevice = _device(
      ip: null,
      signalingId: 'sig-1',
      fingerprint: 'fp-sig',
      alias: 'Pretty Mango',
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final state = NearbyDevicesState(
      runningFavoriteScan: false,
      runningIps: const {},
      devices: {'192.168.0.103': ipDevice},
      signalingDevices: {
        'fp-sig': {signalingDevice},
      },
    );

    final all = state.allDevices.values.toList();

    expect(all.length, 1);
    expect(all.first.ip, '192.168.0.103');
    expect(all.first.alias, 'Pretty Mango');
    expect(all.first.transmissionMethods, contains(TransmissionMethod.http));
    expect(all.first.transmissionMethods, contains(TransmissionMethod.webrtc));
  });

  test('Should merge by fingerprint even when keys differ', () {
    final ipDevice = _device(
      ip: '192.168.0.103',
      fingerprint: 'same-fp',
      alias: 'A',
      discoveryMethods: {const MulticastDiscovery()},
    );

    final signalingDevice = _device(
      ip: null,
      signalingId: 'sig-2',
      fingerprint: 'same-fp',
      alias: 'A',
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final state = NearbyDevicesState(
      runningFavoriteScan: false,
      runningIps: const {},
      devices: {'192.168.0.103': ipDevice},
      signalingDevices: {
        'same-fp': {signalingDevice},
      },
    );

    final all = state.allDevices.values.toList();

    expect(all.length, 1);
    expect(all.first.ip, '192.168.0.103');
    expect(all.first.transmissionMethods, containsAll([TransmissionMethod.http, TransmissionMethod.webrtc]));
  });

  test('Should keep multiple pure signaling devices when no reliable merge key exists', () {
    final signalingA = _device(
      ip: null,
      signalingId: 'sig-a',
      fingerprint: 'fp-a',
      alias: 'A',
      deviceType: DeviceType.mobile,
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final signalingB = _device(
      ip: null,
      signalingId: 'sig-b',
      fingerprint: 'fp-b',
      alias: 'B',
      deviceType: DeviceType.mobile,
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final state = NearbyDevicesState(
      runningFavoriteScan: false,
      runningIps: const {},
      devices: const {},
      signalingDevices: {
        'fp-a': {signalingA},
        'fp-b': {signalingB},
      },
    );

    final all = state.allDevices.values.toList();

    expect(all.length, 2);
  });

  test('Should merge pure signaling duplicates with same alias, type and model', () {
    final signalingA = _device(
      ip: null,
      signalingId: 'sig-a',
      fingerprint: 'fp-a',
      alias: 'Device-990A',
      deviceType: DeviceType.desktop,
      deviceModel: 'Windows',
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final signalingB = _device(
      ip: null,
      signalingId: 'sig-b',
      fingerprint: 'fp-b',
      alias: 'Device-990A',
      deviceType: DeviceType.desktop,
      deviceModel: 'Windows',
      discoveryMethods: {const SignalingDiscovery(signalingServer: 'wss://example.com')},
    );

    final state = NearbyDevicesState(
      runningFavoriteScan: false,
      runningIps: const {},
      devices: const {},
      signalingDevices: {
        'fp-a': {signalingA},
        'fp-b': {signalingB},
      },
    );

    final all = state.allDevices.values.toList();

    expect(all.length, 1);
    expect(all.first.alias, 'Device-990A');
    expect(all.first.deviceType, DeviceType.desktop);
    expect(all.first.deviceModel, 'Windows');
  });
}

Device _device({
  required String? ip,
  String? signalingId,
  required String fingerprint,
  required String alias,
  DeviceType deviceType = DeviceType.mobile,
  String deviceModel = 'OPPO',
  required Set<DiscoveryMethod> discoveryMethods,
}) {
  return Device(
    signalingId: signalingId,
    ip: ip,
    version: '1.0.0',
    port: 53317,
    https: false,
    fingerprint: fingerprint,
    alias: alias,
    deviceModel: deviceModel,
    deviceType: deviceType,
    download: false,
    discoveryMethods: discoveryMethods,
  );
}
