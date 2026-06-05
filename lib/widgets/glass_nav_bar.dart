import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';

const _snappyMotion = CupertinoMotion.snappy();
final _springCurve = MotionCurve(motion: _snappyMotion);

class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final void Function(int) onTap;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    (icon: Icons.home, labelKey: 'menu.home'),
    (icon: Icons.calendar_month, labelKey: 'menu.calendar'),
    (icon: Icons.analytics, labelKey: 'menu.analytics'),
    (icon: Icons.settings, labelKey: 'menu.settings'),
  ];

  late final AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _snappyMotion.duration,
    );
    final idx = widget.selectedIndex.toDouble();
    _position = Tween<double>(begin: idx, end: idx)
        .chain(CurveTween(curve: _springCurve))
        .animate(_controller);
  }

  @override
  void didUpdateWidget(GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final from = _position.value;
      final to = widget.selectedIndex.toDouble();
      _position = Tween<double>(begin: from, end: to)
          .chain(CurveTween(curve: _springCurve))
          .animate(_controller);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / _tabs.length;
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final pos = _position.value;
                    return SizedBox(
                      height: 64,
                      child: Stack(
                        children: [
                          Positioned(
                            left: tabWidth * pos,
                            top: 6,
                            bottom: 6,
                            width: tabWidth,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(_tabs.length, (index) {
                              final activation =
                                  (1.0 - (pos - index).abs()).clamp(0.0, 1.0);
                              final color = Color.lerp(
                                cs.onSurfaceVariant.withValues(alpha: 0.6),
                                cs.primary,
                                activation,
                              )!;
                              return Expanded(
                                child: Semantics(
                                  label: _tabs[index].labelKey.tr(),
                                  selected: index == widget.selectedIndex,
                                  button: true,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      widget.onTap(index);
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(_tabs[index].icon,
                                            color: color, size: 22),
                                        const SizedBox(height: 3),
                                        Text(
                                          _tabs[index].labelKey.tr(),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: activation > 0.5
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
