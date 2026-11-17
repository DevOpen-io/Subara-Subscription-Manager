import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/billing.dart';
import 'package:subs_tracker/models/sub_slice.dart';

SubSlice _sub(DateTime start, Frequency f, {int interval = 1}) => SubSlice(
  name: 'x',
  amount: 10,
  color: 0,
  startDate: start,
  frequency: f,
  interval: interval,
);

void main() {
  group('occurrence', () {
    test('monthly from Jan 31 clamps per month without drifting', () {
      final s = _sub(DateTime(2026, 1, 31, 20, 15), Frequency.monthly);
      expect(
        [for (var k = 0; k < 5; k++) s.occurrence(k)],
        [
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
          DateTime(2026, 4, 30),
          DateTime(2026, 5, 31),
        ],
      );
    });

    test('monthly crosses the year boundary', () {
      final s = _sub(DateTime(2026, 11, 30), Frequency.monthly);
      expect(s.occurrence(3), DateTime(2027, 2, 28));
    });

    test('yearly from Feb 29 falls on Feb 28 in common years', () {
      final s = _sub(DateTime(2028, 2, 29), Frequency.yearly);
      expect(s.occurrence(1), DateTime(2029, 2, 28));
      expect(s.occurrence(4), DateTime(2032, 2, 29));
    });

    test('weekly and daily step in calendar days (DST safe)', () {
      // Europe DST change on 2026-03-29 must not shift the date.
      final w = _sub(DateTime(2026, 3, 22), Frequency.weekly);
      expect(w.occurrence(1), DateTime(2026, 3, 29));
      expect(w.occurrence(2), DateTime(2026, 4, 5));
      final d = _sub(DateTime(2026, 3, 28), Frequency.daily);
      expect(d.occurrence(2), DateTime(2026, 3, 30));
    });
  });

  group('nextChargeDate', () {
    test('charge due today counts as next', () {
      final s = _sub(DateTime(2026, 1, 16), Frequency.monthly);
      expect(
        s.nextChargeDate(DateTime(2026, 11, 16, 23, 59)),
        DateTime(2026, 11, 16),
      );
    });

    test('a day after the charge moves to next month', () {
      final s = _sub(DateTime(2026, 1, 16), Frequency.monthly);
      expect(s.nextChargeDate(DateTime(2026, 11, 17)), DateTime(2026, 12, 16));
    });

    test('Jan 31 monthly: in April the next charge is Apr 30, not 28', () {
      final s = _sub(DateTime(2026, 1, 31), Frequency.monthly);
      expect(s.nextChargeDate(DateTime(2026, 4, 2)), DateTime(2026, 4, 30));
    });

    test('future start date is the next charge', () {
      final s = _sub(DateTime(2027, 5), Frequency.yearly);
      expect(s.nextChargeDate(DateTime(2026, 11, 16)), DateTime(2027, 5));
    });

    test('weekly lands on the start weekday', () {
      final s = _sub(DateTime(2026, 11, 2), Frequency.weekly); // Monday
      final next = s.nextChargeDate(DateTime(2026, 11, 18)); // Wednesday
      expect(next, DateTime(2026, 11, 23));
      expect(next.weekday, DateTime.monday);
    });

    test('long-running subscriptions resolve without iterating forever', () {
      final s = _sub(DateTime(1990), Frequency.daily);
      expect(
        s.nextChargeDate(DateTime(2026, 11, 16, 8)),
        DateTime(2026, 11, 16),
      );
    });
  });

  group('isDueOn', () {
    test('monthly from the 31st is due on the last day of short months', () {
      final s = _sub(DateTime(2026, 1, 31), Frequency.monthly);
      expect(s.isDueOn(DateTime(2026, 2, 28)), isTrue);
      expect(s.isDueOn(DateTime(2026, 4, 30)), isTrue);
      expect(s.isDueOn(DateTime(2026, 4, 28)), isFalse);
      expect(s.isDueOn(DateTime(2026, 3, 28)), isFalse);
      expect(s.isDueOn(DateTime(2026, 3, 31)), isTrue);
    });

    test('never due before the start date', () {
      final s = _sub(DateTime(2026, 6, 10), Frequency.monthly);
      expect(s.isDueOn(DateTime(2026, 5, 10)), isFalse);
      expect(s.isDueOn(DateTime(2026, 6, 10, 18)), isTrue);
    });
  });

  group('pastCharges', () {
    test('newest first, includes today, respects limit', () {
      final s = _sub(DateTime(2026, 1, 31), Frequency.monthly);
      expect(s.pastCharges(DateTime(2026, 4, 30, 9), limit: 3), [
        DateTime(2026, 4, 30),
        DateTime(2026, 3, 31),
        DateTime(2026, 2, 28),
      ]);
    });

    test('empty before the first charge', () {
      final s = _sub(DateTime(2026, 12), Frequency.monthly);
      expect(s.pastCharges(DateTime(2026, 11, 16)), isEmpty);
    });
  });

  group('monthlyAmount', () {
    test('daily and weekly use the same average month', () {
      final daily = _sub(DateTime(2026), Frequency.daily).monthlyAmount;
      final weekly = _sub(DateTime(2026), Frequency.weekly).monthlyAmount;
      // Both use an average month of 365/12 days: 10/day == 70/week.
      expect(daily, closeTo(10 * 365 / 12, 1e-9));
      expect(daily, closeTo(weekly * 7, 1e-9));
      expect(weekly, closeTo(10 * 365 / 12 / 7, 1e-9));
    });
  });

  group('interval', () {
    test('every 3 months from Nov 30 clamps without drifting', () {
      final s = _sub(DateTime(2026, 11, 30), Frequency.monthly, interval: 3);
      expect(
        [for (var k = 0; k < 4; k++) s.occurrence(k)],
        [
          DateTime(2026, 11, 30),
          DateTime(2027, 2, 28),
          DateTime(2027, 5, 30),
          DateTime(2027, 8, 30),
        ],
      );
    });

    test('biweekly is not due on the off week', () {
      final s = _sub(DateTime(2026, 11, 2), Frequency.weekly, interval: 2);
      expect(s.isDueOn(DateTime(2026, 11, 9)), isFalse);
      expect(s.isDueOn(DateTime(2026, 11, 16)), isTrue);
      expect(s.nextChargeDate(DateTime(2026, 11, 3)), DateTime(2026, 11, 16));
    });

    test('next charge never skips one (estimate stays below)', () {
      for (final (f, n) in [
        (Frequency.daily, 3),
        (Frequency.weekly, 2),
        (Frequency.monthly, 6),
        (Frequency.yearly, 2),
      ]) {
        final s = _sub(DateTime(2020, 1, 31), f, interval: n);
        var day = DateTime(2020, 1, 31);
        for (var i = 0; i < 900; i++) {
          final next = s.nextChargeDate(day);
          expect(next.isBefore(day), isFalse);
          final prev = s.pastCharges(
            day.subtract(const Duration(days: 1)),
            limit: 1,
          );
          // No charge between the previous one and the next one is skipped.
          if (prev.isNotEmpty) {
            expect(
              s.chargeCountBetween(
                prev.first.add(const Duration(days: 1)),
                next,
              ),
              1,
              reason: '$f x$n on $day',
            );
          }
          day = DateTime(day.year, day.month, day.day + 1);
        }
      }
    });

    test('every 2 years from Feb 29', () {
      final s = _sub(DateTime(2024, 2, 29), Frequency.yearly, interval: 2);
      expect(s.occurrence(1), DateTime(2026, 2, 28));
      expect(s.occurrence(2), DateTime(2028, 2, 29));
    });

    test('monthlyAmount divides by the interval', () {
      expect(
        _sub(DateTime(2026), Frequency.monthly, interval: 3).monthlyAmount,
        closeTo(10 / 3, 1e-9),
      );
      expect(
        _sub(DateTime(2026), Frequency.yearly, interval: 2).monthlyAmount,
        closeTo(10 / 24, 1e-9),
      );
      expect(
        _sub(DateTime(2026), Frequency.weekly, interval: 2).monthlyAmount,
        closeTo(10 * 365 / 12 / 14, 1e-9),
      );
    });

    test('a huge imported interval is capped', () {
      final s = _sub(
        DateTime(2026, 1, 15),
        Frequency.yearly,
        interval: 1 << 40,
      );
      expect(s.period, SubSlice.maxInterval);
      expect(s.nextChargeDate(DateTime(2026, 3, 2)), DateTime(2038, 1, 15));
    });

    test('an invalid interval behaves as 1 instead of hanging', () {
      final s = _sub(DateTime(2026, 1, 15), Frequency.monthly, interval: 0);
      expect(s.nextChargeDate(DateTime(2026, 3, 2)), DateTime(2026, 3, 15));
      expect(s.monthlyAmount, 10);
    });
  });

  group('chargeCountBetween', () {
    test('counts charges in an inclusive date range', () {
      final s = _sub(DateTime(2026, 1, 31), Frequency.monthly);
      expect(s.chargeCountBetween(DateTime(2026, 2), DateTime(2026, 4, 30)), 3);
      expect(s.chargeCountBetween(DateTime(2026, 2), DateTime(2026, 4, 29)), 2);
      expect(s.chargeCountBetween(DateTime(2025), DateTime(2026, 1, 30)), 0);
      expect(s.chargeCountBetween(DateTime(2026, 5), DateTime(2026, 4)), 0);
    });

    test('daily within a week', () {
      final s = _sub(DateTime(2026), Frequency.daily);
      expect(
        s.chargeCountBetween(DateTime(2026, 11, 17), DateTime(2026, 11, 23)),
        7,
      );
    });
  });

  group('cancellation', () {
    SubSlice cancelled(DateTime? at) => _sub(
      DateTime(2026, 1, 10),
      Frequency.monthly,
    ).copyWith(status: SubStatus.cancelled, cancelledAt: at);

    test('savings count charges skipped after the cancel date', () {
      final s = cancelled(DateTime(2026, 3, 10, 15));
      // Mar 10 was paid; Apr 10, May 10, Jun 10 were saved.
      expect(s.savedSinceCancel(DateTime(2026, 6, 20)), 30);
      expect(s.savedSinceCancel(DateTime(2026, 4, 9)), 0);
    });

    test('no cancel date means no savings', () {
      expect(cancelled(null).savedSinceCancel(DateTime(2026, 6, 20)), 0);
    });

    test('active subscriptions save nothing', () {
      final s = cancelled(
        DateTime(2026, 3, 10),
      ).copyWith(status: SubStatus.active);
      expect(s.savedSinceCancel(DateTime(2026, 6, 20)), 0);
    });

    test('payment history stops at the cancel date', () {
      final s = cancelled(DateTime(2026, 3, 12));
      expect(s.paymentDates(DateTime(2026, 6, 20)), [
        DateTime(2026, 3, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 1, 10),
      ]);
    });
  });

  test('chargesBetween sums a list of subscriptions', () {
    final subs = [
      _sub(DateTime(2026, 1, 20), Frequency.monthly),
      _sub(DateTime(2026, 11, 2), Frequency.weekly),
      _sub(DateTime(2026, 3), Frequency.yearly),
    ];
    final r = subs.chargesBetween(
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 23),
    );
    // Nov 20 monthly + Nov 23 weekly.
    expect(r.count, 2);
    expect(r.total, 20);
  });
}
