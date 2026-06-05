import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/color_palette.dart';
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
  final now = DateTime.now();
  final history = <DateTime>[];
  var current = slice.startDate;
  while (!current.isAfter(now)) {
    history.add(current);
    current = _advanceByFrequency(current, slice.frequency);
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

void _showColorPicker(
  BuildContext context,
  int initialColor,
  void Function(int) onColorSelected,
) {
  showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      var currentColor = Color(initialColor);
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);

          Future<void> openCustom() async {
            Color temp = currentColor;
            final result = await showDialog<Color>(
              context: ctx,
              builder: (dialogCtx) => StatefulBuilder(
                builder: (dCtx, setS) => AlertDialog.adaptive(
                  title: Text('dialogs.custom_color'.tr()),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: temp,
                      onColorChanged: (c) => setS(() => temp = c),
                      enableAlpha: false,
                      paletteType: PaletteType.hsvWithHue,
                      labelTypes: const [],
                      pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('dialogs.cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogCtx, temp),
                      child: Text('dialogs.use_color'.tr()),
                    ),
                  ],
                ),
              ),
            );
            if (result != null) {
              setSheetState(() => currentColor = result);
              onColorSelected(result.toARGB32());
            }
          }

          final isCustom = !kSliceColors.any(
            (c) => c.toARGB32() == currentColor.toARGB32(),
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'dialogs.slice_color'.tr(),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kSliceColors.map((c) {
                      final isSelected = c.toARGB32() == currentColor.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => currentColor = c);
                          onColorSelected(c.toARGB32());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: isSelected ? 44 : 38,
                          height: isSelected ? 44 : 38,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black12,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 2),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: openCustom,
                          icon: Icon(isCustom ? Icons.check_circle : Icons.colorize),
                          label: Text(
                            isCustom
                                ? 'dialogs.custom_color_selected'.tr()
                                : 'dialogs.custom_color_btn'.tr(),
                          ),
                          style: isCustom
                              ? OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                  backgroundColor: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}

const _kCategories = [
  'Streaming', 'Music', 'Cloud', 'Productivity', 'Fitness', 'Gaming',
  'AI', 'Education', 'Security', 'Health', 'Transport', 'Food', 'Shopping',
  'Dating', 'Career', 'Social', 'Reading', 'News', 'Books', 'Developer',
  'Design', 'Marketing', 'E-commerce', 'Website', 'Lifestyle', 'Pet',
  'Beauty', 'Fashion', 'Sports', 'Bundle', 'Other',
];

