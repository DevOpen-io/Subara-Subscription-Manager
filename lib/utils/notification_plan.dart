import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;

import '../models/billing.dart';
import '../models/sub_slice.dart';

enum ReminderKind {
  dueToday,
  dueSoon,
  trialEndsToday,
  trialEndsSoon,

  /// A manually paid charge that hasn't been marked paid.
  overdue,
}

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.sub,
    required this.kind,
    required this.at,
    this.repeat,
    this.daysBefore = 0,
    this.markPaidCharge,
  });

  final int id;
  final SubSlice sub;
  final ReminderKind kind;

  /// First fire time (local).
  final DateTime at;

  /// OS-level repeat, or null for a one-shot that is re-planned on the next
  /// app start or subscription change.
  final DateTimeComponents? repeat;

  /// Days between this reminder and the charge / trial end (0 = same day).
  final int daysBefore;

  /// The manually paid charge this reminder is about, for a "Paid" button;
  /// null when there is nothing to mark.
  final DateTime? markPaidCharge;
}

/// iOS keeps at most 64 pending local notifications per app.
const maxPendingReminders = 64;

/// How many future charges get one-shot reminders when the OS can't repeat
/// them, so reminders keep coming even if the app isn't opened for months.
const oneShotHorizon = 12;

/// Default reminder time of day, in minutes after midnight (12:00).
const defaultReminderMinutes = 12 * 60;

typedef _Draft = ({
  SubSlice sub,
  ReminderKind kind,
  DateTime at,
  DateTimeComponents? repeat,
  int daysBefore,
  DateTime? markPaidCharge,
});

/// Pure scheduling plan: which reminders to register for [subs] at [now],
/// firing at [fireMinutes] after midnight.
///
/// A reminder only repeats at OS level when the OS rule matches every future
/// reminder (e.g. "day 15 of each month"). Anything else (the 29th–31st, a
/// reminder that crosses a month end, Feb 29, every-N-periods cycles) gets
/// one-shots for the next [oneShotHorizon] charges. The result is sorted by
/// fire time and limited to the [cap] soonest reminders.
List<PlannedReminder> planReminders(
  List<SubSlice> subs,
  DateTime now, {
  int cap = maxPendingReminders,
  int fireMinutes = defaultReminderMinutes,
}) {
  DateTime fireOn(DateTime day, [int daysBefore = 0]) => DateTime(
    day.year,
    day.month,
    day.day - daysBefore,
    fireMinutes ~/ 60,
    fireMinutes % 60,
  );

  final drafts = <_Draft>[];

  for (final sub in subs) {
    if (sub.reminderMode == ReminderMode.none) continue;
    if (sub.status == SubStatus.paused || sub.status == SubStatus.cancelled) {
      continue;
    }
    final onDay =
        sub.reminderMode == ReminderMode.onDay ||
        sub.reminderMode == ReminderMode.both;
    final before =
        sub.reminderMode == ReminderMode.dayBefore ||
        sub.reminderMode == ReminderMode.both;
    final days = sub.daysBefore;
    // Snoozed: nothing fires before this time.
    final quietUntil = sub.remindersSnoozedUntil;
    bool allowed(DateTime at) => quietUntil == null || !at.isBefore(quietUntil);

    if (sub.status == SubStatus.freeTrial) {
      final end = sub.trialEndDate;
      if (end == null) continue;
      final endAt = fireOn(end);
      final endsToday = _sameDay(end, now);
      if (onDay && (endAt.isAfter(now) || endsToday) && allowed(endAt)) {
        drafts.add((
          sub: sub,
          kind: ReminderKind.trialEndsToday,
          at: endAt.isAfter(now) ? endAt : now.add(const Duration(seconds: 5)),
          repeat: null,
          daysBefore: 0,
          markPaidCharge: null,
        ));
      }
      final beforeAt = fireOn(end, days);
      if (before && beforeAt.isAfter(now) && allowed(beforeAt)) {
        drafts.add((
          sub: sub,
          kind: ReminderKind.trialEndsSoon,
          at: beforeAt,
          repeat: null,
          daysBefore: days,
          markPaidCharge: null,
        ));
      }
      continue;
    }

    void addSeries(ReminderKind kind, int daysBefore) {
      bool ok(DateTime d) =>
          fireOn(d, daysBefore).isAfter(now) && allowed(fireOn(d, daysBefore));
      // A manual charge's due-day reminder gets a "Paid" button for that
      // charge, so it can't be an OS repeat.
      final markable = kind == ReminderKind.dueToday && !sub.autoRenew;
      var repeat = markable ? null : _repeatFor(sub, daysBefore);
      if (repeat != null) {
        // The plugin starts a repeat at the next match from now, not at the
        // date we pass. If that isn't our first reminder (a future start, a
        // snooze), the repeat would fire early: use one-shots instead.
        final first = fireOn(
          _upcomingCharges(sub, now, ok, count: 1).single,
          daysBefore,
        );
        if (_osNextMatch(now, first, repeat) != first) repeat = null;
      }
      for (final charge in _upcomingCharges(
        sub,
        now,
        ok,
        count: repeat == null ? oneShotHorizon : 1,
      )) {
        drafts.add((
          sub: sub,
          kind: kind,
          at: fireOn(charge, daysBefore),
          repeat: repeat,
          daysBefore: daysBefore,
          markPaidCharge: markable ? charge : null,
        ));
      }
    }

    if (sub.isOverdue(now)) {
      final today = fireOn(now);
      final at = today.isAfter(now)
          ? today
          : fireOn(DateTime(now.year, now.month, now.day + 1));
      if (allowed(at)) {
        drafts.add((
          sub: sub,
          kind: ReminderKind.overdue,
          at: at,
          repeat: null,
          daysBefore: 0,
          markPaidCharge: sub.unpaidCharge(now),
        ));
      }
    }

    if (onDay) addSeries(ReminderKind.dueToday, 0);
    // A reminder at or beyond one cycle would land on/before the previous
    // charge, which is confusing; skip it.
    if (before && days < _minCycleDays(sub)) {
      addSeries(ReminderKind.dueSoon, days);
    }
  }

  drafts.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final (i, d) in drafts.take(cap).indexed)
      PlannedReminder(
        id: i,
        sub: d.sub,
        kind: d.kind,
        at: d.at,
        repeat: d.repeat,
        daysBefore: d.daysBefore,
        markPaidCharge: d.markPaidCharge,
      ),
  ];
}

