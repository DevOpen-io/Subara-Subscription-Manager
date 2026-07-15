import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/app_theme.dart';
import 'settings_controller.dart';

part 'theme_provider.g.dart';

@riverpod
ThemeData lightTheme(Ref ref) {
  final scheme = ref.watch(
    settingsControllerProvider.select(
      (v) => v.value?.colorScheme ?? FlexScheme.bahamaBlue,
    ),
  );
  return FlexThemeData.light(
    scheme: scheme,
    surfaceTint: kCoralAccent,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}

@riverpod
ThemeData darkTheme(Ref ref) {
  final scheme = ref.watch(
    settingsControllerProvider.select(
      (v) => v.value?.colorScheme ?? FlexScheme.bahamaBlue,
    ),
  );
  return FlexThemeData.dark(
    scheme: scheme,
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
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
