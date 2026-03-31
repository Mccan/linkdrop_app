import 'package:flutter/material.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/util/native/platform_check.dart';

/// LinkDrop 颜色定义
///
/// 主色调: 青绿科技风 - 与 Logo 品牌色统一
/// 主色: 青绿色 #2DD4BF (活力、清新、高效)
/// 辅助色: 紫罗兰 #8B5CF6 (创新、科技、可信赖)
class LinkDropColors {
  // ===== 主色调 - 青绿色系 =====
  static const primary = Color(0xFF2DD4BF); // 青绿主色
  static const primaryDark = Color(0xFF14B8A6); // 青绿深 (悬停)
  static const primaryLight = Color(0xFFFDFBF8); // 浅米色 (选中背景)
  static const primaryBorder = Color(0xFFE8DFD3); // 米色边框
  static const primaryText = Color(0xFF0F766E); // 青绿文字

  // ===== 辅助色 - 紫罗兰色系 =====
  static const accent = Color(0xFF8B5CF6); // 紫罗兰辅助色
  static const accentDark = Color(0xFF7C3AED); // 紫色深
  static const accentLight = Color(0xFFF5F3FF); // 紫色浅

  // ===== 背景色 =====
  static const white = Color(0xFFFFFFFF);
  static const backgroundLight = Color(0xFFFAFAFA); // 浅灰白
  static const backgroundDark = Color(0xFF0A1A18); // 深青黑
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF162524); // 深青灰

  // ===== 文字色 =====
  static const textPrimary = Color(0xFF1A2E2C); // 深青黑
  static const textSecondary = Color(0xFF6B7280); // 中灰
  static const textTertiary = Color(0xFF9CA3AF); // 浅灰
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFA1A1AA);

  // ===== 边框色 =====
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF2A3B3E); // 深青边框

  // ===== Zinc 色系 (中性色) =====
  static const zinc50 = Color(0xFFFAFAFA);
  static const zinc100 = Color(0xFFF4F4F5);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc500 = Color(0xFF71717A); // Secondary text
  static const zinc600 = Color(0xFF52525B);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  static const zinc900 = Color(0xFF18181B);
  static const zinc950 = Color(0xFF09090B);

  // ===== 功能色 =====
  static const success = Color(0xFF10B981); //  emerald-500
  static const error = Color(0xFFEF4444); //  red-500
  static const warning = Color(0xFFF59E0B); //  amber-500
  static const info = Color(0xFF3B82F6); //  blue-500

  // ===== 阴影色 =====
  static const shadowLight = Color(0x14000000); // 8% 黑色
  static const shadowPrimary = Color(0x262DD4BF); // 15% 青绿

  // ===== 兼容旧代码的颜色别名 =====
  static const teal500 = primary; // 青绿作为 teal
  static const teal600 = primaryDark;
  static const red500 = error;
  static const orange500 = warning;

  // ===== 渐变 =====
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF5EEAD4)], // 青绿到浅青绿
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary], // 紫到青绿
  );

  static const primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, Color(0xFFCCFBF1)],
  );
}

/// 获取 LinkDrop 主题
ThemeData getLinkDropTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Define ColorScheme
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: LinkDropColors.primary,
    onPrimary: Colors.white,
    secondary: LinkDropColors.accent,
    onSecondary: Colors.white,
    error: LinkDropColors.error,
    onError: Colors.white,
    surface: isDark ? LinkDropColors.cardDark : LinkDropColors.cardLight,
    onSurface: isDark ? LinkDropColors.textPrimaryDark : LinkDropColors.textPrimary,
    surfaceContainer: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
  );

  // Font Family Logic
  final String? fontFamily;
  if (checkPlatform([TargetPlatform.windows])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Yu Gothic UI',
      AppLocale.ko => 'Malgun Gothic',
      AppLocale.zhCn => 'Microsoft YaHei UI',
      AppLocale.zhHk || AppLocale.zhTw => 'Microsoft JhengHei UI',
      _ => 'Segoe UI Variable Display',
    };
  } else if (checkPlatform([TargetPlatform.linux])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Noto Sans CJK JP',
      AppLocale.ko => 'Noto Sans CJK KR',
      AppLocale.zhCn => 'Noto Sans CJK SC',
      AppLocale.zhHk || AppLocale.zhTw => 'Noto Sans CJK TC',
      _ => 'Noto Sans',
    };
  } else {
    fontFamily = null;
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
    fontFamily: fontFamily,

    // Card Theme - 统一卡片样式
    cardTheme: CardThemeData(
      color: isDark ? LinkDropColors.cardDark : LinkDropColors.cardLight,
      elevation: 0,
      shadowColor: LinkDropColors.shadowPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
          width: 1,
        ),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
      foregroundColor: isDark ? LinkDropColors.textPrimaryDark : LinkDropColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    // Navigation Bar Theme - 青绿选中色
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.cardLight,
      indicatorColor: isDark ? LinkDropColors.primary.withValues(alpha: 0.15) : LinkDropColors.primaryLight,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: isDark ? Colors.white : LinkDropColors.primaryDark);
        }
        return IconThemeData(color: LinkDropColors.zinc500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: isDark ? Colors.white : LinkDropColors.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return const TextStyle(
          color: LinkDropColors.zinc500,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
      thickness: 1,
    ),

    // Switch Theme - 青绿激活色
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return LinkDropColors.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return LinkDropColors.primary.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),

    // Elevated Button Theme - 青绿渐变
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LinkDropColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LinkDropColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: LinkDropColors.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
  );
}

/// ThemeData 扩展 - 导出供其他模块使用
extension ThemeDataExt on ThemeData {
  /// This is the actual [cardColor] being used.
  Color get cardColorWithElevation {
    return ElevationOverlay.applySurfaceTint(cardColor, colorScheme.surfaceTint, 1);
  }
}

/// ColorScheme 扩展 - 导出供其他模块使用
extension ColorSchemeExt on ColorScheme {
  Color get warning {
    return Colors.orange;
  }

  Color? get secondaryContainerIfDark {
    return brightness == Brightness.dark ? secondaryContainer : null;
  }

  Color? get onSecondaryContainerIfDark {
    return brightness == Brightness.dark ? onSecondaryContainer : null;
  }
}
