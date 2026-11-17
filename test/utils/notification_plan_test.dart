import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/utils/notification_plan.dart';

SubSlice _sub(
  DateTime start, {
  Frequency f = Frequency.monthly,
  String name = 'Netflix',
  ReminderMode mode = ReminderMode.both,
  SubStatus status = SubStatus.active,
  DateTime? trialEnd,
  int interval = 1,
  int daysBefore = 1,
}) => SubSlice(
  name: name,
  amount: 10,
  color: 0,
  startDate: start,
  frequency: f,
  reminderMode: mode,
  status: status,
  trialEndDate: trialEnd,
  interval: interval,
  remindDaysBefore: daysBefore,
);

List<PlannedReminder> _all(List<PlannedReminder> plan, ReminderKind kind) =>
    plan.where((r) => r.kind == kind).toList();

PlannedReminder _only(List<PlannedReminder> plan, ReminderKind kind) =>
    plan.singleWhere((r) => r.kind == kind);

void main() {
  final now = DateTime(2026, 11, 16, 9); // Monday 09:00

  test('monthly on day 15 repeats by day of month at noon', () {
    final plan = planReminders([_sub(DateTime(2026, 1, 15))], now);
    final due = _only(plan, ReminderKind.dueToday);
    expect(due.at, DateTime(2026, 12, 15, 12));
    expect(due.repeat, DateTimeComponents.dayOfMonthAndTime);
    final before = _only(plan, ReminderKind.dueSoon);
    expect(before.at, DateTime(2026, 12, 14, 12));
    expect(before.repeat, DateTimeComponents.dayOfMonthAndTime);
  });

  test('due today before noon fires today', () {
    final plan = planReminders([_sub(DateTime(2026, 1, 16))], now);
    expect(_only(plan, ReminderKind.dueToday).at, DateTime(2026, 11, 16, 12));
  });

  test('due today after noon moves to the next charge', () {
    final plan = planReminders([
      _sub(DateTime(2026, 1, 16)),
    ], DateTime(2026, 11, 16, 13));
    expect(_only(plan, ReminderKind.dueToday).at, DateTime(2026, 12, 16, 12));
  });

  test('day 31 is a one-shot on the clamped date, never a monthly repeat', () {
    final plan = planReminders([
      _sub(DateTime(2026, 1, 31)),
    ], DateTime(2027, 2, 2));
    // One-shots for the next 12 charges, so reminders keep coming even if
    // the app isn't opened for months.
    final due = _all(plan, ReminderKind.dueToday);
    expect(due, hasLength(oneShotHorizon));
    expect(due.every((r) => r.repeat == null), isTrue);
    expect(due.take(4).map((r) => r.at), [
      DateTime(2027, 2, 28, 12),
      DateTime(2027, 3, 31, 12),
      DateTime(2027, 4, 30, 12),
      DateTime(2027, 5, 31, 12),
    ]);
    final before = _all(plan, ReminderKind.dueSoon);
    expect(before, hasLength(oneShotHorizon));
    expect(before.take(3).map((r) => r.at), [
      DateTime(2027, 2, 27, 12),
      DateTime(2027, 3, 30, 12),
      DateTime(2027, 4, 29, 12),
    ]);
  });

  test(
    'day before a charge on the 1st is a one-shot on the previous month end',
    () {
      final plan = planReminders([_sub(DateTime(2026))], now);
      final before = _all(plan, ReminderKind.dueSoon);
      expect(before.take(3).map((r) => r.at), [
        DateTime(2026, 11, 30, 12),
        DateTime(2026, 12, 31, 12),
        DateTime(2027, 1, 31, 12),
      ]);
      expect(before.every((r) => r.repeat == null), isTrue);
      expect(
        _only(plan, ReminderKind.dueToday).repeat,
        DateTimeComponents.dayOfMonthAndTime,
      );
    },
  );

  test('yearly Feb 29 never uses a yearly repeat', () {
    final plan = planReminders([
      _sub(DateTime(2024, 2, 29), f: Frequency.yearly),
    ], now);
    final due = _all(plan, ReminderKind.dueToday);
    expect(due.take(2).map((r) => (r.at, r.repeat)), [
      (DateTime(2027, 2, 28, 12), null),
      (DateTime(2028, 2, 29, 12), null),
    ]);
  });

  test('yearly on a normal date repeats yearly', () {
    final plan = planReminders([
      _sub(DateTime(2025, 6, 10), f: Frequency.yearly),
    ], now);
    final due = _only(plan, ReminderKind.dueToday);
    expect(due.at, DateTime(2027, 6, 10, 12));
    expect(due.repeat, DateTimeComponents.dateAndTime);
  });

  test('weekly repeats by weekday; daily has no day-before reminder', () {
    final plan = planReminders([
      _sub(DateTime(2026, 11, 4), f: Frequency.weekly, name: 'W'), // Wed
      _sub(DateTime(2026, 11), f: Frequency.daily, name: 'D'),
    ], now);
    final weekly = plan.where((r) => r.sub.name == 'W').toList();
    expect(_only(weekly, ReminderKind.dueToday).at, DateTime(2026, 11, 18, 12));
    expect(
      _only(weekly, ReminderKind.dueToday).repeat,
      DateTimeComponents.dayOfWeekAndTime,
    );
    final daily = plan.where((r) => r.sub.name == 'D').toList();
    expect(daily.map((r) => r.kind), [ReminderKind.dueToday]);
    expect(daily.single.repeat, DateTimeComponents.time);
  });

  test('reminder mode, paused and cancelled are respected', () {
    final plan = planReminders([
      _sub(DateTime(2026, 1, 15), name: 'onDay', mode: ReminderMode.onDay),
      _sub(DateTime(2026, 1, 15), name: 'none', mode: ReminderMode.none),
      _sub(DateTime(2026, 1, 15), name: 'p', status: SubStatus.paused),
      _sub(DateTime(2026, 1, 15), name: 'c', status: SubStatus.cancelled),
    ], now);
    expect(plan.map((r) => (r.sub.name, r.kind)), [
      ('onDay', ReminderKind.dueToday),
    ]);
  });

  test('free trial gets one-shot trial-end reminders only', () {
    final plan = planReminders([
      _sub(
        DateTime(2026, 11),
        status: SubStatus.freeTrial,
        trialEnd: DateTime(2026, 11, 20),
      ),
    ], now);
    expect(plan.map((r) => (r.kind, r.at, r.repeat)), [
      (ReminderKind.trialEndsSoon, DateTime(2026, 11, 19, 12), null),
      (ReminderKind.trialEndsToday, DateTime(2026, 11, 20, 12), null),
    ]);
  });

  test('trial ending today after noon still notifies shortly', () {
    final late = DateTime(2026, 11, 20, 15);
    final plan = planReminders([
      _sub(
        DateTime(2026, 11),
        status: SubStatus.freeTrial,
        trialEnd: DateTime(2026, 11, 20),
      ),
    ], late);
    expect(
      _only(plan, ReminderKind.trialEndsToday).at,
      late.add(const Duration(seconds: 5)),
    );
  });

  test('caps the plan to the soonest reminders with unique ids', () {
    final subs = [
      for (var d = 1; d <= 28; d++)
        for (var i = 0; i < 2; i++) _sub(DateTime(2026, 1, d), name: 's$d-$i'),
    ]; // 56 subs -> 112 reminders
    final plan = planReminders(subs, now);
    expect(plan, hasLength(64));
    expect(plan.map((r) => r.id).toSet(), hasLength(64));
    final sorted = [...plan]..sort((a, b) => a.at.compareTo(b.at));
    expect(plan.map((r) => r.at), sorted.map((r) => r.at));
    final all = planReminders(subs, now, cap: 1000);
    final cutoff = plan.last.at;
    expect(all.where((r) => r.at.isBefore(cutoff)).length, lessThan(64));
  });

  test('every N periods never uses an OS repeat', () {
    final plan = planReminders(
      [
        _sub(DateTime(2026, 1, 15), interval: 3, name: 'Q'),
        _sub(
          DateTime(2026, 11, 4),
          f: Frequency.weekly,
          interval: 2,
          name: 'B',
        ),
        _sub(
          DateTime(2025, 6, 10),
          f: Frequency.yearly,
          interval: 2,
          name: 'Y',
        ),
      ],
      now,
      cap: 1000,
    );
    expect(plan.every((r) => r.repeat == null), isTrue);
    final q = plan
        .where((r) => r.sub.name == 'Q' && r.kind == ReminderKind.dueToday)
        .map((r) => r.at)
        .take(3);
    expect(q, [
      DateTime(2027, 1, 15, 12),
      DateTime(2027, 4, 15, 12),
      DateTime(2027, 7, 15, 12),
    ]);
    final b = plan
        .where((r) => r.sub.name == 'B' && r.kind == ReminderKind.dueToday)
        .map((r) => r.at)
        .take(2);
    expect(b, [DateTime(2026, 11, 18, 12), DateTime(2026, 12, 2, 12)]);
  });

  test('N days before repeats monthly only when the day is stable', () {
    final stable = _only(
      planReminders([_sub(DateTime(2026, 1, 15), daysBefore: 7)], now),
      ReminderKind.dueSoon,
    );
    expect(stable.at, DateTime(2026, 12, 8, 12));
    expect(stable.repeat, DateTimeComponents.dayOfMonthAndTime);
    expect(stable.daysBefore, 7);

    // Charge on the 3rd, 7 days before lands on 24th..27th: one-shots.
    final unstable = _all(
      planReminders([_sub(DateTime(2026, 1, 3), daysBefore: 7)], now),
      ReminderKind.dueSoon,
    );
    expect(unstable, hasLength(oneShotHorizon));
    expect(unstable.every((r) => r.repeat == null), isTrue);
    expect(unstable.take(3).map((r) => r.at), [
      DateTime(2026, 11, 26, 12),
      DateTime(2026, 12, 27, 12),
      DateTime(2027, 1, 27, 12),
    ]);
  });

  test('N days before a yearly charge in early March has no yearly repeat', () {
    final plan = planReminders([
      _sub(DateTime(2026, 3, 3), f: Frequency.yearly, daysBefore: 3),
    ], now);
    final soon = _all(plan, ReminderKind.dueSoon);
    expect(soon.every((r) => r.repeat == null), isTrue);
    expect(soon.take(2).map((r) => r.at), [
      DateTime(2027, 2, 28, 12),
      DateTime(2028, 2, 29, 12),
    ]);
    // On-day is still a stable date.
    expect(
      _only(plan, ReminderKind.dueToday).repeat,
      DateTimeComponents.dateAndTime,
    );
  });

  test('weekly 7 days before is skipped (same day as the previous charge)', () {
    final plan = planReminders([
      _sub(DateTime(2026, 11, 4), f: Frequency.weekly, daysBefore: 7),
    ], now);
    expect(plan.map((r) => r.kind), [ReminderKind.dueToday]);
  });

  test('every 3 days with 1 day before is allowed', () {
    final plan = planReminders(
      [_sub(DateTime(2026, 11, 16), f: Frequency.daily, interval: 3)],
      now,
      cap: 1000,
    );
    expect(
      _all(plan, ReminderKind.dueSoon).first.at,
      DateTime(2026, 11, 18, 12),
    );
  });

  test('reminder time of day is configurable', () {
    final plan = planReminders(
      [_sub(DateTime(2026, 1, 15))],
      now,
      fireMinutes: 9 * 60 + 30,
    );
    expect(
      _only(plan, ReminderKind.dueToday).at,
      DateTime(2026, 12, 15, 9, 30),
    );
    expect(_only(plan, ReminderKind.dueSoon).at, DateTime(2026, 12, 14, 9, 30));
  });

  test('trial reminder uses the chosen days before', () {
    final plan = planReminders([
      _sub(
        DateTime(2026, 11),
        status: SubStatus.freeTrial,
        trialEnd: DateTime(2026, 11, 30),
        daysBefore: 3,
      ),
    ], now);
    final soon = _only(plan, ReminderKind.trialEndsSoon);
    expect(soon.at, DateTime(2026, 11, 27, 12));
    expect(soon.daysBefore, 3);
  });

  group('snooze', () {
    test('no reminders before the snooze ends', () {
      final plan = planReminders([
        _sub(
          DateTime(2026, 1, 15),
        ).copyWith(remindersSnoozedUntil: DateTime(2027, 1, 20)),
      ], now);
      // Dec 14/15 and Jan 14/15 are skipped; resumes in February. The OS
      // would start a repeat at the next match (Dec 15), so these must be
      // one-shots.
      final due = _all(plan, ReminderKind.dueToday);
      expect(due.first.at, DateTime(2027, 2, 15, 12));
      expect(due.every((r) => r.repeat == null), isTrue);
      expect(
        _all(plan, ReminderKind.dueSoon).first.at,
        DateTime(2027, 2, 14, 12),
      );
    });

    test('an expired snooze changes nothing', () {
      final plan = planReminders([
        _sub(
          DateTime(2026, 1, 15),
        ).copyWith(remindersSnoozedUntil: DateTime(2026, 11)),
      ], now);
      expect(_only(plan, ReminderKind.dueToday).at, DateTime(2026, 12, 15, 12));
    });

    test('snoozed trials stay quiet until the snooze ends', () {
      final plan = planReminders([
        _sub(
          DateTime(2026, 11),
          status: SubStatus.freeTrial,
          trialEnd: DateTime(2026, 11, 20),
        ).copyWith(remindersSnoozedUntil: DateTime(2026, 11, 21)),
      ], now);
      expect(plan, isEmpty);
    });
  });

  group('OS repeats start at the next match from now', () {
    test('a start date months away uses one-shots', () {
      final plan = planReminders([_sub(DateTime(2027, 3, 15))], now);
      final due = _all(plan, ReminderKind.dueToday);
      expect(due.first.at, DateTime(2027, 3, 15, 12));
      expect(due.every((r) => r.repeat == null), isTrue);
    });

    test('a weekly start two weeks away uses one-shots', () {
      final plan = planReminders([
        _sub(DateTime(2026, 11, 30), f: Frequency.weekly),
      ], now);
      final due = _all(plan, ReminderKind.dueToday);
      expect(due.first.at, DateTime(2026, 11, 30, 12));
      expect(due.first.repeat, isNull);
    });

    test('a start date within the first cycle can still repeat', () {
      final plan = planReminders([_sub(DateTime(2026, 11, 25))], now);
      final due = _only(plan, ReminderKind.dueToday);
      expect(due.at, DateTime(2026, 11, 25, 12));
      expect(due.repeat, DateTimeComponents.dayOfMonthAndTime);
    });
  });
}
