import 'package:flutter/material.dart';
import 'package:linkdrop_app/pages/home_page.dart';
import 'package:linkdrop_app/pages/login_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:provider/provider.dart' as provider;

/// 启动页
///
/// 显示 Logo 和加载动画，初始化完成后自动跳转
class SplashPage extends StatefulWidget {
  final WidgetBuilder? loginPageBuilder;
  final Widget Function(BuildContext context, HomeTab initialTab, bool appStart)? homePageBuilder;

  const SplashPage({
    super.key,
    this.loginPageBuilder,
    this.homePageBuilder,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // 监听认证状态变化
    _checkAuthAndNavigate();
  }

  /// 检查认证状态并导航
  Future<void> _checkAuthAndNavigate() async {
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);

    // 等待初始化完成
    if (authProvider.isLoading) {
      await _waitForInitialization(authProvider);
    }

    if (!mounted) return;

    // 根据登录状态导航
    if (authProvider.isAuthenticated) {
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  /// 等待初始化完成
  Future<void> _waitForInitialization(AuthProvider authProvider) async {
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 导航到主页
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            widget.homePageBuilder?.call(context, HomeTab.receive, false) ??
            LinkDropHomePage(
              initialTab: HomeTab.receive,
              appStart: false,
            ),
      ),
    );
  }

  /// 导航到登录页
  void _navigateToLogin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => widget.loginPageBuilder?.call(context) ?? const LoginPage(),
        fullscreenDialog: true,
      ),
    );

    // 登录成功后跳转主页
    if (result == true && mounted) {
      _navigateToHome();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo - 直接显示带背景的新 logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: LinkDropColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/img/logo-512-white.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 应用名称
              Text(
                'LinkDrop',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // 副标题
              Text(
                '跨平台文件传输',
                style: TextStyle(
                  fontSize: 14,
                  color: LinkDropColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // 加载指示器
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LinkDropColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
