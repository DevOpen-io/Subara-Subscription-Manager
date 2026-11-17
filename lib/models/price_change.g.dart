// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceChange _$PriceChangeFromJson(Map<String, dynamic> json) => _PriceChange(
  amount: (json['amount'] as num).toDouble(),
  until: DateTime.parse(json['until'] as String),
  currency: $enumDecodeNullable(
    _$CurrencyEnumMap,
    json['currency'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
);

Map<String, dynamic> _$PriceChangeToJson(_PriceChange instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'until': instance.until.toIso8601String(),
      'currency': _$CurrencyEnumMap[instance.currency],
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
