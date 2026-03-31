import 'package:flutter/material.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/pages/login_page.dart';
import 'package:linkdrop_app/pages/payment_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';

/// 权限检查结果
enum PermissionStatus {
  /// 允许访问
  granted,

  /// 需要登录
  requiresLogin,

  /// 需要开通会员
  requiresMembership,
}

/// 权限检查工具类
///
/// 用于统一处理页面级别的权限控制逻辑
class PermissionChecker {
  /// 检查接收页权限
  ///
  /// 接收页需要登录才能使用
  static PermissionStatus checkReceivePermission(User? user, bool isAuthenticated) {
    if (!isAuthenticated || user == null) {
      return PermissionStatus.requiresLogin;
    }
    return PermissionStatus.granted;
  }

  /// 检查发送页权限
  ///
  /// 发送页需要登录且开通会员才能使用
  static PermissionStatus checkSendPermission(User? user, bool isAuthenticated) {
    if (!isAuthenticated || user == null) {
      return PermissionStatus.requiresLogin;
    }
    if (!user.isVipActive) {
      return PermissionStatus.requiresMembership;
    }
    return PermissionStatus.granted;
  }

  /// 直接跳转到登录页面
  /// 返回登录是否成功
  static Future<bool> showLoginDialog(BuildContext context) async {
    // 直接跳转登录页，不显示确认弹窗
    final loginResult = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
        fullscreenDialog: true,
      ),
    );
    return loginResult == true;
  }

  /// 直接跳转到开通会员页面
  /// 返回是否开通成功
  static Future<bool> showMembershipDialog(BuildContext context) async {
    // 直接跳转支付页，不显示确认弹窗
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PaymentPage(),
        fullscreenDialog: true,
      ),
    );
    // 支付完成后刷新用户信息并返回结果
    if (context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUser();
      final user = authProvider.user;
      final isVip = user?.isVipActive ?? false;
      return isVip;
    }
    return false;
  }
}

/// 权限控制混入
///
/// 用于 StatefulWidget 中快速集成权限控制
/// 在 initState 中调用 checkPermission 方法
/// 自动监听 AuthProvider 变化，登录状态改变时重新检查权限
mixin PermissionControlMixin<T extends StatefulWidget> on State<T> {
  bool _isCheckingPermission = true;
  bool _hasPermission = false;
  bool _shouldShowLogin = false;
  bool _shouldShowMembership = false;

  /// 用于追踪认证状态变化
  bool? _lastIsAuthenticated;
  User? _lastUser;
  bool _initialized = false;

  /// 子类需要实现的权限检查方法
  /// 返回需要的权限类型
  PermissionStatus get requiredPermission;

  @override
  void initState() {
    super.initState();
    // 不在这里检查权限，等待 didChangeDependencies 中 AuthProvider 状态稳定后再检查
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 使用 listen: true 建立监听关系，当 AuthProvider 状态变化时会触发重建
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final currentIsAuthenticated = authProvider.isAuthenticated;
    final currentUser = authProvider.user;

    // 首次检查或状态发生变化时重新检查权限
    final authChanged = _lastIsAuthenticated != currentIsAuthenticated;
    final userChanged = _lastUser?.id != currentUser?.id;
    final membershipChanged = _lastUser?.membership?.hasVip != currentUser?.membership?.hasVip;
    final shouldCheck = !_initialized || (_lastIsAuthenticated != null && (authChanged || userChanged || membershipChanged));

    if (shouldCheck) {
      _initialized = true;
      // 使用微任务延迟执行，避免在 didChangeDependencies 中同步调用 setState
      Future.microtask(() {
        if (mounted) {
          _doCheckPermission();
        }
      });
    }

    _lastIsAuthenticated = currentIsAuthenticated;
    _lastUser = currentUser;
  }

  /// 重新检查权限
  void recheckPermission() {
    setState(() {
      _isCheckingPermission = true;
      _hasPermission = false;
      _shouldShowLogin = false;
      _shouldShowMembership = false;
    });
    _doCheckPermission();
  }

  /// 执行权限检查
  void _doCheckPermission() {
    // 延迟到下一帧执行，确保 context 可用且 AuthProvider 状态已更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 使用 read 获取最新状态（不建立监听，避免重复触发）
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      final isAuthenticated = authProvider.isAuthenticated;

      // 更新追踪的状态
      _lastIsAuthenticated = isAuthenticated;
      _lastUser = user;

      // 检查权限状态
      final status = _getPermissionStatus(user, isAuthenticated);

      if (status == PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _isCheckingPermission = false;
            _hasPermission = true;
          });
        }
      } else {
        // 无权限，显示对应的提示界面
        if (mounted) {
          setState(() {
            _isCheckingPermission = false;
            _hasPermission = false;
            _shouldShowLogin = status == PermissionStatus.requiresLogin;
            _shouldShowMembership = status == PermissionStatus.requiresMembership;
          });
        }
      }
    });
  }

  /// 获取权限状态
  PermissionStatus _getPermissionStatus(User? user, bool isAuthenticated) {
    switch (requiredPermission) {
      case PermissionStatus.requiresLogin:
        return PermissionChecker.checkReceivePermission(user, isAuthenticated);
      case PermissionStatus.requiresMembership:
        return PermissionChecker.checkSendPermission(user, isAuthenticated);
      case PermissionStatus.granted:
        return PermissionStatus.granted;
    }
  }

  /// 处理登录按钮点击
  Future<void> handleLoginPressed() async {
    final success = await PermissionChecker.showLoginDialog(context);
    if (success && mounted) {
      recheckPermission();
    }
  }

  /// 处理开通会员按钮点击
  Future<void> handleMembershipPressed() async {
    await PermissionChecker.showMembershipDialog(context);
    if (mounted) {
      recheckPermission();
    }
  }

  /// 是否正在检查权限
  bool get isCheckingPermission => _isCheckingPermission;

  /// 是否有权限
  bool get hasPermission => _hasPermission;

  /// 是否需要显示登录提示
  bool get shouldShowLogin => _shouldShowLogin;

  /// 是否需要显示会员提示
  bool get shouldShowMembership => _shouldShowMembership;

  /// 构建权限检查中的加载界面
  Widget buildPermissionCheckingWidget() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在检查权限...'),
          ],
        ),
      ),
    );
  }

  /// 构建无权限的提示界面
  Widget buildNoPermissionWidget() {
    if (_shouldShowLogin) {
      return _buildLoginRequiredWidget();
    }
    if (_shouldShowMembership) {
      return _buildMembershipRequiredWidget();
    }
    return _buildGenericNoPermissionWidget();
  }

  /// 构建需要登录的提示界面
  Widget _buildLoginRequiredWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '请先登录后再使用该功能',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: handleLoginPressed,
              icon: const Icon(Icons.login),
              label: const Text('立即登录'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建需要开通会员的提示界面
  Widget _buildMembershipRequiredWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              '发送文件需要开通会员',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '开通会员后即可享受文件发送功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: handleMembershipPressed,
              icon: const Icon(Icons.payment),
              label: const Text('立即开通'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建通用无权限提示界面
  Widget _buildGenericNoPermissionWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无权限使用该功能',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: recheckPermission,
              child: const Text('重新检查权限'),
            ),
          ],
        ),
      ),
    );
  }
}
