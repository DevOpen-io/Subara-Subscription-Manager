import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'price_change.freezed.dart';
part 'price_change.g.dart';

/// A previous price: [amount] (in [currency], null = main currency) was
/// charged until [until], when the user changed it.
@freezed
abstract class PriceChange with _$PriceChange {
  const factory PriceChange({
    required double amount,
    required DateTime until,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    Currency? currency,
  }) = _PriceChange;

  factory PriceChange.fromJson(Map<String, dynamic> json) =>
      _$PriceChangeFromJson(json);
}

/// Decodes price history entry by entry, skipping any that are invalid, so
/// one bad entry can't make the whole subscription list undecodable.
class PriceHistoryConverter
    implements JsonConverter<List<PriceChange>, Object?> {
  const PriceHistoryConverter();

  @override
  List<PriceChange> fromJson(Object? json) {
    if (json is! List) return const [];
    final history = <PriceChange>[];
    for (final e in json) {
      if (e is! Map) continue;
      try {
        history.add(PriceChange.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {
        // Skip just this entry.
      }
    }
    return history;
  }

  @override
  List<Map<String, dynamic>> toJson(List<PriceChange> history) => [
    for (final p in history) p.toJson(),
  ];
}
