import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/services/api_service.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:provider/provider.dart' as provider;
import 'package:linkdrop_app/provider/auth_provider.dart';

class RedeemCodePage extends StatefulWidget {
  const RedeemCodePage({super.key});

  @override
  State<RedeemCodePage> createState() => _RedeemCodePageState();
}

class _RedeemCodePageState extends State<RedeemCodePage> {
  final _codeController = TextEditingController();
  final _apiService = ApiService();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('请输入兑换码');
      return;
    }

    // 格式化检查：应该是 XXXX-XXXX-XXXX 格式
    if (!RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code) &&
        !RegExp(r'^[A-Z0-9]{12}$').hasMatch(code)) {
      _showError('兑换码格式不正确');
      return;
    }

    setState(() => _isRedeeming = true);

    try {
      final result = await _apiService.redeemCoupon(code);

      if (result.success) {
        final message = result.type == 'svip'
            ? 'SVIP 已激活'
            : '${result.projectName ?? "VIP"} 已激活';

        // 刷新用户信息
        await provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();

        if (mounted) {
          _showSuccess(message);
          _codeController.clear();
        }
      } else {
        if (mounted) {
          _showError(result.message ?? '兑换失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('兑换失败，请稍后重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
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
          '我的兑换码',
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
                Text(
                  '兑换码',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LinkDropColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: '请输入兑换码（如：XXXX-XXXX-XXXX）',
                    filled: true,
                    fillColor: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      Icons.card_giftcard,
                      color: LinkDropColors.primary,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                  ],
                  onSubmitted: (_) => _handleRedeem(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isRedeeming ? null : _handleRedeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: LinkDropColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isRedeeming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.card_giftcard, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '立即兑换',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? LinkDropColors.zinc800.withOpacity(0.5)
                  : LinkDropColors.zinc100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: LinkDropColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '兑换说明',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 输入兑换码即可激活会员权益\n'
                  '• 兑换码通常为 12 位字母或数字组成\n'
                  '• SVIP 兑换码可解锁全部应用会员功能\n'
                  '• VIP 兑换码仅可解锁当前应用会员功能\n'
                  '• 已使用的兑换码无法重复使用',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    color: LinkDropColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
