// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_slice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubSlice _$SubSliceFromJson(Map<String, dynamic> json) => _SubSlice(
  id: json['id'] as String? ?? '',
  brand: json['brand'] == null
      ? null
      : Brand.fromJson(json['brand'] as Map<String, dynamic>),
  name: json['name'] as String,
  amount: (json['amount'] as num).toDouble(),
  color: (json['color'] as num).toInt(),
  startDate: DateTime.parse(json['startDate'] as String),
  frequency:
      $enumDecodeNullable(
        _$FrequencyEnumMap,
        json['frequency'],
        unknownValue: Frequency.monthly,
      ) ??
      Frequency.monthly,
  category: json['category'] as String?,
  reminderMode:
      $enumDecodeNullable(
        _$ReminderModeEnumMap,
        json['reminderMode'],
        unknownValue: ReminderMode.both,
      ) ??
      ReminderMode.both,
  cardLastFour: json['cardLastFour'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  status:
      $enumDecodeNullable(
        _$SubStatusEnumMap,
        json['status'],
        unknownValue: SubStatus.active,
      ) ??
      SubStatus.active,
  note: json['note'] as String?,
  trialEndDate: json['trialEndDate'] == null
      ? null
      : DateTime.parse(json['trialEndDate'] as String),
  interval: (json['interval'] as num?)?.toInt() ?? 1,
  remindDaysBefore: (json['remindDaysBefore'] as num?)?.toInt() ?? 1,
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  manageUrl: json['manageUrl'] as String?,
  currency: $enumDecodeNullable(
    _$CurrencyEnumMap,
    json['currency'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  priceHistory: json['priceHistory'] == null
      ? const <PriceChange>[]
      : const PriceHistoryConverter().fromJson(json['priceHistory']),
  sharedWith: (json['sharedWith'] as num?)?.toInt() ?? 1,
  autoRenew: json['autoRenew'] as bool? ?? true,
  paidCharges: json['paidCharges'] == null
      ? const <DateTime>[]
      : const PaidChargesConverter().fromJson(json['paidCharges']),
  remindersSnoozedUntil: json['remindersSnoozedUntil'] == null
      ? null
      : DateTime.parse(json['remindersSnoozedUntil'] as String),
);

Map<String, dynamic> _$SubSliceToJson(_SubSlice instance) => <String, dynamic>{
  'id': instance.id,
  'brand': instance.brand,
  'name': instance.name,
  'amount': instance.amount,
  'color': instance.color,
  'startDate': instance.startDate.toIso8601String(),
  'frequency': _$FrequencyEnumMap[instance.frequency]!,
  'category': instance.category,
  'reminderMode': _$ReminderModeEnumMap[instance.reminderMode]!,
  'cardLastFour': instance.cardLastFour,
  'paymentMethod': instance.paymentMethod,
  'status': _$SubStatusEnumMap[instance.status]!,
  'note': instance.note,
  'trialEndDate': instance.trialEndDate?.toIso8601String(),
  'interval': instance.interval,
  'remindDaysBefore': instance.remindDaysBefore,
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
  'manageUrl': instance.manageUrl,
  'currency': _$CurrencyEnumMap[instance.currency],
  'priceHistory': const PriceHistoryConverter().toJson(instance.priceHistory),
  'sharedWith': instance.sharedWith,
  'autoRenew': instance.autoRenew,
  'paidCharges': const PaidChargesConverter().toJson(instance.paidCharges),
  'remindersSnoozedUntil': instance.remindersSnoozedUntil?.toIso8601String(),
};

const _$FrequencyEnumMap = {
  Frequency.daily: 'daily',
  Frequency.weekly: 'weekly',
  Frequency.monthly: 'monthly',
  Frequency.yearly: 'yearly',
};

const _$ReminderModeEnumMap = {
  ReminderMode.none: 'none',
  ReminderMode.onDay: 'onDay',
  ReminderMode.dayBefore: 'dayBefore',
  ReminderMode.both: 'both',
};

const _$SubStatusEnumMap = {
  SubStatus.active: 'active',
  SubStatus.freeTrial: 'freeTrial',
  SubStatus.paused: 'paused',
  SubStatus.cancelled: 'cancelled',
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
