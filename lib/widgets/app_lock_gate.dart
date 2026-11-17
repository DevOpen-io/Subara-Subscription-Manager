import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/app_lock.dart';
import '../providers/settings_controller.dart';

/// Covers the app with a lock screen while [appLockProvider] is locked, and
/// tracks backgrounding so the app relocks after [appLockGracePeriod].
class AppLockGate extends HookConsumerWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.value?.appLock ?? false),
    );
    final settingsLoaded = ref.watch(
      settingsControllerProvider.select((s) => s.hasValue),
    );
    final locked = ref.watch(appLockProvider);
    final lock = ref.read(appLockProvider.notifier);
    final reason = 'lock.reason'.tr();

    // Lock once at start, when settings are known.
    useEffect(() {
      if (!settingsLoaded) return null;
      // Effects run during build; providers can't change until it's done.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await lock.start(enabled: enabled);
        if (ref.read(appLockProvider)) await lock.unlock(reason: reason);
      });
      return null;
    }, [settingsLoaded]);

    useOnAppLifecycleStateChange((_, state) {
      final now = DateTime.now();
      if (state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused) {
        lock.onBackground(now);
      } else if (state == AppLifecycleState.resumed) {
        lock.onForeground(now, enabled: enabled).then((lockedNow) {
          if (lockedNow) lock.unlock(reason: reason);
        });
      }
    });

    return Stack(
      children: [
        // Hidden from screen readers and taps while locked.
        ExcludeSemantics(
          excluding: locked,
          child: IgnorePointer(ignoring: locked, child: child),
        ),
        if (locked) _LockScreen(onUnlock: () => lock.unlock(reason: reason)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/App_Logo.png', width: 72, height: 72),
                  const SizedBox(height: 20),
                  Text(
                    'lock.title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onUnlock,
                    icon: const Icon(Icons.lock_open),
                    label: Text('lock.unlock'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
