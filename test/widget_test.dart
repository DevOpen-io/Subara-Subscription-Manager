// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subs_tracker/main.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/notification_service.dart';

import 'helpers/fake_notification_service.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    // Override the settings and subs controllers to return a fixed state
    // This avoids database calls and platform channel issues
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    // MyApp reads localization delegates from EasyLocalization, as in main().
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(FakeSettingsController.new),
          subsControllerProvider.overrideWith(FakeSubsController.new),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const MyApp(),
        ),
      ),
    );
    await tester.pump();

    // Verify that the app builds and shows the loading or main screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() {
    return const SettingsViewModel(
      theme: ThemeMode.light,
      currency: Currency.usd,
    );
  }
}

class FakeSubsController extends SubsController {
  @override
  FutureOr<List<SubSlice>> build() {
    return [];
  }
}
