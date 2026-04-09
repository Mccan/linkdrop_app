import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:provider/provider.dart' as provider;
import 'package:linkdrop_app/provider/auth_provider.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = provider.Provider.of<AuthProvider>(context, listen: false).user;

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
          '基本信息',
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
          _buildInfoCard(
            isDark: isDark,
            label: '用户名',
            value: user?.username ?? '--',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            isDark: isDark,
            label: '注册时间',
            value: user?.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(user!.createdAt) : '--',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Container(
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
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: LinkDropColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : LinkDropColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
