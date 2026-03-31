enum SelfDeviceMatchReason {
  fingerprint,
  aliasAndIp,
  ipAndPort,
}

enum LocalSignalingPeerMatchReason {
  signalingId,
  fingerprint,
}

bool isSelfDevice({
  required String localFingerprint,
  required String deviceFingerprint,
  required String localAlias,
  required String deviceAlias,
  required Iterable<String> localIps,
  required String? deviceIp,
  required int localPort,
  required int devicePort,
}) {
  return detectSelfDeviceMatchReason(
        localFingerprint: localFingerprint,
        deviceFingerprint: deviceFingerprint,
        localAlias: localAlias,
        deviceAlias: deviceAlias,
        localIps: localIps,
        deviceIp: deviceIp,
        localPort: localPort,
        devicePort: devicePort,
      ) !=
      null;
}

SelfDeviceMatchReason? detectSelfDeviceMatchReason({
  required String localFingerprint,
  required String deviceFingerprint,
  required String localAlias,
  required String deviceAlias,
  required Iterable<String> localIps,
  required String? deviceIp,
  required int localPort,
  required int devicePort,
}) {
  if (isSelfDeviceByFingerprint(localFingerprint: localFingerprint, deviceFingerprint: deviceFingerprint)) {
    return SelfDeviceMatchReason.fingerprint;
  }

  if (deviceIp == null || deviceIp.isEmpty) {
    return null;
  }

  final normalizedLocalAlias = localAlias.trim();
  final normalizedDeviceAlias = deviceAlias.trim();
  // Guardrail: alias+ip is intentionally kept as a fallback because some discovery paths
  // may provide incomplete metadata (for example missing/invalid port or delayed fingerprint sync).
  if (normalizedLocalAlias.isNotEmpty && normalizedDeviceAlias.isNotEmpty) {
    final sameAlias = normalizedLocalAlias == normalizedDeviceAlias;
    final sameIp = localIps.any((localIp) => localIp == deviceIp);
    if (sameAlias && sameIp) {
      return SelfDeviceMatchReason.aliasAndIp;
    }
  }

  final sameIp = localIps.any((localIp) => localIp == deviceIp);
  if (localPort == devicePort && sameIp) {
    return SelfDeviceMatchReason.ipAndPort;
  }

  return null;
}

bool isSelfDeviceByFingerprint({
  required String localFingerprint,
  required String deviceFingerprint,
}) {
  // Guardrail: keep normalization; hidden whitespace differences were observed in the wild
  // and caused self-device filtering regressions.
  final normalizedLocalFingerprint = localFingerprint.trim();
  final normalizedDeviceFingerprint = deviceFingerprint.trim();
  if (normalizedLocalFingerprint.isEmpty || normalizedDeviceFingerprint.isEmpty) {
    return false;
  }
  return normalizedLocalFingerprint == normalizedDeviceFingerprint;
}

bool isLocalSignalingPeer({
  required String? localSignalingPeerId,
  required String? localFingerprint,
  required String peerId,
  required String peerFingerprint,
}) {
  return detectLocalSignalingPeerMatchReason(
        localSignalingPeerId: localSignalingPeerId,
        localFingerprint: localFingerprint,
        peerId: peerId,
        peerFingerprint: peerFingerprint,
      ) !=
      null;
}

LocalSignalingPeerMatchReason? detectLocalSignalingPeerMatchReason({
  required String? localSignalingPeerId,
  required String? localFingerprint,
  required String peerId,
  required String peerFingerprint,
}) {
  final normalizedLocalSignalingPeerId = localSignalingPeerId?.trim();
  final normalizedPeerId = peerId.trim();
  final normalizedLocalFingerprint = localFingerprint?.trim();
  final normalizedPeerFingerprint = peerFingerprint.trim();

  // Guardrail: signaling self-detection must accept either same peer id or same fingerprint.
  // Both checks are required because reconnect/rejoin timing may briefly desync peer ids.
  final byId =
      normalizedLocalSignalingPeerId != null &&
      normalizedLocalSignalingPeerId.isNotEmpty &&
      normalizedPeerId == normalizedLocalSignalingPeerId;
  final byFingerprint =
      normalizedLocalFingerprint != null &&
      normalizedLocalFingerprint.isNotEmpty &&
      normalizedPeerFingerprint.isNotEmpty &&
      normalizedPeerFingerprint == normalizedLocalFingerprint;
  if (byId) {
    return LocalSignalingPeerMatchReason.signalingId;
  }
  if (byFingerprint) {
    return LocalSignalingPeerMatchReason.fingerprint;
  }
  return null;
}