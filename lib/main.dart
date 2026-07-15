import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'config/router_config.dart';
import 'providers/settings_controller.dart';
import 'providers/theme_provider.dart';
import 'utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await LocalNotificationService.instance.init();
  await HomeWidget.setAppGroupId('group.io.devopen.subzilla');

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('tr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(
          settingsControllerProvider.select((value) => value.value?.theme),
        ) ??
        ThemeMode.system;
    //TODO: Merge light and dark theme providers into a single provider that returns both themes as a tuple or a class
    final light = ref.watch(lightThemeProvider);
    final dark = ref.watch(darkThemeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'SubZilla',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
    );
  }
}
