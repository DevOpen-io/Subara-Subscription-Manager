// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/main.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    // Override the settings and subs controllers to return a fixed state
    // This avoids database calls and platform channel issues
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(FakeSettingsController.new),
          subsControllerProvider.overrideWith(FakeSubsController.new),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app builds and shows the loading or main screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() {
    return const SettingsViewModel(theme: ThemeMode.light, currency: Currency.usd);
  }
}

class FakeSubsController extends SubsController {
  @override
  FutureOr<List<SubSlice>> build() {
    return [];
  }
}
