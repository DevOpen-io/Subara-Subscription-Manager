import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../config/router_config.dart';
import '../models/billing.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/billing_labels.dart';
import '../utils/sub_filter.dart';
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
    final filter = useState(const SubFilter());
    final searchOpen = useState(false);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: SubaraAppBar(
        trailing: IconButton(
          icon: const Icon(Icons.add),
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
        ),
      ),
      body: slicesAsync.when(
        data: (slices) => settingsAsync.when(
          data: (settings) => buildBody(
            slices,
            settings,
            context,
            ref,
            showYearly: showYearly.value,
            onToggleYearly: () => showYearly.value = !showYearly.value,
            filter: filter.value,
            onFilterChanged: (f) => filter.value = f,
            searchOpen: searchOpen.value,
            onToggleSearch: () {
              searchOpen.value = !searchOpen.value;
              // Closing the search clears it.
              if (!searchOpen.value) filter.value = const SubFilter();
            },
          ),
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
    required SubFilter filter,
    required ValueChanged<SubFilter> onFilterChanged,
    required bool searchOpen,
    required VoidCallback onToggleSearch,
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

    // Totals in the main currency; subs without a rate are left out.
    final converted = settings.inMain(slices.activeOnly);
    final activeSlices = converted.subs;
    final total = activeSlices.fold<double>(0, (a, b) => a + b.monthlyAmount);
    final sortedSlices = List<SubSlice>.from(activeSlices)
      ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    final mostExpensive = sortedSlices.isNotEmpty ? sortedSlices.first : null;
    final now = DateTime.now();
    final upcoming = activeSlices.chargesBetween(
      now,
      DateTime(now.year, now.month, now.day + 6),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Summary Card
          _SummaryCard(
            total: showYearly ? total * 12 : total,
            monthlyTotal: total,
            budget: settings.monthlyBudget,
            count: slices.activeOnly.length,
            mostExpensive: mostExpensive,
            currencySymbol: settings.currency.symbol,
            showYearly: showYearly,
            missingRates: converted.missing,
          ),
          const SizedBox(height: 8),
          _UpcomingCard(
            count: upcoming.count,
            total: upcoming.total,
            currencySymbol: settings.currency.symbol,
          ),
          const SizedBox(height: 8),
          // Toolbar: sort + monthly/yearly toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const _SortButton(),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'home.search_hint'.tr(),
                  onPressed: onToggleSearch,
                  icon: Icon(searchOpen ? Icons.close : Icons.search),
                ),
                const Spacer(),
                _LiquidGlassSegmentedControl(
                  showYearly: showYearly,
                  onToggle: onToggleYearly,
                ),
              ],
            ),
          ),
          if (searchOpen)
            _SearchPanel(filter: filter, onChanged: onFilterChanged),
          const SizedBox(height: 8),
          // Compact Subscription List. Reordering only makes sense on the
          // full list, so a filtered list is a plain list.
          Flexible(
            fit: FlexFit.tight,
            child: filter.isActive
                ? _FilteredList(
                    slices: filter.apply(slices),
                    settings: settings,
                    showYearly: showYearly,
                  )
                : _ActiveList(
                    slices: slices,
                    settings: settings,
                    showYearly: showYearly,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Everything but cancelled subscriptions, reorderable, with the archived
/// (cancelled) ones behind a footer button.
class _ActiveList extends ConsumerWidget {
  const _ActiveList({
    required this.slices,
    required this.settings,
    required this.showYearly,
  });

  final List<SubSlice> slices;
  final SettingsViewModel settings;
  final bool showYearly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = [
      for (final s in slices)
        if (s.status != SubStatus.cancelled) s,
    ];
    final archived = [
      for (final s in slices)
        if (s.status == SubStatus.cancelled) s,
    ];
    return ReorderableListView.builder(
      footer: archived.isEmpty
          ? null
          : _ArchiveButton(archived: archived, settings: settings),
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.paddingOf(context).bottom + 80,
      ),
      onReorder: (oldIndex, newIndex) => ref
          .read(subsControllerProvider.notifier)
          .reorderWithin([for (final s in visible) s.id], oldIndex, newIndex),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final slice = visible[index];
        return _CompactSubscriptionTile(
          key: ValueKey(slice.id),
          slice: slice,
          index: index,
          currencySymbol: settings.currencyOf(slice).symbol,
          showYearly: showYearly,
        );
      },
    );
  }
}

