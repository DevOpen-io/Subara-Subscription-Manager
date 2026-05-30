import 'dart:typed_data';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_view_model.freezed.dart';
part 'settings_view_model.g.dart';

enum Currency {
  try_('₺', 'Turkish Lira'),
  usd('\$', 'US Dollar'),
  eur('€', 'Euro'),
  gbp('£', 'British Pound'),
  jpy('¥', 'Japanese Yen'),
  cad('C\$', 'Canadian Dollar'),
  aud('A\$', 'Australian Dollar');

  final String symbol;
  final String label;

  const Currency(this.symbol, this.label);
}

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
  }) = _SettingsViewModel;

  factory SettingsViewModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsViewModelFromJson(json);
}

class Uint8ListConverter implements JsonConverter<Uint8List?, List?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(List? json) {
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
