import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkdrop_app/pages/about_page.dart';
import 'package:linkdrop_app/pages/general_settings_page.dart';
import 'package:linkdrop_app/pages/login_page.dart';
import 'package:linkdrop_app/pages/payment_page.dart';
import 'package:linkdrop_app/pages/why_not_wechat_page.dart';
import 'package:linkdrop_app/pages/widget/settings_item.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:provider/provider.dart' as provider;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = provider.Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '管理您的账户和会员信息',
                      style: TextStyle(
                        color: LinkDropColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                _buildAccountHeader(context, isDark, isAuthenticated, user),
                const SizedBox(height: 24),
                if (isAuthenticated && user != null) ...[
                  _buildMembershipCard(context, isDark, user),
                  const SizedBox(height: 24),
                ],
                if (isAuthenticated && user != null) ...[
                  _buildWhyNotWechatEntry(context, isDark),
                  const SizedBox(height: 16),
                  _buildSettingsEntry(context, isDark),
                  const SizedBox(height: 16),
                  _buildAboutEntry(context, isDark),
                  const SizedBox(height: 16),
                  _buildAccountActions(context, isDark, user),
                ] else ...[
                  _buildLoginPrompt(context, isDark),
                  const SizedBox(height: 24),
                  _buildAboutEntry(context, isDark),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsEntry(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GeneralSettingsPage(),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LinkDropColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings,
                color: LinkDropColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '通用、接收、网络设置',
                    style: TextStyle(
                      fontSize: 13,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: LinkDropColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyNotWechatEntry(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WhyNotWechatPage(),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.compare_arrows,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '为什么不选微信',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '对比微信/QQ，LinkDrop 的核心优势',
                    style: TextStyle(
                      fontSize: 13,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: LinkDropColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeader(BuildContext context, bool isDark, bool isAuthenticated, user) {
    if (isAuthenticated && user != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [LinkDropColors.zinc800, LinkDropColors.zinc900] : [Colors.white, const Color(0xFFF5F5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [LinkDropColors.primary, LinkDropColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LinkDrop 用户',
                    style: TextStyle(
                      fontSize: 14,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.membership?.hasSvip == true
                    ? LinkDropColors.primary
                    : user.membership?.hasVip == true
                    ? LinkDropColors.primary.withOpacity(0.8)
                    : LinkDropColors.zinc300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.membership?.hasSvip == true
                    ? 'SVIP'
                    : user.membership?.hasVip == true
                    ? 'VIP'
                    : '普通',
                style: TextStyle(
                  color: user.membership?.hasSvip == true || user.membership?.hasVip == true ? Colors.white : LinkDropColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: LinkDropColors.zinc200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person_outline,
                size: 32,
                color: LinkDropColors.zinc500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '登录后享受更多功能',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildMembershipCard(BuildContext context, bool isDark, user) {
    final isVipActive = user.isVipActive;
    final hasSvip = user.membership?.hasSvip == true;
    final hasVip = user.membership?.hasVip == true;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentPage(),
            fullscreenDialog: true,
          ),
        );
        await provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasSvip
                ? [LinkDropColors.primary, LinkDropColors.primaryDark]
                : hasVip
                ? [LinkDropColors.primary.withOpacity(0.8), LinkDropColors.primary]
                : [LinkDropColors.zinc400, LinkDropColors.zinc500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (hasSvip || hasVip ? LinkDropColors.primary : Colors.grey).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasSvip ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSvip
                        ? 'SVIP 大会员'
                        : hasVip
                        ? 'VIP 会员'
                        : '开通会员',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVipActive ? (user.vipRemainingDays == -1 ? '永久会员' : '剩余 ${user.vipRemainingDays} 天') : '享受更多特权',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isVipActive ? '续费' : '开通',
                style: TextStyle(
                  color: hasSvip || hasVip ? LinkDropColors.primary : LinkDropColors.zinc600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, bool isDark, user) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
      ),
      child: Column(
        children: [
          if (user.inviteCode != null)
            SettingsItem(
              icon: Icons.card_giftcard,
              title: '我的邀请码',
              value: user.inviteCode,
              isDark: isDark,
              trailing: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('邀请码已复制')),
                  );
                },
                child: Icon(Icons.copy, size: 20, color: LinkDropColors.primary),
              ),
            ),
          SettingsItem(
            icon: Icons.logout,
            title: '退出登录',
            isDark: isDark,
            iconColor: Colors.red[400],
            titleColor: Colors.red[400],
            onTap: () async {
              final confirm = await showDialog<bool>(
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
                      child: Text(
                        '退出',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.Provider.of<AuthProvider>(context, listen: false).logout();
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
      ),
      child: SettingsItem(
        icon: Icons.login,
        title: '登录 / 注册',
        value: '登录后享受更多功能',
        isDark: isDark,
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
              fullscreenDialog: true,
            ),
          );
          if (result == true) {
            setState(() {});
            final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
            await authProvider.refreshUser();
            if (!authProvider.user!.isVipActive) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PaymentPage(),
                  fullscreenDialog: true,
                ),
              );
              await authProvider.refreshUser();
            }
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildAboutEntry(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AboutPage(),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LinkDropColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: LinkDropColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关于我们',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : LinkDropColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '功能介绍、帮助中心、服务条款等',
                    style: TextStyle(
                      fontSize: 13,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: LinkDropColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => _InfoDialog(title: title, content: content),
    );
  }

  static const String _featuresContent = '''
跨平台传输
支持 Windows、Mac、Linux、Android、iOS 全平台设备之间的文件互传。

局域网直连
利用局域网优势，设备之间直接发现和传输，不依赖互联网。

安全加密
采用端到端加密技术，确保传输过程中的数据安全。

高速传输
充分利用局域网带宽，传输速度取决于您的网络环境。

批量传输
支持同时传输多个文件和整个文件夹。

热点配对
开启热点即可快速发现并配对设备。

离线传输
在无网络环境下也能正常使用。

无需安装
Windows 和 Linux 支持便携模式，无需安装即可使用。
''';

  static const String _helpContent = '''
常见问题

Q: LinkDrop 支持哪些平台？
A: LinkDrop 支持 Windows、macOS、Linux、Android 和 iOS 全平台设备之间的文件互传。

Q: 传输需要联网吗？
A: 不需要。LinkDrop 使用局域网直连技术，只需设备连接到同一 WiFi 网络即可发现并传输文件。

Q: 传输速度如何？
A: 传输速度取决于您的局域网带宽。在千兆局域网环境下，传输速度可以达到每秒上百兆。

Q: 文件大小有限制吗？
A: 没有限制。无论是大文件还是小文件，都可以自由传输。

Q: 如何确保传输安全？
A: LinkDrop 采用端到端加密技术，文件只在两台设备之间传输，不经过任何服务器。

Q: 手机和电脑不在同一网络怎么办？
A: 可以开启 LinkDrop 的热点模式，通过手机热点让电脑连接，实现跨网络传输。
''';

  static const String _termsContent = '''
服务条款

一、服务协议的接受
欢迎您使用 LinkDrop 服务。在使用 LinkDrop 服务前，请您仔细阅读并理解本服务协议的全部内容。

二、服务内容
LinkDrop 是一款跨平台文件传输工具，为用户提供便捷、安全的文件传输服务。我们保留随时变更、中断或终止部分或全部服务的权利。

三、用户账号
1. 您需要注册账号才能使用部分功能。
2. 您应妥善保管账号和密码，因账号密码泄露造成的损失由您自行承担。
3. 您不得将账号转让、出借给他人使用。

四、用户行为规范
使用 LinkDrop 服务时，您承诺遵守以下规定：
- 遵守中华人民共和国相关法律法规
- 不得传输违法、有害、侵权的内容
- 不得利用服务从事任何违法或不当活动

五、会员服务
1. 会员服务为付费增值服务，具体权益以购买页面展示为准。
2. 会员服务一经购买，除法定情形外，不予退款。
3. 会员有效期满后，如未续费，将自动恢复为普通用户权限。

六、知识产权
LinkDrop 服务的所有内容，其知识产权归 LinkDrop 所有。未经书面授权，任何人不得复制、修改、发布、出售或以其他方式使用上述内容。
''';

  static const String _privacyContent = '''
隐私政策

一、引言
LinkDrop 深知个人信息对您的重要性，我们将按照法律法规要求，采取相应安全保护措施，尽力保护您的个人信息安全可控。

二、我们收集的信息
为了向您提供服务，我们可能收集以下信息：

账号信息：用户名、密码（加密存储）

设备信息：设备型号、操作系统版本、唯一设备标识符

使用信息：服务使用记录、会员订阅记录

三、信息的使用
我们收集的信息将用于：
- 提供、维护和改进我们的服务
- 账号认证和安全管理
- 处理您的会员订阅和支付
- 遵守法律法规的要求

四、信息的安全
我们采用业界标准的安全措施保护您的个人信息，包括但不限于数据加密、访问控制、安全审计等。文件传输采用端到端加密，我们不存储您传输的文件内容。

五、联系我们
如果您对我们的隐私政策有任何疑问，请通过联系方式与我们联系。
''';

  static const String _contactContent = '''
联系我们

如果您在使用过程中遇到任何问题，或者有任何建议和反馈，欢迎通过以下方式联系我们：

邮箱：support@linkdrop.example.com

我们会尽快回复您的留言，感谢您的支持！

工作时间：周一至周五 9:00-18:00（节假日除外）
''';
}

class _InfoDialog extends StatelessWidget {
  final String title;
  final String content;

  const _InfoDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.white70 : LinkDropColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
