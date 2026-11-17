import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'brand.dart';
import 'currency.dart';
import 'price_change.dart';

export 'price_change.dart';

part 'sub_slice.freezed.dart';
part 'sub_slice.g.dart';

enum Frequency { daily, weekly, monthly, yearly }

enum ReminderMode { none, onDay, dayBefore, both }

enum SubStatus { active, freeTrial, paused, cancelled }

@freezed
abstract class SubSlice with _$SubSlice {
  const factory SubSlice({
    /// Stable identity. Empty only for rows saved before ids existed;
    /// `SubsController` fills it on load.
    @Default('') String id,
    Brand? brand,
    required String name,
    required double amount,
    required int color,
    required DateTime startDate,
    @JsonKey(unknownEnumValue: Frequency.monthly)
    @Default(Frequency.monthly)
    Frequency frequency,
    String? category,
    @JsonKey(unknownEnumValue: ReminderMode.both)
    @Default(ReminderMode.both)
    ReminderMode reminderMode,
    String? cardLastFour,

    /// Free-text payment method ("Credit card", "PayPal"), grouped on in
    /// analytics together with [cardLastFour].
    String? paymentMethod,
    @JsonKey(unknownEnumValue: SubStatus.active)
    @Default(SubStatus.active)
    SubStatus status,
    String? note,
    DateTime? trialEndDate,

    /// Charges every [interval] periods of [frequency] (e.g. 3 x monthly).
    /// Use [period] when computing; it never returns less than 1.
    @Default(1) int interval,

    /// How many days before a charge the "due soon" reminder fires.
    @Default(1) int remindDaysBefore,

    /// When the subscription was cancelled in the app; null if unknown
    /// (cancelled before this field existed) or not cancelled.
    DateTime? cancelledAt,

    /// User-entered link to manage or cancel the subscription.
    String? manageUrl,

    /// Currency this subscription is billed in; null means the main
    /// currency from settings. Unknown codes (newer app) fall back to null.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    Currency? currency,

    /// Earlier prices, oldest first. Recorded by `SubsController.updateSlice`.
    @PriceHistoryConverter()
    @Default(<PriceChange>[])
    List<PriceChange> priceHistory,

    /// How many people split the cost, including you. Use [people].
    @Default(1) int sharedWith,

    /// False for subscriptions paid by hand (rent, invoices): each charge is
    /// "unpaid" until marked in [paidCharges].
    @Default(true) bool autoRenew,

    /// Charge dates (midnight) marked as paid, oldest first; the most recent
    /// [maxPaidCharges] are kept.
    @PaidChargesConverter() @Default(<DateTime>[]) List<DateTime> paidCharges,

    /// No reminders for this subscription before this time (snoozed).
    DateTime? remindersSnoozedUntil,
  }) = _SubSlice;

  factory SubSlice.fromJson(Map<String, dynamic> json) =>
      _$SubSliceFromJson(json);

  const SubSlice._();

  static final _random = Random.secure();

  /// Unique, sortable-enough id without extra dependencies.
  static String newId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(8, (_) => _random.nextInt(36).toRadixString(36));
    return '$time-${rand.join()}';
  }

  /// [interval], guarded against invalid stored values (0 would hang date
  /// calculations, a huge one would overflow DateTime).
  int get period => interval.clamp(1, maxInterval);

  /// [remindDaysBefore], guarded against invalid stored values.
  int get daysBefore => remindDaysBefore.clamp(1, maxRemindDaysBefore);

  static const maxInterval = 12;
  static const maxPeople = 50;
  static const maxPaidCharges = 24;

  /// [sharedWith], guarded against invalid stored values.
  int get people => sharedWith.clamp(1, maxPeople);

  /// Your part of [amount] when the cost is shared.
  double get myAmount => amount / people;
  static const maxRemindDaysBefore = 30;

  /// Average days per month, used to normalise every frequency consistently.
  static const _daysPerMonth = 365 / 12;

  double get monthlyAmount {
    final perPeriod = switch (frequency) {
      Frequency.daily => amount * _daysPerMonth,
      Frequency.weekly => amount * _daysPerMonth / 7,
      Frequency.monthly => amount,
      Frequency.yearly => amount / 12,
    };
    return perPeriod / period;
  }
}

extension SubSliceListX on List<SubSlice> {
  List<SubSlice> get activeOnly =>
      where((s) => s.status == SubStatus.active).toList();
}

/// Decodes paid charge dates one by one, skipping invalid entries, so a bad
/// value can't make the whole subscription list undecodable.
class PaidChargesConverter implements JsonConverter<List<DateTime>, Object?> {
  const PaidChargesConverter();

  @override
  List<DateTime> fromJson(Object? json) => [
    if (json is List)
      for (final e in json)
        if (e is String)
          if (DateTime.tryParse(e) case final d?)
            DateTime(d.year, d.month, d.day),
  ];

  @override
  List<String> toJson(List<DateTime> dates) => [
    for (final d in dates) d.toIso8601String(),
  ];
}
