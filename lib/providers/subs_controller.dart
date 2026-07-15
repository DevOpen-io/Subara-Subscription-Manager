import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;
import 'package:in_app_review/in_app_review.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/sub_slice.dart';
import '../services/widget_update_service.dart';
import '../utils/notification_service.dart';
import 'settings_controller.dart';

part 'subs_controller.g.dart';

// Clamps day to the last valid day of the given month (handles Feb, 30-day months, etc.)
int _clampDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return day.clamp(1, lastDay);
}

@Riverpod(keepAlive: true)
Future<JsonSqFliteStorage> subsStorage(Ref ref) async {
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
    await persist(
      ref.watch(subsStorageProvider.future),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: 'v2',
      ),
    ).future;
    await scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
    return state.value ?? [];
  }

  void addSlice(SubSlice slice) {
    state = AsyncValue.data(List.of(state.value ?? [])..add(slice));
    scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
    final count = state.value?.length ?? 0;
    if (count % 3 == 0) {
      InAppReview.instance.isAvailable().then((available) {
        if (available) InAppReview.instance.requestReview();
      });
    }
  }

  Future<void> scheduleNotification() async {
    await LocalNotificationService.instance.cancelAllNotifications();
    final subs = state.value ?? [];
    for (var i = 0; i < subs.length; i++) {
      await scheduleRepeatingNotification(subs[i], i);
    }
  }

  Future<void> scheduleRepeatingNotification(SubSlice slice, int index) async {
    if (slice.reminderMode == ReminderMode.none) return;
    if (slice.status == SubStatus.cancelled || slice.status == SubStatus.paused) return;

    final idDue = index * 2;
    final idDueTomorrow = index * 2 + 1;

    if (slice.status == SubStatus.freeTrial) {
      await _scheduleTrialEndNotification(slice, idDue, idDueTomorrow);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    // Compute the next due date for this subscription
    tz.TZDateTime nextDate;
    DateTimeComponents repeatComponents;

    switch (slice.frequency) {
      case Frequency.daily:
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12);
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        repeatComponents = DateTimeComponents.time;
      case Frequency.weekly:
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12);
        while (nextDate.weekday != slice.startDate.weekday || nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        repeatComponents = DateTimeComponents.dayOfWeekAndTime;
      case Frequency.monthly:
        final curDay = _clampDay(now.year, now.month, slice.startDate.day);
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, curDay, 12);
        if (nextDate.isBefore(now)) {
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          final nextDay = _clampDay(nextYear, nextMonth, slice.startDate.day);
          nextDate = tz.TZDateTime(tz.local, nextYear, nextMonth, nextDay, 12);
        }
        repeatComponents = DateTimeComponents.dayOfMonthAndTime;
      case Frequency.yearly:
        nextDate = tz.TZDateTime(tz.local, now.year, slice.startDate.month, slice.startDate.day, 12);
        if (nextDate.isBefore(now)) {
          nextDate = tz.TZDateTime(tz.local, now.year + 1, slice.startDate.month, slice.startDate.day, 12);
        }
        repeatComponents = DateTimeComponents.dateAndTime;
    }

    // "Due today" — repeats at the correct cadence
    if (slice.reminderMode == ReminderMode.onDay || slice.reminderMode == ReminderMode.both) {
      await LocalNotificationService.instance.scheduleNotification(
        id: idDue,
        title: 'Subscription Reminder',
        body: 'Your ${slice.name} subscription is due today.',
        scheduledDate: nextDate,
        matchDateTimeComponents: repeatComponents,
      );
    }

    // "Due tomorrow" — skip for daily (every day is "tomorrow")
    if (slice.frequency != Frequency.daily &&
        (slice.reminderMode == ReminderMode.dayBefore || slice.reminderMode == ReminderMode.both)) {
      await LocalNotificationService.instance.scheduleNotification(
        id: idDueTomorrow,
        title: 'Subscription Reminder',
        body: 'Your ${slice.name} subscription is due tomorrow.',
        scheduledDate: nextDate.subtract(const Duration(days: 1)),
        matchDateTimeComponents: repeatComponents,
      );
    }
  }

  Future<void> _scheduleTrialEndNotification(SubSlice slice, int idDue, int idDueTomorrow) async {
    final trialEndDate = slice.trialEndDate;
    if (trialEndDate == null) return;
    final now = tz.TZDateTime.now(tz.local);
    final endDate = tz.TZDateTime(
      tz.local,
      trialEndDate.year,
      trialEndDate.month,
      trialEndDate.day,
      12,
    );

    // One-shot "trial ends today" — trial end dates don't repeat.
    // If noon already passed but it's still the trial's last day, fire almost immediately
    // instead of dropping the reminder.
    final isEndDateToday =
        endDate.year == now.year && endDate.month == now.month && endDate.day == now.day;
    final dueAt = endDate.isAfter(now) ? endDate : (isEndDateToday ? now.add(const Duration(seconds: 5)) : null);
    if ((slice.reminderMode == ReminderMode.onDay || slice.reminderMode == ReminderMode.both) &&
        dueAt != null) {
      await LocalNotificationService.instance.scheduleNotification(
        id: idDue,
        title: 'Subscription Reminder',
        body: 'Your ${slice.name} free trial ends today.',
        scheduledDate: dueAt,
      );
    }

    // One-shot "trial ends tomorrow"
    final dayBefore = endDate.subtract(const Duration(days: 1));
    if ((slice.reminderMode == ReminderMode.dayBefore || slice.reminderMode == ReminderMode.both) &&
        dayBefore.isAfter(now)) {
      await LocalNotificationService.instance.scheduleNotification(
        id: idDueTomorrow,
        title: 'Subscription Reminder',
        body: 'Your ${slice.name} free trial ends tomorrow.',
        scheduledDate: dayBefore,
      );
    }
  }

  void removeAt(int index) {
    state = AsyncValue.data(List.of(state.value ?? [])..removeAt(index));
    scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
  }

  void updateAt(int index, SubSlice updated) {
    state = AsyncValue.data(List.of(state.value ?? [])..[index] = updated);
    scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
  }

  void reorderSlices(int oldIndex, int newIndex) {
    final list = List<SubSlice>.from(state.value ?? []);
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(insertIndex, item);
    state = AsyncValue.data(list);
    scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
  }

  void sortSlices(int Function(SubSlice, SubSlice) compare) {
    final list = List<SubSlice>.from(state.value ?? [])..sort(compare);
    state = AsyncValue.data(list);
    scheduleNotification();
    final currency = ref.read(settingsControllerProvider).value?.currency.symbol ?? '';
    unawaited(WidgetUpdateService.instance.update(state.value ?? [], currency));
  }

  void clear() {
    state = const AsyncValue.data([]);
    scheduleNotification();
  }

  /// Export subscriptions to JSON format
  Future<String> exportToJson() async {
    final subs = state.value ?? [];
    final jsonList = subs.map((sub) => sub.toJson()).toList();
    return jsonEncode({
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'subscriptions': jsonList,
    });
  }

  /// Import subscriptions from JSON format
  Future<bool> importFromJson(String jsonString) async {
    if (!ref.mounted) return false;
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final subscriptionsList = decoded['subscriptions'] as List<dynamic>;

      final importedSubs = subscriptionsList
          .map((json) => SubSlice.fromJson(json as Map<String, dynamic>))
          .toList();
      // Replace current subscriptions with imported ones
      state = AsyncValue.data(importedSubs);
      await scheduleNotification();
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
