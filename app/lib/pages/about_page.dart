import 'package:flutter/material.dart';
import 'package:linkdrop_app/pages/about_content_page.dart';
import 'package:linkdrop_app/pages/contact_page.dart';
import 'package:linkdrop_app/pages/widget/settings_item.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc900 : Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '关于我们',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '功能介绍、帮助中心、服务条款等',
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
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    ),
                  ),
                  child: Column(
                    children: [
                      SettingsItem(
                        icon: Icons.star_outline,
                        title: '功能介绍',
                        isDark: isDark,
                        onTap: () => _navigateToContent(context, '功能介绍', _featuresContent),
                      ),
                      _buildDivider(isDark),
                      SettingsItem(
                        icon: Icons.help_outline,
                        title: '帮助中心',
                        isDark: isDark,
                        onTap: () => _navigateToContent(context, '帮助中心', _helpContent),
                      ),
                      _buildDivider(isDark),
                      SettingsItem(
                        icon: Icons.description_outlined,
                        title: '服务条款',
                        isDark: isDark,
                        onTap: () => _navigateToContent(context, '服务条款', _termsContent),
                      ),
                      _buildDivider(isDark),
                      SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: '隐私政策',
                        isDark: isDark,
                        onTap: () => _navigateToContent(context, '隐私政策', _privacyContent),
                      ),
                      _buildDivider(isDark),
                      SettingsItem(
                        icon: Icons.mail_outline,
                        title: '联系我们',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ContactPage(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
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

  void _navigateToContent(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AboutContentPage(title: title, content: content),
        fullscreenDialog: true,
      ),
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
