import 'dart:typed_data';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:subs_tracker/models/settings_view_model.dart';

part 'settings_controller.g.dart';

@riverpod
Future<JsonSqFliteStorage> settingsStorage(Ref ref) async {
  JsonSqFliteStorage storage = await JsonSqFliteStorage.open(
    join(await getDatabasesPath(), 'settings.db'),
  );
  ref
    ..onDispose(storage.close)
    ..keepAlive();
  return storage;
}

@Riverpod(keepAlive: true)
@JsonPersist()
class SettingsController extends _$SettingsController {
  @override
  FutureOr<SettingsViewModel> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
        destroyKey: "v1",
      ),
    ).future;
    return state.value ??
        SettingsViewModel(
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
  }

  void updateProfilePicture(Uint8List? profilePicture) {
    state = AsyncData(state.value!.copyWith(profilePicture: profilePicture));
  }

  void updateUserName(String? userName) {
    state = AsyncData(state.value!.copyWith(userName: userName));
  }

  void updateUserEmail(String? userEmail) {
    state = AsyncData(state.value!.copyWith(email: userEmail));
  }

  void updateIsFirstTime(bool isFirstTime) {
    state = AsyncData(state.value!.copyWith(isFirstTime: isFirstTime));
  }
}
