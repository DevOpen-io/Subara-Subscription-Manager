import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:simple_icons/simple_icons.dart';
import '../widgets/floating_sub_card.dart';

class IntroPage extends HookWidget {
  const IntroPage({
    super.key,
    required this.onGetStarted,
    this.pageOffset = 0.0,
  });

  final VoidCallback onGetStarted;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final darkCard = cs.inverseSurface;
    final darkCardText = cs.onInverseSurface;
    final lightCard = cs.surfaceContainerLow;
    final lightCardText = cs.onSurface;

    final tiltTarget = useRef<Offset>(Offset.zero);
    final tiltSmooth = useState<Offset>(Offset.zero);

    final lerpController = useAnimationController(
      duration: const Duration(seconds: 1),
    )..repeat();

    useEffect(() {
      void onTick() {
        final c = tiltSmooth.value;
        final t = tiltTarget.value;
        tiltSmooth.value = Offset(
          lerpDouble(c.dx, t.dx, 0.10)!,
          lerpDouble(c.dy, t.dy, 0.10)!,
        );
      }
      lerpController.addListener(onTick);
      return () => lerpController.removeListener(onTick);
    }, [lerpController]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Floating cards illustration
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (event) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final s = box.size;
              tiltTarget.value = Offset(
                ((event.localPosition.dx / s.width) * 2 - 1).clamp(-1.0, 1.0),
                ((event.localPosition.dy / s.height) * 2 - 1).clamp(-1.0, 1.0),
              );
            },
            onPointerUp: (_) => tiltTarget.value = Offset.zero,
            onPointerCancel: (_) => tiltTarget.value = Offset.zero,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(-tiltSmooth.value.dy * 0.2)
                ..rotateY(tiltSmooth.value.dx * 0.2),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Netflix — top-left (fades out as overlay card takes over)
                  Opacity(
                    opacity: (1.0 - pageOffset * 3).clamp(0.0, 1.0),
                    child: Align(
                      alignment: const Alignment(-0.68, -0.75),
                      child: FloatingSubCard(
                        rotation: -0.18,
                        name: 'Netflix',
                        amount: '£8.99',
                        label: 'Renews\nsoon',
                        cardColor: darkCard,
                        textColor: darkCardText,
                        logoColor: const Color(0xFFE50914),
                        logoInitials: 'N',
                        logoIcon: SimpleIcons.values['netflix'],
                      ),
                    ),
                  ),
                  // Spotify — top-right
                  Align(
                    alignment: const Alignment(0.60, -0.72),
                    child: FloatingSubCard(
                      rotation: 0.15,
                      name: 'Spotify',
                      amount: '£16.99',
                      label: 'Renews\nsoon',
                      cardColor: lightCard,
                      textColor: lightCardText,
                      logoColor: const Color(0xFF1DB954),
                      logoInitials: 'S',
                      logoIcon: SimpleIcons.values['spotify'],
                      phaseOffset: 0.2,
                    ),
                  ),
                  // Xbox Game Pass — center
                  Align(
                    alignment: const Alignment(-0.10, 0.10),
                    child: FloatingSubCard(
                      rotation: 0.07,
                      name: 'Xbox G...',
                      amount: '£11.00',
                      label: 'Today',
                      cardColor: const Color(0xFF107C10),
                      textColor: Colors.white,
                      logoColor: cs.surface,
                      logoInitials: 'X',
                      width: 158,
                      phaseOffset: 0.4,
                    ),
                  ),
                  // Amazon — bottom-left
                  Align(
                    alignment: const Alignment(-0.62, 0.68),
                    child: FloatingSubCard(
                      rotation: -0.13,
                      name: 'Ama...',
                      amount: '£12.49',
                      label: 'Renews\nsoon',
                      cardColor: lightCard,
                      textColor: lightCardText,
                      logoColor: const Color(0xFF00A8E0),
                      logoInitials: 'a',
                      logoIcon: SimpleIcons.values['amazonprime'],
                      width: 148,
                      phaseOffset: 0.6,
                    ),
                  ),
                  // GitHub — bottom-right
                  Align(
                    alignment: const Alignment(0.65, 0.62),
                    child: FloatingSubCard(
                      rotation: 0.19,
                      name: 'GitH...',
                      amount: '£10.00',
                      label: 'Renews\nsoon',
                      cardColor: darkCard,
                      textColor: darkCardText,
                      logoColor: cs.surface,
                      logoInitials: 'GH',
                      logoIcon: SimpleIcons.values['github'],
                      width: 148,
                      phaseOffset: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Copy section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coral eyebrow
                Text(
                  'intro.eyebrow'.tr(),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Big headline with coral accent phrase
                RichText(
                  text: TextSpan(
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: cs.onSurface,
                    ),
                    children: [
                      TextSpan(text: '${'intro.headline'.tr()} '),
                      TextSpan(
                        text: 'intro.headline_accent'.tr(),
                        style: TextStyle(color: cs.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'intro.subtitle'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Ink CTA button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FilledButton(
            onPressed: onGetStarted,
            style: FilledButton.styleFrom(
              backgroundColor: cs.inverseSurface,
              foregroundColor: cs.onInverseSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'intro.get_started'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ],
            ),
          ),
        ),

        // Secondary: Restore from backup
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Center(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restore from backup — coming soon')),
                );
              },
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(text: '${'intro.already_user'.tr()} '),
                    TextSpan(
                      text: 'intro.restore_backup'.tr(),
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
