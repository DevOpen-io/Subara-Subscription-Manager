import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/app_theme.dart';
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
      appBar: const SubZillaAppBar(),
      body: slicesAsync.when(
        data: (slices) => settingsAsync.when(
          data: (settings) => _buildBody(slices, settings, context, period, chartMode),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('common.error_generic'.tr())),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('common.error_generic'.tr())),
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

    final sorted = [...slices.activeOnly]
      ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    final multiplier = period.value.multiplier;
    final total =
        sorted.fold<double>(0, (a, b) => a + b.monthlyAmount) * multiplier;

    return SafeArea(
      bottom:false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_Period>(
              segments: _Period.values
                  .map((p) => ButtonSegment(
                        value: p,
                        label: Text(p.labelKey.tr()),
                      ))
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                        : SubsPie(key: const ValueKey(_ChartMode.percentage), slices: sorted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'analytics.breakdown'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Divider(
                  height: 20,
                  thickness: 0.5,
                  color: scheme.outline.withValues(alpha: 0.2),
                ),
                Text(
                  'analytics.avg_cost'.tr(),
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  '$currency${(count == 0 ? 0 : total / count).toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
