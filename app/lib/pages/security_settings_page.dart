import 'package:flutter/material.dart';
import 'package:linkdrop_app/services/api_service.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      return false;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  void _validateNewPassword() {
    final password = _newPasswordController.text;
    if (password.isEmpty) {
      setState(() => _newPasswordError = null);
      return;
    }
    if (password.length < 8) {
      setState(() => _newPasswordError = '密码长度至少8位');
    } else if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      setState(() => _newPasswordError = '密码必须包含字母');
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _newPasswordError = '密码必须包含数字');
    } else {
      setState(() => _newPasswordError = null);
    }
  }

  void _validateConfirmPassword() {
    final confirm = _confirmPasswordController.text;
    if (confirm.isEmpty) {
      setState(() => _confirmPasswordError = null);
      return;
    }
    if (confirm != _newPasswordController.text) {
      setState(() => _confirmPasswordError = '两次输入的密码不一致');
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  Future<void> _handleSave() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    if (currentPassword.isEmpty) {
      setState(() => _currentPasswordError = '请输入当前密码');
      hasError = true;
    } else {
      setState(() => _currentPasswordError = null);
    }

    if (!_validatePassword(newPassword)) {
      setState(() => _newPasswordError = '密码至少8位，包含字母和数字');
      hasError = true;
    } else {
      setState(() => _newPasswordError = null);
    }

    if (confirmPassword != newPassword) {
      setState(() => _confirmPasswordError = '两次输入的密码不一致');
      hasError = true;
    } else {
      setState(() => _confirmPasswordError = null);
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密码修改成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final message = result['message'] ?? '修改失败';
        if (message.contains('密码') || message.contains('错误')) {
          setState(() => _currentPasswordError = message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('网络错误，请稍后重试'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : LinkDropColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '安全设置',
          style: TextStyle(
            color: isDark ? Colors.white : LinkDropColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordField(
                  label: '当前密码',
                  controller: _currentPasswordController,
                  hint: '请输入当前密码',
                  obscure: _obscureCurrent,
                  error: _currentPasswordError,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  label: '新密码',
                  controller: _newPasswordController,
                  hint: '至少8位，包含字母和数字',
                  obscure: _obscureNew,
                  error: _newPasswordError,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: (_) => _validateNewPassword(),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  label: '确认新密码',
                  controller: _confirmPasswordController,
                  hint: '请再次输入新密码',
                  obscure: _obscureConfirm,
                  error: _confirmPasswordError,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  onChanged: (_) => _validateConfirmPassword(),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: LinkDropColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '修改密码',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required String? error,
    required VoidCallback onToggle,
    required bool isDark,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: LinkDropColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: LinkDropColors.textSecondary,
              ),
              onPressed: onToggle,
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : LinkDropColors.textPrimary,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
