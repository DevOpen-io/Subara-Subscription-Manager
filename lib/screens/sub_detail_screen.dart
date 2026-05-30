import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/widgets/brand_logo.dart';

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

DateTime _advanceByFrequency(DateTime date, Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return date.add(const Duration(days: 1));
    case Frequency.weekly:
      return date.add(const Duration(days: 7));
    case Frequency.monthly:
      var month = date.month + 1;
      var year = date.year;
      if (month > 12) {
        month = 1;
        year++;
      }
      final maxDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, date.day.clamp(1, maxDay));
    case Frequency.yearly:
      final nextYear = date.year + 1;
      final maxDay = DateTime(nextYear, date.month + 1, 0).day;
      return DateTime(nextYear, date.month, date.day.clamp(1, maxDay));
  }
}

DateTime _nextChargeDate(SubSlice slice) {
  final now = DateTime.now();
  var date = slice.startDate;
  while (!date.isAfter(now)) {
    date = _advanceByFrequency(date, slice.frequency);
  }
  return date;
}

List<(DateTime, double)> _paymentHistory(SubSlice slice, {int limit = 4}) {
  // Find the last past charge date (the one just before next charge)
  final now = DateTime.now();
  // To avoid O(N) for daily subs, advance but keep only last `limit` entries
  final history = <DateTime>[];
  var current = slice.startDate;
  while (!current.isAfter(now)) {
    history.add(current);
    current = _advanceByFrequency(current, slice.frequency);
    // If history is already longer than limit, drop the oldest
    if (history.length > limit) history.removeAt(0);
  }
  return history.reversed
      .take(limit)
      .map((d) => (d, slice.amount))
      .toList();
}

// ---------------------------------------------------------------------------
// Picker helpers
// ---------------------------------------------------------------------------

