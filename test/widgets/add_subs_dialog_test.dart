import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subs_tracker/models/brand.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/brands_provider.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/widgets/add_subs_dialog.dart';

// Mock Brands
class FakeBrands extends Brands {
  @override
  Future<List<Brand>> build() async {
    return [const Brand(text: 'Netflix'), const Brand(text: 'Spotify')];
  }
}

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() =>
      const SettingsViewModel(theme: ThemeMode.light, currency: Currency.usd);
}

// Mock SubsController
class MockSubsController extends SubsController {
  @override
  Future<List<SubSlice>> build() async {
    return [];
  }

  @override
  void addSlice(SubSlice slice) {
    state = AsyncData([...(state.value ?? []), slice]);
  }
}

/// Finds the [TextFormField] in the form row labelled [label].
Finder fieldFor(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
  matching: find.byType(TextFormField),
);

void main() {
  testWidgets('AddSubsDialog allows adding a subscription', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final mockSubsController = MockSubsController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandsProvider.overrideWith(FakeBrands.new),
          settingsControllerProvider.overrideWith(FakeSettingsController.new),
          subsControllerProvider.overrideWith(() => mockSubsController),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('tr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: Builder(
            builder: (appContext) => MaterialApp(
              localizationsDelegates: appContext.localizationDelegates,
              supportedLocales: appContext.supportedLocales,
              locale: appContext.locale,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const AddSubsDialog(),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In the app the subs list is already loaded before the sheet opens;
    // otherwise the pending build() would overwrite the added slice.
    await ProviderScope.containerOf(
      tester.element(find.text('open')),
    ).read(subsControllerProvider.future);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('New Subscription'), findsOneWidget);

    await tester.enterText(fieldFor('Name'), 'My Sub');
    await tester.enterText(fieldFor('Price'), '10,5');
    await tester.pump();

    final weekly = find.text('Weekly');
    await tester.ensureVisible(weekly);
    await tester.tap(weekly);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final added = mockSubsController.state.value!;
    expect(added, hasLength(1));
    expect(added.first.name, 'My Sub');
    expect(added.first.amount, 10.5);
    expect(added.first.frequency, Frequency.weekly);
    // Sheet closes after save.
    expect(find.text('New Subscription'), findsNothing);
  });
}
