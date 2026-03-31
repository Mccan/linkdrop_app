import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/pages/language_page.dart' show AppLocaleExt;
import 'package:linkdrop_app/pages/tabs/settings_tab_controller.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/device_type_ext.dart';
import 'package:linkdrop_app/util/native/pick_directory_path.dart';
import 'package:linkdrop_app/util/native/platform_check.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// 通用设置页面
///
/// 包含语言、主题、保存目录、设备类型等设置
/// 采用现代分组卡片设计，清晰的视觉层次和流畅的交互体验
class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final vm = ref.watch(settingsTabControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc900 : LinkDropColors.zinc50,
      body: Column(
        children: [
          // 顶部导航栏
          _buildAppBar(context, isDark),

          // 设置内容
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // 通用设置组
                _buildSettingsGroup(
                  title: t.settingsTab.general.title,
                  icon: Icons.tune,
                  isDark: isDark,
                  children: [
                    // 语言设置
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.language_outlined,
                      title: t.settingsTab.general.language,
                      value: vm.settings.locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                      isDark: isDark,
                      onTap: () => vm.onTapLanguage(context),
                    ),
                    _buildDivider(isDark),
                    // 主题设置
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.brightness_6_outlined,
                      title: t.settingsTab.general.brightness,
                      isDark: isDark,
                      trailing: _buildThemeDropdown(vm, isDark, context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 接收设置组
                _buildSettingsGroup(
                  title: t.settingsTab.receive.title,
                  icon: Icons.download_outlined,
                  isDark: isDark,
                  children: [
                    if (checkPlatformWithFileSystem())
                      _buildSettingsItem(
                        context: context,
                        icon: Icons.folder_outlined,
                        title: t.settingsTab.receive.destination,
                        value: vm.settings.destination ?? t.settingsTab.receive.downloads,
                        isDark: isDark,
                        onTap: () async {
                          final directory = await pickDirectoryPath();
                          if (directory != null) {
                            await ref.notifier(settingsProvider).setDestination(directory);
                          }
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // 网络设置组
                _buildSettingsGroup(
                  title: t.settingsTab.network.title,
                  icon: Icons.wifi_outlined,
                  isDark: isDark,
                  children: [
                    _buildSettingsItem(
                      context: context,
                      icon: Icons.devices_outlined,
                      title: t.settingsTab.network.deviceType,
                      isDark: isDark,
                      trailing: _buildDeviceTypeDropdown(vm, isDark, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        16,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? LinkDropColors.zinc800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : LinkDropColors.zinc700,
              ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '通用、接收、网络设置',
                  style: TextStyle(
                    fontSize: 13,
                    color: LinkDropColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置组卡片
  Widget _buildSettingsGroup({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 组标题
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LinkDropColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: LinkDropColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
              ],
            ),
          ),
          // 设置项列表
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? value,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? LinkDropColors.zinc400 : LinkDropColors.zinc600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: LinkDropColors.zinc500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 22,
              color: LinkDropColors.zinc400,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }

  /// 构建分隔线
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
      ),
    );
  }

  /// 构建主题下拉选择器
  Widget _buildThemeDropdown(dynamic vm, bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: vm.settings.theme,
          dropdownColor: isDark ? LinkDropColors.zinc800 : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: LinkDropColors.zinc500,
          ),
          isDense: true,
          items: vm.themeModes.map<DropdownMenuItem<ThemeMode>>((theme) {
            return DropdownMenuItem<ThemeMode>(
              value: theme,
              child: Text(
                _getThemeModeName(theme),
                style: TextStyle(
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (theme) => vm.onChangeTheme(context, theme!),
        ),
      ),
    );
  }

  /// 构建设备类型下拉选择器
  Widget _buildDeviceTypeDropdown(dynamic vm, bool isDark, Ref ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DeviceType>(
          value: vm.deviceInfo.deviceType,
          dropdownColor: isDark ? LinkDropColors.zinc800 : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: LinkDropColors.zinc500,
          ),
          isDense: true,
          items: DeviceType.values.map<DropdownMenuItem<DeviceType>>((type) {
            return DropdownMenuItem<DeviceType>(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (type) async {
            if (type != null) {
              await ref.notifier(settingsProvider).setDeviceType(type);
            }
          },
        ),
      ),
    );
  }
}

/// 获取主题模式的显示名称
String _getThemeModeName(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟随系统';
    case ThemeMode.light:
      return '浅色';
    case ThemeMode.dark:
      return '深色';
  }
}
