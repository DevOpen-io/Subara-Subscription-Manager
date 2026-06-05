import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:subs_tracker/models/brand.dart';

part 'sub_slice.freezed.dart';
part 'sub_slice.g.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

@freezed
abstract class SubSlice with _$SubSlice {
  const factory SubSlice({
    Brand? brand,
    required String name,
    required double amount,
    required int color,
    required DateTime startDate,
    @Default(Frequency.monthly) Frequency frequency,
    String? category,
  }) = _SubSlice;

  const SubSlice._();

  double get monthlyAmount {
    switch (frequency) {
      case Frequency.daily:
        return amount * 30;
      case Frequency.weekly:
        return amount * 4.33;
      case Frequency.monthly:
        return amount;
      case Frequency.yearly:
        return amount / 12;
    }
  }

  factory SubSlice.fromJson(Map<String, dynamic> json) =>
      _$SubSliceFromJson(json);
}
