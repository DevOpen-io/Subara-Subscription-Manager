import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/billing.dart';
import '../models/categories.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/billing_labels.dart';
import '../utils/color_palette.dart';
import '../utils/manage_url.dart';
import '../utils/payment_methods.dart';
import '../widgets/brand_logo.dart';
import '../widgets/exchange_rate_dialog.dart';
import '../widgets/status_picker.dart';

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

/// `paid` is null for auto-renewing subscriptions (always paid).
typedef _Payment = ({DateTime date, double amount, String symbol, bool? paid});

/// Recent charges with the price (and currency) in force on each.
List<_Payment> _paymentHistory(SubSlice slice, Currency main) => [
  for (final p in slice.paymentHistory(DateTime.now()))
    (
      date: p.date,
      amount: p.amount,
      symbol: (p.currency ?? main).symbol,
      paid: slice.autoRenew ? null : slice.isPaid(p.date),
    ),
];

// ---------------------------------------------------------------------------
// Picker helpers
// ---------------------------------------------------------------------------

/// Two wheels: "every N" and the period unit, saved as they change.
void _showFrequencyPicker(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  const frequencies = Frequency.values;
  var current = draft;

  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final textStyle = TextStyle(color: theme.colorScheme.onSurface);
      return StatefulBuilder(
        builder: (ctx, setState) {
          void update(SubSlice next) {
            setState(() => current = next);
            onUpdate(next);
          }

          return Container(
            height: 290,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Text(
                      current.cycleLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem:
                                  current.period.clamp(
                                    1,
                                    SubSlice.maxInterval,
                                  ) -
                                  1,
                            ),
                            onSelectedItemChanged: (i) =>
                                update(current.copyWith(interval: i + 1)),
                            children: List.generate(
                              SubSlice.maxInterval,
                              (i) => Center(
                                child: Text('${i + 1}', style: textStyle),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: frequencies.indexOf(
                                current.frequency,
                              ),
                            ),
                            onSelectedItemChanged: (i) => update(
                              current.copyWith(frequency: frequencies[i]),
                            ),
                            children: [
                              for (final f in frequencies)
                                Center(
                                  child: Text(
                                    'frequency.unit.${f.name}'.plural(
                                      current.period,
                                    ),
                                    style: textStyle,
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
            ),
          );
        },
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
            ref.read(subsControllerProvider.notifier).removeSlice(liveSlice.id);
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
            var temp = currentColor;
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
                      labelTypes: const [],
                      pickerAreaBorderRadius: const BorderRadius.all(
                        Radius.circular(12),
                      ),
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
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
                      final isSelected =
                          c.toARGB32() == currentColor.toARGB32();
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
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
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
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
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
                          icon: Icon(
                            isCustom ? Icons.check_circle : Icons.colorize,
                          ),
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
                                  backgroundColor: theme
                                      .colorScheme
                                      .primaryContainer
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

/// Built-in and user categories; users can add new ones and remove their
/// own (long list, so a scrollable sheet).
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
    builder: (sheetCtx) => _CategorySheet(
      current: current,
      onSelected: (cat) {
        Navigator.of(sheetCtx).pop();
        onSelected(cat);
      },
    ),
  );
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({required this.current, required this.onSelected});

  final String? current;
  final ValueChanged<String?> onSelected;

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    if (name == null) return;
    // An existing (or built-in) name isn't added again, just selected.
    ref.read(settingsControllerProvider.notifier).addCategory(name);
    onSelected(name.trim());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final custom =
        ref.watch(settingsControllerProvider).value?.customCategories ??
        const <String>[];
    final all = [...builtInCategories, ...custom];
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
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'detail.category'.tr(),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addCategory(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('detail.category_add'.tr()),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: all.length,
              itemBuilder: (_, i) {
                final cat = all[i];
                final isCustom = i >= builtInCategories.length;
                final isSelected = cat == current;
                return ListTile(
                  title: Text(cat),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(Icons.check, color: theme.colorScheme.primary),
                      if (isCustom)
                        IconButton(
                          tooltip: 'detail.category_remove'.tr(),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref
                              .read(settingsControllerProvider.notifier)
                              .removeCategory(cat),
                        ),
                    ],
                  ),
                  onTap: () => onSelected(cat == current ? null : cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCategoryDialog extends HookWidget {
  const _NewCategoryDialog();

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    void save() {
      if (controller.text.trim().isEmpty) return;
      Navigator.of(context).pop(controller.text);
    }

    return AlertDialog.adaptive(
      title: Text('detail.category_add'.tr()),
      content: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 30,
          decoration: InputDecoration(hintText: 'detail.category_hint'.tr()),
          onSubmitted: (_) => save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('dialogs.cancel'.tr()),
        ),
        FilledButton(onPressed: save, child: Text('common.save'.tr())),
      ],
    );
  }
}

const _reminderDayOptions = [1, 3, 7];

/// Reminder mode plus how many days ahead the "before" reminder fires.
void _showReminderPicker(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  var current = draft;
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        void update(SubSlice next) {
          setState(() => current = next);
          onUpdate(next);
        }

        final hasBefore =
            current.reminderMode == ReminderMode.dayBefore ||
            current.reminderMode == ReminderMode.both;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'detail.reminder_when'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final mode in ReminderMode.values)
                _ReminderModeTile(
                  label: switch (mode) {
                    ReminderMode.none => 'detail.reminder_none'.tr(),
                    ReminderMode.onDay => 'detail.reminder_onDay'.tr(),
                    ReminderMode.dayBefore => daysBeforeLabel(
                      current.daysBefore,
                    ),
                    ReminderMode.both =>
                      current
                          .copyWith(reminderMode: ReminderMode.both)
                          .reminderLabel,
                  },
                  selected: mode == current.reminderMode,
                  onTap: () => update(current.copyWith(reminderMode: mode)),
                ),
              _SnoozeRow(
                snoozedUntil: current.remindersSnoozedUntil,
                onSnooze: (until) =>
                    update(current.copyWith(remindersSnoozedUntil: until)),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: hasBefore
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'detail.reminder_how_early'.tr(),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: [
                                for (final d in _reminderDayOptions)
                                  ButtonSegment(value: d, label: Text('$d')),
                              ],
                              selected: {current.daysBefore},
                              emptySelectionAllowed: true,
                              onSelectionChanged: (s) {
                                if (s.isEmpty) return;
                                update(
                                  current.copyWith(remindDaysBefore: s.first),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}

/// "Snooze 1 week / 1 month", or "Snoozed until … — Resume".
class _SnoozeRow extends StatelessWidget {
  const _SnoozeRow({required this.snoozedUntil, required this.onSnooze});

  final DateTime? snoozedUntil;
  final ValueChanged<DateTime?> onSnooze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final until = snoozedUntil;
    final active = until != null && until.isAfter(now);
    DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.snooze,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active
                  ? 'detail.snoozed_until'.tr(
                      args: [
                        DateFormat(
                          'MMM d',
                          context.locale.toString(),
                        ).format(until),
                      ],
                    )
                  : 'detail.snooze'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (active)
            TextButton(
              onPressed: () => onSnooze(null),
              child: Text('detail.snooze_resume'.tr()),
            )
          else ...[
            ActionChip(
              label: Text('detail.snooze_week'.tr()),
              visualDensity: VisualDensity.compact,
              onPressed: () => onSnooze(inDays(7)),
            ),
            const SizedBox(width: 6),
            ActionChip(
              label: Text('detail.snooze_month'.tr()),
              visualDensity: VisualDensity.compact,
              onPressed: () => onSnooze(inDays(30)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderModeTile extends StatelessWidget {
  const _ReminderModeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      leading: selected
          ? Icon(
              Icons.radio_button_checked,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}

const _maxPeopleOption = 10;

/// "Just me", "2 people", ... — how many split the cost.
void _showSharedPicker(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'detail.shared_with'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: _maxPeopleOption,
                  itemBuilder: (_, i) {
                    final n = i + 1;
                    return ListTile(
                      title: Text(_sharedLabel(n)),
                      trailing: n == draft.people
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onUpdate(draft.copyWith(sharedWith: n));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _sharedLabel(int people) => people <= 1
    ? 'detail.shared_just_me'.tr()
    : 'detail.shared_people'.plural(people);

/// Edits the manage/cancel link; only http(s) links are accepted.
void _showManageUrlInput(
  BuildContext context,
  String? current,
  ValueChanged<String?> onSelected,
) {
  final controller = TextEditingController(text: current ?? '');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setState) {
          void save() {
            final text = controller.text.trim();
            if (text.isEmpty) {
              Navigator.of(ctx).pop();
              onSelected(null);
              return;
            }
            final url = normalizeManageUrl(text);
            if (url == null) {
              setState(() => error = 'detail.manage_invalid'.tr());
              return;
            }
            Navigator.of(ctx).pop();
            onSelected(url);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'detail.manage_link'.tr(),
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'detail.manage_hint'.tr(),
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (current != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onSelected(null);
                        },
                        child: Text('detail.manage_remove'.tr()),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: save,
                      child: Text('common.save'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}

/// Picks the billing currency; a foreign one without a rate asks for it
/// right away, so the subscription can be counted in totals.
void _pickCurrency(
  BuildContext context,
  WidgetRef ref,
  SettingsViewModel settings,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  final options = <Currency?>[null, ...Currency.values];
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'detail.currency'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final c = options[i];
                    return ListTile(
                      title: Text(
                        c == null
                            ? 'detail.currency_main'.tr(
                                args: [settings.currency.symbol],
                              )
                            : '${c.label} (${c.symbol})',
                      ),
                      trailing: c == draft.currency
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () async {
                        Navigator.of(sheetCtx).pop();
                        // Same as main is stored as "follow main".
                        final picked = c == settings.currency ? null : c;
                        onUpdate(draft.copyWith(currency: picked));
                        if (picked == null ||
                            settings.hasRate(picked) ||
                            !context.mounted) {
                          return;
                        }
                        final edit = await showExchangeRateDialog(
                          context,
                          from: picked,
                          main: settings.currency,
                        );
                        if (edit is RateSet) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setExchangeRate(picked, edit.rate);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmRemovePriceChange(
  BuildContext context,
  VoidCallback remove,
) => showCupertinoDialog<void>(
  context: context,
  builder: (ctx) => CupertinoAlertDialog(
    title: Text('detail.price_change_delete_title'.tr()),
    content: Text('detail.price_change_delete_body'.tr()),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text('detail.cancel'.tr()),
      ),
      CupertinoDialogAction(
        isDestructiveAction: true,
        onPressed: () {
          remove();
          Navigator.of(ctx).pop();
        },
        child: Text('detail.delete_action'.tr()),
      ),
    ],
  ),
);

Future<void> _openManageUrl(BuildContext context, String? url) async {
  final uri = safeManageUri(url);
  final messenger = ScaffoldMessenger.of(context);
  final opened =
      uri != null &&
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).catchError((Object _) => false);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('detail.manage_open_failed'.tr())),
    );
  }
}

void _showTrialEndPicker(
  BuildContext context,
  DateTime? current,
  ValueChanged<DateTime> onSelected,
) {
  var selected = current ?? DateTime.now();
  showCupertinoModalPopup<DateTime?>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('detail.cancel'.tr()),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: Text('common.save'.tr()),
                  onPressed: () => Navigator.of(ctx).pop(selected),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                onDateTimeChanged: (date) => selected = date,
              ),
            ),
          ],
        ),
      );
    },
  ).then((result) {
    if (result != null) onSelected(result);
  });
}

const _paymentSuggestionKeys = [
  'credit_card',
  'debit_card',
  'paypal',
  'apple_pay',
  'google_pay',
  'bank_transfer',
];

/// Payment method label (with suggestions) plus the card's last 4 digits.
void _showPaymentInput(
  BuildContext context,
  SubSlice draft,
  void Function(SubSlice) onUpdate,
) {
  final method = TextEditingController(text: draft.paymentMethod ?? '');
  final card = TextEditingController(text: draft.cardLastFour ?? '');
  String? clean(String v) => v.trim().isEmpty ? null : v.trim();
  void save(BuildContext ctx) {
    Navigator.of(ctx).pop();
    onUpdate(
      draft.copyWith(
        paymentMethod: clean(method.text),
        cardLastFour: clean(card.text),
      ),
    );
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'detail.payment_method'.tr(),
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: method,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'detail.payment_method_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final key in _paymentSuggestionKeys)
                  ActionChip(
                    label: Text('payment_methods.$key'.tr()),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => method.text = 'payment_methods.$key'.tr(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: card,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'detail.card_hint'.tr(),
                hintText: '1234',
                prefixText: '•••• ',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => save(ctx),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => save(ctx),
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    method.dispose();
    card.dispose();
  });
}

void _showNoteInput(
  BuildContext context,
  String? current,
  ValueChanged<String?> onSelected,
) {
  final controller = TextEditingController(text: current ?? '');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'detail.note'.tr(),
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'detail.note_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final trimmed = controller.text.trim();
                onSelected(trimmed.isEmpty ? null : trimmed);
              },
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      );
    },
  ).whenComplete(controller.dispose);
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class SubDetailScreen extends HookConsumerWidget {
  const SubDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesAsync = ref.watch(subsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    final liveSlice = slicesAsync.value?.where((s) => s.id == id).firstOrNull;
    if (liveSlice == null) {
      // Deleted (or not loaded yet); the screen is about to be popped.
      return const Scaffold();
    }
    final settings = settingsAsync.value;
    final symbol = settings?.currencyOf(liveSlice).symbol ?? '';

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
      draft.value = updated;
      ref.read(subsControllerProvider.notifier).updateSlice(updated);
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

    final nextCharge = liveSlice.nextChargeDate(DateTime.now());
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final nextChargeMidnight = DateTime(
      nextCharge.year,
      nextCharge.month,
      nextCharge.day,
    );
    final daysUntil = nextChargeMidnight.difference(todayMidnight).inDays;

    final main = settings?.currency ?? Currency.try_;
    final history = _paymentHistory(liveSlice, main);
    final priceChanges = liveSlice.priceChanges;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
          label: Text(
            'detail.back'.tr(),
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
        ),
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context, ref, liveSlice),
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
              onTapColor: () => _showColorPicker(
                context,
                draft.value.color,
                (c) => saveUpdate(draft.value.copyWith(color: c)),
              ),
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
            if (liveSlice.unpaidCharge(DateTime.now()) case final charge?) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PaymentDueCard(
                  charge: charge,
                  overdue: liveSlice.isOverdue(DateTime.now()),
                  onMarkPaid: () => ref
                      .read(subsControllerProvider.notifier)
                      .markPaid(liveSlice.id, charge, paid: true),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DetailsSection(
                slice: draft.value,
                onTapFrequency: () =>
                    _showFrequencyPicker(context, draft.value, saveUpdate),
                onTapDate: () =>
                    _showDatePicker(context, draft.value, saveUpdate),
                onTapColor: () => _showColorPicker(
                  context,
                  draft.value.color,
                  (c) => saveUpdate(draft.value.copyWith(color: c)),
                ),
                onTapCategory: draft.value.brand == null
                    ? () => _showCategoryPicker(
                        context,
                        draft.value.category,
                        (cat) =>
                            saveUpdate(draft.value.copyWith(category: cat)),
                      )
                    : null,
                onTapReminder: () =>
                    _showReminderPicker(context, draft.value, saveUpdate),
                mainCurrency: settings?.currency,
                onTapCurrency: settings == null
                    ? null
                    : () => _pickCurrency(
                        context,
                        ref,
                        settings,
                        draft.value,
                        saveUpdate,
                      ),
                onTapShared: () =>
                    _showSharedPicker(context, draft.value, saveUpdate),
                onAutoRenewChanged: (v) =>
                    saveUpdate(draft.value.copyWith(autoRenew: v)),
                onTapManageUrl: () => _showManageUrlInput(
                  context,
                  draft.value.manageUrl,
                  (url) => saveUpdate(draft.value.copyWith(manageUrl: url)),
                ),
                onTapCard: () =>
                    _showPaymentInput(context, draft.value, saveUpdate),
                onTapNote: () => _showNoteInput(
                  context,
                  draft.value.note,
                  (val) => saveUpdate(draft.value.copyWith(note: val)),
                ),
                onTapStatus: () => showStatusPicker(
                  context,
                  draft.value.status,
                  (status) => saveUpdate(draft.value.copyWith(status: status)),
                ),
                onTapTrialEnds: () => _showTrialEndPicker(
                  context,
                  draft.value.trialEndDate,
                  (date) =>
                      saveUpdate(draft.value.copyWith(trialEndDate: date)),
                ),
              ),
            ),
            if (safeManageUri(liveSlice.manageUrl) != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FilledButton.tonalIcon(
                  onPressed: () => _openManageUrl(context, liveSlice.manageUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text('detail.manage_open'.tr()),
                ),
              ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PaymentHistorySection(
                history: history,
                onTogglePaid: (date, {required paid}) => ref
                    .read(subsControllerProvider.notifier)
                    .markPaid(liveSlice.id, date, paid: paid),
              ),
            ),
            if (priceChanges.isNotEmpty) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PriceChangesSection(
                  changes: priceChanges,
                  main: main,
                  onRemove: (at) => _confirmRemovePriceChange(
                    context,
                    () => ref
                        .read(subsControllerProvider.notifier)
                        .removePriceChange(liveSlice.id, at),
                  ),
                ),
              ),
            ],
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
        children: [
          GestureDetector(
            onTap: onTapColor,
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
                        slice.name.isNotEmpty
                            ? slice.name[0].toUpperCase()
                            : '?',
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
                    children: [
                      Expanded(
                        child: EditableText(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          cursorColor: theme.colorScheme.primary,
                          backgroundCursorColor:
                              theme.colorScheme.onSurfaceVariant,
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
                if (slice.status != SubStatus.active) ...[
                  const SizedBox(height: 6),
                  StatusBadge(status: slice.status),
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
    final costSub = slice.people > 1
        ? '${slice.cycleLabel} · ${'detail.your_share'.tr(args: ['$symbol${slice.myAmount.toStringAsFixed(2)}'])}'
        : slice.cycleLabel;
    final cancelledAt = slice.cancelledAt;
    final showSaved =
        slice.status == SubStatus.cancelled && cancelledAt != null;

    // Paused/cancelled subscriptions have no upcoming charge.
    final charges =
        slice.status != SubStatus.paused && slice.status != SubStatus.cancelled;
    final nextSub = !charges
        ? ''
        : daysUntil == 0
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
            prefix: symbol,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: showSaved
              ? _StatCard(
                  label: 'detail.saved'.tr(),
                  value:
                      '$symbol${(slice.savedSinceCancel(DateTime.now()) / slice.people).toStringAsFixed(2)}',
                  sub: 'detail.saved_since'.tr(
                    args: [
                      DateFormat(
                        'MMM d',
                        context.locale.toString(),
                      ).format(cancelledAt),
                    ],
                  ),
                )
              : _StatCard(
                  label: 'detail.next_charge'.tr(),
                  value: charges
                      ? DateFormat(
                          'MMM d',
                          context.locale.toString(),
                        ).format(nextChargeDate)
                      : '—',
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
    this.prefix,
  });

  /// Shown before the editable value (the currency symbol).
  final String? prefix;
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
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => focusNode!.requestFocus(),
              child: Row(
                children: [
                  if (prefix != null)
                    Text(
                      prefix!,
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
              ),
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
    required this.onTapReminder,
    required this.onTapCard,
    required this.onTapStatus,
    required this.onTapTrialEnds,
    required this.onTapNote,
    required this.onTapManageUrl,
    required this.onTapShared,
    required this.onAutoRenewChanged,
    this.mainCurrency,
    this.onTapCurrency,
  });

  final SubSlice slice;
  final Currency? mainCurrency;
  final VoidCallback? onTapCurrency;
  final VoidCallback onTapFrequency;
  final VoidCallback onTapDate;
  final VoidCallback? onTapColor;
  final VoidCallback? onTapCategory;
  final VoidCallback onTapReminder;
  final VoidCallback onTapCard;
  final VoidCallback onTapStatus;
  final VoidCallback onTapTrialEnds;
  final VoidCallback onTapNote;
  final VoidCallback onTapManageUrl;
  final VoidCallback onTapShared;
  final ValueChanged<bool> onAutoRenewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryValue = slice.brand != null
        ? (slice.brand!.category ?? 'detail.not_set'.tr())
        : (slice.category ?? 'detail.not_set'.tr());

    final rows = <Widget>[
      _DetailRow(
        label: 'detail.billing_cycle'.tr(),
        value: slice.cycleLabel,
        hasChevron: true,
        onTap: onTapFrequency,
      ),
      _DetailRow(
        label: 'detail.status'.tr(),
        value: 'detail.status_${slice.status.name}'.tr(),
        hasChevron: true,
        onTap: onTapStatus,
      ),
      if (slice.status == SubStatus.freeTrial)
        _DetailRow(
          label: 'detail.trial_ends'.tr(),
          value: slice.trialEndDate != null
              ? DateFormat(
                  'MMM d, y',
                  context.locale.toString(),
                ).format(slice.trialEndDate!)
              : 'detail.not_set'.tr(),
          hasChevron: true,
          onTap: onTapTrialEnds,
        ),
      _ColorDetailRow(
        color: Color(slice.color),
        onTap: onTapColor,
        hasChevron: onTapColor != null,
      ),
      _DetailRow(
        label: 'detail.started'.tr(),
        value: DateFormat(
          'MMM d, y',
          context.locale.toString(),
        ).format(slice.startDate),
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
        value: paymentLabel(
          slice.paymentMethod,
          slice.cardLastFour,
          notSet: 'detail.not_set'.tr(),
        ),
        hasChevron: true,
        onTap: onTapCard,
      ),
      _DetailRow(
        label: 'detail.reminder'.tr(),
        value: switch (slice.remindersSnoozedUntil) {
          final until? when until.isAfter(DateTime.now()) =>
            'detail.snoozed_until'.tr(
              args: [
                DateFormat('MMM d', context.locale.toString()).format(until),
              ],
            ),
          _ => slice.reminderLabel,
        },
        hasChevron: true,
        onTap: onTapReminder,
      ),
      _SwitchDetailRow(
        label: 'detail.auto_renew'.tr(),
        value: slice.autoRenew,
        onChanged: onAutoRenewChanged,
      ),
      _DetailRow(
        label: 'detail.shared_with'.tr(),
        value: _sharedLabel(slice.people),
        hasChevron: true,
        onTap: onTapShared,
      ),
      _DetailRow(
        label: 'detail.currency'.tr(),
        value: switch ((slice.currency, mainCurrency)) {
          (final Currency c, _) => '${c.label} (${c.symbol})',
          (null, final Currency m) => 'detail.currency_main'.tr(
            args: [m.symbol],
          ),
          (null, null) => 'detail.not_set'.tr(),
        },
        hasChevron: onTapCurrency != null,
        onTap: onTapCurrency,
      ),
      _DetailRow(
        label: 'detail.manage_link'.tr(),
        value: safeManageUri(slice.manageUrl)?.host ?? 'detail.not_set'.tr(),
        hasChevron: true,
        onTap: onTapManageUrl,
      ),
      _DetailRow(
        label: 'detail.note'.tr(),
        value: slice.note ?? 'detail.not_set'.tr(),
        hasChevron: true,
        onTap: onTapNote,
      ),
    ];

    final separated = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      separated.add(rows[i]);
      if (i < rows.length - 1) {
        separated.add(const Divider(height: 1, indent: 16, endIndent: 16));
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
            ),
            child: Column(children: separated),
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
  const _ColorDetailRow({
    required this.color,
    this.onTap,
    this.hasChevron = true,
  });

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
                ),
              ),
            ),
            if (hasChevron) ...[
              const SizedBox(width: 8),
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
    required this.onTogglePaid,
  });

  final List<_Payment> history;

  /// Marks a manual charge paid / unpaid.
  final void Function(DateTime date, {required bool paid}) onTogglePaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <Widget>[];
    for (var i = 0; i < history.length; i++) {
      final p = history[i];
      rows.add(
        _PaymentHistoryRow(
          date: p.date,
          amount: p.amount,
          symbol: p.symbol,
          paid: p.paid,
          onTap: p.paid == null
              ? null
              : () => onTogglePaid(p.date, paid: !p.paid!),
        ),
      );
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
            child: DecoratedBox(
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
    this.paid,
    this.onTap,
  });

  final DateTime date;
  final double amount;
  final String symbol;

  /// null: auto-renewing (shown as paid, not tappable).
  final bool? paid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unpaid = paid == false;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: unpaid
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                unpaid ? Icons.schedule : Icons.check,
                size: 16,
                color: unpaid
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMM dd', context.locale.toString()).format(date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (unpaid) ...[
              const SizedBox(width: 8),
              Text(
                'home.unpaid'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const Spacer(),
            Text(
              '$symbol${amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Payment due Nov 10 — Mark paid" for a manually paid subscription.
class _PaymentDueCard extends StatelessWidget {
  const _PaymentDueCard({
    required this.charge,
    required this.overdue,
    required this.onMarkPaid,
  });

  final DateTime charge;
  final bool overdue;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('MMM d', context.locale.toString()).format(charge);
    final fg = overdue
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: overdue
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.schedule,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              overdue
                  ? 'detail.payment_overdue'.tr(args: [date])
                  : 'detail.payment_due'.tr(args: [date]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onMarkPaid,
            child: Text('detail.mark_paid'.tr()),
          ),
        ],
      ),
    );
  }
}

/// A details row with a switch instead of a chevron.
class _SwitchDetailRow extends StatelessWidget {
  const _SwitchDetailRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price changes section
// ---------------------------------------------------------------------------

class _PriceChangesSection extends StatelessWidget {
  const _PriceChangesSection({
    required this.changes,
    required this.main,
    required this.onRemove,
  });

  final List<({DateTime at, Price from, Price to})> changes;
  final Currency main;

  /// Called with the change time when a row is tapped.
  final ValueChanged<DateTime> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < changes.length; i++) {
      final c = changes[i];
      rows.add(
        _PriceChangeRow(
          at: c.at,
          from:
              '${(c.from.currency ?? main).symbol}${c.from.amount.toStringAsFixed(2)}',
          to: '${(c.to.currency ?? main).symbol}${c.to.amount.toStringAsFixed(2)}',
          // Only comparable when both prices are in the same currency.
          increase: c.from.currency == c.to.currency
              ? c.to.amount > c.from.amount
              : null,
          onTap: () => onRemove(c.at),
        ),
      );
      if (i < changes.length - 1) {
        rows.add(const Divider(height: 1, indent: 16, endIndent: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'detail.section_price_changes'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
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

class _PriceChangeRow extends StatelessWidget {
  const _PriceChangeRow({
    required this.at,
    required this.from,
    required this.to,
    required this.increase,
    required this.onTap,
  });

  final VoidCallback onTap;
  final DateTime at;
  final String from;
  final String to;

  /// null when the currencies differ.
  final bool? increase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (increase) {
      true => theme.colorScheme.error,
      false => Colors.green.shade600,
      null => theme.colorScheme.onSurfaceVariant,
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                switch (increase) {
                  true => Icons.trending_up,
                  false => Icons.trending_down,
                  null => Icons.swap_horiz,
                },
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMM d, y', context.locale.toString()).format(at),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              from,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              to,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
