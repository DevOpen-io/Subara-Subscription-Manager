import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/utils/app_theme.dart';
import 'package:subs_tracker/widgets/color_scheme_picker.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "settings.title",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ).tr(),
          const SizedBox(height: 24),
          // Theme Section
          _SettingsSection(
            title: "settings.appearance".tr(),
            children: [
              _SettingsTile(
                title: "settings.theme".tr(),
                subtitle: _getThemeLabel(settings.theme).tr(),
                onTap: () => _showThemeBottomSheet(context, settings, ref),
              ),
              _SettingsTile(
                title: "settings.color_scheme".tr(),
                subtitle: schemeDisplayName(settings.colorScheme),
                onTap: () => _showColorSchemeBottomSheet(context, settings, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Currency Section
          _SettingsSection(
            title: "settings.currency".tr(),
            children: [
              _SettingsTile(
                title: "settings.currency_unit".tr(),
                subtitle:
                    "${settings.currency.label} (${settings.currency.symbol})",
                onTap: () =>
                    _showCurrencyBottomSheet(context, settings, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Language Section
          _SettingsSection(
            title: "settings.language".tr(),
            children: [
              _SettingsTile(
                title: "settings.language".tr(),
                subtitle: context.locale.languageCode == 'en'
                    ? 'English'
                    : 'Türkçe',
                onTap: () async => await _showLanguageBottomSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // About Section
          _SettingsSection(
            title: "settings.about".tr(),
            children: [
              _SettingsTile(
                title: "settings.version".tr(),
                subtitle: "1.0.0",
                onTap: null,
              ),
              _SettingsTile(
                title: "settings.app_name".tr(),
                subtitle: "SubZilla",
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
        if (kDebugMode)
          _SettingsSection(
            title: "Developer",
            children: [
              _ResetOnboardingTile(ref: ref),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "settings.light";
      case ThemeMode.dark:
        return "settings.dark";
      case ThemeMode.system:
        return "settings.system";
    }
  }

  void _showThemeBottomSheet(
    BuildContext context,
    SettingsViewModel settings,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "settings.select_theme".tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...[ThemeMode.light, ThemeMode.dark, ThemeMode.system]
                  .map((mode) => _ThemeOption(
                        label: _getThemeLabel(mode).tr(),
                        isSelected: settings.theme == mode,
                        onTap: () {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateTheme(mode);
                          Navigator.pop(context);
                        },
                      )),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "settings.select_color_scheme".tr(),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "settings.select_currency".tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: Currency.values
                      .map((currency) => _CurrencyOption(
                            label: currency.label,
                            symbol: currency.symbol,
                            isSelected: settings.currency == currency,
                            onTap: () {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .updateCurrency(currency);
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  Future<void> _showLanguageBottomSheet(
    BuildContext context,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "settings.select_language".tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              LanguageOption(
                label: "English",
                isSelected: context.locale.languageCode == 'en',
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              LanguageOption(
                label: "Türkçe",
                isSelected: context.locale.languageCode == 'tr',
                onTap: () {
                  context.setLocale(const Locale('tr'));
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
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.2),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
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
          ? Icon(Icons.radio_button_checked,
              color: Theme.of(context).primaryColor)
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
          ? Icon(Icons.radio_button_checked,
              color: Theme.of(context).primaryColor)
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reset onboarding?'),
              content: const Text('This will show the intro screens on next app launch.'),
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
          if (confirmed == true && context.mounted) {
            ref.read(settingsControllerProvider.notifier).updateIsFirstTime(true);
            context.go('/intro');
          }
        },
      ),
    );
  }
}

class LanguageOption extends StatelessWidget {
  const LanguageOption({super.key, 
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
          ? Icon(Icons.radio_button_checked,
              color: Theme.of(context).primaryColor)
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}
