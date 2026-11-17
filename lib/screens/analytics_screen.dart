import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/billing.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/app_theme.dart';
import '../utils/payment_methods.dart';
import '../widgets/bar_chart.dart';
import '../widgets/pie_chart.dart';
import '../widgets/sub_zilla_app_bar.dart';

enum _Period { month, quarter, year }

enum _ChartMode { price, percentage }

extension _PeriodX on _Period {
  String get labelKey => switch (this) {
    _Period.month => 'analytics.period_month',
    _Period.quarter => 'analytics.period_quarter',
    _Period.year => 'analytics.period_year',
  };

  String get totalLabelKey => switch (this) {
    _Period.month => 'analytics.total_monthly',
    _Period.quarter => 'analytics.total_quarterly',
    _Period.year => 'analytics.total_yearly',
  };

  double get multiplier => switch (this) {
    _Period.month => 1,
    _Period.quarter => 3,
    _Period.year => 12,
  };
}

class AnalyticsScreen extends HookConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(subsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final period = useState(_Period.month);
    final chartMode = useState(_ChartMode.price);

    return Scaffold(
      appBar: const SubaraAppBar(),
      body: slicesAsync.when(
        data: (slices) => settingsAsync.when(
          data: (settings) =>
              _buildBody(slices, settings, context, period, chartMode),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('common.error_generic'.tr())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('common.error_generic'.tr())),
      ),
    );
  }

  Widget _buildBody(
    List<SubSlice> slices,
    SettingsViewModel settings,
    BuildContext context,
    ValueNotifier<_Period> period,
    ValueNotifier<_ChartMode> chartMode,
  ) {
    if (slices.isEmpty) {
      return Center(child: Text('analytics.no_data'.tr()));
    }

    // Everything here is in the main currency; subs without a rate are left
    // out (the home screen says which).
    final converted = settings.inMain(slices.activeOnly);
    final sorted = [...converted.subs]
      ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    final multiplier = period.value.multiplier;
    final total =
        sorted.fold<double>(0, (a, b) => a + b.monthlyAmount) * multiplier;
    final now = DateTime.now();
    final saved = settings
        .inMain(slices)
        .subs
        .fold<double>(0, (a, b) => a + b.savedSinceCancel(now));

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_Period>(
              segments: _Period.values
                  .map(
                    (p) =>
                        ButtonSegment(value: p, label: Text(p.labelKey.tr())),
                  )
                  .toList(),
              selected: {period.value},
              onSelectionChanged: (s) => period.value = s.first,
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              total: total,
              count: sorted.length,
              currency: settings.currency.symbol,
              totalLabel: period.value.totalLabelKey.tr(),
            ),
            if (converted.missing.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MissingRatesNote(currencies: converted.missing),
            ],
            if (saved > 0) ...[
              const SizedBox(height: 12),
              _SavedCard(saved: saved, currency: settings.currency.symbol),
            ],
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'analytics.chart_title'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (chartMode.value == _ChartMode.price)
                        Text(
                          period.value.totalLabelKey.tr(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SegmentedButton<_ChartMode>(
                      segments: [
                        ButtonSegment(
                          value: _ChartMode.price,
                          label: Text('analytics.chart_mode_amount'.tr()),
                        ),
                        ButtonSegment(
                          value: _ChartMode.percentage,
                          label: Text('analytics.chart_mode_share'.tr()),
                        ),
                      ],
                      selected: {chartMode.value},
                      onSelectionChanged: (s) => chartMode.value = s.first,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: chartMode.value == _ChartMode.price
                        ? SubsBar(
                            key: const ValueKey(_ChartMode.price),
                            slices: sorted,
                            currency: settings.currency.symbol,
                            multiplier: period.value.multiplier,
                          )
                        : SubsPie(
                            key: const ValueKey(_ChartMode.percentage),
                            slices: sorted,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _PaymentMethodsSection(
              groups: groupByPaymentMethod(sorted),
              currency: settings.currency.symbol,
              multiplier: multiplier,
            ),
            const SizedBox(height: 32),
            Text(
              'analytics.breakdown'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final slice = sorted[index];
                final sliceAmount = slice.monthlyAmount * multiplier;
                final percent = total == 0 ? 0.0 : sliceAmount / total;
                return _BreakdownItem(
                  slice: slice,
                  amount: sliceAmount,
                  percent: percent,
                  currency: settings.currency.symbol,
                  rank: index + 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.count,
    required this.currency,
    required this.totalLabel,
  });

  final double total;
  final int count;
  final String currency;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency${total.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kCoralAccent,
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 32,
              color: scheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'analytics.active_subs'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(
                    height: 20,
                    thickness: 0.5,
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                  Text(
                    'analytics.avg_cost'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency${(count == 0 ? 0 : total / count).toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.slice,
    required this.amount,
    required this.percent,
    required this.currency,
    required this.rank,
  });

  final SubSlice slice;
  final double amount;
  final double percent;
  final String currency;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = Color(slice.color);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: textTheme.bodySmall?.copyWith(
                  color: rank == 1 ? kCoralAccent : scheme.onSurfaceVariant,
                  fontWeight: rank == 1 ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slice.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                      semanticsLabel:
                          '${slice.name}: ${(percent * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${amount.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Money not spent since cancelling subscriptions in the app.
class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.saved, required this.currency});

  final double saved;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'analytics.saved_total'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '$currency${saved.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subscriptions in these currencies have no exchange rate and aren't in
/// the totals or charts.
class _MissingRatesNote extends StatelessWidget {
  const _MissingRatesNote({required this.currencies});

  final List<Currency> currencies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'home.missing_rates'.tr(
              args: [currencies.map((c) => c.code).join(', ')],
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Monthly (or period) spending per payment method.
class _PaymentMethodsSection extends StatelessWidget {
  const _PaymentMethodsSection({
    required this.groups,
    required this.currency,
    required this.multiplier,
  });

  final List<PaymentGroup> groups;
  final String currency;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      rows.add(
        ListTile(
          dense: true,
          leading: Icon(
            g.method == null && g.card == null
                ? Icons.help_outline
                : Icons.credit_card,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            paymentLabel(
              g.method,
              g.card,
              notSet: 'analytics.method_not_set'.tr(),
            ),
          ),
          subtitle: Text('analytics.subs_count'.plural(g.count)),
          trailing: Text(
            '$currency${(g.monthly * multiplier).toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      if (i < groups.length - 1) rows.add(const Divider(height: 1));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.by_payment_method'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}
