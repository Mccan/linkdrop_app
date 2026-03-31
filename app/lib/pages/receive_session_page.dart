import 'dart:async';

import 'package:common/model/device.dart';
import 'package:common/model/dto/file_dto.dart';
import 'package:common/model/session_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/config/theme.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/pages/home_page.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/model/persistence/color_mode.dart';
import 'package:linkdrop_app/pages/receive_options_page.dart';
import 'package:linkdrop_app/provider/favorites_provider.dart';
import 'package:linkdrop_app/provider/selection/selected_receiving_files_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/util/device_type_ext.dart';
import 'package:linkdrop_app/util/favorites.dart';
import 'package:linkdrop_app/util/ip_helper.dart';
import 'package:linkdrop_app/util/native/platform_check.dart';
import 'package:linkdrop_app/util/native/taskbar_helper.dart';
import 'package:linkdrop_app/util/ui/snackbar.dart';
import 'package:linkdrop_app/widget/device_bage.dart';
import 'package:linkdrop_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceivePageVm {
  final SessionStatus? status;
  final Device sender;

  /// Show hashtag and device model.
  final bool showSenderInfo;
  final List<FileDto> files;
  final String? message;
  final bool isLink;
  final void Function() onAccept;
  final void Function() onDecline;
  final void Function() onClose;

  ReceivePageVm({
    required this.status,
    required this.sender,
    required this.showSenderInfo,
    required this.files,
    required this.message,
    required this.onAccept,
    required this.onDecline,
    required this.onClose,
  }) : isLink = message != null && (Uri.tryParse(message)?.isAbsolute ?? false);
}

class ReceiveSessionPage extends StatefulWidget {
  final ViewProvider<ReceivePageVm> vm;

  const ReceiveSessionPage(this.vm);

  @override
  State<ReceiveSessionPage> createState() => _ReceiveSessionPageState();
}

class _ReceiveSessionPageState extends State<ReceiveSessionPage> with Refena {
  bool _showFullIp = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch(
      widget.vm,
      listener: (prev, next) {
        if (prev.status != next.status) {
          // ignore: discarded_futures
          TaskbarHelper.visualizeStatus(next.status);
        }
      },
    );

