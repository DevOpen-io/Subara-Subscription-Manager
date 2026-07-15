import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/router_config.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import 'add_subs_dialog.dart';

class SidebarMenu extends ConsumerStatefulWidget {
  const SidebarMenu({super.key});

  @override
  ConsumerState<SidebarMenu> createState() => _MenubarState();
}

class _MenubarState extends ConsumerState<SidebarMenu> {
  late Future<PackageInfo> _pkg;

  @override
  void initState() {
    super.initState();
    _pkg = PackageInfo.fromPlatform();
  }

  final Uri _url = Uri.parse('https://github.com/DevOpen-io/Subs-Tracker-App');
  final Uri _privacyPolicyUrl = Uri.parse(
    'https://github.com/DevOpen-io/Subs-Tracker-App/blob/main/docs/privacy-policy.md',
  );
  final Uri _termsUrl = Uri.parse(
    'https://github.com/DevOpen-io/Subs-Tracker-App/blob/main/docs/terms-and-conditions.md',
  );

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    if (!await launchUrl(
      _privacyPolicyUrl,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $_privacyPolicyUrl');
    }
  }

  Future<void> _launchTermsAndConditions() async {
    if (!await launchUrl(_termsUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_termsUrl');
    }
  }

  Future<void> _exportSubscriptions() async {
    try {
      final controller = ref.read(subsControllerProvider.notifier);
      final jsonString = await controller.exportToJson();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'subscriptions_backup_$timestamp.json';

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempFile.path)]),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('menu.export_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('menu.export_error_generic'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importSubscriptions() async {
    try {
      const jsonType = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
        uniformTypeIdentifiers: ['public.json'],
      );
      final picked = await openFile(acceptedTypeGroups: [jsonType]);

      if (picked != null) {
        final jsonString = await picked.readAsString();

        final controller = ref.read(subsControllerProvider.notifier);
        final success = await controller.importFromJson(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'menu.import_success'.tr()
                    : 'menu.import_error'.tr(),
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('menu.import_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAdaptiveDialog<void>(
      context: context,
      builder: (_) => FutureBuilder<PackageInfo>(
        future: _pkg,
        builder: (ctx, snap) {
          final version = snap.hasData
              ? '${snap.data!.version} (${snap.data!.buildNumber})'
              : '—';
          return AlertDialog.adaptive(
            title: Text('settings.app_name'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/App_Logo.png', width: 48, height: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'settings.version'.tr(),
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                          Text(version),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('menu.about_desc'.tr()),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _launchUrl,
                  child: Text(
                    'menu.view_github'.tr(),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('common.back'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: settingsController.when(
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        data: (slice) => SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.primary),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: ClipOval(child: Image.asset('assets/App_Logo.png', width: 48, height: 48)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'settings.app_name'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text('menu.home'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(Routes.home.route);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_outlined),
                title: Text('menu.add_sub'.tr()),
                onTap: () async {
                  Navigator.of(context).pop();

                  await showModalBottomSheet<void>(
                    useRootNavigator: true,
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (ctx) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: const AddSubsSheet(),
                    ),
                  );
                },
              ),
              const Divider(height: 24, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text('menu.dark_mode'.tr()),
                value: slice.theme == ThemeMode.dark,
                onChanged: (value) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text('menu.export'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportSubscriptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text('menu.import'.tr()),
                onTap: () async {
                  final confirmed = await showAdaptiveDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog.adaptive(
                      title: Text('menu.import_confirm_title'.tr()),
                      content: Text('menu.import_confirm_body'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text('home.cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text('menu.import_confirm_action'.tr()),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  await _importSubscriptions();
                },
              ),
              const Divider(height: 24, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('menu.privacy_policy'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchPrivacyPolicy();
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: Text('menu.terms_conditions'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _launchTermsAndConditions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('menu.about'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
