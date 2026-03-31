import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/config/init.dart';
import 'package:linkdrop_app/gen/assets.gen.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/pages/home_page_controller.dart';
import 'package:linkdrop_app/pages/login_page.dart';
import 'package:linkdrop_app/pages/payment_page.dart';
import 'package:linkdrop_app/pages/receive_page.dart';
import 'package:linkdrop_app/pages/send_page.dart';
import 'package:linkdrop_app/pages/settings_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/provider/selection/selected_sending_files_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/native/cross_file_converters.dart';
import 'package:linkdrop_app/widget/responsive_builder.dart';
import 'package:linkdrop_app/widget/window_title_bar.dart';
import 'package:provider/provider.dart' as provider;
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  receive(Icons.wifi),
  send(Icons.send),
  settings(Icons.person);

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return '用户'; // 修改为用户
    }
  }
}

class LinkDropHomePage extends StatefulWidget {
  final HomeTab initialTab;
  final bool appStart;

  const LinkDropHomePage({
    required this.initialTab,
    required this.appStart,
    super.key,
  });

  @override
  State<LinkDropHomePage> createState() => _LinkDropHomePageState();
}

class _LinkDropHomePageState extends State<LinkDropHomePage> with Refena {
  bool _dragAndDropIndicator = false;
  bool _isSidebarExpanded = true;
  bool _initialTabSet = false;

