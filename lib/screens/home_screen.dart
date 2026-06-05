import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/config/router_config.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/widgets/add_subs_dialog.dart';
import 'package:subs_tracker/widgets/brand_logo.dart';
import 'package:subs_tracker/widgets/sub_zilla_app_bar.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(subsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
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
          data: (settings) => buildBody(slices, settings, context, ref),
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
    WidgetRef ref,
  ) {
      if (slices.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Text("home.no_subs".tr())),
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
              child: Text("home.add_sub".tr()),
            ),
          ],
        );
      }

      final total = slices.fold<double>(0, (a, b) => a + b.monthlyAmount);
      final sortedSlices = List<SubSlice>.from(slices)
        ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
      final mostExpensive = sortedSlices.first;

      return SafeArea(
        child: Column(
          children: [
            // Summary Card
            _SummaryCard(
              total: total,
              count: slices.length,
              mostExpensive: mostExpensive,
              currencySymbol: settings.currency.symbol,
            ),
            const SizedBox(height: 16),
            // Compact Subscription List
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: slices.length,
                itemBuilder: (context, index) {
                  final slice = slices[index];
                  return _CompactSubscriptionTile(
                    slice: slice,
                    index: index,
                    currencySymbol: settings.currency.symbol,
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
  });

  final double total;
  final int count;
  final SubSlice mostExpensive;
  final String currencySymbol;

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
                    "home.total_spending".tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$currencySymbol${total.toStringAsFixed(2)}",
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
                  "home.active_count".tr(args: [count.toString()]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
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
                  "home.most_expensive".tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                Text(
                  "${mostExpensive.name} ($currencySymbol${mostExpensive.amount.toStringAsFixed(2)}${'frequency.short.${mostExpensive.frequency.name.toLowerCase()}'.tr()})",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSubscriptionTile extends ConsumerWidget {
  const _CompactSubscriptionTile({
    required this.slice,
    required this.index,
    required this.currencySymbol,
  });

  final SubSlice slice;
  final int index;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String frequencyShort = 'frequency.short.${slice.frequency.name.toLowerCase()}'.tr();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key('${slice.name}-$index'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showAdaptiveDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog.adaptive(
                title: Text(
                  "home.delete_title".tr(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text("home.delete_confirm".tr(args: [slice.name])),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("home.cancel".tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("home.delete".tr()),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          ref.read(subsControllerProvider.notifier).removeAt(index);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Colors.white,
          ),
        ),
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
                      Text(
                        slice.name,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "home.renews_info".tr(args: [
                          "${slice.startDate.month}/${slice.startDate.day}",
                          "frequency.${slice.frequency.name.toLowerCase()}".tr()
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
                  "$currencySymbol${slice.amount.toStringAsFixed(2)}$frequencyShort",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
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


