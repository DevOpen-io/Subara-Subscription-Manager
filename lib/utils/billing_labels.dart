import 'package:easy_localization/easy_localization.dart';

import '../models/sub_slice.dart';

/// "Monthly", "Every 3 months" / "Aylık", "3 ayda bir".
String cycleLabelFor(Frequency frequency, int interval) => interval <= 1
    ? 'frequency.${frequency.name}'.tr()
    : 'frequency.every.${frequency.name}'.tr(args: ['$interval']);

/// "1 day before", "7 days before".
String daysBeforeLabel(int days) => 'detail.reminder_days_before'.plural(days);

extension SubSliceLabels on SubSlice {
  String get cycleLabel => cycleLabelFor(frequency, period);

  /// Price suffix: "/mo", "/3 mo".
  String get shortCycleLabel => period == 1
      ? 'frequency.short.${frequency.name}'.tr()
      : 'frequency.short_every.${frequency.name}'.tr(args: ['$period']);

  String get reminderLabel => switch (reminderMode) {
    ReminderMode.none => 'detail.reminder_none'.tr(),
    ReminderMode.onDay => 'detail.reminder_onDay'.tr(),
    ReminderMode.dayBefore => daysBeforeLabel(daysBefore),
    ReminderMode.both =>
      '${'detail.reminder_onDay'.tr()} + ${daysBeforeLabel(daysBefore)}',
  };
}
