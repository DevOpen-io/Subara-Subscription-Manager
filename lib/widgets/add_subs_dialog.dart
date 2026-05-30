import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/models/brand.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/brands_provider.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/color_palette.dart';
import 'package:subs_tracker/widgets/brand_logo.dart';

const _kPopularBrandNames = [
  'Netflix',
  'Spotify',
  'Amazon Prime',
  'YouTube Premium',
  'ChatGPT Plus',
  'Duolingo',
];

class AddSubsSheet extends HookConsumerWidget {
  const AddSubsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final searchCtrl = useTextEditingController();
    final nameCtrl = useTextEditingController();
    final amountCtrl = useTextEditingController();
    final brandFocusNode = useFocusNode();
    final theme = Theme.of(context);

    final draftSlice = useState<SubSlice>(
      SubSlice(
        brand: null,
        name: '',
        amount: 0,
        color: kSliceColors.first.toARGB32(),
        startDate: DateTime.now(),
      ),
    );

    final settingsAsync = ref.watch(settingsControllerProvider);
    final currencySymbol =
        settingsAsync.asData?.value.currency.symbol ?? '\$';

    void selectBrand(Brand brand) {
      draftSlice.value = draftSlice.value.copyWith(brand: brand, name: brand.text);
      nameCtrl.text = brand.text;
      searchCtrl.value = TextEditingValue(
        text: brand.text,
        selection: TextSelection.collapsed(offset: brand.text.length),
      );
      brandFocusNode.unfocus();
    }

    Future<void> openCustomColorPicker() async {
      Color tempColor = Color(draftSlice.value.color);
      final Color? result = await showDialog<Color>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog.adaptive(
                title: Text('dialogs.custom_color'.tr()),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: tempColor,
                    onColorChanged: (color) => setStateDialog(() {
                      tempColor = color;
                    }),
                    enableAlpha: false,
                    paletteType: PaletteType.hsvWithHue,
                    labelTypes: const [],
                    pickerAreaBorderRadius: const BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('dialogs.cancel'.tr()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, tempColor),
                    child: Text('dialogs.use_color'.tr()),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null) {
        draftSlice.value = draftSlice.value.copyWith(color: result.toARGB32());
      }
    }

    Widget buildSheetContent(List<Brand> allBrands) {
      final popularBrands = allBrands
          .where((b) => _kPopularBrandNames.contains(b.text))
          .toList()
        ..sort(
          (a, b) =>
              _kPopularBrandNames.indexOf(a.text) -
              _kPopularBrandNames.indexOf(b.text),
        );

      void submit() {
        if (formKey.currentState!.validate()) {
          final amount = double.parse(
            amountCtrl.text.replaceAll(',', '.'),
          );
          ref.read(subsControllerProvider.notifier).addSlice(
            draftSlice.value.copyWith(
              name: nameCtrl.text.trim(),
              amount: amount,
            ),
          );
          Navigator.pop(context);
        }
      }

      final labelStyle = theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      );

