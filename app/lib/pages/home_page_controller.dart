import 'package:flutter/material.dart';
import 'package:linkdrop_app/pages/home_page.dart';
import 'package:refena_flutter/refena_flutter.dart';

class HomePageVm {
  final PageController controller;
  final HomeTab currentTab;
  final void Function(HomeTab, {bool animate}) changeTab;

  HomePageVm({
    required this.controller,
    required this.currentTab,
    required this.changeTab,
  });
}

final homePageControllerProvider = ReduxProvider<HomePageController, HomePageVm>(
  (ref) => HomePageController(),
);

class HomePageController extends ReduxNotifier<HomePageVm> {
  final HomeTab initialTab;

  HomePageController({this.initialTab = HomeTab.receive});

  @override
  HomePageVm init() {
    return HomePageVm(
      controller: PageController(initialPage: initialTab.index),
      currentTab: initialTab,
      changeTab: (tab, {bool animate = true}) => redux.dispatch(ChangeTabAction(tab, animate: animate)),
    );
  }

  /// 设置初始页面
  void setInitialPage(HomeTab tab) {
    redux.dispatch(ChangeTabAction(tab, animate: false));
  }
}

/// 切换 Tab 的 Action
///
/// 【重要修复记录 - BugID: TAB_SWITCH_001】
///
/// 问题描述：
/// 当从 ProgressPage 使用 pushAndRemoveUntil 返回到 LinkDropHomePage 时，
/// 如果传入 initialTab=HomeTab.send，PageView 仍然显示接收页内容，
/// 但 tabbar 显示发送页被选中（PageView 内容与 tabbar 不同步）。
///
/// 问题原因：
/// PageController 被创建时 hasClients 为 false（因为 PageView 还没 build），
/// 此时调用 jumpToPage() 不会生效，PageView 默认显示第 0 页（接收页）。
///
/// 解决方案：
/// 在 reduce() 中检查 hasClients：
/// - 如果 hasClients == false：直接创建带正确 initialPage 的新 PageController
/// - 如果 hasClients == true：使用 animateToPage 或 jumpToPage
///
/// 修改记录：
/// - 2026-03-30：修复 PageController 未 attached 时 jumpToPage 无效的问题
///
class ChangeTabAction extends ReduxAction<HomePageController, HomePageVm> {
  final HomeTab tab;
  final bool animate;

  ChangeTabAction(this.tab, {this.animate = true});

  @override
  HomePageVm reduce() {
    final oldController = state.controller;
    PageController newController;

    if (!oldController.hasClients) {
      // PageController 还没有 attached，直接创建带有正确 initialPage 的新 controller
      // 这是解决白屏后页面与 tabbar 不同步的关键！
      newController = PageController(initialPage: tab.index);
      oldController.dispose();
    } else {
      newController = oldController;
      if (animate) {
        oldController.animateToPage(
          tab.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        oldController.jumpToPage(tab.index);
      }
    }

    return HomePageVm(
      controller: newController,
      currentTab: tab,
      changeTab: state.changeTab,
    );
  }
}
