import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../services/live_activity_service.dart';
import '../utils/update_service.dart';

class AppStartup extends ConsumerStatefulWidget {
  const AppStartup({super.key , required this.child});

  final Widget child;

  @override
  ConsumerState<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<AppStartup> {
  bool _liveActivityStarted = false;

  @override
  void initState() {
    super.initState();
    unawaited(UpdateService.instance.checkAndUpdate());
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    return settingsAsync.when(
      data: (settings) {
        if (!_liveActivityStarted) {
          _liveActivityStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final subsAsync = ref.read(subsControllerProvider);
            subsAsync.whenData((subs) {
              unawaited(LiveActivityService.instance.startIfDueToday(
                subs,
                settings.currency.symbol,
              ));
            });
          });
        }
        return widget.child;
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('common.error_generic'.tr()),
      ),
    );
  }
}
