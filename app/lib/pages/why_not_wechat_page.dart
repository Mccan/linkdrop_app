import 'package:flutter/material.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';

class WhyNotWechatPage extends StatelessWidget {
  const WhyNotWechatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc900 : const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 380 ? 16 : 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroSection(isDark),
                    const SizedBox(height: 28),
                    _buildPainPointsSection(context, isDark),
                    const SizedBox(height: 32),
                    _buildAdvantagesSection(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '传输方式对比',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '微信 / QQ 传文件有哪些问题？',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LinkDropColors.zinc900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '看似方便的传统方式，其实有四大痛点。LinkDrop 帮你一一解决。',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: LinkDropColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainPointsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '核心痛点',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : LinkDropColors.zinc900,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_painPoints.length, (index) {
          final pain = _painPoints[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PainCard(
              pain: pain,
              isDark: isDark,
              index: index + 1,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdvantagesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LinkDrop 核心优势',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : LinkDropColors.zinc900,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? LinkDropColors.zinc800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(_advantages.length, (index) {
              final adv = _advantages[index];
              final isLast = index == _advantages.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: LinkDropColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAdvIcon(adv['icon']),
                            size: 18,
                            color: LinkDropColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            adv['text'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : LinkDropColors.zinc800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  IconData _getAdvIcon(String iconName) {
    switch (iconName) {
      case 'lightning':
        return Icons.flash_on;
      case 'folder':
        return Icons.folder_outlined;
      case 'infinity':
        return Icons.all_inclusive;
      case 'airplane':
        return Icons.airplanemode_active;
      case 'shield':
        return Icons.shield_outlined;
      case 'devices':
        return Icons.devices;
      default:
        return Icons.check;
    }
  }
}

class _PainCard extends StatelessWidget {
  final Map<String, dynamic> pain;
  final bool isDark;
  final int index;

  const _PainCard({
    required this.pain,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? LinkDropColors.zinc300 : LinkDropColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pain['title'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : LinkDropColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildHighlightBox(
                        '问题',
                        pain['problem'],
                        isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFF0F0),
                        isDark ? const Color(0xFFFCA5A5) : Colors.red[600]!,
                        Icons.close,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildHighlightBox(
                        'LinkDrop 解决',
                        pain['solution'],
                        isDark ? const Color(0xFF1F3D2F) : const Color(0xFFF0FFF4),
                        isDark ? const Color(0xFF86EFAC) : Colors.green[600]!,
                        Icons.check,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBox(String label, String text, Color bgColor, Color accentColor, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> _painPoints = [
  {
    'title': '速度堪忧',
    'problem': '微信/QQ 传输需要先上传至服务器，接收方再从服务器下载。两段传输耗时加倍。',
    'solution': 'LinkDrop 采用局域网直连，设备间直接传输，无中转服务器，带宽利用率最大化。',
  },
  {
    'title': '双份存储',
    'problem': '通过微信传输的文件，会在手机相册留下一份，微信缓存又存一份，重复占用空间。',
    'solution': 'LinkDrop 支持直接保存到指定目录，不产生额外缓存副本，文件管理更清晰。',
  },
  {
    'title': '大小受限',
    'problem': '微信传输单个文件上限约 200MB，QQ 也有限制，想传大视频只能压缩。',
    'solution': 'LinkDrop 对文件大小完全无限制，几 GB 的视频、整个文件夹，都能一键传输。',
  },
  {
    'title': '断网即失',
    'problem': '在地铁、电梯等无网络环境时，微信无法发送也无法接收文件。',
    'solution': '开个热点即可传输，不依赖外部网络，离线环境照样正常使用。',
  },
];

final List<Map<String, dynamic>> _advantages = [
  {'icon': 'lightning', 'text': '局域网高速传输，可达数十 MB/s'},
  {'icon': 'folder', 'text': '文件直达目标目录，无额外缓存'},
  {'icon': 'infinity', 'text': '文件大小完全无限制'},
  {'icon': 'airplane', 'text': '无网络环境照样使用'},
  {'icon': 'shield', 'text': '端到端加密，隐私安全'},
  {'icon': 'devices', 'text': '全平台支持，互传无障碍'},
];
