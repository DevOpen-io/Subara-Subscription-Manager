import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand coral — same value used as surfaceTint in AppTheme light theme.
const Color kCoralAccent = Color(0xFFD83434);

const List<(FlexScheme, String)> kCuratedSchemes = [
  (FlexScheme.bahamaBlue,  'Bahama Blue'),
  (FlexScheme.blue,        'Blue'),
  (FlexScheme.indigo,      'Indigo'),
  (FlexScheme.hippieBlue,  'Hippie Blue'),
  (FlexScheme.aquaBlue,    'Aqua Blue'),
  (FlexScheme.deepPurple,  'Deep Purple'),
  (FlexScheme.purpleM3,    'Purple'),
  (FlexScheme.pinkM3,      'Pink'),
  (FlexScheme.sakura,      'Sakura'),
  (FlexScheme.mandyRed,    'Red'),
  (FlexScheme.orangeM3,    'Orange'),
  (FlexScheme.amber,       'Amber'),
  (FlexScheme.greenM3,     'Green'),
  (FlexScheme.tealM3,      'Teal'),
  (FlexScheme.blueWhale,   'Blue Whale'),
  (FlexScheme.espresso,    'Espresso'),
];

String schemeDisplayName(FlexScheme scheme) {
  for (final (s, name) in kCuratedSchemes) {
    if (s == scheme) return name;
  }
  return scheme.name;
}

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.3.0.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // Using FlexColorScheme built-in FlexScheme enum based colors
    scheme: FlexScheme.bahamaBlue,
    // Surface color adjustments.
    surfaceTint: const Color(0xFFD83434),
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // Using FlexColorScheme built-in FlexScheme enum based colors.
    scheme: FlexScheme.bahamaBlue,
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
