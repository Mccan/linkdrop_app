import 'package:linkdrop_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Stores local-only alias overrides for remote devices.
///
/// Key: remote device fingerprint
/// Value: alias shown only on this device
final deviceAliasOverridesProvider = ReduxProvider<DeviceAliasOverridesService, Map<String, String>>((ref) {
  return DeviceAliasOverridesService(ref.read(persistenceProvider));
});

class DeviceAliasOverridesService extends ReduxNotifier<Map<String, String>> {
  final PersistenceService _persistence;

  DeviceAliasOverridesService(this._persistence);

  @override
  Map<String, String> init() => Map.unmodifiable(_persistence.getDeviceAliasOverrides());
}

class SetDeviceAliasOverrideAction extends AsyncReduxAction<DeviceAliasOverridesService, Map<String, String>> {
  final String fingerprint;
  final String alias;

  SetDeviceAliasOverrideAction({
    required this.fingerprint,
    required this.alias,
  });

  @override
  Future<Map<String, String>> reduce() async {
    final key = fingerprint.trim();
    if (key.isEmpty) {
      return state;
    }

    final trimmedAlias = alias.trim();
    final updated = <String, String>{...state};

    if (trimmedAlias.isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = trimmedAlias;
    }

    final immutable = Map<String, String>.unmodifiable(updated);
    await notifier._persistence.setDeviceAliasOverrides(immutable);
    return immutable;
  }
}

class RemoveDeviceAliasOverrideAction extends AsyncReduxAction<DeviceAliasOverridesService, Map<String, String>> {
  final String fingerprint;

  RemoveDeviceAliasOverrideAction({required this.fingerprint});

  @override
  Future<Map<String, String>> reduce() async {
    final key = fingerprint.trim();
    if (key.isEmpty || !state.containsKey(key)) {
      return state;
    }

    final updated = <String, String>{...state}..remove(key);
    final immutable = Map<String, String>.unmodifiable(updated);
    await notifier._persistence.setDeviceAliasOverrides(immutable);
    return immutable;
  }
}
