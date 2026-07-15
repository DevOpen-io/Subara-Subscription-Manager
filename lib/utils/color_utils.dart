import 'package:flutter/material.dart';

Color darkerOf(Color c, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}
