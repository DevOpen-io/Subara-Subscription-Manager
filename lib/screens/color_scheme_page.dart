import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/utils/app_theme.dart';
import 'package:subs_tracker/widgets/color_scheme_picker.dart';
import 'package:subs_tracker/widgets/floating_sub_card.dart';

class ColorSchemePage extends ConsumerWidget {
  const ColorSchemePage({super.key, this.pageOffset = 0.0});

  final double pageOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(
      settingsControllerProvider.select(
        (v) => v.value?.colorScheme ?? FlexScheme.bahamaBlue,
      ),
    );
    final primaryColor = FlexColor.schemes[scheme]!.light.primary;
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated preview: radial glow + floating card
        Expanded(
          flex: 3,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: primaryColor),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (ctx, c, _) {
                final col = c ?? primaryColor;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 264,
                      height: 264,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            col.withValues(alpha: 0.30),
                            col.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Fades in as overlay card arrives
                    Opacity(
                      opacity: (pageOffset * 3 - 2).clamp(0.0, 1.0),
                      child: IgnorePointer(
                        child: FloatingSubCard(
                          name: 'Netflix',
                          amount: '£8.99',
                          label: 'Renews\nsoon',
                          cardColor: col,
                          textColor: Colors.white,
                          logoColor: Colors.white.withValues(alpha: 0.22),
                          logoInitials: 'N',
                          logoIcon: SimpleIcons.values['netflix'],
                          phaseOffset: 0.3,
                          width: 178,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Copy + animated scheme name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'intro.color_scheme_eyebrow'.tr(),
                style: textTheme.labelSmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'intro.color_scheme_title'.tr(),
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'intro.color_scheme_subtitle'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _SchemeNameChip(
                  key: ValueKey(scheme),
                  name: schemeDisplayName(scheme),
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        ColorSchemePicker(
          selectedScheme: scheme,
          onSchemeSelected: (s) =>
              ref.read(settingsControllerProvider.notifier).updateColorScheme(s),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SchemeNameChip extends StatelessWidget {
  const _SchemeNameChip({
    super.key,
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