void _showFrequencyPicker(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  final frequencies = Frequency.values;
  final initialIndex = frequencies.indexOf(draft.frequency);

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Container(
        height: 250,
        color: theme.colorScheme.surface,
        child: CupertinoPicker(
          itemExtent: 40,
          scrollController: FixedExtentScrollController(initialItem: initialIndex),
          onSelectedItemChanged: (i) {
            final updated = draft.copyWith(frequency: frequencies[i]);
            onUpdate(updated);
          },
          children: frequencies.map((f) {
            final key = f.name.toLowerCase();
            return Center(
              child: Text(
                'frequency.$key'.tr(),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}

void _showDatePicker(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Container(
        height: 250,
        color: theme.colorScheme.surface,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: draft.startDate,
          onDateTimeChanged: (date) {
            final updated = draft.copyWith(startDate: date);
            onUpdate(updated);
          },
        ),
      );
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  SubSlice liveSlice,
  int index,
) async {
  await showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text('detail.delete'.tr()),
      content: Text('detail.delete_confirm'.tr(args: [liveSlice.name])),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('detail.cancel'.tr()),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            ref.read(subsControllerProvider.notifier).removeAt(index);
            Navigator.of(ctx).pop();
            if (context.mounted) context.pop();
          },
          child: Text('detail.delete_action'.tr()),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class SubDetailScreen extends HookConsumerWidget {
  const SubDetailScreen({
    super.key,
    required this.slice,
    required this.index,
  });

  final SubSlice slice;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(subsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    final subs = slicesAsync.value;
    final liveSlice = (subs != null && index < subs.length) ? subs[index] : slice;
    final symbol = settingsAsync.value?.currency.symbol ?? '';

    final draft = useState<SubSlice>(liveSlice);

    useEffect(() {
      draft.value = liveSlice;
      return null;
    }, [liveSlice]);

    void saveUpdate(SubSlice updated) {
      final currentLength = ref.read(subsControllerProvider).value?.length ?? 0;
      if (index >= currentLength) return;
      draft.value = updated;
      ref.read(subsControllerProvider.notifier).updateAt(index, updated);
    }

    final theme = Theme.of(context);

    final nextCharge = _nextChargeDate(liveSlice);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final nextChargeMidnight = DateTime(nextCharge.year, nextCharge.month, nextCharge.day);
    final daysUntil = nextChargeMidnight.difference(todayMidnight).inDays;

    final history = _paymentHistory(liveSlice);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            'detail.back'.tr(),
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 4),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _HeroSection(slice: liveSlice),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatCardsRow(
                slice: liveSlice,
                symbol: symbol,
                nextChargeDate: nextCharge,
                daysUntil: daysUntil,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DetailsSection(
                slice: draft.value,
                onTapFrequency: () => _showFrequencyPicker(context, draft.value, saveUpdate),
                onTapDate: () => _showDatePicker(context, draft.value, saveUpdate),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PaymentHistorySection(
                history: history,
                symbol: symbol,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _confirmDelete(context, ref, liveSlice, index),
                  child: Text(
                    'detail.delete'.tr(),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.slice});

  final SubSlice slice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (slice.brand != null)
            BrandLogo(brand: slice.brand, size: 72)
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Color(slice.color),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  slice.name.isNotEmpty ? slice.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slice.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (slice.brand?.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    slice.brand!.category!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD83434),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'detail.active'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Stat cards row
// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.slice,
    required this.symbol,
    required this.nextChargeDate,
    required this.daysUntil,
  });

  final SubSlice slice;
  final String symbol;
  final DateTime nextChargeDate;
  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    final freqKey = slice.frequency.name.toLowerCase();
    final freqLabel = 'frequency.short.$freqKey'.tr().toLowerCase();
    final costSub = 'detail.per_frequency'.tr(args: [freqLabel]);

    final nextSub = daysUntil == 0
        ? 'detail.today'.tr()
        : 'detail.in_days'.tr(args: [daysUntil.toString()]);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'detail.cost'.tr(),
            value: '$symbol${slice.amount.toStringAsFixed(2)}',
            sub: costSub,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'detail.next_charge'.tr(),
            value: DateFormat('MMM d').format(nextChargeDate),
            sub: nextSub,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Details section
// ---------------------------------------------------------------------------

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.slice,
    required this.onTapFrequency,
    required this.onTapDate,
  });

  final SubSlice slice;
  final VoidCallback onTapFrequency;
  final VoidCallback onTapDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freqKey = slice.frequency.name.toLowerCase();
    final category = slice.brand?.category;

    final rows = <Widget>[
      _DetailRow(
        label: 'detail.billing_cycle'.tr(),
        value: 'frequency.$freqKey'.tr(),
        hasChevron: true,
        onTap: onTapFrequency,
      ),
      _DetailRow(
        label: 'detail.started'.tr(),
        value: DateFormat('MMM d, y').format(slice.startDate),
        hasChevron: true,
        onTap: onTapDate,
      ),
      _DetailRow(
        label: 'detail.payment_method'.tr(),
        value: 'detail.not_set'.tr(),
      ),
      _DetailRow(
        label: 'detail.category'.tr(),
        value: category ?? 'detail.not_set'.tr(),
      ),
      _DetailRow(
        label: 'detail.reminder'.tr(),
        value: 'detail.not_set'.tr(),
      ),
    ];

    final separated = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      separated.add(rows[i]);
      if (i < rows.length - 1) {
        separated.add(
          const Divider(height: 1, indent: 16, endIndent: 16),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'detail.section_details'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
            ),
            child: Column(
              children: separated,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.hasChevron = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool hasChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment history section
// ---------------------------------------------------------------------------

class _PaymentHistorySection extends StatelessWidget {
  const _PaymentHistorySection({
    required this.history,
    required this.symbol,
  });

  final List<(DateTime, double)> history;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <Widget>[];
    for (var i = 0; i < history.length; i++) {
      final (date, amount) = history[i];
      rows.add(_PaymentHistoryRow(date: date, amount: amount, symbol: symbol));
      if (i < history.length - 1) {
        rows.add(const Divider(height: 1, indent: 16, endIndent: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'detail.section_history'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        if (history.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
              ),
              child: Column(children: rows),
            ),
          ),
      ],
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({
    required this.date,
    required this.amount,
    required this.symbol,
  });

  final DateTime date;
  final double amount;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('MMM dd').format(date),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
