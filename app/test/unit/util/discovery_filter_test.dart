import 'package:linkdrop_app/util/discovery_filter.dart';
import 'package:test/test.dart';

void main() {
  test('Should treat signaling peer as local when fingerprint matches', () {
    final isLocal = isLocalSignalingPeer(
      localSignalingPeerId: 'local-id',
      localFingerprint: 'local-fp',
      peerId: 'other-id',
      peerFingerprint: 'local-fp',
    );

    expect(isLocal, isTrue);
  });

  test('Should treat signaling peer as local when signaling id matches', () {
    final isLocal = isLocalSignalingPeer(
      localSignalingPeerId: 'local-id',
      localFingerprint: 'local-fp',
      peerId: 'local-id',
      peerFingerprint: 'other-fp',
    );

    expect(isLocal, isTrue);
  });

  test('Should not treat peer as local when id and fingerprint both differ', () {
    final isLocal = isLocalSignalingPeer(
      localSignalingPeerId: 'local-id',
      localFingerprint: 'local-fp',
      peerId: 'other-id',
      peerFingerprint: 'other-fp',
    );

    expect(isLocal, isFalse);
  });

  test('Should detect self device by fingerprint', () {
    expect(isSelfDeviceByFingerprint(localFingerprint: 'abc', deviceFingerprint: 'abc'), isTrue);
    expect(isSelfDeviceByFingerprint(localFingerprint: 'abc', deviceFingerprint: 'def'), isFalse);
    expect(isSelfDeviceByFingerprint(localFingerprint: '', deviceFingerprint: 'abc'), isFalse);
  });

  test('Should detect self device by fingerprint with surrounding spaces', () {
    expect(isSelfDeviceByFingerprint(localFingerprint: '  abc  ', deviceFingerprint: 'abc'), isTrue);
    expect(isSelfDeviceByFingerprint(localFingerprint: 'abc', deviceFingerprint: '  abc  '), isTrue);
  });

  test('Should detect self device by local ip and port when fingerprint is missing', () {
    final isLocal = isSelfDevice(
      localFingerprint: 'local-fp',
      deviceFingerprint: '',
      localAlias: 'This Device',
      deviceAlias: 'Another Device',
      localIps: const {'192.168.1.23', '10.0.0.5'},
      deviceIp: '192.168.1.23',
      localPort: 53317,
      devicePort: 53317,
    );

    expect(isLocal, isTrue);
  });

  test('Should not detect other device when only port matches', () {
    final isLocal = isSelfDevice(
      localFingerprint: 'local-fp',
      deviceFingerprint: '',
      localAlias: 'This Device',
      deviceAlias: 'Another Device',
      localIps: const {'192.168.1.23'},
      deviceIp: '192.168.1.99',
      localPort: 53317,
      devicePort: 53317,
    );

    expect(isLocal, isFalse);
  });

  test('Should detect self device by local alias and ip even when port differs', () {
    final isLocal = isSelfDevice(
      localFingerprint: 'local-fp',
      deviceFingerprint: '',
      localAlias: 'This Device',
      deviceAlias: 'This Device',
      localIps: const {'192.168.1.23'},
      deviceIp: '192.168.1.23',
      localPort: 53317,
      devicePort: 53318,
    );

    expect(isLocal, isTrue);
  });

  test('Should return aliasAndIp match reason when alias and ip match', () {
    final reason = detectSelfDeviceMatchReason(
      localFingerprint: 'local-fp',
      deviceFingerprint: '',
      localAlias: 'This Device',
      deviceAlias: 'This Device',
      localIps: const {'192.168.1.23'},
      deviceIp: '192.168.1.23',
      localPort: 53317,
      devicePort: 9999,
    );

    expect(reason, SelfDeviceMatchReason.aliasAndIp);
  });

  test('Should return signalingId match reason when local signaling id matches', () {
    final reason = detectLocalSignalingPeerMatchReason(
      localSignalingPeerId: 'peer-self',
      localFingerprint: 'local-fp',
      peerId: 'peer-self',
      peerFingerprint: 'other-fp',
    );

    expect(reason, LocalSignalingPeerMatchReason.signalingId);
  });

  test('Should return fingerprint match reason when fingerprints differ only by spaces', () {
    final reason = detectLocalSignalingPeerMatchReason(
      localSignalingPeerId: null,
      localFingerprint: ' local-fp ',
      peerId: 'peer-id',
      peerFingerprint: 'local-fp',
    );

    expect(reason, LocalSignalingPeerMatchReason.fingerprint);
  });
}