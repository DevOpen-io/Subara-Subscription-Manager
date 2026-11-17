import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/billing.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/utils/notification_plan.dart';

SubSlice _manual({List<DateTime> paid = const [], bool autoRenew = false}) =>
    SubSlice(
      name: 'Rent',
      amount: 100,
      color: 0,
      startDate: DateTime(2026, 1, 10),
      autoRenew: autoRenew,
      paidCharges: paid,
    );

void main() {
  test('auto-renewing subscriptions are never unpaid', () {
    expect(
      _manual(autoRenew: true).unpaidCharge(DateTime(2026, 11, 17)),
      isNull,
    );
  });

  test('the latest charge is unpaid until marked', () {
    final s = _manual();
    expect(s.unpaidCharge(DateTime(2026, 11, 17)), DateTime(2026, 11, 10));
    expect(s.isOverdue(DateTime(2026, 11, 17)), isTrue);
    // Due today: unpaid but not overdue yet.
    expect(s.unpaidCharge(DateTime(2026, 11, 10, 9)), DateTime(2026, 11, 10));
    expect(s.isOverdue(DateTime(2026, 11, 10, 9)), isFalse);
  });

  test('marking paid clears it until the next charge', () {
    final s = _manual(paid: [DateTime(2026, 11, 10)]);
    expect(s.unpaidCharge(DateTime(2026, 11, 17)), isNull);
    expect(s.isPaid(DateTime(2026, 11, 10, 15)), isTrue);
    expect(s.unpaidCharge(DateTime(2026, 12, 11)), DateTime(2026, 12, 10));
  });

  test('paused and cancelled subscriptions owe nothing', () {
    expect(
      _manual()
          .copyWith(status: SubStatus.paused)
          .unpaidCharge(DateTime(2026, 11, 17)),
      isNull,
    );
  });

  test('before the first charge nothing is owed', () {
    final s = _manual().copyWith(startDate: DateTime(2026, 12));
    expect(s.unpaidCharge(DateTime(2026, 11, 17)), isNull);
  });

  test('paid dates decode tolerantly', () {
    final json = _manual().toJson()
      ..['paidCharges'] = ['2026-11-10T00:00:00.000', 'nope', 3, null];
    expect(SubSlice.fromJson(json).paidCharges, [DateTime(2026, 11, 10)]);
    final legacy = _manual().toJson()
      ..remove('paidCharges')
      ..remove('autoRenew');
    final s = SubSlice.fromJson(legacy);
    expect(s.autoRenew, isTrue);
    expect(s.paidCharges, isEmpty);
  });

  test('an overdue manual payment gets a reminder at the next fire time', () {
    final plan = planReminders([_manual()], DateTime(2026, 11, 17, 9));
    final overdue = plan.where((r) => r.kind == ReminderKind.overdue).single;
    expect(overdue.at, DateTime(2026, 11, 17, 12));
    expect(overdue.repeat, isNull);

    final late = planReminders(
      [_manual()],
      DateTime(2026, 11, 17, 13),
    ).where((r) => r.kind == ReminderKind.overdue).single;
    expect(late.at, DateTime(2026, 11, 18, 12));

    final paid = planReminders([
      _manual(paid: [DateTime(2026, 11, 10)]),
    ], DateTime(2026, 11, 17, 9));
    expect(paid.where((r) => r.kind == ReminderKind.overdue), isEmpty);

    // Reminders turned off: no overdue reminder either.
    final off = planReminders([
      _manual().copyWith(reminderMode: ReminderMode.none),
    ], DateTime(2026, 11, 17, 9));
    expect(off, isEmpty);
  });

  test('reminders of a manual charge carry it for the "Paid" button', () {
    final now = DateTime(2026, 11, 17, 9);
    final plan = planReminders([_manual()], now);
    final overdue = plan.where((r) => r.kind == ReminderKind.overdue).single;
    expect(overdue.markPaidCharge, DateTime(2026, 11, 10));

    // Due-today reminders become one-shots so each knows its charge.
    final today = plan.where((r) => r.kind == ReminderKind.dueToday).toList();
    expect(today, isNotEmpty);
    for (final r in today) {
      expect(r.repeat, isNull);
      expect(r.markPaidCharge, DateTime(r.at.year, r.at.month, r.at.day));
    }
    expect(
      plan
          .where((r) => r.kind == ReminderKind.dueSoon)
          .every((r) => r.markPaidCharge == null),
      isTrue,
    );

    // Auto-renewing: nothing to mark.
    final auto = planReminders([_manual(autoRenew: true)], now);
    expect(auto.every((r) => r.markPaidCharge == null), isTrue);
  });
}