/// "Archive (3)": opens the cancelled subscriptions.
class _ArchiveButton extends StatelessWidget {
  const _ArchiveButton({required this.archived, required this.settings});

  final List<SubSlice> archived;
  final SettingsViewModel settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (_) => _ArchiveSheet(
            archived: archived,
            settings: settings,
            // The sheet's context is gone once popped; push from here.
            onOpen: (id) => context.push(Routes.subscription.route, extra: id),
          ),
        ),
        icon: const Icon(Icons.inventory_2_outlined, size: 18),
        label: Text('home.archive'.tr(args: ['${archived.length}'])),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

const _archiveRowHeight = 72.0;

class _ArchiveSheet extends StatelessWidget {
  const _ArchiveSheet({
    required this.archived,
    required this.settings,
    required this.onOpen,
  });

  final List<SubSlice> archived;
  final SettingsViewModel settings;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'home.archive_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'home.archive_hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Sized to the rows (up to the sheet's max) so a short archive
            // gives a short sheet; fixed row height, no shrinkWrap.
            Flexible(
              child: SizedBox(
                height: archived.length * _archiveRowHeight,
                child: ListView.builder(
                  itemExtent: _archiveRowHeight,
                  itemCount: archived.length,
                  itemBuilder: (_, i) {
                    final s = archived[i];
                    final saved = s.savedSinceCancel(DateTime.now()) / s.people;
                    final symbol = settings.currencyOf(s).symbol;
                    return ListTile(
                      leading: _CompactSliceLeading(slice: s),
                      title: Text(s.name),
                      subtitle: Text(s.cycleLabel),
                      trailing: saved > 0
                          ? Text(
                              'home.archive_saved'.tr(
                                args: ['$symbol${saved.toStringAsFixed(2)}'],
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpen(s.id);
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Search field plus status chips, shown under the toolbar.
class _SearchPanel extends HookWidget {
  const _SearchPanel({required this.filter, required this.onChanged});

  final SubFilter filter;
  final ValueChanged<SubFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: filter.query);
    const statuses = SubStatus.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'home.search_hint'.tr(),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (q) => onChanged(filter.copyWith(query: q)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final status = statuses[i];
                final selected = filter.statuses.contains(status);
                return FilterChip(
                  label: Text('detail.status_${status.name}'.tr()),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (on) => onChanged(
                    filter.copyWith(
                      statuses: on
                          ? {...filter.statuses, status}
                          : ({...filter.statuses}..remove(status)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredList extends StatelessWidget {
  const _FilteredList({
    required this.slices,
    required this.settings,
    required this.showYearly,
  });

  final List<SubSlice> slices;
  final SettingsViewModel settings;
  final bool showYearly;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Text(
          'home.no_matches'.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.paddingOf(context).bottom + 80,
      ),
      itemCount: slices.length,
      itemBuilder: (context, index) {
        final slice = slices[index];
        return _CompactSubscriptionTile(
          key: ValueKey(slice.id),
          slice: slice,
          index: index,
          currencySymbol: settings.currencyOf(slice).symbol,
          showYearly: showYearly,
        );
      },
    );
  }
}

/// Payments due in the next 7 days (today included); taps open the calendar.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.count,
    required this.total,
    required this.currencySymbol,
  });

  final int count;
  final double total;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(Routes.calendar.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'home.upcoming_title'.tr(),
                  style: theme.textTheme.labelLarge,
                ),
                const Spacer(),
                Text(
                  'home.upcoming_count'.plural(count),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '$currencySymbol${total.toStringAsFixed(2)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Unpaid" / "Overdue" for a manually paid subscription.
class _UnpaidBadge extends StatelessWidget {
  const _UnpaidBadge({required this.overdue});

  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: overdue ? cs.errorContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        overdue ? 'home.overdue'.tr() : 'home.unpaid'.tr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: overdue ? cs.onErrorContainer : cs.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Monthly spending against the budget; turns red when over it.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.spent,
    required this.budget,
    required this.currencySymbol,
  });

  final double spent;
  final double budget;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final over = spent > budget;
    String money(double v) => '$currencySymbol${v.toStringAsFixed(2)}';
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (spent / budget).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
              over ? Colors.red.shade300 : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (over) ...[
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                over
                    ? 'home.over_budget'.tr(args: [money(spent - budget)])
                    : 'home.budget'.tr(args: [money(spent), money(budget)]),
                style: style?.copyWith(
                  fontWeight: over ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "USD isn't in the total: add an exchange rate" — opens settings.
class _MissingRatesNote extends StatelessWidget {
  const _MissingRatesNote({required this.currencies});

  final List<Currency> currencies;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(Routes.settings.route),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'home.missing_rates'.tr(
                args: [currencies.map((c) => c.code).join(', ')],
              ),
              style: style,
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
    required this.missingRates,
    required this.monthlyTotal,
    required this.budget,
  });

  /// Monthly total and budget, for the budget bar (always monthly).
  final double monthlyTotal;
  final double? budget;
  final double total;
  final int count;
  final SubSlice? mostExpensive;
  final String currencySymbol;
  final bool showYearly;

  /// Currencies without an exchange rate; their subs aren't in [total].
  final List<Currency> missingRates;

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
                    showYearly
                        ? 'home.total_spending_yearly'.tr()
                        : 'home.total_spending'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
          if (budget != null) ...[
            const SizedBox(height: 10),
            _BudgetBar(
              spent: monthlyTotal,
              budget: budget!,
              currencySymbol: currencySymbol,
            ),
          ],
          if (missingRates.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MissingRatesNote(currencies: missingRates),
          ],
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    '${mostExpensive!.name} ($currencySymbol${mostExpensive!.amount.toStringAsFixed(2)}${mostExpensive!.shortCycleLabel})',
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
    // Your share when the cost is split.
    final monthly = slice.monthlyAmount / slice.people;
    final displayAmount = showYearly ? monthly * 12 : monthly;
    final displaySuffix = showYearly
        ? 'frequency.short.yearly'.tr()
        : 'frequency.short.monthly'.tr();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          context.push(Routes.subscription.route, extra: slice.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
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
                        if (slice.unpaidCharge(DateTime.now()) != null) ...[
                          const SizedBox(width: 6),
                          _UnpaidBadge(
                            overdue: slice.isOverdue(DateTime.now()),
                          ),
                        ],
                        if (slice.status != SubStatus.active) ...[
                          const SizedBox(width: 6),
                          StatusBadge(
                            status: slice.status,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            borderRadius: 6,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Paused/cancelled subs don't renew: show only the cycle.
                      slice.status == SubStatus.paused ||
                              slice.status == SubStatus.cancelled
                          ? slice.cycleLabel
                          : 'home.renews_info'.tr(
                              args: [
                                DateFormat.Md(
                                  context.locale.toString(),
                                ).format(slice.nextChargeDate(DateTime.now())),
                                slice.cycleLabel,
                              ],
                            ),
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
              if (slice.people > 1) ...[
                Icon(
                  Icons.group_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
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
              Icon(
                Icons.sort,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
    final settings = ref.read(settingsControllerProvider).value;
    // Compare in the main currency when a rate is known.
    double monthly(SubSlice s) =>
        settings?.toMain(s.monthlyAmount, settings.currencyOf(s)) ??
        s.monthlyAmount;
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
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                notifier.sortSlices((a, b) => monthly(a).compareTo(monthly(b)));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text('home.sort_amount_desc'.tr()),
              onTap: () {
                notifier.sortSlices((a, b) => monthly(b).compareTo(monthly(a)));
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
                alignment: showYearly
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
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
