import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import '../models/settings_view_model.dart';
import '../services/widget_update_service.dart';
import 'subs_controller.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
Future<JsonSqFliteStorage> settingsStorage(Ref ref) async {
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
    return state.value ??
        const SettingsViewModel(
          theme: ThemeMode.light,
          currency: Currency.try_,
          isFirstTime: true,
        );
  }

  void updateTheme(ThemeMode mode) {
    state = AsyncData(state.value!.copyWith(theme: mode));
  }

  void updateColorScheme(FlexScheme scheme) {
    state = AsyncData(state.value!.copyWith(colorScheme: scheme));
  }

  void updateCurrency(Currency currency) {
    state = AsyncData(state.value!.copyWith(currency: currency));
    final subs = ref.read(subsControllerProvider).value ?? [];
    unawaited(WidgetUpdateService.instance.update(subs, currency.symbol));
  }

  void updateUserName(String? userName) {
    state = AsyncData(state.value!.copyWith(userName: userName));
  }

  void updateUserEmail(String? userEmail) {
    state = AsyncData(state.value!.copyWith(email: userEmail));
  }

  void updateIsFirstTime({required bool isFirstTime}) {
    state = AsyncData(state.value!.copyWith(isFirstTime: isFirstTime));
  }

}