/// The first [count] charges whose reminder time passes [ok].
List<DateTime> _upcomingCharges(
  SubSlice sub,
  DateTime now,
  bool Function(DateTime charge) ok, {
  required int count,
}) {
  final charges = <DateTime>[];
  var charge = sub.nextChargeDate(now);
  while (charges.length < count) {
    if (ok(charge)) charges.add(charge);
    charge = sub.nextChargeDate(charge.add(const Duration(days: 1)));
  }
  return charges;
}

int _minCycleDays(SubSlice sub) => switch (sub.frequency) {
  Frequency.daily => sub.period,
  Frequency.weekly => 7 * sub.period,
  Frequency.monthly => 28 * sub.period,
  Frequency.yearly => 365 * sub.period,
};

/// The OS repeat that matches every reminder [daysBefore] days ahead of a
/// charge, or null if none does. Verified against enough charges to cover
/// every month length and a leap year, instead of hand-written rules.
DateTimeComponents? _repeatFor(SubSlice sub, int daysBefore) {
  // OS repeats are fixed daily/weekly/monthly/yearly; never every N.
  if (sub.period != 1) return null;
  DateTime reminder(int k) {
    final c = sub.occurrence(k);
    return DateTime(c.year, c.month, c.day - daysBefore);
  }

  switch (sub.frequency) {
    case Frequency.daily:
      return DateTimeComponents.time;
    case Frequency.weekly:
      return DateTimeComponents.dayOfWeekAndTime;
    case Frequency.monthly:
      final day = reminder(0).day;
      // The OS skips months without that day, so only 1..28 is safe.
      if (day > 28) return null;
      for (var k = 1; k <= 48; k++) {
        if (reminder(k).day != day) return null;
      }
      return DateTimeComponents.dayOfMonthAndTime;
    case Frequency.yearly:
      final first = reminder(0);
      if (first.month == 2 && first.day == 29) return null;
      for (var k = 1; k <= 8; k++) {
        final r = reminder(k);
        if (r.month != first.month || r.day != first.day) return null;
      }
      return DateTimeComponents.dateAndTime;
  }
}

/// When flutter_local_notifications (Android) first fires a repeating
/// reminder scheduled for [at]: the next time after [now] matching [repeat],
/// ignoring [at]'s date (mirrors getNextFireDateMatchingDateTimeComponents).
DateTime _osNextMatch(DateTime now, DateTime at, DateTimeComponents repeat) {
  var next = DateTime(
    now.year,
    now.month,
    now.day,
    at.hour,
    at.minute,
    at.second,
  );
  while (next.isBefore(now)) {
    next = DateTime(next.year, next.month, next.day + 1, at.hour, at.minute);
  }
  bool matches(DateTime d) => switch (repeat) {
    DateTimeComponents.time => true,
    DateTimeComponents.dayOfWeekAndTime => d.weekday == at.weekday,
    DateTimeComponents.dayOfMonthAndTime => d.day == at.day,
    DateTimeComponents.dateAndTime => d.month == at.month && d.day == at.day,
  };
  // At most a few years for dateAndTime; Feb 29 never gets that repeat.
  for (var i = 0; i < 1500 && !matches(next); i++) {
    next = DateTime(next.year, next.month, next.day + 1, at.hour, at.minute);
  }
  return next;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
