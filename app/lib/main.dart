import 'package:common/isolate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:linkdrop_app/config/init.dart';
import 'package:linkdrop_app/config/init_error.dart';
import 'package:linkdrop_app/config/theme.dart';
import 'package:linkdrop_app/gen/strings.g.dart';
import 'package:linkdrop_app/model/persistence/color_mode.dart';
import 'package:linkdrop_app/pages/splash_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:linkdrop_app/provider/local_ip_provider.dart';
import 'package:linkdrop_app/provider/settings_provider.dart';
import 'package:linkdrop_app/theme/linkdrop_theme.dart';
import 'package:linkdrop_app/util/ui/dynamic_colors.dart';
import 'package:linkdrop_app/widget/watcher/life_cycle_watcher.dart';
import 'package:linkdrop_app/widget/watcher/auth_identity_watcher.dart';
import 'package:linkdrop_app/widget/watcher/shortcut_watcher.dart';
import 'package:linkdrop_app/widget/watcher/tray_watcher.dart';
import 'package:linkdrop_app/widget/watcher/window_watcher.dart';
import 'package:provider/provider.dart' as provider;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

Future<void> main(List<String> args) async {
  final RefenaContainer container;
  try {
    container = await preInit(args);
  } catch (e, stackTrace) {
    showInitErrorApp(
      error: e,
      stackTrace: stackTrace,
    );
    return;
  }

  runApp(
    RefenaScope.withContainer(
      container: container,
      child: TranslationProvider(
        child: provider.ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
          child: const LinkDropApp(),
        ),
      ),
    ),
  );
}

class LinkDropApp extends StatelessWidget {
  const LinkDropApp();

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final (themeMode, colorMode) = ref.watch(settingsProvider.select((settings) => (settings.theme, settings.colorMode)));
    final dynamicColors = ref.watch(dynamicColorsProvider);
    return TrayWatcher(
      child: WindowWatcher(
        child: LifeCycleWatcher(
          onChangedState: (AppLifecycleState state) {
            switch (state) {
              case AppLifecycleState.resumed:
                ref.redux(localIpProvider).dispatch(InitLocalIpAction());
                break;
              case AppLifecycleState.detached:
                // The main isolate is only exited when all child isolates are exited.
                // https://github.com/localsend/localsend/issues/1568
                ref.redux(parentIsolateProvider).dispatch(IsolateDisposeAction());
                break;
              default:
                break;
            }
          },
            child: AuthIdentityWatcher(
              child: ShortcutWatcher(
                child: MaterialApp(
                  title: t.appName,
                  locale: TranslationProvider.of(context).flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  debugShowCheckedModeBanner: false,
                  theme: getLinkDropTheme(Brightness.light),
                  darkTheme: getLinkDropTheme(Brightness.dark),
                  themeMode: colorMode == ColorMode.oled ? ThemeMode.dark : themeMode,
                  navigatorKey: Routerino.navigatorKey,
                  home: RouterinoHome(
                    builder: () => const SplashPage(),
                  ),
                ),
            ),
          ),
        ),
      ),
    );
  }
}
