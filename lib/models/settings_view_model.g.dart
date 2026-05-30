// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsViewModel _$SettingsViewModelFromJson(Map<String, dynamic> json) =>
    _SettingsViewModel(
      theme: $enumDecode(_$ThemeModeEnumMap, json['theme']),
      currency: $enumDecode(_$CurrencyEnumMap, json['currency']),
      profilePicture: const Uint8ListConverter().fromJson(
        json['profilePicture'] as List?,
      ),
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      isFirstTime: json['isFirstTime'] as bool?,
      colorScheme: json['colorScheme'] == null
          ? FlexScheme.bahamaBlue
          : const FlexSchemeConverter().fromJson(json['colorScheme'] as String),
    );

Map<String, dynamic> _$SettingsViewModelToJson(
  _SettingsViewModel instance,
) => <String, dynamic>{
  'theme': _$ThemeModeEnumMap[instance.theme]!,
  'currency': _$CurrencyEnumMap[instance.currency]!,
  'profilePicture': const Uint8ListConverter().toJson(instance.profilePicture),
  'userName': instance.userName,
  'email': instance.email,
  'isFirstTime': instance.isFirstTime,
  'colorScheme': const FlexSchemeConverter().toJson(instance.colorScheme),
};

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$CurrencyEnumMap = {
  Currency.try_: 'try_',
  Currency.usd: 'usd',
  Currency.eur: 'eur',
  Currency.gbp: 'gbp',
  Currency.jpy: 'jpy',
  Currency.cad: 'cad',
  Currency.aud: 'aud',
};
