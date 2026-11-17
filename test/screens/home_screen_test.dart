import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/screens/home_screen.dart';

class _Subs extends SubsController {
  @override
  Future<List<SubSlice>> build() async => [
    SubSlice(
      id: 'n',
      name: 'Netflix',
      amount: 15,
      color: 0xFF000000,
      startDate: DateTime(2026),
    ),
    SubSlice(
      id: 'o',
      name: 'OldGym',
      amount: 5,
      color: 0xFF000000,
      startDate: DateTime(2026),
      status: SubStatus.cancelled,
    ),
  ];
}

class _Settings extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() =>
      const SettingsViewModel(theme: ThemeMode.light, currency: Currency.try_);
}

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subsControllerProvider.overrideWith(_Subs.new),
        settingsControllerProvider.overrideWith(_Settings.new),
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
            home: const HomeScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // One test: easy_localization only loads its assets once per test file.
  testWidgets('cancelled subscriptions move to the archive; search still '
      'finds them', (tester) async {
    await _pump(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('OldGym'), findsNothing);
    expect(find.text('Archive (1)'), findsOneWidget);

    await tester.tap(find.text('Archive (1)'));
    await tester.pumpAndSettle();
    expect(find.text('OldGym'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search subscriptions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'oldg');
    await tester.pumpAndSettle();
    expect(find.text('OldGym'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
  });
}
