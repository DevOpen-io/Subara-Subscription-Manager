import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/settings_view_model.dart';

void main() {
  group('SettingsViewModel colorScheme', () {
    test('serializes FlexScheme by name string', () {
      const vm = SettingsViewModel(
        theme: ThemeMode.light,
        currency: Currency.usd,
        colorScheme: FlexScheme.deepPurple,
      );
      final json = vm.toJson();
      expect(json['colorScheme'], 'deepPurple');
    });

    test('deserializes FlexScheme from name string', () {
      final json = <String, dynamic>{
        'theme': 'light',
        'currency': 'usd',
        'colorScheme': 'tealM3',
      };
      final vm = SettingsViewModel.fromJson(json);
      expect(vm.colorScheme, FlexScheme.tealM3);
    });

    test('defaults to bahamaBlue when colorScheme missing from JSON', () {
      final json = <String, dynamic>{
        'theme': 'light',
        'currency': 'usd',
      };
      final vm = SettingsViewModel.fromJson(json);
      expect(vm.colorScheme, FlexScheme.bahamaBlue);
    });
  });
}
