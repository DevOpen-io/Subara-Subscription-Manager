import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import '../models/categories.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../services/widget_update_service.dart';
import '../utils/notification_service.dart';
import 'subs_controller.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
Future<Storage<String, String>> settingsStorage(Ref ref) async {
  final storage = await JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'settings.db'),
  );
  ref.onDispose(storage.close);
  return storage;
}

@Riverpod(keepAlive: true)
@JsonPersist()
class SettingsController extends _$SettingsController {
  @override
  FutureOr<SettingsViewModel> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: 'v1',
      ),
    ).future;
    final settings =
        state.value ??
        const SettingsViewModel(
          theme: ThemeMode.light,
          currency: Currency.try_,
          isFirstTime: true,
        );
    // Onboarding already done (or restored from a backup): make sure we have
    // permission. The OS doesn't prompt again once the user has decided.
    if (settings.isFirstTime == false) {
      unawaited(ref.read(notificationServiceProvider).requestPermission());
    }
    return settings;
  }

  void updateTheme(ThemeMode mode) {
    state = AsyncData(state.value!.copyWith(theme: mode));
  }

  void updateColorScheme(FlexScheme scheme) {
    state = AsyncData(state.value!.copyWith(colorScheme: scheme));
  }

  void updateCurrency(Currency currency) {
    final old = state.value!;
    final updated = old.copyWith(
      currency: currency,
      exchangeRates: rebaseRates(
        old.exchangeRates,
        from: old.currency,
        to: currency,
      ),
    );
    state = AsyncData(updated);
    _refreshWidget(updated);
  }

  /// Sets how many main-currency units one unit of [currency] is worth;
  /// null removes the rate.
  void setExchangeRate(Currency currency, double? rate) {
    final rates = {...state.value!.exchangeRates};
    if (rate == null || !rate.isFinite || rate <= 0) {
      rates.remove(currency);
    } else {
      rates[currency] = rate;
    }
    final updated = state.value!.copyWith(exchangeRates: rates);
    state = AsyncData(updated);
    _refreshWidget(updated);
  }

  /// Sets the monthly budget (main currency); null or non-positive clears it.
  void setMonthlyBudget(double? budget) {
    final valid = budget != null && budget.isFinite && budget > 0;
    state = AsyncData(
      state.value!.copyWith(monthlyBudget: valid ? budget : null),
    );
  }

  /// Adds a category; false if empty or it already exists (ignoring case),
  /// built-in ones included.
  bool addCategory(String name) {
    final trimmed = name.trim();
    final lower = trimmed.toLowerCase();
    final current = state.value!.customCategories;
    if (trimmed.isEmpty ||
        [
          ...builtInCategories,
          ...current,
        ].any((c) => c.toLowerCase() == lower)) {
      return false;
    }
    state = AsyncData(
      state.value!.copyWith(customCategories: [...current, trimmed]),
    );
    return true;
  }

  void removeCategory(String name) {
    state = AsyncData(
      state.value!.copyWith(
        customCategories: [
          ...state.value!.customCategories.where((c) => c != name),
        ],
      ),
    );
  }

  void setAppLock({required bool enabled}) {
    state = AsyncData(state.value!.copyWith(appLock: enabled));
  }

  void _refreshWidget(SettingsViewModel settings) {
    final subs = ref.read(subsControllerProvider).value ?? [];
    unawaited(
      WidgetUpdateService.instance.update(
        settings.inMain(subs).subs,
        settings.currency.symbol,
      ),
    );
  }

  void updateReminderMinutes(int minutes) {
    state = AsyncData(state.value!.copyWith(reminderMinutes: minutes));
    unawaited(
      ref.read(subsControllerProvider.notifier).scheduleNotifications(),
    );
  }

  void updateUserName(String? userName) {
    state = AsyncData(state.value!.copyWith(userName: userName));
  }

  void updateUserEmail(String? userEmail) {
    state = AsyncData(state.value!.copyWith(email: userEmail));
  }

  void updateIsFirstTime({required bool isFirstTime}) {
    state = AsyncData(state.value!.copyWith(isFirstTime: isFirstTime));
    // Ask once onboarding is done, so the prompt has context.
    if (!isFirstTime) {
      unawaited(ref.read(notificationServiceProvider).requestPermission());
    }
  }
}
