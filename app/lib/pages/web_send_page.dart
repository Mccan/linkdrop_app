import 'package:common/util/sleep.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/config/theme.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/cross_file.dart';
import 'package:linkdrop_app/provider/local_ip_provider.dart';
import 'package:linkdrop_app/provider/network/server/server_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/native/platform_check.dart';
import 'package:linkdrop_app/util/ui/snackbar.dart';
import 'package:linkdrop_app/widget/dialogs/pin_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/qr_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/zoom_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _ServerState { initializing, running, error, stopping }

class WebSendPage extends StatefulWidget {
  final List<CrossFile> files;

  const WebSendPage(this.files);

  @override
  State<WebSendPage> createState() => _WebSendPageState();
}

class _WebSendPageState extends State<WebSendPage> with Refena {
  _ServerState _stateEnum = _ServerState.initializing;
  bool _encrypted = false;
  String? _initializedError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(encrypted: false);
    });
  }

  void _init({required bool encrypted}) async {
    final settings = ref.read(settingsProvider);
    final (beforeAutoAccept, beforePin) = ref.read(serverProvider.select((state) => (state?.webSendState?.autoAccept, state?.webSendState?.pin)));
    setState(() {
      _stateEnum = _ServerState.initializing;
      _encrypted = encrypted;
      _initializedError = null;
    });
    await sleepAsync(500);
    try {
      await ref
          .notifier(serverProvider)
          .restartServer(
            alias: settings.alias,
            port: settings.port,
            https: _encrypted,
          );
      await ref.notifier(serverProvider).initializeWebSend(widget.files);
      if (beforeAutoAccept != null) {
        ref.notifier(serverProvider).setWebSendAutoAccept(beforeAutoAccept);
      }
      ref.notifier(serverProvider).setWebSendPin(beforePin);
      setState(() {
        _stateEnum = _ServerState.running;
      });
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _stateEnum = _ServerState.error;
          _initializedError = e.toString();
        });
      }
    }
  }

  Future<void> _revertServerState() async {
    await ref.notifier(serverProvider).restartServerFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (_, __) async {
        if (_stateEnum != _ServerState.running) {
          return;
        }

        setState(() {
          _stateEnum = _ServerState.stopping;
        });
        await sleepAsync(250);
        await _revertServerState();
        await sleepAsync(250);

        if (context.mounted) {
          context.pop();
        }
      },
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Web Share',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : LinkDropColors.zinc900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share files via web link',
                          style: TextStyle(
                            color: LinkDropColors.zinc500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () async {
                        if (_stateEnum == _ServerState.running) {
                          setState(() {
                            _stateEnum = _ServerState.stopping;
                          });
                          await sleepAsync(250);
                          await _revertServerState();
                          await sleepAsync(250);
                        }
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white : LinkDropColors.zinc900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_stateEnum != _ServerState.running) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) ...[
                                CircularProgressIndicator(
                                  color: LinkDropColors.teal500,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _stateEnum == _ServerState.initializing ? 'Initializing...' : 'Stopping...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                                  ),
                                ),
                              ] else if (_initializedError != null) ...[
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  _initializedError!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: LinkDropColors.zinc500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      final serverState = context.watch(serverProvider)!;
                      final webSendState = serverState.webSendState!;
                      final networkState = context.watch(localIpProvider);

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open link on other device',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : LinkDropColors.zinc900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...networkState.localIps.map((ip) {
                              final url = '${_encrypted ? 'https' : 'http'}://$ip:${serverState.port}';
                              final urlWithPin = switch (webSendState.pin) {
                                String() => '$url/?pin=${Uri.encodeQueryComponent(webSendState.pin!)}',
                                null => url,
                              };
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        url,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white : LinkDropColors.zinc900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.content_copy_rounded,
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(text: url));
                                        if (context.mounted && checkPlatformIsDesktop()) {
                                          context.showSnackBar(t.general.copiedToClipboard);
                                        }
                                      },
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.qr_code_rounded,
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => QrDialog(
                                            data: urlWithPin,
                                            label: url,
                                            listenIncomingWebSendRequests: true,
                                            pin: webSendState.pin,
                                          ),
                                        );
                                      },
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.tv_rounded,
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => ZoomDialog(
                                            label: url,
                                            pin: webSendState.pin,
                                            listenIncomingWebSendRequests: true,
                                          ),
                                        );
                                      },
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            Text(
                              'Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : LinkDropColors.zinc900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (webSendState.sessions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Text(
                                  'No requests yet',
                                  style: TextStyle(
                                    color: LinkDropColors.zinc500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ...webSendState.sessions.entries.map((entry) {
                              final session = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.deviceInfo,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: session.responseHandler != null
                                                  ? LinkDropColors.orange500
                                                  : (isDark ? Colors.white : LinkDropColors.zinc900),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            session.ip,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: LinkDropColors.zinc500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (session.responseHandler != null) ...[
                                      IconButton(
                                        onPressed: () {
                                          ref.notifier(serverProvider).declineWebSendRequest(session.sessionId);
                                        },
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: LinkDropColors.red500,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ref.notifier(serverProvider).acceptWebSendRequest(session.sessionId);
                                        },
                                        icon: Icon(
                                          Icons.check_circle_rounded,
                                          color: LinkDropColors.teal500,
                                        ),
                                      ),
                                    ] else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          'Accepted',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: LinkDropColors.teal500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            _SettingItem(
                              label: 'Encryption',
                              isDark: isDark,
                              child: Checkbox(
                                value: _encrypted,
                                activeColor: LinkDropColors.teal500,
                                onChanged: (value) {
                                  _init(encrypted: value == true);
                                },
                              ),
                            ),
                            if (_encrypted)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, top: 8),
                                child: Text(
                                  t.webSharePage.encryptionHint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LinkDropColors.orange500,
                                  ),
                                ),
                              ),
                            _SettingItem(
                              label: 'Auto Accept',
                              isDark: isDark,
                              child: Checkbox(
                                value: webSendState.autoAccept,
                                activeColor: LinkDropColors.teal500,
                                onChanged: (value) {
                                  ref.notifier(serverProvider).setWebSendAutoAccept(value == true);
                                },
                              ),
                            ),
                            _SettingItem(
                              label: 'Require PIN',
                              isDark: isDark,
                              child: Checkbox(
                                value: webSendState.pin != null,
                                activeColor: LinkDropColors.teal500,
                                onChanged: (value) async {
                                  final currentPIN = webSendState.pin;
                                  if (currentPIN != null) {
                                    ref.notifier(serverProvider).setWebSendPin(null);
                                  } else {
                                    final String? newPin = await showDialog<String>(
                                      context: context,
                                      builder: (_) => const PinDialog(
                                        obscureText: false,
                                        generateRandom: true,
                                      ),
                                    );

                                    if (newPin != null && newPin.isNotEmpty) {
                                      ref.notifier(serverProvider).setWebSendPin(newPin);
                                    }
                                  }
                                },
                              ),
                            ),
                            if (webSendState.pin != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 16, top: 8),
                                child: Text(
                                  t.webSharePage.pinHint(pin: webSendState.pin!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LinkDropColors.orange500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : LinkDropColors.zinc700,
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isDark;

  const _SettingItem({
    required this.label,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}