  @override
  void initState() {
    super.initState();
    ensureRef((ref) async {
      // 【关键修复】立即同步设置初始 tab，确保在 build 之前 PageController 已经正确初始化
      // 使用 dispatch 而不是 setInitialPage，因为 dispatch 会创建新的 PageController
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab, animate: false));

      // 在 first frame 后再次确认 tab 设置（防止 race condition）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialTabSet) {
          _initialTabSet = true;
          final currentTab = ref.read(homePageControllerProvider).currentTab;
          if (currentTab != widget.initialTab) {
            ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab, animate: false));
          }
        }
      });
      try {
        await postInit(context, ref, widget.appStart);
      } catch (e, stackTrace) {
        debugPrint('postInit error: $e\n$stackTrace');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context);
    final vm = ref.watch(homePageControllerProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = provider.Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragAndDropIndicator = true),
      onDragExited: (_) => setState(() => _dragAndDropIndicator = false),
      onDragDone: (event) async {
        if (event.files.length == 1 && Directory(event.files.first.path).existsSync()) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(event.files.first.path));
        } else {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(
                AddFilesAction(
                  files: event.files,
                  converter: CrossFileConverters.convertXFile,
                ),
              );
        }
        vm.changeTab(HomeTab.send);
      },
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          return Scaffold(
            body: Container(
              color: isDark ? const Color(0xFF1c1c1e) : LinkDropColors.primaryLight,
              child: Row(
                children: [
                  if (!sizingInformation.isMobile)
                    Stack(
                      children: [
                        NavigationRail(
                          selectedIndex: vm.currentTab.index,
                          onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                          extended: _isSidebarExpanded,
                          backgroundColor: isDark ? const Color(0xFF1c1c1e) : LinkDropColors.primaryLight,
                          indicatorColor: isDark ? LinkDropColors.primary.withValues(alpha: 0.15) : LinkDropColors.primaryLight,
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selectedLabelTextStyle: TextStyle(
                            color: isDark ? Colors.white : LinkDropColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                          leading: Column(
                            children: [
                              const SizedBox(height: 40),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  hoverColor: LinkDropColors.primary.withOpacity(0.1),
                                  onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedRotation(
                                          turns: _isSidebarExpanded ? 0 : 0.5,
                                          duration: const Duration(milliseconds: 200),
                                          child: Assets.img.logo32.image(
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                        if (_isSidebarExpanded) ...[
                                          const SizedBox(width: 12),
                                          const Text(
                                            'LinkDrop',
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                          destinations: HomeTab.values.map((tab) {
                            return NavigationRailDestination(
                              icon: Icon(tab.icon),
                              selectedIcon: Icon(tab.icon, color: LinkDropColors.primary),
                              label: Text(tab.label),
                            );
                          }).toList(),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    hoverColor: LinkDropColors.primary.withOpacity(0.1),
                                    onTap: () async {
                                      await ref
                                          .notifier(settingsProvider)
                                          .setTheme(
                                            settings.theme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
                                          );
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: _isSidebarExpanded ? 24 : 0),
                                      child: Row(
                                        mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            settings.theme == ThemeMode.light ? Icons.light_mode : Icons.dark_mode,
                                            size: 24,
                                          ),
                                          if (_isSidebarExpanded) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              settings.theme == ThemeMode.light ? '日间模式' : '夜间模式',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: PopupMenuButton<String>(
                                    offset: const Offset(120, -180),
                                    tooltip: '',
                                    itemBuilder: (context) => [
                                      if (isAuthenticated && user != null) ...[
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person, size: 18),
                                              const SizedBox(width: 8),
                                              Text(user.username),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Row(
                                            children: [
                                              Icon(
                                                user.isVipActive ? Icons.workspace_premium : Icons.person_outline,
                                                size: 18,
                                                color: user.isVipActive ? LinkDropColors.primary : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                user.isVipActive
                                                    ? (user.vipRemainingDays == -1
                                                          ? '${user.membershipTypeName} · 永久会员'
                                                          : '${user.membershipTypeName} · 剩余${user.vipRemainingDays}天')
                                                    : '普通用户',
                                                style: TextStyle(
                                                  color: user.isVipActive ? LinkDropColors.primary : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (user.inviteCode != null)
                                          PopupMenuItem(
                                            enabled: false,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.card_giftcard, size: 18),
                                                const SizedBox(width: 8),
                                                Text('邀请码: ${user.inviteCode}'),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () {
                                                    Clipboard.setData(ClipboardData(text: user.inviteCode!));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('邀请码已复制')),
                                                    );
                                                  },
                                                  child: Icon(Icons.copy, size: 16, color: LinkDropColors.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem(
                                          value: 'payment',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.payment, size: 18),
                                              const SizedBox(width: 8),
                                              Text(user.isVipActive ? '续费会员' : '开通会员'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'logout',
                                          child: Row(
                                            children: [
                                              Icon(Icons.logout, size: 18, color: LinkDropColors.error),
                                              const SizedBox(width: 8),
                                              Text('退出登录', style: TextStyle(color: LinkDropColors.error)),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Text(t.settingsTab.general.loginStatus + ': 未登录'),
                                        ),
                                        PopupMenuItem(
                                          value: 'login',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.login, size: 18),
                                              const SizedBox(width: 8),
                                              Text('登录'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'login') {
                                        final result = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (context) => const LoginPage(),
                                            fullscreenDialog: true,
                                          ),
                                        );
                                        if (result == true) {
                                          setState(() {});
                                        }
                                      } else if (value == 'payment') {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PaymentPage(),
                                            fullscreenDialog: true,
                                          ),
                                        );
                                        await provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();
                                        setState(() {});
                                      } else if (value == 'logout') {
                                        // 显示确认退出弹窗
                                        final shouldLogout = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('确认退出'),
                                            content: const Text('确定要退出登录吗？'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('取消'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: Text('退出', style: TextStyle(color: LinkDropColors.error)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (shouldLogout == true) {
                                          await provider.Provider.of<AuthProvider>(context, listen: false).logout();
                                          setState(() {});
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: _isSidebarExpanded ? 24 : 0),
                                      child: Row(
                                        mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isAuthenticated ? Icons.person : Icons.person_outline,
                                            size: 24,
                                          ),
                                          if (_isSidebarExpanded) ...[
                                            const SizedBox(width: 16),
                                            Text(
                                              isAuthenticated && user != null ? user.username : t.settingsTab.general.profile,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: MoveWindow(),
                        ),
                      ],
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        // 标题栏 - 与左侧菜单同色
                        WindowTitleBar(
                          backgroundColor: isDark ? const Color(0xFF1c1c1e) : LinkDropColors.primaryLight,
                        ),
                        // 内容区域 - 白色/深色圆角卡片
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 12, bottom: 12, left: 0, top: 0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2c2c2e) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isDark
                                  ? Border.all(
                                      color: const Color(0xFF3a3a3c),
                                      width: 1,
                                    )
                                  : null,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  PageView(
                                    controller: vm.controller,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: const [
                                      SafeArea(child: ReceivePage()),
                                      SafeArea(child: SendPage()),
                                      SettingsPage(),
                                    ],
                                  ),
                                  if (_dragAndDropIndicator)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.file_download, size: 128),
                                          const SizedBox(height: 30),
                                          Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: sizingInformation.isMobile
                ? NavigationBar(
                    selectedIndex: vm.currentTab.index,
                    onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
                    destinations: HomeTab.values.map((tab) {
                      return NavigationDestination(icon: Icon(tab.icon), label: tab.label);
                    }).toList(),
                  )
                : null,
          );
        },
      ),
    );
  }
}
