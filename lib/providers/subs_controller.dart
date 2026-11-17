import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';

import '../models/billing.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';
import '../services/widget_update_service.dart';
import '../utils/notification_plan.dart';
import '../utils/notification_service.dart';
import 'settings_controller.dart';

part 'subs_controller.g.dart';

/// Storage key holding a verbatim copy of subs data that failed to decode.
const subsBackupKey = 'SubsController.undecodable-backup';

// NEVER change destroyKey: bumping it deletes every user's subscriptions.
// Evolve the schema with defaulted/nullable fields and migrate in build().
const _subsStorageOptions = StorageOptions(
  cacheTime: StorageCacheTime.unsafe_forever,
  destroyKey: 'v2',
);

List<SubSlice> _decodeSubs(String data) => (jsonDecode(data) as List<dynamic>)
    .map((e) => SubSlice.fromJson(e as Map<String, dynamic>))
    .toList();

/// Repairs loaded or imported rows: gives every subscription a unique,
/// non-empty id (legacy rows have none) and replaces invalid stored values.
List<SubSlice> _normalized(List<SubSlice> subs) {
  final seen = <String>{};
  return [
    for (final s in subs)
      s.copyWith(
        id: s.id.isEmpty || !seen.add(s.id) ? _newUniqueId(seen) : s.id,
        interval: s.period,
        remindDaysBefore: s.daysBefore,
        sharedWith: s.people,
      ),
  ];
}

String _newUniqueId(Set<String> seen) {
  String id;
  do {
    id = SubSlice.newId();
  } while (!seen.add(id));
  return id;
}

@Riverpod(keepAlive: true)
Future<Storage<String, String>> subsStorage(Ref ref) async {
  final storage = await JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'subs.db'),
  );
  ref.onDispose(storage.close);
  return storage;
}

@Riverpod(keepAlive: true)
@JsonPersist()
class SubsController extends _$SubsController {
  @override
  FutureOr<List<SubSlice>> build() async {
    final storage = await ref.watch(subsStorageProvider.future);

    // If stored data can't be decoded, persist() would silently fall back to
    // an empty list and then overwrite the database with it. Keep a copy and
    // fail loudly instead, so user data is never lost.
    final stored = await storage.read(key);
    if (stored != null && stored.destroyKey == _subsStorageOptions.destroyKey) {
      try {
        _decodeSubs(stored.data);
      } catch (_) {
        await storage.write(subsBackupKey, stored.data, _subsStorageOptions);
        rethrow;
      }
    }

    await persist(storage, options: _subsStorageOptions).future;
    final subs = _normalized(state.value ?? []);
    unawaited(_afterChange(subs));
    // "Paid" taps on reminders; the one that launched the app may arrive
    // before the list is set, so wait for it.
    final taps = ref.read(notificationServiceProvider).markPaidRequests.listen((
      tap,
    ) async {
      await future;
      markPaid(tap.subId, tap.charge, paid: true);
    });
    ref.onDispose(taps.cancel);
    return subs;
  }

  void addSlice(SubSlice slice) {
    _set([
      ...state.value ?? [],
      if (slice.id.isEmpty) slice.copyWith(id: SubSlice.newId()) else slice,
    ]);
    final count = state.value?.length ?? 0;
    if (count % 3 == 0) {
      InAppReview.instance.isAvailable().then((available) {
        if (available) InAppReview.instance.requestReview();
      });
    }
  }

  /// Replaces the subscription with the same id. No-op if it was deleted.
  /// Stamps [SubSlice.cancelledAt] when it becomes cancelled and clears it
  /// when it is reactivated, so every edit path keeps it consistent.
  void updateSlice(SubSlice updated) {
    final subs = state.value ?? [];
    final old = subs.where((s) => s.id == updated.id).firstOrNull;
    if (old == null) return;
    final now = DateTime.now();
    // cancelledAt, priceHistory and paidCharges are owned here, not by the
    // caller (a screen may hold a stale copy), so derive them from the
    // stored row.
    var next = updated.copyWith(
      cancelledAt: updated.status != SubStatus.cancelled
          ? null
          : old.status == SubStatus.cancelled
          ? old.cancelledAt
          : now,
      priceHistory: old.priceHistory,
      paidCharges: old.paidCharges,
    );
    // Charges before the switch to manual payment were paid automatically;
    // only today's and later ones are left to mark.
    if (old.autoRenew && !next.autoRenew) {
      next = next.copyWith(paidCharges: _paidBefore(next, now));
    }
    // Only a new amount is a price change; switching the currency alone is
    // treated as a correction (earlier entries keep their own currency).
    if (old.amount != next.amount) {
      next = next.copyWith(priceHistory: _recordPrice(old, next, now));
    }
    _set([
      for (final s in subs)
        if (s.id == updated.id) next else s,
    ]);
  }

