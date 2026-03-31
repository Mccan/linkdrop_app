import 'package:flutter/material.dart';
import 'package:linkdrop_app/model/state/settings_state.dart';
import 'package:linkdrop_app/provider/network/server/server_provider.dart';
import 'package:linkdrop_app/provider/network/webrtc/signaling_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Keeps advertised local identity in sync with local alias changes.
///
/// When the user modifies the local alias, this watcher refreshes server and
/// signaling identity immediately.
class AuthIdentityWatcher extends StatefulWidget {
  final Widget child;

  const AuthIdentityWatcher({
    required this.child,
    super.key,
  });

  @override
  State<AuthIdentityWatcher> createState() => _AuthIdentityWatcherState();
}

class _AuthIdentityWatcherState extends State<AuthIdentityWatcher> with Refena {
  String? _previousIdentityKey;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final identityKey = _buildIdentityKey(settings);

    if (_previousIdentityKey == null) {
      _previousIdentityKey = identityKey;
    } else if (identityKey != _previousIdentityKey) {
      _previousIdentityKey = identityKey;
      _scheduleIdentityRefresh();
    } else {
      _previousIdentityKey = identityKey;
    }

    return widget.child;
  }

  String _buildIdentityKey(SettingsState settings) {
    if (settings.isAliasModified) {
      return 'manual:${settings.alias.trim()}';
    }

    return 'auto';
  }

  void _scheduleIdentityRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _refreshing) {
        return;
      }

      _refreshing = true;
      try {
        await ref.notifier(serverProvider).restartServerFromSettings();
        await ref.global.dispatchAsync(RefreshSignalingIdentityAction());
      } finally {
        _refreshing = false;
      }
    });
  }
}
