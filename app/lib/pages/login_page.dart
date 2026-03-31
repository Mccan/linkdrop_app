import 'package:flutter/material.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:provider/provider.dart' as provider;

/// 登录页面
///
/// 提供手机号/用户名 + 密码登录功能
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isRegisterMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    final savedUsername = await authProvider.getSavedUsername();
    final savedPassword = await authProvider.getSavedPassword();

    if (savedUsername != null && savedUsername.isNotEmpty) {
      setState(() {
        _usernameController.text = savedUsername;
        // 如果有保存的密码，也自动填充
        if (savedPassword != null && savedPassword.isNotEmpty) {
          _passwordController.text = savedPassword;
          _rememberMe = true; // 有保存的密码时，默认勾选记住我
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isRegisterMode) {
      success = await authProvider.register(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      // 根据记住我选项保存或清除凭据
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      if (_rememberMe) {
        await authProvider.saveCredentials(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authProvider.clearCredentials();
      }
      Navigator.of(context).pop(true); // 返回登录成功标志
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = provider.Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDark ? LinkDropColors.zinc800 : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo - 直接显示带背景的新 logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: LinkDropColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/img/logo-512-white.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 标题
                        Text(
                          _isRegisterMode ? '创建账户' : '欢迎回来',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : LinkDropColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode ? '注册新账户开始使用' : '登录您的 LinkDrop 账户',
                          style: TextStyle(
                            fontSize: 14,
                            color: LinkDropColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 用户名输入框
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: '用户名',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: LinkDropColors.textSecondary.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: LinkDropColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入用户名';
                            }
                            if (value.length < 3) {
                              return '用户名至少3个字符';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 密码输入框
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: LinkDropColors.textSecondary.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: LinkDropColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            if (_isRegisterMode && value.length < 8) {
                              return '密码至少8个字符';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),

                        // 记住我（仅登录模式显示）
                        if (!_isRegisterMode) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() => _rememberMe = value ?? false);
                                  },
                                  activeColor: LinkDropColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                child: Text(
                                  '记住我',
                                  style: TextStyle(
                                    color: LinkDropColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 错误提示
                        if (authProvider.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 提交按钮
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LinkDropColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode ? '注册' : '登录',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 切换登录/注册
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegisterMode ? '已有账户？' : '没有账户？',
                              style: TextStyle(color: LinkDropColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  authProvider.clearError();
                                });
                              },
                              child: Text(
                                _isRegisterMode ? '立即登录' : '立即注册',
                                style: const TextStyle(
                                  color: LinkDropColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
