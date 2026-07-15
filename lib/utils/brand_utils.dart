import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/brand.dart';

/// Extension on [Brand] to derive icon data from Simple Icons.
///
/// Uses the built-in [SimpleIcons.values] and [SimpleIconColors.values]
/// lookup maps, so no manual mapping is needed.
extension BrandIconData on Brand {
  /// Returns the [IconData] for this brand from Simple Icons, or null.
  IconData? get iconData =>
      icon != null ? SimpleIcons.values[icon!] : null;

  /// Returns the brand color from Simple Icons, or null.
  Color? get iconColor =>
      icon != null ? SimpleIconColors.values[icon!] : null;
}
