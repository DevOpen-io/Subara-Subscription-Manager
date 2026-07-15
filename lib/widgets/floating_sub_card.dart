import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FloatingSubCard extends HookWidget {
  const FloatingSubCard({
    super.key,
    required this.name,
    required this.amount,
    required this.label,
    required this.cardColor,
    required this.textColor,
    required this.logoColor,
    required this.logoInitials,
    this.logoIcon,
    this.rotation = 0.0,
    this.width = 162,
    this.phaseOffset = 0.0,
    this.amplitude = 1.0,
  });

  final String name;
  final String amount;
  final String label;
  final Color cardColor;
  final Color textColor;
  final Color logoColor;
  final String logoInitials;
  final IconData? logoIcon;
  final double rotation;
  final double width;
  final double phaseOffset;
  // 0.0 = no float (landing), 1.0 = full bob.
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    final t = useAnimation(controller);
    final yOffset = (sin((t + phaseOffset) * 2 * pi) * 6.0
        + sin((t + phaseOffset * 1.4) * 5.1 * pi) * 2.2) * amplitude;
    final xOffset = cos((t + phaseOffset * 0.7) * 1.3 * 2 * pi) * 3.5 * amplitude;

    final logoTextColor = logoColor.computeLuminance() > 0.4
        ? const Color(0xFF1A1A1A)
        : Colors.white;

    return Transform.translate(
      offset: Offset(xOffset, yOffset),
      child: Transform.rotate(
        angle: rotation,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: logoColor,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: logoIcon != null
                  ? Icon(logoIcon, size: 16, color: logoTextColor)
                  : Text(
                      logoInitials,
                      style: TextStyle(
                        color: logoTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.55),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              amount,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
