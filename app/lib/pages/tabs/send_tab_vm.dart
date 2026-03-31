import 'package:collection/collection.dart';
import 'package:common/model/device.dart';
import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/cross_file.dart';
import 'package:linkdrop_app/model/persistence/favorite_device.dart';
import 'package:linkdrop_app/model/send_mode.dart';
import 'package:linkdrop_app/pages/progress_page.dart';
import 'package:linkdrop_app/pages/send_session_page.dart';
import 'package:linkdrop_app/pages/web_send_page.dart';
import 'package:linkdrop_app/provider/device_alias_overrides_provider.dart';
import 'package:linkdrop_app/provider/favorites_provider.dart';
import 'package:linkdrop_app/provider/local_ip_provider.dart';
import 'package:linkdrop_app/provider/network/nearby_devices_provider.dart';
import 'package:linkdrop_app/provider/network/scan_facade.dart';
import 'package:linkdrop_app/provider/network/send_provider.dart';
import 'package:linkdrop_app/provider/selection/selected_sending_files_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/util/favorites.dart';
import 'package:linkdrop_app/util/ip_helper.dart';
import 'package:linkdrop_app/widget/dialogs/address_input_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/favorite_delete_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/favorite_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/favorite_edit_dialog.dart';
import 'package:linkdrop_app/widget/dialogs/no_files_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// 发送标签页视图模型
///
/// 提供发送页面的所有状态和操作方法
/// 包括文件选择、设备发现、发送模式切换等功能
class SendTabVm {
  final SendMode sendMode;
  final List<CrossFile> selectedFiles;
  final List<String> localIps;
  final Iterable<Device> nearbyDevices;
  final List<FavoriteDevice> favoriteDevices;
  final Map<String, String> deviceAliasOverrides;
  final Future<void> Function(BuildContext context) onTapAddress;
  final Future<void> Function(BuildContext context) onTapFavorite;
  final Future<void> Function(BuildContext context, SendMode mode) onTapSendMode;
  final Future<void> Function(BuildContext context, Device device) onEditDeviceAlias;
  final Future<void> Function(BuildContext context, Device device) onToggleFavorite;
  final Future<void> Function(BuildContext context, Device device) onTapDevice;
  final Future<void> Function(BuildContext context, Device device) onTapDeviceMultiSend;

  const SendTabVm({
    required this.sendMode,
    required this.selectedFiles,
    required this.localIps,
    required this.nearbyDevices,
    required this.favoriteDevices,
    required this.deviceAliasOverrides,
    required this.onTapAddress,
    required this.onTapFavorite,
    required this.onTapSendMode,
    required this.onEditDeviceAlias,
    required this.onToggleFavorite,
    required this.onTapDevice,
    required this.onTapDeviceMultiSend,
  });
}

