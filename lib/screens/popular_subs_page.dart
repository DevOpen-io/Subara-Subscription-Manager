import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../config/router_config.dart';
import '../models/brand.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../providers/brands_provider.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/brand_utils.dart';
import '../widgets/brand_logo.dart';

int _colorForBrand(Brand brand) {
  final c = brand.iconColor;
  if (c != null) return c.toARGB32();
  final hash = brand.text.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.58, 0.45).toColor().toARGB32();
}

class PopularSubsPage extends HookConsumerWidget {
  const PopularSubsPage({super.key, required this.pageOffset});

  final double pageOffset;

  // Fixed header height — must stay in sync with _popularHeaderH in OnboardingScreen.
  // Adjust both if the overlay card doesn't land on the first tile.
  static const headerH = 160.0;
  static const _popularCount = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final brandsAsync = ref.watch(brandsProvider);
    final subsAsync = ref.watch(subsControllerProvider);
    final existingSubs = subsAsync.value ?? const <SubSlice>[];
    final currency = ref.watch(
      settingsControllerProvider.select(
        (v) => v.value?.currency ?? Currency.usd,
      ),
    );

    // Mirror ColorSchemePage's fade-in pattern for the first tile.
    final netflixOpacity = ((pageOffset - 1.0) * 3 - 2).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerH,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'intro.popular_eyebrow'.tr(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'intro.popular_title'.tr(),
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'intro.popular_subtitle'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: brandsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (brands) {
              final popular = brands.take(_popularCount).toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const ClampingScrollPhysics(),
                itemCount: popular.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final brand = popular[i];
                  final isAdded = existingSubs.any((s) => s.name == brand.text);
                  return Opacity(
                    opacity: i == 0 ? netflixOpacity : 1.0,
                    child: _PopularSubTile(
                      brand: brand,
                      isAdded: isAdded,
                      currencySymbol: currency.symbol,
                      onAdd: (amount) {
                        if (isAdded) return;
                        ref.read(subsControllerProvider.notifier).addSlice(
                          SubSlice(
                            name: brand.text,
                            amount: amount,
                            color: _colorForBrand(brand),
                            startDate: DateTime.now(),
                            brand: brand,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: FilledButton(
            onPressed: () {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateIsFirstTime(isFirstTime: false);
              context.go(Routes.home.route);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.inverseSurface,
              foregroundColor: cs.onInverseSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'intro.popular_cta'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopularSubTile extends HookWidget {
  const _PopularSubTile({
    required this.brand,
    required this.isAdded,
    required this.currencySymbol,
    required this.onAdd,
  });

  final Brand brand;
  final bool isAdded;
  final String currencySymbol;
  final void Function(double amount) onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountCtrl = useMemoized(TextEditingController.new);
    useEffect(() => amountCtrl.dispose, const []);
    useListenable(amountCtrl);

    final parsed =
        double.tryParse(amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
    final hasAmount = parsed > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          BrandLogo(brand: brand, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  brand.text,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand.category != null)
                  Text(
                    brand.category!,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              enabled: !isAdded,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: currencySymbol,
                prefixStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.30),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: cs.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasAmount && !isAdded ? () => onAdd(parsed) : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(isAdded),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isAdded
                      ? const Color(0xFF22C55E).withValues(alpha: 0.14)
                      : hasAmount
                          ? cs.primary.withValues(alpha: 0.10)
                          : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAdded ? Icons.check_rounded : Icons.add_rounded,
                  size: 15,
                  color: isAdded
                      ? const Color(0xFF22C55E)
                      : hasAmount
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
