import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../config/router_config.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../widgets/add_subs_dialog.dart';
import '../widgets/brand_logo.dart';
import '../widgets/status_picker.dart';
import '../widgets/sub_zilla_app_bar.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(subsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    final showYearly = useState(false);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: SubZillaAppBar(
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => showModalBottomSheet<void>(
            useRootNavigator: true,
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: const AddSubsSheet(),
            ),
          ),
        ),
      ),
      body: slicesAsync.when(
        data: (slices) => settingsAsync.when(
          data: (settings) => buildBody(slices, settings, context, ref, showYearly: showYearly.value, onToggleYearly: () => showYearly.value = !showYearly.value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget buildBody(
    List<SubSlice> slices,
    SettingsViewModel settings,
    BuildContext context,
    WidgetRef ref, {
    required bool showYearly,
    required VoidCallback onToggleYearly,
  }) {
      if (slices.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Text('home.no_subs'.tr())),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
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
              ),
              child: Text('home.add_sub'.tr()),
            ),
          ],
        );
      }

      final activeSlices = slices.activeOnly;
      final total = activeSlices.fold<double>(0, (a, b) => a + b.monthlyAmount);
      final sortedSlices = List<SubSlice>.from(activeSlices)
        ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
      final mostExpensive = sortedSlices.isNotEmpty ? sortedSlices.first : null;

      return SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Summary Card
            _SummaryCard(
              total: showYearly ? total * 12 : total,
              count: activeSlices.length,
              mostExpensive: mostExpensive,
              currencySymbol: settings.currency.symbol,
              showYearly: showYearly,
            ),
            const SizedBox(height: 8),
            // Toolbar: sort + monthly/yearly toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const _SortButton(),
                  const Spacer(),
                  _LiquidGlassSegmentedControl(
                    showYearly: showYearly,
                    onToggle: onToggleYearly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Compact Subscription List
            Flexible(
              fit: FlexFit.tight,
              child: ReorderableListView.builder(
                padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.paddingOf(context).bottom + 80),
                onReorder: (oldIndex, newIndex) =>
                    ref.read(subsControllerProvider.notifier).reorderSlices(oldIndex, newIndex),
                itemCount: slices.length,
                itemBuilder: (context, index) {
                  final slice = slices[index];
                  return _CompactSubscriptionTile(
                    key: ValueKey(slice.name),
                    slice: slice,
                    index: index,
                    currencySymbol: settings.currency.symbol,
                    showYearly: showYearly,
                  );
                },
              ),
            ),
          ],
        ),
      );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.count,
    required this.mostExpensive,
    required this.currencySymbol,
    required this.showYearly,
  });

  final double total;
  final int count;
  final SubSlice? mostExpensive;
  final String currencySymbol;
  final bool showYearly;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showYearly ? 'home.total_spending_yearly'.tr() : 'home.total_spending'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currencySymbol${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'home.active_count'.tr(args: [count.toString()]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (mostExpensive != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'home.most_expensive'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  Text(
                    "${mostExpensive!.name} ($currencySymbol${mostExpensive!.amount.toStringAsFixed(2)}${'frequency.short.${mostExpensive!.frequency.name.toLowerCase()}'.tr()})",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactSubscriptionTile extends ConsumerWidget {
  const _CompactSubscriptionTile({
    super.key,
    required this.slice,
    required this.index,
    required this.currencySymbol,
    required this.showYearly,
  });

  final SubSlice slice;
  final int index;
  final String currencySymbol;
  final bool showYearly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAmount = showYearly
        ? slice.monthlyAmount * 12
        : slice.monthlyAmount;
    final displaySuffix = showYearly
        ? 'frequency.short.yearly'.tr()
        : 'frequency.short.monthly'.tr();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
          onTap: () {
            context.push(
              Routes.subscription.route,
              extra: {'slice': slice, 'index': index},
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Row(
              children: [
                _CompactSliceLeading(slice: slice),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              slice.name,
                              style: Theme.of(context).textTheme.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (slice.status != SubStatus.active) ...[
                            const SizedBox(width: 6),
                            StatusBadge(
                              status: slice.status,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              borderRadius: 6,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'home.renews_info'.tr(args: [
                          '${slice.startDate.month}/${slice.startDate.day}',
                          'frequency.${slice.frequency.name.toLowerCase()}'.tr()
                        ]),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$currencySymbol${displayAmount.toStringAsFixed(2)}$displaySuffix',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton();

  static const _glassSettings = LiquidGlassSettings(
    thickness: 18,
    lightIntensity: 0.45,
    refractiveIndex: 1.15,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSheet(context, ref),
      child: LiquidGlass.withOwnLayer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
        settings: _glassSettings,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 16, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                'home.sort'.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(subsControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'home.sort_title'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text('home.sort_name_asc'.tr()),
              onTap: () {
                notifier.sortSlices((a, b) => a.name.compareTo(b.name));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text('home.sort_name_desc'.tr()),
              onTap: () {
                notifier.sortSlices((a, b) => b.name.compareTo(a.name));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text('home.sort_amount_asc'.tr()),
              onTap: () {
                notifier.sortSlices((a, b) => a.monthlyAmount.compareTo(b.monthlyAmount));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text('home.sort_amount_desc'.tr()),
              onTap: () {
                notifier.sortSlices((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LiquidGlassSegmentedControl extends StatelessWidget {
  const _LiquidGlassSegmentedControl({
    required this.showYearly,
    required this.onToggle,
  });

  final bool showYearly;
  final VoidCallback onToggle;

  static const _bgSettings = LiquidGlassSettings(
    blur: 3,
    thickness: 12,
    lightIntensity: 0.25,
    refractiveIndex: 1.08,
  );

  static const _thumbSettings = LiquidGlassSettings(
    blur: 6,
    refractiveIndex: 1.15,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: SizedBox(
        height: 34,
        child: Stack(
          children: [
            // Drives Stack width
            Opacity(opacity: 0, child: _LabelsRow(showYearly: showYearly)),
            // Background glass
            const Positioned.fill(
              child: LiquidGlass.withOwnLayer(
                shape: LiquidRoundedSuperellipse(borderRadius: 17),
                settings: _bgSettings,
                child: SizedBox.expand(),
              ),
            ),
            // Animated sliding thumb
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                alignment: showYearly ? Alignment.centerRight : Alignment.centerLeft,
                child: const FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: LiquidGlass.withOwnLayer(
                      shape: LiquidRoundedSuperellipse(borderRadius: 14),
                      settings: _thumbSettings,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            // Visible labels on top
            _LabelsRow(showYearly: showYearly),
          ],
        ),
      ),
    );
  }
}

class _LabelsRow extends StatelessWidget {
  const _LabelsRow({required this.showYearly});

  final bool showYearly;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SegmentLabel(label: 'home.view_monthly', active: !showYearly),
        _SegmentLabel(label: 'home.view_yearly', active: showYearly),
      ],
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _CompactSliceLeading extends StatelessWidget {
  const _CompactSliceLeading({required this.slice});

  final SubSlice slice;

  @override
  Widget build(BuildContext context) {
    return SubLeadingIcon(
      name: slice.name,
      brand: slice.brand,
      color: Color(slice.color),
      size: 40,
    );
  }
}
