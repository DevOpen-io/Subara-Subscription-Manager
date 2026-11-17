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
import 'package:subs_tracker/screens/calendar_screen.dart';
import 'package:table_calendar/table_calendar.dart';

// Mock SubsController
class MockSubsController extends SubsController {
  @override
  Future<List<SubSlice>> build() async {
    return [
      SubSlice(
        name: 'Netflix',
        amount: 15,
        color: 0xFF000000,
        startDate: DateTime.now(),
      ),
      SubSlice(
        name: 'Paused',
        amount: 5,
        color: 0xFF000000,
        startDate: DateTime.now(),
        status: SubStatus.paused,
      ),
      SubSlice(
        name: 'Cancelled',
        amount: 5,
        color: 0xFF000000,
        startDate: DateTime.now(),
        status: SubStatus.cancelled,
      ),
    ];
  }
}

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() =>
      const SettingsViewModel(theme: ThemeMode.light, currency: Currency.try_);
}

void main() {
  testWidgets('CalendarScreen renders and shows events', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subsControllerProvider.overrideWith(MockSubsController.new),
          settingsControllerProvider.overrideWith(FakeSettingsController.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('tr'),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const CalendarScreen(),
            ),
          ),
        ),
      ),
    );

    // Wait for async data
    await tester.pumpAndSettle();

    // Verify Calendar is present
    expect(find.byType(TableCalendar<SubSlice>), findsOneWidget);

    // Verify Subscription List shows the item (since it's today)
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Aylık'), findsOneWidget);

    // Calendar follows the app language.
    final month = DateFormat.yMMMM('tr').format(DateTime.now());
    expect(find.text(month), findsOneWidget);

    // Amount uses the user's currency, not the device default ($).
    expect(find.text('₺15.00'), findsOneWidget);

    // Paused/cancelled subscriptions are not charged, so not on the calendar.
    expect(find.text('Paused'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);
  });
}
