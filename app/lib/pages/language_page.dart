import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// 语言选择页面
///
/// 提供应用语言切换功能
/// 支持跟随系统语言或手动选择特定语言
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  @override
  void initState() {
    super.initState();
    LocaleSettings.instance.loadAllLocales().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final activeLocale = context.ref.watch(settingsProvider.select((s) => s.locale));
    final settings = context.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGridView = settings.languageViewMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Expanded(
                  child: Text(
                    t.sendTab.selection.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : LinkDropColors.zinc900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await context.ref.notifier(settingsProvider).setLanguageViewMode(!isGridView);
                  },
                  icon: Icon(
                    isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  ),
                  tooltip: isGridView ? '列表视图' : '宫格视图',
                  color: LinkDropColors.zinc500,
                ),
              ],
            ),
          ),

          Expanded(
            child: isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2,
                    ),
                    itemCount: [null, ...AppLocale.values].length,
                    itemBuilder: (context, index) {
                      final locale = [null, ...AppLocale.values][index];
                      return _LanguageGridItem(
                        locale: locale,
                        isActive: locale == activeLocale,
                        isDark: isDark,
                        onTap: () async {
                          await context.ref.notifier(settingsProvider).setLocale(locale);
                          if (locale == null) {
                            await LocaleSettings.useDeviceLocale();
                          } else {
                            await LocaleSettings.setLocale(locale);
                          }
                        },
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    children: [
                      ...[
                        null,
                        ...AppLocale.values,
                      ].map((locale) {
                        return _LanguageItem(
                          locale: locale,
                          isActive: locale == activeLocale,
                          isDark: isDark,
                          onTap: () async {
                            await context.ref.notifier(settingsProvider).setLocale(locale);
                            if (locale == null) {
                              await LocaleSettings.useDeviceLocale();
                            } else {
                              await LocaleSettings.setLocale(locale);
                            }
                          },
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 语言宫格选项组件
///
/// 显示单个语言选项的宫格视图
class _LanguageGridItem extends StatelessWidget {
  final AppLocale? locale;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageGridItem({
    required this.locale,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? LinkDropColors.teal500 : (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  locale?.languageTag.toUpperCase() ?? 'AUTO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : LinkDropColors.zinc900,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 语言选项组件
///
/// 显示单个语言选项，包含语言名称和选中状态指示器
class _LanguageItem extends StatelessWidget {
  final AppLocale? locale;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.locale,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc50) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? LinkDropColors.teal500 : (isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : LinkDropColors.zinc900,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: LinkDropColors.teal500,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension AppLocaleExt on AppLocale {
  String get humanName {
    return LocaleSettings.instance.translationMap[this]?.locale ?? 'Loading';
  }
}
