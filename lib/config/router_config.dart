import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../layout/root_layout.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../screens/analytics_screen.dart';
import '../screens/app_startup.dart';
import '../screens/calendar_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sub_detail_screen.dart';

part 'router_config.g.dart';

enum Routes {
  home,
  analytics,
  intro,
  settings,
  calendar,
  subscription;

  String get name => toString().replaceAll('Routes.', '');
  String get route => '/$name';
}

@riverpod
GoRouter goRouter(Ref ref) {
  // final settingsAsync = ref.watch(settingsControllerProvider);

  return GoRouter(
    initialLocation: Routes.home.route,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          if (state.uri.toString() == Routes.intro.route) {
            return child;
          }
          return RootLayout(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.home.route,
            builder: (context, state) {
              return const AppStartup(child: HomeScreen());
            },
            redirect: (context, state) async {
              final settingsAsync = await ref.read(
                settingsControllerProvider.future,
              );
              if (settingsAsync.isFirstTime ?? false) {
                return Routes.intro.route;
              }
              return null;
            },
          ),
          GoRoute(
            path: Routes.intro.route,
            builder: (context, state) {
              return const OnboardingScreen();
            },
          ),
          GoRoute(
            path: Routes.calendar.route,
            builder: (context, state) {
              return const CalendarScreen();
            },
          ),
          GoRoute(
            path: Routes.analytics.route,
            builder: (context, state) {
              return const AnalyticsScreen();
            },
          ),
          GoRoute(
            path: Routes.settings.route,
            builder: (context, state) =>
                const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.subscription.route,
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return SubDetailScreen(
            slice: extra['slice'] as SubSlice,
            index: extra['index'] as int,
          );
        },
      ),
    ],
  );
}
