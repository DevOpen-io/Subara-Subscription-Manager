import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../config/router_config.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/menu_bar.dart';

final rootScaffoldKey = GlobalKey<ScaffoldState>();

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key, required this.child});

  final Widget
  child; // The widget (e.g., HomeScreen or TestScreen) that GoRouter will place here

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final currentPath = router.state.path;

    // Determine current tab index
    var selectedIndex = 0;
    if (currentPath == Routes.calendar.route) {
      selectedIndex = 1;
    } else if (currentPath == Routes.analytics.route) {
      selectedIndex = 2;
    } else if (currentPath == Routes.settings.route) {
      selectedIndex = 3;
    }

    return Scaffold(
      key: rootScaffoldKey,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const SidebarMenu(),
      body: child,
      bottomNavigationBar: GlassNavBar(
        selectedIndex: selectedIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(Routes.home.route);
            case 1:
              context.go(Routes.calendar.route);
            case 2:
              context.go(Routes.analytics.route);
            case 3:
              context.go(Routes.settings.route);
          }
        },
      ),
    );
  }
}
