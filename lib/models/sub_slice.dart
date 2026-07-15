import 'package:freezed_annotation/freezed_annotation.dart';
import 'brand.dart';

part 'sub_slice.freezed.dart';
part 'sub_slice.g.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

enum ReminderMode { none, onDay, dayBefore, both }

enum SubStatus { active, freeTrial, paused, cancelled }

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
    @Default(ReminderMode.both) ReminderMode reminderMode,
    String? cardLastFour,
    @Default(SubStatus.active) SubStatus status,
    String? note,
    DateTime? trialEndDate,
  }) = _SubSlice;

  factory SubSlice.fromJson(Map<String, dynamic> json) =>
      _$SubSliceFromJson(json);

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
}

extension SubSliceListX on List<SubSlice> {
  List<SubSlice> get activeOnly =>
      where((s) => s.status == SubStatus.active).toList();
}
