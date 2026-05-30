import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/utils/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

part 'subs_controller.g.dart';

// Clamps day to the last valid day of the given month (handles Feb, 30-day months, etc.)
int _clampDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return day.clamp(1, lastDay);
}

@riverpod
Future<JsonSqFliteStorage> subsStorage(Ref ref) async {
  JsonSqFliteStorage storage = await JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'subs.db'),
  );
  ref
    ..onDispose(storage.close)
    ..keepAlive();
  return storage;
}

@Riverpod(keepAlive: true)
@JsonPersist()
class SubsController extends _$SubsController {
  @override
  FutureOr<List<SubSlice>> build() async {
    await persist(
      ref.watch(subsStorageProvider.future),
      options: StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: "v2",
      ),
    ).future;
    await scheduleNotification();
    return state.value ?? [];
  }

  void addSlice(SubSlice slice) {
    state = AsyncValue.data(List.of(state.value ?? [])..add(slice));
    scheduleNotification();
  }

  Future<void> scheduleNotification() async {
    await LocalNotificationService.instance.cancelAllNotifications();
    final subs = state.value ?? [];
    for (int i = 0; i < subs.length; i++) {
      await scheduleRepeatingNotification(subs[i], i);
    }
  }

  Future<void> scheduleRepeatingNotification(SubSlice slice, int index) async {
    final now = tz.TZDateTime.now(tz.local);

    // Compute the next due date for this subscription
    tz.TZDateTime nextDate;
    DateTimeComponents repeatComponents;

    switch (slice.frequency) {
      case Frequency.daily:
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12, 0, 0);
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        repeatComponents = DateTimeComponents.time;
        break;
      case Frequency.weekly:
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12, 0, 0);
        while (nextDate.weekday != slice.startDate.weekday || nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        repeatComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case Frequency.monthly:
        final curDay = _clampDay(now.year, now.month, slice.startDate.day);
        nextDate = tz.TZDateTime(tz.local, now.year, now.month, curDay, 12, 0, 0);
        if (nextDate.isBefore(now)) {
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          final nextDay = _clampDay(nextYear, nextMonth, slice.startDate.day);
          nextDate = tz.TZDateTime(tz.local, nextYear, nextMonth, nextDay, 12, 0, 0);
        }
        repeatComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case Frequency.yearly:
        nextDate = tz.TZDateTime(tz.local, now.year, slice.startDate.month, slice.startDate.day, 12, 0, 0);
        if (nextDate.isBefore(now)) {
          nextDate = tz.TZDateTime(tz.local, now.year + 1, slice.startDate.month, slice.startDate.day, 12, 0, 0);
        }
        repeatComponents = DateTimeComponents.dateAndTime;
        break;
    }

    final idDue = index * 2;
    final idDueTomorrow = index * 2 + 1;

    // "Due today" — repeats at the correct cadence
    await LocalNotificationService.instance.scheduleNotification(
      id: idDue,
      title: "Subscription Reminder",
      body: "Your ${slice.name} subscription is due today.",
      scheduledDate: nextDate,
      matchDateTimeComponents: repeatComponents,
    );

    // "Due tomorrow" — skip for daily (every day is "tomorrow")
    if (slice.frequency != Frequency.daily) {
      await LocalNotificationService.instance.scheduleNotification(
        id: idDueTomorrow,
        title: "Subscription Reminder",
        body: "Your ${slice.name} subscription is due tomorrow.",
        scheduledDate: nextDate.subtract(const Duration(days: 1)),
        matchDateTimeComponents: repeatComponents,
      );
    }
  }

  void removeAt(int index) {
    state = AsyncValue.data(List.of(state.value ?? [])..removeAt(index));
    scheduleNotification();
  }

  void updateAt(int index, SubSlice updated) {
    state = AsyncValue.data(List.of(state.value ?? [])..[index] = updated);
    scheduleNotification();
  }

  void clear() {
    state = AsyncValue.data([]);
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
