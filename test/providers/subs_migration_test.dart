import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:subs_tracker/models/billing.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/notification_service.dart';

import '../helpers/fake_notification_service.dart';

/// Exact on-disk format written by 1.0.0 (pulled from a device): no `id`.
const _legacyJson =
    '[{"brand":{"text":"Netflix","logo":null,"icon":"netflix","category":"Streaming","name":null,"country":"US","desc":null,"isNative":null},"name":"Netflix","amount":12.99,"color":4293200148,"startDate":"2026-11-16T20:37:57.882085","frequency":"monthly","category":null,"reminderMode":"both","cardLastFour":null,"status":"active","note":null,"trialEndDate":null},'
    '{"brand":{"text":"Spotify","logo":null,"icon":"spotify","category":"Music","name":null,"country":"SE","desc":null,"isNative":null},"name":"Spotify","amount":9.99,"color":4280211296,"startDate":"2026-11-16T20:37:59.953401","frequency":"monthly","category":null,"reminderMode":"both","cardLastFour":null,"status":"active","note":null,"trialEndDate":null}]';

const _key = 'SubsController';
const _options = StorageOptions(
  cacheTime: StorageCacheTime.unsafe_forever,
  destroyKey: 'v2',
);

class FakeSettingsController extends SettingsController {
  @override
  FutureOr<SettingsViewModel> build() =>
      const SettingsViewModel(theme: ThemeMode.light, currency: Currency.usd);
}

/// Settings that finish loading after subs, with a non-default reminder time.
class SlowSettingsController extends SettingsController {
  @override
  Future<SettingsViewModel> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const SettingsViewModel(
      theme: ThemeMode.light,
      currency: Currency.usd,
      reminderMinutes: 9 * 60 + 30,
    );
  }
}