      final dividerColor =
          theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
            const SizedBox(height: 4),
            // Header: Cancel | Title | Save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      child: Text('dialogs.cancel'.tr()),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'dialogs.new_sub_title'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: TextButton(
                      onPressed: submit,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: Text('dialogs.save_btn'.tr()),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search bar
                      RawAutocomplete<Brand>(
                        textEditingController: searchCtrl,
                        focusNode: brandFocusNode,
                        displayStringForOption: (option) => option.text,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.trim().isEmpty) {
                            return const Iterable<Brand>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return allBrands.where(
                            (option) =>
                                option.text.toLowerCase().contains(query),
                          );
                        },
                        onSelected: (Brand selection) {
                          selectBrand(selection);
                        },
                        fieldViewBuilder: (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'dialogs.search_placeholder'.tr(
                                args: ['${allBrands.length}'],
                              ),
                              isDense: true,
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHigh,
                              prefixIcon: draftSlice.value.brand != null
                                  ? Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: BrandLogo(
                                        brand: draftSlice.value.brand,
                                        size: 30,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded),
                              suffixIcon: draftSlice.value.brand != null
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              if (draftSlice.value.brand != null &&
                                  draftSlice.value.brand!.text != value) {
                                draftSlice.value = draftSlice.value.copyWith(
                                  brand: null,
                                );
                              }
                            },
                            onSubmitted: (_) => onFieldSubmitted(),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.hardEdge,
                              elevation: 6,
                              child: SizedBox(
                                width: 360,
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 0),
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      leading: BrandLogo(
                                        brand: option,
                                        size: 40,
                                      ),
                                      title: Text(option.text),
                                      subtitle:
                                          option.category != null ||
                                              option.country != null
                                          ? Text(
                                              [
                                                if (option.category != null)
                                                  option.category!,
                                                if (option.country != null)
                                                  option.country!,
                                              ].join(' • '),
                                            )
                                          : null,
                                      trailing: const Icon(
                                        Icons.north_east,
                                        size: 18,
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Popular label
                      Text(
                        'dialogs.popular'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Popular brands grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.05,
                        children: popularBrands.map((brand) {
                          final isSelected =
                              draftSlice.value.brand?.text == brand.text;
                          return _PopularBrandCard(
                            brand: brand,
                            isSelected: isSelected,
                            onTap: () => selectBrand(brand),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // OR ENTER MANUALLY divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'dialogs.or_enter_manually'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Grouped form card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Name
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'dialogs.name_label'.tr(),
                                        style: labelStyle,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: nameCtrl,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        style: theme.textTheme.bodyMedium,
                                        validator: (value) =>
                                            (value == null ||
                                                    value.trim().isEmpty)
                                            ? 'dialogs.required'.tr()
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 0,
                                indent: 16,
                                color: dividerColor,
                              ),
                              // Price
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'dialogs.price_label'.tr(),
                                        style: labelStyle,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: amountCtrl,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          prefixText: currencySymbol,
                                          prefixStyle:
                                              theme.textTheme.bodyMedium,
                                        ),
                                        style: theme.textTheme.bodyMedium,
                                        validator: (v) {
                                          final d = double.tryParse(
                                            (v ?? '').replaceAll(',', '.'),
                                          );
                                          if (d == null || d < 0) {
                                            return 'dialogs.invalid_number'
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 0,
                                indent: 16,
                                color: dividerColor,
                              ),
                              // Cycle
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'dialogs.cycle_label'.tr(),
                                        style: labelStyle,
                                      ),
                                    ),
                                    Expanded(
                                      child: SegmentedButton<Frequency>(
                                        multiSelectionEnabled: false,
                                        showSelectedIcon: false,
                                        style: SegmentedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          visualDensity:
                                              VisualDensity.compact,
                                          textStyle:
                                              theme.textTheme.labelSmall,
                                        ),
                                        segments: Frequency.values.map((f) {
                                          return ButtonSegment<Frequency>(
                                            value: f,
                                            label: Text(
                                              'frequency.${f.name}'.tr(),
                                            ),
                                          );
                                        }).toList(),
                                        selected: {
                                          draftSlice.value.frequency,
                                        },
                                        onSelectionChanged: (s) {
                                          draftSlice.value =
                                              draftSlice.value.copyWith(
                                            frequency: s.first,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 0,
                                indent: 16,
                                color: dividerColor,
                              ),
                              // First charge
                              InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: draftSlice.value.startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    draftSlice.value =
                                        draftSlice.value.copyWith(
                                      startDate: pickedDate,
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          'dialogs.first_charge'.tr(),
                                          style: labelStyle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _formatDate(
                                            draftSlice.value.startDate,
                                          ),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Color section
                      Text(
                        'dialogs.slice_color'.tr(),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: kSliceColors.map((c) {
                          final isSelected =
                              c.toARGB32() == draftSlice.value.color;
                          return GestureDetector(
                            onTap: () => draftSlice.value =
                                draftSlice.value.copyWith(
                              color: c.toARGB32(),
                            ),
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
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.25),
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
                      const SizedBox(height: 12),
                      // Custom color
                      Builder(
                        builder: (context) {
                          final isCustomColor = !kSliceColors.any(
                            (c) => c.toARGB32() == draftSlice.value.color,
                          );
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: openCustomColorPicker,
                                  icon: Icon(
                                    isCustomColor
                                        ? Icons.check_circle
                                        : Icons.colorize,
                                  ),
                                  label: Text(
                                    isCustomColor
                                        ? 'dialogs.custom_color_selected'.tr()
                                        : 'dialogs.custom_color_btn'.tr(),
                                  ),
                                  style: isCustomColor
                                      ? OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                          backgroundColor: theme
                                              .colorScheme.primaryContainer
                                              .withValues(alpha: 0.3),
                                        )
                                      : null,
                                ),
                              ),
                              if (isCustomColor) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(draftSlice.value.color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
            // Sticky CTA
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('dialogs.add_title'.tr()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final brandsAsync = ref.watch(brandsProvider);

    return brandsAsync.when(
      data: (allBrands) => buildSheetContent(allBrands),
      loading: () => _SheetSkeleton(
        child: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => _SheetSkeleton(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('dialogs.error_loading'.tr(args: [err.toString()])),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('dialogs.close_btn'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

class _PopularBrandCard extends StatelessWidget {
  const _PopularBrandCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final Brand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2.0 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandLogo(brand: brand, size: 44),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                brand.text,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep old name as alias for backward compat with any un-migrated call sites
typedef AddSubsDialog = AddSubsSheet;

class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}