  /// [sub]'s paid charges plus every charge before [now]'s day, newest
  /// [SubSlice.maxPaidCharges] kept.
  static List<DateTime> _paidBefore(SubSlice sub, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day - 1, 23, 59);
    final dates = {
      ...sub.paidCharges,
      ...sub.pastCharges(yesterday, limit: SubSlice.maxPaidCharges),
    }.toList()..sort();
    return dates.length > SubSlice.maxPaidCharges
        ? dates.sublist(dates.length - SubSlice.maxPaidCharges)
        : dates;
  }

  /// Appends [old]'s price. Several edits on one day keep a single entry
  /// (the price before that day's edits); returning to it drops the entry.
  static List<PriceChange> _recordPrice(
    SubSlice old,
    SubSlice next,
    DateTime now,
  ) {
    bool today(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    final history = [...old.priceHistory];
    if (history.isEmpty || !today(history.last.until)) {
      history.add(
        PriceChange(amount: old.amount, until: now, currency: old.currency),
      );
    }
    final base = history.last;
    if (base.amount == next.amount && base.currency == next.currency) {
      history.removeLast();
    }
    return history;
  }

  /// Deletes one recorded price (e.g. a typo that was saved as a change).
  /// Goes through [_set] directly: [updateSlice] owns the history.
  void removePriceChange(String id, DateTime until) {
    final subs = state.value ?? [];
    final sub = subs.where((s) => s.id == id).firstOrNull;
    if (sub == null || !sub.priceHistory.any((p) => p.until == until)) return;
    final history = [...sub.priceHistory.where((p) => p.until != until)];
    _set([
      for (final s in subs)
        if (s.id == id) s.copyWith(priceHistory: history) else s,
    ]);
  }

  /// Marks the charge on [charge]'s day as paid (or not) for a manually
  /// paid subscription.
  void markPaid(String id, DateTime charge, {required bool paid}) {
    final subs = state.value ?? [];
    final sub = subs.where((s) => s.id == id).firstOrNull;
    if (sub == null) return;
    final day = DateTime(charge.year, charge.month, charge.day);
    final dates = {
      ...sub.paidCharges.where((d) => d != day),
      if (paid) day,
    }.toList()..sort();
    final kept = dates.length > SubSlice.maxPaidCharges
        ? dates.sublist(dates.length - SubSlice.maxPaidCharges)
        : dates;
    _set([
      for (final s in subs)
        if (s.id == id) s.copyWith(paidCharges: kept) else s,
    ]);
  }

  void removeSlice(String id) {
    _set([...?state.value?.where((s) => s.id != id)]);
  }

  void reorderSlices(int oldIndex, int newIndex) {
    final list = List<SubSlice>.from(state.value ?? []);
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(insertIndex, item);
    _set(list);
  }

  /// Reorders the subscriptions shown in a partial list ([visibleIds], in
  /// list order, e.g. without archived ones) and leaves the hidden ones where
  /// they are. Ignored if the ids are stale.
  void reorderWithin(List<String> visibleIds, int oldIndex, int newIndex) {
    final list = [...?state.value];
    final ids = visibleIds.toSet();
    final positions = [
      for (final (i, s) in list.indexed)
        if (ids.contains(s.id)) i,
    ];
    if (positions.length != visibleIds.length) return;
    final items = [for (final p in positions) list[p]];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    for (final (i, p) in positions.indexed) {
      list[p] = items[i];
    }
    _set(list);
  }

  void sortSlices(int Function(SubSlice, SubSlice) compare) {
    _set(List<SubSlice>.from(state.value ?? [])..sort(compare));
  }

  void clear() => _set(const []);

  void _set(List<SubSlice> subs) {
    // Stored data failed to decode: nothing is persisted in this state, so an
    // edit would only hide the error and vanish on restart.
    if (state.hasError) return;
    state = AsyncValue.data(subs);
    unawaited(_afterChange(subs));
  }

  Future<void> _afterChange(List<SubSlice> subs) async {
    // Read everything from ref before any await: the provider may be
    // disposed while this runs.
    final settings = _settingsWhenLoaded();
    await scheduleNotifications(subs);
    final s = await settings;
    // The widget shows totals, so amounts go in the main currency.
    await WidgetUpdateService.instance.update(
      s == null ? subs : s.inMain(subs).subs,
      s?.currency.symbol ?? '',
    );
  }

  /// Settings once loaded (at app start they may still be loading when subs
  /// are ready), or null if they fail to load. Call before any await.
  Future<SettingsViewModel?> _settingsWhenLoaded() {
    final loaded = ref.read(settingsControllerProvider).value;
    if (loaded != null) return Future.value(loaded);
    return ref
        .read(settingsControllerProvider.future)
        .then<SettingsViewModel?>((s) => s)
        .timeout(const Duration(seconds: 10))
        .catchError((Object _) => null);
  }

  Future<void> _scheduling = Future.value();

  /// Replaces all pending reminders with the plan for [subs] (defaults to the
  /// current state). Calls are serialised so rapid edits can't interleave a
  /// cancel-all with another run's scheduling.
  Future<void> scheduleNotifications([List<SubSlice>? subs]) {
    final list = subs ?? state.value ?? [];
    final service = ref.read(notificationServiceProvider);
    final settings = _settingsWhenLoaded();
    return _scheduling = _scheduling.then((_) async {
      try {
        final fireMinutes =
            (await settings)?.reminderMinutes ?? defaultReminderMinutes;
        await service.cancelAllNotifications();
        for (final r in planReminders(
          list,
          DateTime.now(),
          fireMinutes: fireMinutes,
        )) {
          await service.scheduleNotification(
            id: r.id,
            title: 'notifications.title'.tr(),
            body: _reminderBody(r),
            scheduledDate: r.at,
            matchDateTimeComponents: r.repeat,
            markPaid: r.markPaidCharge == null
                ? null
                : (
                    subId: r.sub.id,
                    charge: r.markPaidCharge!,
                    label: 'notifications.mark_paid'.tr(),
                  ),
          );
        }
      } catch (e) {
        debugPrint('Failed to schedule reminders: $e');
      }
    });
  }

  String _reminderBody(PlannedReminder r) {
    final name = r.sub.name;
    final days = '${r.daysBefore}';
    return switch (r.kind) {
      ReminderKind.dueToday => 'notifications.due_today'.tr(args: [name]),
      ReminderKind.dueSoon when r.daysBefore == 1 =>
        'notifications.due_tomorrow'.tr(args: [name]),
      ReminderKind.dueSoon => 'notifications.due_in_days'.tr(
        args: [name, days],
      ),
      ReminderKind.trialEndsToday => 'notifications.trial_ends_today'.tr(
        args: [name],
      ),
      ReminderKind.trialEndsSoon when r.daysBefore == 1 =>
        'notifications.trial_ends_tomorrow'.tr(args: [name]),
      ReminderKind.overdue => 'notifications.overdue'.tr(args: [name]),
      ReminderKind.trialEndsSoon => 'notifications.trial_ends_in_days'.tr(
        args: [name, days],
      ),
    };
  }

  /// Export subscriptions to JSON format. Also carries the main currency
  /// and exchange rates, which subscriptions in other currencies need.
  Future<String> exportToJson() async {
    final subs = state.value ?? [];
    final settings = ref.read(settingsControllerProvider).value;
    final jsonList = subs.map((sub) => sub.toJson()).toList();
    return jsonEncode({
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      if (settings != null) ...{
        'mainCurrency': settings.currency.name,
        'exchangeRates': const ExchangeRatesConverter().toJson(
          settings.exchangeRates,
        ),
      },
      'subscriptions': jsonList,
    });
  }

  /// Applies a backup's currency settings. [restoreSettings] (restoring onto
  /// a fresh install) takes its main currency and rates as they are;
  /// otherwise only rates that are missing here are added, and only when
  /// both use the same main currency (rates are relative to it).
  void _importCurrencySettings(
    Map<String, dynamic> backup, {
    required bool restoreSettings,
  }) {
    final settings = ref.read(settingsControllerProvider.notifier);
    final current = ref.read(settingsControllerProvider).value;
    final main = Currency.values
        .where((c) => c.name == backup['mainCurrency'])
        .firstOrNull;
    if (current == null || main == null) return;
    final rates = const ExchangeRatesConverter().fromJson(
      backup['exchangeRates'],
    );
    if (restoreSettings) {
      if (main != current.currency) settings.updateCurrency(main);
      for (final c in Currency.values) {
        if (c != main) settings.setExchangeRate(c, rates[c]);
      }
    } else if (main == current.currency) {
      for (final MapEntry(:key, :value) in rates.entries) {
        if (!current.exchangeRates.containsKey(key) && key != main) {
          settings.setExchangeRate(key, value);
        }
      }
    }
  }

  /// Import subscriptions from JSON format. See [_importCurrencySettings]
  /// for [restoreSettings].
  Future<bool> importFromJson(
    String jsonString, {
    bool restoreSettings = false,
  }) async {
    if (!ref.mounted) return false;
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final subscriptionsList = decoded['subscriptions'] as List<dynamic>;

      final importedSubs = subscriptionsList
          .map((json) => SubSlice.fromJson(json as Map<String, dynamic>))
          .toList();
      // Replace current subscriptions with imported ones. Backups made
      // before ids existed get ids here.
      final subs = _normalized(importedSubs);
      _importCurrencySettings(decoded, restoreSettings: restoreSettings);
      state = AsyncValue.data(subs);
      await _afterChange(subs);
      return true;
    } catch (e) {
      debugPrint('Error importing subscriptions: $e');
      return false;
    }
  }

  /// Export to file and return the file path
  Future<File?> exportToFile(String filePath) async {
    try {
      final jsonString = await exportToJson();
      final file = File(filePath);
      await file.writeAsString(jsonString);
      return file;
    } catch (e) {
      debugPrint('Error exporting to file: $e');
      return null;
    }
  }

  /// Import from file
  Future<bool> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString);
    } catch (e) {
      debugPrint('Error importing from file: $e');
      return false;
    }
  }
}
