import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/notification_service.dart';

import '../helpers/fake_notification_service.dart';

Future<ProviderContainer> _loaded() async {
  final container = ProviderContainer(
    overrides: [
      settingsStorageProvider.overrideWith(
        (ref) => Storage<String, String>.inMemory(),
      ),
      subsStorageProvider.overrideWith(
        (ref) => Storage<String, String>.inMemory(),
      ),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(settingsControllerProvider.future);
  await container.read(subsControllerProvider.future);
  return container;
}

SettingsViewModel _settings(ProviderContainer c) =>
    c.read(settingsControllerProvider).value!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backups carry the main currency and rates', () async {
    final c = await _loaded();
    c.read(settingsControllerProvider.notifier)
      ..updateCurrency(Currency.eur)
      ..setExchangeRate(Currency.usd, 0.9);
    c
        .read(subsControllerProvider.notifier)
        .addSlice(
          SubSlice(
            name: 'A',
            amount: 5,
            color: 0,
            startDate: DateTime(2026),
            currency: Currency.usd,
          ),
        );

    final json =
        jsonDecode(await c.read(subsControllerProvider.notifier).exportToJson())
            as Map<String, dynamic>;
    expect(json['mainCurrency'], 'eur');
    expect(json['exchangeRates'], {'usd': 0.9});
    final sub = (json['subscriptions'] as List).single as Map<String, dynamic>;
    expect(sub['currency'], 'usd');
  });

  test(
    'restoring on a new phone applies the backup currency and rates',
    () async {
      final c = await _loaded();
      expect(_settings(c).currency, Currency.try_);
      final ok = await c
          .read(subsControllerProvider.notifier)
          .importFromJson(
            jsonEncode({
              'version': 1,
              'mainCurrency': 'eur',
              'exchangeRates': {'usd': 0.9, 'bogus': 3},
              'subscriptions': [
                SubSlice(
                  name: 'A',
                  amount: 5,
                  color: 0,
                  startDate: DateTime(2026),
                  currency: Currency.usd,
                ).toJson(),
              ],
            }),
            restoreSettings: true,
          );
      expect(ok, isTrue);
      expect(_settings(c).currency, Currency.eur);
      expect(_settings(c).exchangeRates, {Currency.usd: 0.9});
      expect(c.read(subsControllerProvider).value!.single.name, 'A');
    },
  );

  test(
    'a normal import only adds missing rates in the same main currency',
    () async {
      final c = await _loaded();
      c
          .read(settingsControllerProvider.notifier)
          .setExchangeRate(Currency.usd, 30);
      final notifier = c.read(subsControllerProvider.notifier);

      await notifier.importFromJson(
        jsonEncode({
          'version': 1,
          'mainCurrency': 'try_',
          'exchangeRates': {'usd': 25, 'eur': 33},
          'subscriptions': <Object>[],
        }),
      );
      // Keeps the newer USD rate, adds EUR.
      expect(_settings(c).exchangeRates, {Currency.usd: 30, Currency.eur: 33});

      await notifier.importFromJson(
        jsonEncode({
          'version': 1,
          'mainCurrency': 'gbp',
          'exchangeRates': {'jpy': 0.005},
          'subscriptions': <Object>[],
        }),
      );
      // Different main currency: those rates mean something else; ignored.
      expect(_settings(c).currency, Currency.try_);
      expect(_settings(c).exchangeRates.containsKey(Currency.jpy), isFalse);
    },
  );

  test('old backups without settings still import', () async {
    final c = await _loaded();
    final ok = await c
        .read(subsControllerProvider.notifier)
        .importFromJson(
          jsonEncode({
            'version': 1,
            'subscriptions': [
              SubSlice(
                name: 'Old',
                amount: 1,
                color: 0,
                startDate: DateTime(2026),
              ).toJson(),
            ],
          }),
          restoreSettings: true,
        );
    expect(ok, isTrue);
    expect(_settings(c).currency, Currency.try_);
  });
}
