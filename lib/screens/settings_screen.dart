import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../providers/app_lock.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../services/live_activity_service.dart';
import '../utils/app_theme.dart';
import '../utils/notification_service.dart';
import '../widgets/color_scheme_picker.dart';
import '../widgets/exchange_rate_dialog.dart';
import '../widgets/sub_zilla_app_bar.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: const SubaraAppBar(),
      body: settingsAsync.when(
        data: (settings) => _buildSettings(context, settings, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    SettingsViewModel settings,
    WidgetRef ref,
  ) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'settings.title',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).tr(),
          const SizedBox(height: 24),
          // Theme Section
          _SettingsSection(
            title: 'settings.appearance'.tr(),
            children: [
              _SettingsTile(
                title: 'settings.theme'.tr(),
                subtitle: _getThemeLabel(settings.theme).tr(),
                onTap: () => _showThemeBottomSheet(context, settings, ref),
              ),
              _SettingsTile(
                title: 'settings.color_scheme'.tr(),
                subtitle: schemeDisplayName(settings.colorScheme),
                onTap: () =>
                    _showColorSchemeBottomSheet(context, settings, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Currency Section
          _SettingsSection(
            title: 'settings.currency'.tr(),
            children: [
              _SettingsTile(
                title: 'settings.currency_unit'.tr(),
                subtitle:
                    '${settings.currency.label} (${settings.currency.symbol})',
                onTap: () => _showCurrencyBottomSheet(context, settings, ref),
              ),
              _SettingsTile(
                title: 'settings.exchange_rates'.tr(),
                subtitle: settings.rateCount == 0
                    ? 'settings.exchange_rates_none'.tr()
                    : 'settings.exchange_rates_count'.plural(
                        settings.rateCount,
                      ),
                onTap: () => _showExchangeRatesSheet(context),
              ),
              _SettingsTile(
                title: 'settings.budget'.tr(),
                subtitle: settings.monthlyBudget == null
                    ? 'settings.budget_none'.tr()
                    : '${settings.currency.symbol}${formatRate(settings.monthlyBudget!)}',
                onTap: () => _editBudget(context, settings, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Language Section
          _SettingsSection(
            title: 'settings.language'.tr(),
            children: [
              _SettingsTile(
                title: 'settings.language'.tr(),
                subtitle: context.locale.languageCode == 'en'
                    ? 'English'
                    : 'Türkçe',
                onTap: () => _showLanguageBottomSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'settings.security'.tr(),
            children: [_AppLockTile(enabled: settings.appLock)],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'settings.notifications_title'.tr(),
            children: [
              _SettingsTile(
                title: 'settings.reminder_time'.tr(),
                subtitle: _reminderTime(settings).format(context),
                onTap: () => _pickReminderTime(context, settings, ref),
              ),
              const _ExactRemindersTile(),
            ],
          ),
          const SizedBox(height: 24),
          // About Section
          _SettingsSection(
            title: 'settings.about'.tr(),
            children: [
              const _VersionTile(),
              _SettingsTile(
                title: 'settings.app_name'.tr(),
                subtitle: 'Subara',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (kDebugMode)
            _SettingsSection(
              title: 'Developer',
              children: [
                _ResetOnboardingTile(ref: ref),
                _TestLiveActivityTile(),
              ],
            ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'settings.light';
      case ThemeMode.dark:
        return 'settings.dark';
      case ThemeMode.system:
        return 'settings.system';
    }
  }

  void _showThemeBottomSheet(
    BuildContext context,
    SettingsViewModel settings,
    WidgetRef ref,
  ) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'settings.select_theme'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...[ThemeMode.light, ThemeMode.dark, ThemeMode.system].map(
                (mode) => _ThemeOption(
                  label: _getThemeLabel(mode).tr(),
                  isSelected: settings.theme == mode,
                  onTap: () {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateTheme(mode);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showColorSchemeBottomSheet(
    BuildContext context,
    SettingsViewModel settings,
    WidgetRef ref,
  ) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'settings.select_color_scheme'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ColorSchemePicker(
                selectedScheme: settings.colorScheme,
                onSchemeSelected: (scheme) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateColorScheme(scheme);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyBottomSheet(
    BuildContext context,
    SettingsViewModel settings,
    WidgetRef ref,
  ) {
    final outerContext = context;
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'settings.select_currency'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: ListView.builder(
                    itemCount: Currency.values.length,
                    itemBuilder: (_, i) {
                      final currency = Currency.values[i];
                      return _CurrencyOption(
                        label: currency.label,
                        symbol: currency.symbol,
                        isSelected: settings.currency == currency,
                        onTap: () {
                          Navigator.pop(context);
                          _changeMainCurrency(
                            outerContext,
                            ref,
                            settings,
                            currency,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLanguageBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'settings.select_language'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              LanguageOption(
                label: 'English',
                isSelected: context.locale.languageCode == 'en',
                onTap: () => _changeLanguage(context, const Locale('en')),
              ),
              LanguageOption(
                label: 'Türkçe',
                isSelected: context.locale.languageCode == 'tr',
                onTap: () => _changeLanguage(context, const Locale('tr')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// Rates are stored relative to the main currency, so switching to a
/// currency without a rate would drop them all. Ask for that one rate first
/// (in the old main currency) so the others can be converted; cancelling
/// keeps the current main currency and rates.
Future<void> _changeMainCurrency(
  BuildContext context,
  WidgetRef ref,
  SettingsViewModel settings,
  Currency next,
) async {
  final notifier = ref.read(settingsControllerProvider.notifier);
  if (next != settings.currency &&
      settings.rateCount > 0 &&
      !settings.hasRate(next)) {
    final edit = await showExchangeRateDialog(
      context,
      from: next,
      main: settings.currency,
    );
    if (edit is! RateSet) return;
    notifier.setExchangeRate(next, edit.rate);
  }
  notifier.updateCurrency(next);
}

void _showExchangeRatesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _ExchangeRatesSheet(),
  );
}

/// Every non-main currency with its user-entered rate; tap to edit.
class _ExchangeRatesSheet extends ConsumerWidget {
  const _ExchangeRatesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final others = Currency.values
        .where((c) => c != settings.currency)
        .toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'settings.exchange_rates'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'settings.exchange_rates_hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                itemCount: others.length,
                itemBuilder: (context, i) => _ExchangeRateTile(
                  currency: others[i],
                  main: settings.currency,
                  rate: settings.rateFor(others[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeRateTile extends ConsumerWidget {
  const _ExchangeRateTile({
    required this.currency,
    required this.main,
    required this.rate,
  });

  final Currency currency;
  final Currency main;
  final double? rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text('rates.equals'.tr(args: [currency.code])),
      subtitle: Text(currency.label),
      trailing: Text(
        rate == null ? '—' : '${formatRate(rate!)} ${main.symbol}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: rate == null
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () async {
        final edit = await showExchangeRateDialog(
          context,
          from: currency,
          main: main,
          current: rate,
        );
        final notifier = ref.read(settingsControllerProvider.notifier);
        switch (edit) {
          case RateSet(:final rate):
            notifier.setExchangeRate(currency, rate);
          case RateRemoved():
            notifier.setExchangeRate(currency, null);
          case null:
            break;
        }
      },
    );
  }
}

/// Turning the lock on or off asks for authentication first, so someone
/// holding an unlocked phone can't quietly remove it.
class _AppLockTile extends ConsumerWidget {
  const _AppLockTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same look as _SettingsTile.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: SwitchListTile(
          title: Text('settings.app_lock'.tr()),
          subtitle: Text('settings.app_lock_desc'.tr()),
          value: enabled,
          onChanged: (on) async {
            final messenger = ScaffoldMessenger.of(context);
            final lock = ref.read(appLockProvider.notifier);
            final auth = ref.read(deviceAuthProvider);
            if (!await auth.isSupported()) {
              messenger.showSnackBar(
                SnackBar(content: Text('settings.app_lock_unsupported'.tr())),
              );
              return;
            }
            if (!await lock.confirm(reason: 'lock.reason'.tr())) return;
            ref
                .read(settingsControllerProvider.notifier)
                .setAppLock(enabled: on);
          },
        ),
      ),
    );
  }
}

/// Android only: lets reminders fire at the chosen minute instead of when
/// the OS batches them (up to about an hour late). The switch opens the
/// system screen; the state is re-read when the app comes back.
class _ExactRemindersTile extends ConsumerStatefulWidget {
  const _ExactRemindersTile();

  @override
  ConsumerState<_ExactRemindersTile> createState() =>
      _ExactRemindersTileState();
}

class _ExactRemindersTileState extends ConsumerState<_ExactRemindersTile>
    with WidgetsBindingObserver {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final allowed = await ref
        .read(notificationServiceProvider)
        .exactRemindersAllowed();
    if (!mounted || allowed == _allowed) return;
    final changed = _allowed != null;
    setState(() => _allowed = allowed);
    // Re-register with the new precision.
    if (changed) {
      unawaited(
        ref.read(subsControllerProvider.notifier).scheduleNotifications(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowed;
    if (allowed == null) return const SizedBox.shrink();
    // Same look as _SettingsTile.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: SwitchListTile(
          title: Text('settings.exact_reminders'.tr()),
          subtitle: Text(
            allowed
                ? 'settings.exact_reminders_on'.tr()
                : 'settings.exact_reminders_off'.tr(),
          ),
          value: allowed,
          onChanged: (_) async {
            await ref.read(notificationServiceProvider).requestExactReminders();
            await _refresh();
          },
        ),
      ),
    );
  }
}

Future<void> _editBudget(
  BuildContext context,
  SettingsViewModel settings,
  WidgetRef ref,
) async {
  final result = await showDialog<_BudgetEdit>(
    context: context,
    builder: (_) => _BudgetDialog(
      current: settings.monthlyBudget,
      symbol: settings.currency.symbol,
    ),
  );
  if (result == null) return;
  ref.read(settingsControllerProvider.notifier).setMonthlyBudget(result.value);
}

/// Dialog result; [value] null means "remove the budget".
class _BudgetEdit {
  const _BudgetEdit(this.value);
  final double? value;
}

class _BudgetDialog extends HookWidget {
  const _BudgetDialog({required this.current, required this.symbol});

  final double? current;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(
      text: current == null ? '' : formatRate(current!),
    );
    final error = useState<String?>(null);
    void save() {
      final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
      if (v == null || !v.isFinite || v <= 0) {
        error.value = 'settings.budget_invalid'.tr();
        return;
      }
      Navigator.of(context).pop(_BudgetEdit(v));
    }

    return AlertDialog.adaptive(
      title: Text('settings.budget_title'.tr()),
      content: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.budget_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: symbol,
                errorText: error.value,
              ),
              onSubmitted: (_) => save(),
            ),
          ],
        ),
      ),
      actions: [
        if (current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _BudgetEdit(null)),
            child: Text('settings.budget_remove'.tr()),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('dialogs.cancel'.tr()),
        ),
        FilledButton(onPressed: save, child: Text('common.save'.tr())),
      ],
    );
  }
}

TimeOfDay _reminderTime(SettingsViewModel settings) => TimeOfDay(
  hour: settings.reminderMinutes ~/ 60 % 24,
  minute: settings.reminderMinutes % 60,
);

Future<void> _pickReminderTime(
  BuildContext context,
  SettingsViewModel settings,
  WidgetRef ref,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: _reminderTime(settings),
  );
  if (picked == null) return;
  ref
      .read(settingsControllerProvider.notifier)
      .updateReminderMinutes(picked.hour * 60 + picked.minute);
}

/// Switches language and re-schedules reminders so their text follows it.
Future<void> _changeLanguage(BuildContext context, Locale locale) async {
  final subs = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(subsControllerProvider.notifier);
  // Start the switch before popping: context may belong to the sheet.
  final switched = context.setLocale(locale);
  Navigator.pop(context);
  await switched;
  await subs.scheduleNotifications();
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated Container) so ListTile ink splashes are visible.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}

class _VersionTile extends HookWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    final info = useFuture(useMemoized(PackageInfo.fromPlatform)).data;
    return _SettingsTile(
      title: 'settings.version'.tr(),
      subtitle: info == null ? '—' : '${info.version} (${info.buildNumber})',
      onTap: null,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: isSelected
          ? Icon(
              Icons.radio_button_checked,
              color: Theme.of(context).primaryColor,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.label,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(symbol),
      leading: isSelected
          ? Icon(
              Icons.radio_button_checked,
              color: Theme.of(context).primaryColor,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}

class _ResetOnboardingTile extends StatelessWidget {
  const _ResetOnboardingTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.errorContainer.withValues(alpha: 0.3),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          title: Text(
            'Reset onboarding',
            style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Show intro screens again',
            style: TextStyle(color: cs.error.withValues(alpha: 0.7)),
          ),
          leading: Icon(Icons.restart_alt_rounded, color: cs.error),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset onboarding?'),
                content: const Text(
                  'This will show the intro screens on next app launch.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: cs.error),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if ((confirmed ?? false) && context.mounted) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateIsFirstTime(isFirstTime: true);
              context.go('/intro');
            }
          },
        ),
      ),
    );
  }
}

class LanguageOption extends StatelessWidget {
  const LanguageOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: isSelected
          ? Icon(
              Icons.radio_button_checked,
              color: Theme.of(context).primaryColor,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}

class _TestLiveActivityTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Test Live Activity'),
      subtitle: const Text('Force-starts with dummy Netflix sub'),
      leading: const Icon(Icons.live_tv),
      onTap: () async {
        const subsJson =
            r'[{"name":"Netflix","amount":15.99,"currency":"$","color":4294901760}]';
        await LiveActivityService.instance.startRaw(subsJson);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Live Activity started — lock the screen to see it',
              ),
            ),
          );
        }
      },
    );
  }
}