void _showCategoryPicker(
  BuildContext context,
  String? current,
  void Function(String?) onSelected,
) {
  showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'detail.category'.tr(),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _kCategories.length,
                itemBuilder: (_, i) {
                  final cat = _kCategories[i];
                  final isSelected = cat == current;
                  return ListTile(
                    title: Text(cat),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      onSelected(cat == current ? null : cat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
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

    final nameController = useTextEditingController(text: liveSlice.name);
    final amountController = useTextEditingController(
      text: liveSlice.amount.toStringAsFixed(2),
    );
    final nameFocusNode = useFocusNode();
    final amountFocusNode = useFocusNode();

    useEffect(() {
      draft.value = liveSlice;
      if (nameController.text != liveSlice.name) {
        nameController.text = liveSlice.name;
      }
      final amtStr = liveSlice.amount.toStringAsFixed(2);
      if (amountController.text != amtStr) {
        amountController.text = amtStr;
      }
      return null;
    }, [liveSlice]);

    void saveUpdate(SubSlice updated) {
      final currentLength = ref.read(subsControllerProvider).value?.length ?? 0;
      if (index >= currentLength) return;
      draft.value = updated;
      ref.read(subsControllerProvider.notifier).updateAt(index, updated);
    }

    void onSaveName() {
      final trimmed = nameController.text.trim();
      if (trimmed.isEmpty) return;
      saveUpdate(draft.value.copyWith(name: trimmed));
    }

    void onSaveAmount() {
      final parsed = double.tryParse(
        amountController.text.replaceAll(',', '.'),
      );
      if (parsed == null || parsed < 0) return;
      saveUpdate(draft.value.copyWith(amount: parsed));
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
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context, ref, liveSlice, index),
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _HeroSection(
              slice: liveSlice,
              nameController: nameController,
              nameFocusNode: nameFocusNode,
              onSaveName: onSaveName,
              onTapColor: liveSlice.brand == null
                  ? () => _showColorPicker(
                        context,
                        draft.value.color,
                        (c) => saveUpdate(draft.value.copyWith(color: c)),
                      )
                  : null,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatCardsRow(
                slice: liveSlice,
                symbol: symbol,
                nextChargeDate: nextCharge,
                daysUntil: daysUntil,
                amountController: amountController,
                amountFocusNode: amountFocusNode,
                onSaveAmount: onSaveAmount,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DetailsSection(
                slice: draft.value,
                onTapFrequency: () => _showFrequencyPicker(context, draft.value, saveUpdate),
                onTapDate: () => _showDatePicker(context, draft.value, saveUpdate),
                onTapColor: draft.value.brand == null
                    ? () => _showColorPicker(
                          context,
                          draft.value.color,
                          (c) => saveUpdate(draft.value.copyWith(color: c)),
                        )
                    : null,
                onTapCategory: draft.value.brand == null
                    ? () => _showCategoryPicker(
                          context,
                          draft.value.category,
                          (cat) => saveUpdate(draft.value.copyWith(category: cat)),
                        )
                    : null,
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
  const _HeroSection({
    required this.slice,
    required this.nameController,
    required this.nameFocusNode,
    required this.onSaveName,
    this.onTapColor,
  });

  final SubSlice slice;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final VoidCallback onSaveName;
  final VoidCallback? onTapColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: slice.brand == null ? onTapColor : null,
            child: slice.brand != null
                ? BrandLogo(brand: slice.brand, size: 72)
                : Container(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slice.brand == null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: EditableText(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          cursorColor: theme.colorScheme.primary,
                          backgroundCursorColor: theme.colorScheme.onSurfaceVariant,
                          onSubmitted: (_) => onSaveName(),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  )
                else
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
    required this.amountController,
    required this.amountFocusNode,
    required this.onSaveAmount,
  });

  final SubSlice slice;
  final String symbol;
  final DateTime nextChargeDate;
  final int daysUntil;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final VoidCallback onSaveAmount;

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
            controller: amountController,
            focusNode: amountFocusNode,
            onSave: onSaveAmount,
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
    this.controller,
    this.focusNode,
    this.onSave,
  });

  final String label;
  final String value;
  final String sub;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onSave;

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
          if (controller != null && focusNode != null && onSave != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: EditableText(
                    onTapOutside: (event) {
                      if (focusNode!.hasFocus) {
                        focusNode!.unfocus();
                        onSave!();
                      }
                    },
                    controller: controller!,
                    focusNode: focusNode!,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: theme.colorScheme.primary,
                    backgroundCursorColor: theme.colorScheme.onSurfaceVariant,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (_) => onSave!(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            )
          else
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
    this.onTapColor,
    this.onTapCategory,
  });

  final SubSlice slice;
  final VoidCallback onTapFrequency;
  final VoidCallback onTapDate;
  final VoidCallback? onTapColor;
  final VoidCallback? onTapCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freqKey = slice.frequency.name.toLowerCase();
    final categoryValue = slice.brand != null
        ? (slice.brand!.category ?? 'detail.not_set'.tr())
        : (slice.category ?? 'detail.not_set'.tr());

    final rows = <Widget>[
      _DetailRow(
        label: 'detail.billing_cycle'.tr(),
        value: 'frequency.$freqKey'.tr(),
        hasChevron: true,
        onTap: onTapFrequency,
      ),
      _ColorDetailRow(color: Color(slice.color), onTap: onTapColor, hasChevron: onTapColor != null),
      _DetailRow(
        label: 'detail.started'.tr(),
        value: DateFormat('MMM d, y').format(slice.startDate),
        hasChevron: true,
        onTap: onTapDate,
      ),
      _DetailRow(
        label: 'detail.category'.tr(),
        value: categoryValue,
        hasChevron: onTapCategory != null,
        onTap: onTapCategory,
      ),
      _DetailRow(
        label: 'detail.payment_method'.tr(),
        value: 'detail.not_set'.tr(),
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

class _ColorDetailRow extends StatelessWidget {
  const _ColorDetailRow({required this.color, this.onTap, this.hasChevron = true});

  final Color color;
  final VoidCallback? onTap;
  final bool hasChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text('detail.color'.tr(), style: theme.textTheme.bodyMedium),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            if (hasChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