    // 【关键修改 - BugID: CANCEL_SYNC_001】
    // 当发送端取消时，接收端的 ReceiveSessionPage 应该自动关闭
    // 接收端始终返回 HomeTab.receive，所以这里使用 pushAndRemoveUntil 是可以的
    // （不需要像 progress_page.dart 那样使用 popUntilRoot + ChangeTabAction）
    //
    // 【修改记录】
    // - 2026-03-30：添加发送端取消时自动关闭页面的逻辑
    if (vm.status == SessionStatus.canceledBySender) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // 使用 pushAndRemoveUntil 返回首页，避免 popUntilRoot 导致的页面与 tabbar 不同步问题
          // 参见 home_page_controller.dart 中的 TAB_SWITCH_001 修复记录
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LinkDropHomePage(initialTab: HomeTab.receive, appStart: false),
            ),
            (route) => false,
          );
        }
      });
    }

    if (vm.status == null && vm.message == null) {
      return const Scaffold(
        body: SizedBox(),
      );
    }

    final senderFavoriteEntry = ref.watch(favoritesProvider.select((state) => state.findDevice(vm.sender)));

    return ViewModelBuilder(
      provider: (ref) => widget.vm,
      onFirstFrame: (context, vm) {
        ref.notifier(selectedReceivingFilesProvider).setFiles(vm.files);
      },
      dispose: (ref) {
        ref.dispose(widget.vm);
        unawaited(TaskbarHelper.clearProgressBar());
      },
      builder: (context, vm) {
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              vm.onDecline();
            }
          },
          canPop: true,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: ResponsiveListView.defaultMaxWidth),
                  child: Builder(
                    builder: (context) {
                      final height = MediaQuery.of(context).size.height;
                      final smallUi = vm.message != null && height < 600;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: smallUi ? 20 : 30),
                        child: Column(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (vm.showSenderInfo && !smallUi)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Icon(vm.sender.deviceType.icon, size: 64),
                                    ),
                                  Builder(
                                    builder: (context) {
                                      final alias = senderFavoriteEntry?.alias ?? vm.sender.alias;
                                      if (alias.isEmpty) {
                                        return Text('', style: TextStyle(fontSize: smallUi ? 32 : 48));
                                      }
                                      return FittedBox(
                                        child: Text(
                                          alias,
                                          style: TextStyle(fontSize: smallUi ? 32 : 48),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                  if (vm.showSenderInfo) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showFullIp = !_showFullIp;
                                            });
                                          },
                                          child: DeviceBadge(
                                            backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                            foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
                                            label: switch (vm.sender.ip) {
                                              String ip => _showFullIp ? ip : '#${ip.visualId}',
                                              null => 'WebRTC',
                                            },
                                          ),
                                        ),
                                        if (vm.sender.deviceModel != null) ...[
                                          const SizedBox(width: 10),
                                          DeviceBadge(
                                            backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                            foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
                                            label: vm.sender.deviceModel!,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 40),
                                  Text(
                                    vm.message != null
                                        ? (vm.isLink ? t.receivePage.subTitleLink : t.receivePage.subTitleMessage)
                                        : t.receivePage.subTitle(n: vm.files.length),
                                    style: smallUi ? null : Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (vm.message != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 20),
                                          child: SizedBox(
                                            height: 100,
                                            child: Card(
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10),
                                                  child: SelectableText(
                                                    vm.message!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                unawaited(
                                                  Clipboard.setData(ClipboardData(text: vm.message!)),
                                                );
                                                if (checkPlatformIsDesktop()) {
                                                  context.showSnackBar(t.general.copiedToClipboard);
                                                }
                                                vm.onAccept();
                                                context.pop();
                                              },
                                              child: Text(t.general.copy),
                                            ),
                                            if (vm.isLink)
                                              Padding(
                                                padding: const EdgeInsetsDirectional.only(start: 20),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                  onPressed: () {
                                                    // ignore: discarded_futures
                                                    launchUrl(Uri.parse(vm.message!), mode: LaunchMode.externalApplication);
                                                    vm.onAccept();
                                                    context.pop();
                                                  },
                                                  child: Text(t.general.open),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            _Actions(vm),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  final ReceivePageVm vm;

  const _Actions(this.vm);

  @override
  Widget build(BuildContext context) {
    final selectedFiles = context.watch(selectedReceivingFilesProvider);
    final colorMode = context.watch(settingsProvider.select((state) => state.colorMode));

    if (vm.message != null) {
      return Center(
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            vm.onAccept();
            context.pop();
          },
          icon: const Icon(Icons.close),
          label: Text(t.general.close),
        ),
      );
    }

    if (vm.status == SessionStatus.canceledBySender) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              t.receivePage.canceled,
              style: TextStyle(color: Theme.of(context).colorScheme.warning),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                vm.onClose();
                context.pop();
              },
              icon: const Icon(Icons.check_circle),
              label: Text(t.general.close),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await context.push(() => ReceiveOptionsPage(vm));
            },
            icon: const Icon(Icons.settings),
            label: Text(t.receiveOptionsPage.title),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: colorMode == ColorMode.yaru ? 0 : null,
                backgroundColor: colorMode == ColorMode.yaru ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.error,
                foregroundColor: colorMode == ColorMode.yaru ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                vm.onDecline();
                context.pop();
              },
              icon: const Icon(Icons.close),
              label: Text(t.general.decline),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: selectedFiles.isEmpty ? null : () => vm.onAccept(),
              icon: const Icon(Icons.check_circle),
              label: Text(t.general.accept),
            ),
          ],
        ),
      ],
    );
  }
}
