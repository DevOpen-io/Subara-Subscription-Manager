import 'dart:typed_data';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

export 'currency.dart';

part 'settings_view_model.freezed.dart';
part 'settings_view_model.g.dart';

@freezed
abstract class SettingsViewModel with _$SettingsViewModel {
  const factory SettingsViewModel({
    required ThemeMode theme,
    required Currency currency,
    @Uint8ListConverter() Uint8List? profilePicture,
    String? userName,
    String? email,
    bool? isFirstTime,
    @FlexSchemeConverter()
    @Default(FlexScheme.bahamaBlue)
    FlexScheme colorScheme,

    /// Reminder time of day, in minutes after midnight.
    @Default(12 * 60) int reminderMinutes,

    /// User-entered rates: how many units of [currency] one unit of each
    /// other currency is worth. Never fetched, so the app stays offline.
    @ExchangeRatesConverter()
    @Default(<Currency, double>{})
    Map<Currency, double> exchangeRates,

    /// Monthly spending limit in the main currency; null = no budget.
    @PositiveDoubleConverter() double? monthlyBudget,

    /// Ask for the device lock / biometrics to open the app.
    @Default(false) bool appLock,

    /// User-added categories, after the built-in ones.
    @StringListConverter() @Default(<String>[]) List<String> customCategories,
  }) = _SettingsViewModel;

  factory SettingsViewModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsViewModelFromJson(json);
}

class Uint8ListConverter implements JsonConverter<Uint8List?, List<dynamic>?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return Uint8List.fromList(List.from(json));
  }

  @override
  List<int>? toJson(Uint8List? object) {
    if (object == null) return null;
    return object.toList();
  }
}

class FlexSchemeConverter implements JsonConverter<FlexScheme, String> {
  const FlexSchemeConverter();

  @override
  FlexScheme fromJson(String json) => FlexScheme.values.firstWhere(
    (e) => e.name == json,
    orElse: () => FlexScheme.bahamaBlue,
  );

  @override
  String toJson(FlexScheme object) => object.name;
}

/// Decodes a positive number or null; anything else (an invalid or
/// non-positive value) becomes null instead of failing the settings decode.
class PositiveDoubleConverter implements JsonConverter<double?, Object?> {
  const PositiveDoubleConverter();

  @override
  double? fromJson(Object? json) =>
      json is num && json.isFinite && json > 0 ? json.toDouble() : null;

  @override
  double? toJson(double? value) => value;
}

/// Decodes a list of non-empty, unique strings, skipping anything else.
class StringListConverter implements JsonConverter<List<String>, Object?> {
  const StringListConverter();

  @override
  List<String> fromJson(Object? json) {
    if (json is! List) return const [];
    final out = <String>[];
    for (final e in json) {
      if (e is String && e.trim().isNotEmpty && !out.contains(e.trim())) {
        out.add(e.trim());
      }
    }
    return out;
  }

  @override
  List<String> toJson(List<String> value) => value;
}