/// 发送标签页视图模型提供者
///
/// 提供发送页面的响应式状态管理
final sendTabVmProvider = ViewProvider((ref) {
  final sendMode = ref.watch(settingsProvider.select((s) => s.sendMode));
  final selectedFiles = ref.watch(selectedSendingFilesProvider);
  final localIps = ref.watch(localIpProvider).localIps;
  final nearbyDevices = ref.watch(nearbyDevicesProvider).allDevices.values;
  final favoriteDevices = ref.watch(favoritesProvider);
  final deviceAliasOverrides = ref.watch(deviceAliasOverridesProvider);

  return SendTabVm(
    sendMode: sendMode,
    selectedFiles: selectedFiles,
    localIps: localIps,
    nearbyDevices: nearbyDevices,
    favoriteDevices: favoriteDevices,
    deviceAliasOverrides: deviceAliasOverrides,
    onTapAddress: (context) async {
      final files = ref.read(selectedSendingFilesProvider);
      if (files.isEmpty) {
        await context.pushBottomSheet(() => const NoFilesDialog());
        return;
      }
      final device = await showDialog<Device?>(
        context: context,
        builder: (_) => const AddressInputDialog(),
      );
      if (device != null && context.mounted) {
        await ref
            .notifier(sendProvider)
            .startSession(
              target: device,
              files: files,
              background: false,
            );
      }
    },
    onTapFavorite: (context) async {
      final device = await showDialog<Device?>(
        context: context,
        builder: (_) => const FavoritesDialog(),
      );
      if (device != null && context.mounted) {
        final files = ref.read(selectedSendingFilesProvider);
        if (files.isEmpty) {
          await context.pushBottomSheet(() => const NoFilesDialog());
          return;
        }

        await ref
            .notifier(sendProvider)
            .startSession(
              target: device,
              files: files,
              background: false,
            );
      }
    },
    onTapSendMode: (context, mode) async {
      if (mode == SendMode.link) {
        final files = ref.read(selectedSendingFilesProvider);
        if (files.isEmpty) {
          await context.pushBottomSheet(() => const NoFilesDialog());
          return;
        }
        await context.push(() => WebSendPage(files));
        return;
      }

      await ref.notifier(settingsProvider).setSendMode(mode);
      if (mode != SendMode.multiple) {
        ref.notifier(sendProvider).clearAllSessions();
      }
    },
    onEditDeviceAlias: (context, device) async {
      final existingAlias = deviceAliasOverrides[device.fingerprint] ?? '';
      String fallbackAlias;
      if (device.alias.isNotEmpty) {
        fallbackAlias = device.alias;
      } else if (device.ip != null && device.ip!.isNotEmpty) {
        fallbackAlias = device.ip!.visualId;
      } else {
        fallbackAlias = device.fingerprint.substring(0, 8);
      }

      final result = await showDialog<(bool, String)?>(
        context: context,
        builder: (dialogContext) => _EditAliasDialog(
          initialText: existingAlias.isEmpty ? fallbackAlias : existingAlias,
          hintText: t.receiveTab.infoBox.alias,
        ),
      );

      if (result != null && result.$1 == true) {
        await ref.redux(deviceAliasOverridesProvider).dispatchAsync(SetDeviceAliasOverrideAction(fingerprint: device.fingerprint, alias: result.$2));
      }
    },
    onToggleFavorite: (context, device) async {
      final favoriteDevice = favoriteDevices.findDevice(device);
      if (favoriteDevice != null) {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => FavoriteDeleteDialog(favoriteDevice),
        );
        if (result == true) {
          await ref.redux(favoritesProvider).dispatchAsync(RemoveFavoriteAction(deviceFingerprint: device.fingerprint));
        }
      } else {
        await showDialog(
          context: context,
          builder: (_) => FavoriteEditDialog(prefilledDevice: device),
        );
      }
    },
    onTapDevice: (context, device) async {
      if (selectedFiles.isEmpty) {
        await context.pushBottomSheet(() => const NoFilesDialog());
        return;
      }

      await ref
          .notifier(sendProvider)
          .startSession(
            target: device,
            files: selectedFiles,
            background: false,
          );
    },
    onTapDeviceMultiSend: (context, device) async {
      final session = ref.read(sendProvider).values.firstWhereOrNull((s) => s.target.ip == device.ip);
      if (session != null) {
        if (session.status == SessionStatus.waiting) {
          ref.notifier(sendProvider).setBackground(session.sessionId, false);
          await context.push(
            () => SendSessionPage(showAppBar: true, closeSessionOnClose: true, sessionId: session.sessionId),
            transition: RouterinoTransition.fade(),
          );
          ref.notifier(sendProvider).setBackground(session.sessionId, true);
          return;
        } else if (session.status == SessionStatus.sending || session.status == SessionStatus.finishedWithErrors) {
          ref.notifier(sendProvider).setBackground(session.sessionId, false);
          await context.push(() => ProgressPage(showAppBar: true, closeSessionOnClose: true, sessionId: session.sessionId));
          ref.notifier(sendProvider).setBackground(session.sessionId, true);
          return;
        }
      }

      final files = ref.read(selectedSendingFilesProvider);
      if (files.isEmpty) {
        await context.pushBottomSheet(() => const NoFilesDialog());
        return;
      }

      if (session != null) {
        ref.notifier(sendProvider).closeSession(session.sessionId);
      }

      await ref
          .notifier(sendProvider)
          .startSession(
            target: device,
            files: files,
            background: true,
          );
    },
  );
});

/// 发送标签页初始化操作
///
/// 在页面初始化时自动开始扫描设备
class SendTabInitAction extends AsyncGlobalAction {
  final BuildContext context;

  SendTabInitAction(this.context);

  @override
  Future<void> reduce() async {
    final devices = ref.read(nearbyDevicesProvider).devices;
    if (devices.isEmpty) {
      await dispatchAsync(StartSmartScan(forceLegacy: false));
    }
  }
}

/// 编辑别名弹窗
///
/// 使用 StatefulWidget 来正确管理 TextEditingController 的生命周期
class _EditAliasDialog extends StatefulWidget {
  final String initialText;
  final String hintText;

  const _EditAliasDialog({
    required this.initialText,
    required this.hintText,
  });

  @override
  State<_EditAliasDialog> createState() => _EditAliasDialogState();
}

class _EditAliasDialogState extends State<_EditAliasDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hintText),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((false, '')),
          child: Text(t.general.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((true, _controller.text)),
          child: Text(t.general.save),
        ),
      ],
    );
  }
}
