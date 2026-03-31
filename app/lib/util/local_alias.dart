import 'package:linkdrop_app/util/ip_helper.dart';

String resolveEffectiveLocalAlias({
  required String storedAlias,
  required bool isAliasModified,
}) {
  final trimmedStoredAlias = storedAlias.trim();
  return trimmedStoredAlias;
}

String resolveLocalDeviceDisplayName({
  required String storedAlias,
  required bool isAliasModified,
  String? ip,
}) {
  final effectiveAlias = resolveEffectiveLocalAlias(
    storedAlias: storedAlias,
    isAliasModified: isAliasModified,
  );

  final hasIp = ip != null && ip.isNotEmpty;

  if (isAliasModified || !hasIp) {
    return effectiveAlias;
  }

  return '${ip.visualId}（我）';
}

String resolveLocalAliasEditorInitialValue({
  required String storedAlias,
  required bool isAliasModified,
  String? ip,
}) {
  if (isAliasModified) {
    return storedAlias;
  }

  final hasIp = ip != null && ip.isNotEmpty;
  if (hasIp) {
    return '${ip.visualId}（我）';
  }

  return storedAlias;
}
