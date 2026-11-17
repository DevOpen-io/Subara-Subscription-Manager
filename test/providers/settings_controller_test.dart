import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/notification_service.dart';

import '../helpers/fake_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'notification permission is requested when onboarding finishes',
    () async {
      final notifications = FakeNotificationService();
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) => Storage<String, String>.inMemory(),
          ),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);

      final settings = await container.read(settingsControllerProvider.future);
      expect(settings.isFirstTime, isTrue);
      expect(notifications.permissionRequests, 0);

      container
          .read(settingsControllerProvider.notifier)
          .updateIsFirstTime(isFirstTime: false);

      expect(notifications.permissionRequests, 1);
    },
  );

  test('returning users are asked again at app start', () async {
    // e.g. settings restored by Android backup onto a new phone, where the
    // permission was never granted.
    final storage = Storage<String, String>.inMemory();
    await storage.write(
      'SettingsController',
      '{"theme":"light","currency":"usd","isFirstTime":false}',
      const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: 'v1',
      ),
    );
    final notifications = FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWith((ref) => storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final settings = await container.read(settingsControllerProvider.future);

    expect(settings.isFirstTime, isFalse);
    expect(notifications.permissionRequests, 1);
  });

  test('1.0.0 settings load intact and get the default reminder time', () async {
    // Exact row pulled from a 1.0.0 install.
    final storage = Storage<String, String>.inMemory();
    await storage.write(
      'SettingsController',
      '{"theme":"light","currency":"try_","profilePicture":null,"userName":null,"email":null,"isFirstTime":false,"colorScheme":"hippieBlue"}',
      const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: 'v1',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWith((ref) => storage),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final settings = await container.read(settingsControllerProvider.future);
    expect(settings.currency.name, 'try_');
    expect(settings.isFirstTime, isFalse);
    expect(settings.colorScheme.name, 'hippieBlue');
    expect(settings.reminderMinutes, 12 * 60);
  });

  group('exchange rates', () {
    Future<ProviderContainer> loaded() async {
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) => Storage<String, String>.inMemory(),
          ),
          subsStorageProvider.overrideWith(
            (ref) => Storage<String, String>.inMemory(),
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsControllerProvider.future);
      // Rate changes refresh the widget from the subs list; let it load so
      // teardown doesn't dispose it mid-build.
      await container.read(subsControllerProvider.future);
      return container;
    }

    test('set and remove a rate', () async {
      final container = await loaded();
      final notifier = container.read(settingsControllerProvider.notifier)
        ..setExchangeRate(Currency.usd, 34.5);
      SettingsViewModel current() =>
          container.read(settingsControllerProvider).value!;
      expect(current().exchangeRates, {Currency.usd: 34.5});

      notifier.setExchangeRate(Currency.usd, null);
      expect(current().exchangeRates, isEmpty);
    });

    test('changing the main currency rebases rates', () async {
      final container = await loaded();
      final notifier = container.read(settingsControllerProvider.notifier)
        ..setExchangeRate(Currency.usd, 30)
        ..updateCurrency(Currency.usd);
      final s = container.read(settingsControllerProvider).value!;
      expect(s.currency, Currency.usd);
      expect(s.exchangeRates[Currency.try_], closeTo(1 / 30, 1e-12));
      expect(s.exchangeRates.containsKey(Currency.usd), isFalse);
      notifier.updateCurrency(Currency.usd); // same currency: unchanged
      expect(
        container.read(settingsControllerProvider).value!.exchangeRates,
        s.exchangeRates,
      );
    });
  });

  group('custom categories', () {
    Future<ProviderContainer> loaded() async {
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) => Storage<String, String>.inMemory(),
          ),
          subsStorageProvider.overrideWith(
            (ref) => Storage<String, String>.inMemory(),
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsControllerProvider.future);
      await container.read(subsControllerProvider.future);
      return container;
    }

    test('add trims, skips duplicates and built-ins; remove', () async {
      final c = await loaded();
      final n = c.read(settingsControllerProvider.notifier);
      List<String> cats() =>
          c.read(settingsControllerProvider).value!.customCategories;

      expect(n.addCategory('  Ev  '), isTrue);
      expect(n.addCategory('ev'), isFalse);
      expect(n.addCategory('Music'), isFalse); // built-in
      expect(n.addCategory('   '), isFalse);
      expect(n.addCategory('Sigorta'), isTrue);
      expect(cats(), ['Ev', 'Sigorta']);

      n.removeCategory('Ev');
      expect(cats(), ['Sigorta']);
    });

    test('bad stored categories are skipped', () {
      final s = SettingsViewModel.fromJson({
        'theme': 'light',
        'currency': 'try_',
        'customCategories': ['Ev', 3, null, '', 'Ev', 'Araba'],
      });
      expect(s.customCategories, ['Ev', 'Araba']);
    });
  });
}
