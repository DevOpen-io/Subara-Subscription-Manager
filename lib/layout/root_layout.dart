import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/config/router_config.dart';
import 'package:subs_tracker/widgets/add_subs_dialog.dart';
import 'package:subs_tracker/widgets/menu_bar.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key, required this.child});

  final Widget
  child; // The widget (e.g., HomeScreen or TestScreen) that GoRouter will place here

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final currentPath = router.state.path;

    // Determine current tab index
    int selectedIndex = 0;
    if (currentPath == Routes.calendar.route) {
      selectedIndex = 1;
    } else if (currentPath == Routes.analytics.route) {
      selectedIndex = 2;
    } else if (currentPath == Routes.settings.route) {
      selectedIndex = 3;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
                  title: Text("settings.app_name".tr()),
                  actions: [
                    Visibility(
                      visible: currentPath == Routes.home.route,
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (ctx) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(ctx).viewInsets.bottom,
                            ),
                            child: const AddSubsSheet(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          drawer: const SidebarMenu(),
          body: child,
          bottomNavigationBar: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) {
                    switch (index) {
                      case 0:
                        context.go(Routes.home.route);
                        break;
                      case 1:
                        context.go(Routes.calendar.route);
                        break;
                      case 2:
                        context.go(Routes.analytics.route);
                        break;
                      case 3:
                        context.go(Routes.settings.route);
                        break;
                    }
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'menu.subscriptions'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month),
                      label: 'menu.calendar'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics),
                      label: 'menu.analytics'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'menu.settings'.tr(),
                    ),
                  ],
                ),
        );
  }
}
