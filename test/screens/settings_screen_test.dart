import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/screens/settings_screen.dart';
import 'package:subs_tracker/utils/notification_service.dart';

import '../helpers/fake_notification_service.dart';

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() =>
      const SettingsViewModel(theme: ThemeMode.light, currency: Currency.usd);
}

void main() {
  testWidgets('Settings shows app version from package info', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Subara',
      packageName: 'io.devopen.subzilla',
      version: '1.0.1',
      buildNumber: '74',
      buildSignature: '',
    );
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(FakeSettingsController.new),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.0.1 (74)'), findsOneWidget);
    expect(find.text('1.0.0'), findsNothing);
  });
}