ProviderContainer _container(
  Storage<String, String> storage, [
  FakeNotificationService? notifications,
]) {
  final container = ProviderContainer(
    overrides: [
      subsStorageProvider.overrideWith((ref) => storage),
      settingsControllerProvider.overrideWith(FakeSettingsController.new),
      notificationServiceProvider.overrideWithValue(
        notifications ?? FakeNotificationService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<String?> _stored(Storage<String, String> storage) async =>
    (await storage.read(_key))?.data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy data without ids loads intact and gets ids', () async {
    final storage = Storage<String, String>.inMemory();
    await storage.write(_key, _legacyJson, _options);

    final subs = await _container(storage).read(subsControllerProvider.future);

    expect(subs.map((s) => s.name), ['Netflix', 'Spotify']);
    expect(subs.map((s) => s.amount), [12.99, 9.99]);
    expect(subs.every((s) => s.id.isNotEmpty), isTrue);
    expect(subs.map((s) => s.id).toSet(), hasLength(2));
  });

  test('generated ids are written back and stable across launches', () async {
    final storage = Storage<String, String>.inMemory();
    await storage.write(_key, _legacyJson, _options);

    final first = await _container(storage).read(subsControllerProvider.future);
    await pumpEventQueue();

    final raw = jsonDecode((await _stored(storage))!) as List<dynamic>;
    expect(
      raw.map((e) => (e as Map<String, dynamic>)['id']),
      first.map((s) => s.id),
    );

    final second = await _container(
      storage,
    ).read(subsControllerProvider.future);
    expect(second.map((s) => s.id), first.map((s) => s.id));
  });

  test('unknown enum values from a newer version do not wipe data', () async {
    final storage = Storage<String, String>.inMemory();
    final json = _legacyJson
        .replaceFirst('"frequency":"monthly"', '"frequency":"quarterly"')
        .replaceFirst('"status":"active"', '"status":"archived"')
        .replaceFirst('"reminderMode":"both"', '"reminderMode":"weekBefore"');
    await storage.write(_key, json, _options);

    final subs = await _container(storage).read(subsControllerProvider.future);

    expect(subs, hasLength(2));
    expect(subs.first.name, 'Netflix');
  });

  test('undecodable data is never overwritten and is backed up', () async {
    final storage = Storage<String, String>.inMemory();
    const corrupt = '[{"name":"Netflix","amount":"not-a-number"}]';
    await storage.write(_key, corrupt, _options);

    final container = _container(storage);
    await expectLater(
      container.read(subsControllerProvider.future),
      throwsA(anything),
    );
    await pumpEventQueue();

    expect(await _stored(storage), corrupt);
    final backup = await storage.read(subsBackupKey);
    expect(backup?.data, corrupt);
  });

  test('empty storage starts with an empty list', () async {
    final storage = Storage<String, String>.inMemory();
    final subs = await _container(storage).read(subsControllerProvider.future);
    expect(subs, isEmpty);
  });

  test('added subscriptions get a unique id', () async {
    final storage = Storage<String, String>.inMemory();
    final container = _container(storage);
    await container.read(subsControllerProvider.future);
    final notifier = container.read(subsControllerProvider.notifier);

    notifier
      ..addSlice(
        SubSlice(name: 'A', amount: 1, color: 0, startDate: DateTime(2026)),
      )
      ..addSlice(
        SubSlice(name: 'B', amount: 1, color: 0, startDate: DateTime(2026)),
      );

    final ids = container.read(subsControllerProvider).value!.map((s) => s.id);
    expect(ids.every((id) => id.isNotEmpty), isTrue);
    expect(ids.toSet(), hasLength(2));
  });

  test('changes replace reminders with the current plan', () async {
    final notifications = FakeNotificationService();
    final container = _container(
      Storage<String, String>.inMemory(),
      notifications,
    );
    await container.read(subsControllerProvider.future);
    final notifier = container.read(subsControllerProvider.notifier);

    notifier
      ..addSlice(
        SubSlice(
          name: 'A',
          amount: 1,
          color: 0,
          startDate: DateTime(2026, 1, 10),
        ),
      )
      ..addSlice(
        SubSlice(
          name: 'B',
          amount: 1,
          color: 0,
          startDate: DateTime(2026, 1, 20),
        ),
      );
    await notifier.scheduleNotifications();

    // 2 subs x (due today + due tomorrow), no duplicates from the rapid edits.
    expect(notifications.scheduled, hasLength(4));
    expect(notifications.scheduled.map((r) => r.id).toSet(), hasLength(4));

    notifier.removeSlice(
      container.read(subsControllerProvider).value!.first.id,
    );
    await notifier.scheduleNotifications();
    expect(notifications.scheduled, hasLength(2));
  });

  test('edits are ignored while stored data is undecodable', () async {
    final storage = Storage<String, String>.inMemory();
    const corrupt = '[{"name":"Netflix","amount":"not-a-number"}]';
    await storage.write(_key, corrupt, _options);
    final container = _container(storage);
    await expectLater(
      container.read(subsControllerProvider.future),
      throwsA(anything),
    );

    container
        .read(subsControllerProvider.notifier)
        .addSlice(
          SubSlice(name: 'New', amount: 1, color: 0, startDate: DateTime(2026)),
        );
    await pumpEventQueue();

    expect(await _stored(storage), corrupt);
    expect(container.read(subsControllerProvider).hasError, isTrue);
  });

  test('legacy data gets defaults for new fields', () async {
    final storage = Storage<String, String>.inMemory();
    await storage.write(_key, _legacyJson, _options);
    final subs = await _container(storage).read(subsControllerProvider.future);
    final s = subs.first;
    expect(s.interval, 1);
    expect(s.remindDaysBefore, 1);
    expect(s.cancelledAt, isNull);
    expect(s.manageUrl, isNull);
  });

  test('invalid interval and reminder days are repaired on load', () async {
    final storage = Storage<String, String>.inMemory();
    final json = _legacyJson.replaceFirst(
      '"frequency":"monthly"',
      '"frequency":"monthly","interval":0,"remindDaysBefore":-4',
    );
    await storage.write(_key, json, _options);
    final subs = await _container(storage).read(subsControllerProvider.future);
    expect(subs.first.interval, 1);
    expect(subs.first.remindDaysBefore, 1);
  });

  test('invalid interval in an imported backup is repaired', () async {
    final container = _container(Storage<String, String>.inMemory());
    await container.read(subsControllerProvider.future);
    final ok = await container
        .read(subsControllerProvider.notifier)
        .importFromJson(
          '{"version":1,"subscriptions":${_legacyJson.replaceAll('"frequency":"monthly"', '"frequency":"monthly","interval":-2')}}',
        );
    expect(ok, isTrue);
    final subs = container.read(subsControllerProvider).value!;
    expect(subs.map((s) => s.interval), [1, 1]);
  });

  test('cancelling stamps cancelledAt; reactivating clears it', () async {
    final container = _container(Storage<String, String>.inMemory());
    await container.read(subsControllerProvider.future);
    final notifier = container.read(subsControllerProvider.notifier)
      ..addSlice(
        SubSlice(name: 'A', amount: 1, color: 0, startDate: DateTime(2026)),
      );
    SubSlice current() => container.read(subsControllerProvider).value!.single;

    final before = DateTime.now();
    notifier.updateSlice(current().copyWith(status: SubStatus.cancelled));
    final stamped = current().cancelledAt;
    expect(stamped, isNotNull);
    expect(stamped!.isBefore(before), isFalse);

    // Unrelated edits keep the original date.
    notifier.updateSlice(current().copyWith(note: 'x'));
    expect(current().cancelledAt, stamped);

    notifier.updateSlice(current().copyWith(status: SubStatus.active));
    expect(current().cancelledAt, isNull);
  });

  test('reminders scheduled at launch use the saved time even if settings '
      'load later', () async {
    final storage = Storage<String, String>.inMemory();
    await storage.write(_key, _legacyJson, _options);
    final notifications = FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        subsStorageProvider.overrideWith((ref) => storage),
        settingsControllerProvider.overrideWith(SlowSettingsController.new),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    await container.read(subsControllerProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(notifications.scheduled, isNotEmpty);
    expect(
      notifications.scheduled.every(
        (r) => r.date.hour == 9 && r.date.minute == 30,
      ),
      isTrue,
    );
  });

  group('price history', () {
    Future<(ProviderContainer, SubsController)> withSub() async {
      final container = _container(Storage<String, String>.inMemory());
      await container.read(subsControllerProvider.future);
      final notifier = container.read(subsControllerProvider.notifier)
        ..addSlice(
          SubSlice(name: 'A', amount: 10, color: 0, startDate: DateTime(2026)),
        );
      return (container, notifier);
    }

    test('a mistaken price change can be removed', () async {
      final (container, notifier) = await withSub();
      SubSlice current() =>
          container.read(subsControllerProvider).value!.single;
      notifier.updateSlice(current().copyWith(amount: 12));
      final entry = current().priceHistory.single;

      notifier.removePriceChange(current().id, entry.until);
      expect(current().priceHistory, isEmpty);
      expect(current().amount, 12);

      // Unknown entries and subs are ignored.
      notifier
        ..removePriceChange(current().id, DateTime(2000))
        ..removePriceChange('missing', entry.until);
      expect(current().priceHistory, isEmpty);
    });

    test('switching only the currency is not a price change', () async {
      final (container, notifier) = await withSub();
      SubSlice current() =>
          container.read(subsControllerProvider).value!.single;
      notifier.updateSlice(current().copyWith(currency: Currency.usd));
      expect(current().priceHistory, isEmpty);
      expect(current().currency, Currency.usd);
    });

    test('changing the price records the old one', () async {
      final (container, notifier) = await withSub();
      SubSlice current() =>
          container.read(subsControllerProvider).value!.single;

      notifier.updateSlice(current().copyWith(note: 'x'));
      expect(current().priceHistory, isEmpty);

      notifier.updateSlice(current().copyWith(amount: 12));
      expect(current().priceHistory.map((p) => p.amount), [10.0]);
      expect(current().amount, 12);
    });

    test(
      'several edits on the same day keep one entry with the old price',
      () async {
        final (container, notifier) = await withSub();
        SubSlice current() =>
            container.read(subsControllerProvider).value!.single;

        notifier
          ..updateSlice(current().copyWith(amount: 12))
          ..updateSlice(current().copyWith(amount: 13))
          ..updateSlice(current().copyWith(currency: Currency.usd));
        expect(current().priceHistory.map((p) => (p.amount, p.currency)), [
          (10.0, null),
        ]);
      },
    );

    test(
      'back to the original price on the same day drops the entry',
      () async {
        final (container, notifier) = await withSub();
        SubSlice current() =>
            container.read(subsControllerProvider).value!.single;

        notifier
          ..updateSlice(current().copyWith(amount: 12))
          ..updateSlice(current().copyWith(amount: 10));
        expect(current().priceHistory, isEmpty);
      },
    );
  });

  test('mark a manual charge paid and unpaid', () async {
    final container = _container(Storage<String, String>.inMemory());
    await container.read(subsControllerProvider.future);
    final notifier = container.read(subsControllerProvider.notifier)
      ..addSlice(
        SubSlice(
          name: 'Rent',
          amount: 100,
          color: 0,
          startDate: DateTime(2026, 1, 10),
          autoRenew: false,
        ),
      );
    SubSlice current() => container.read(subsControllerProvider).value!.single;

    notifier.markPaid(current().id, DateTime(2026, 11, 10, 18), paid: true);
    expect(current().paidCharges, [DateTime(2026, 11, 10)]);
    notifier.markPaid(current().id, DateTime(2026, 11, 10), paid: true);
    expect(current().paidCharges, hasLength(1));

    notifier.markPaid(current().id, DateTime(2026, 11, 10), paid: false);
    expect(current().paidCharges, isEmpty);

    // Only the most recent entries are kept.
    for (var m = 1; m <= 40; m++) {
      notifier.markPaid(current().id, DateTime(2023, m, 10), paid: true);
    }
    expect(current().paidCharges, hasLength(SubSlice.maxPaidCharges));
    expect(current().paidCharges.last, DateTime(2026, 4, 10));
  });

  test('switching to manual payment counts earlier charges as paid', () async {
    final container = _container(Storage<String, String>.inMemory());
    await container.read(subsControllerProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifier = container.read(subsControllerProvider.notifier)
      ..addSlice(
        SubSlice(
          name: 'Rent',
          amount: 100,
          color: 0,
          startDate: DateTime(now.year - 3, now.month, now.day),
          frequency: Frequency.weekly,
        ),
      );
    SubSlice current() => container.read(subsControllerProvider).value!.single;

    notifier.updateSlice(current().copyWith(autoRenew: false));
    final paid = current().paidCharges;
    expect(paid, hasLength(SubSlice.maxPaidCharges));
    expect(paid.every((d) => d.isBefore(today)), isTrue);
    // Every charge the history shows, except one due today, is paid.
    for (final d in current().pastCharges(now)) {
      expect(current().isPaid(d), d != today, reason: '$d');
    }

    // Edits from a screen holding an older copy keep the marks.
    final stale = current().copyWith(paidCharges: const []);
    notifier.updateSlice(stale.copyWith(note: 'x'));
    expect(current().paidCharges, paid);

    // Only the switch itself marks; later edits keep an un-marked charge.
    notifier.markPaid(current().id, paid.last, paid: false);
    notifier.updateSlice(current().copyWith(note: 'y'));
    expect(current().isPaid(paid.last), isFalse);
  });

  test('a "Paid" tap on a notification marks that charge', () async {
    final notifications = FakeNotificationService();
    final container = _container(
      Storage<String, String>.inMemory(),
      notifications,
    );
    await container.read(subsControllerProvider.future);
    container
        .read(subsControllerProvider.notifier)
        .addSlice(
          SubSlice(
            id: 'rent',
            name: 'Rent',
            amount: 100,
            color: 0,
            startDate: DateTime(2026, 1, 10),
            autoRenew: false,
          ),
        );
    notifications.markPaidTaps.add((
      subId: 'rent',
      charge: DateTime(2026, 11, 10),
    ));
    notifications.markPaidTaps.add((subId: 'gone', charge: DateTime(2026)));
    await Future<void>.delayed(Duration.zero);
    final sub = container.read(subsControllerProvider).value!.single;
    expect(sub.paidCharges, [DateTime(2026, 11, 10)]);
  });

  group('reorder with hidden items', () {
    Future<(ProviderContainer, SubsController)> withSubs() async {
      final container = _container(Storage<String, String>.inMemory());
      await container.read(subsControllerProvider.future);
      final notifier = container.read(subsControllerProvider.notifier);
      for (final name in ['A', 'X', 'B', 'C', 'Y']) {
        notifier.addSlice(
          SubSlice(
            id: name,
            name: name,
            amount: 1,
            color: 0,
            startDate: DateTime(2026),
          ),
        );
      }
      return (container, notifier);
    }

    List<String> order(ProviderContainer c) =>
        c.read(subsControllerProvider).value!.map((s) => s.id).toList();

    test(
      'moving within the visible list keeps hidden items in place',
      () async {
        final (c, notifier) = await withSubs();
        // X and Y are archived (hidden); the list shows A, B, C.
        notifier.reorderWithin(['A', 'B', 'C'], 2, 0); // C to the top
        expect(order(c), ['C', 'X', 'A', 'B', 'Y']);
        notifier.reorderWithin(['C', 'A', 'B'], 0, 3); // C to the end
        expect(order(c), ['A', 'X', 'B', 'C', 'Y']);
      },
    );

    test('stale ids are ignored', () async {
      final (c, notifier) = await withSubs();
      notifier.reorderWithin(['A', 'gone', 'B'], 0, 2);
      expect(order(c), ['A', 'X', 'B', 'C', 'Y']);
    });
  });
}
