import 'currency.dart';
import 'sub_slice.dart';

typedef Price = ({double amount, Currency? currency});

/// Single source of truth for billing dates. Every screen, notification and
/// widget must use these instead of computing dates on its own.
///
/// All results are local dates at midnight. Charge k is always derived from
/// the original start date (start + k periods, clamped to the month's last
/// day), so a subscription started on the 31st never drifts to the 28th.
extension SubSliceBilling on SubSlice {
  DateTime get _start =>
      DateTime(startDate.year, startDate.month, startDate.day);

  /// The k-th charge date; `occurrence(0)` is the start date.
  DateTime occurrence(int k) {
    final s = _start;
    final n = k * period;
    switch (frequency) {
      case Frequency.daily:
        return DateTime(s.year, s.month, s.day + n);
      case Frequency.weekly:
        return DateTime(s.year, s.month, s.day + 7 * n);
      case Frequency.monthly:
        final monthIndex = s.month - 1 + n;
        return _clamped(s.year + monthIndex ~/ 12, monthIndex % 12 + 1, s.day);
      case Frequency.yearly:
        return _clamped(s.year + n, s.month, s.day);
    }
  }

  /// First charge on or after [now]'s date (a charge due today is "next").
  DateTime nextChargeDate(DateTime now) =>
      occurrence(_firstIndexOnOrAfter(now));

  /// Whether a charge falls on [day]'s date.
  bool isDueOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_start) && nextChargeDate(d) == d;
  }

  /// Charges on or before [now]'s date, newest first.
  List<DateTime> pastCharges(DateTime now, {int limit = 4}) {
    final today = DateTime(now.year, now.month, now.day);
    var k = _firstIndexOnOrAfter(today);
    if (occurrence(k) != today) k--;
    return [for (var i = k; i >= 0 && i > k - limit; i--) occurrence(i)];
  }

  /// Number of charges whose date is within [from]..[to] (inclusive dates).
  int chargeCountBetween(DateTime from, DateTime to) {
    final first = _firstIndexOnOrAfter(from);
    final afterLast = _firstIndexOnOrAfter(
      DateTime(to.year, to.month, to.day + 1),
    );
    return afterLast > first ? afterLast - first : 0;
  }

  /// Money not spent since cancelling: charges after [cancelledAt]'s date up
  /// to [now]. Zero unless cancelled with a known date.
  double savedSinceCancel(DateTime now) {
    final at = cancelledAt;
    if (status != SubStatus.cancelled || at == null) return 0;
    return amount *
        chargeCountBetween(DateTime(at.year, at.month, at.day + 1), now);
  }

  /// Charges that were actually paid, newest first: [pastCharges], but not
  /// past the cancellation date of a cancelled subscription.
  List<DateTime> paymentDates(DateTime now, {int limit = 4}) {
    final at = cancelledAt;
    final end = status == SubStatus.cancelled && at != null && at.isBefore(now)
        ? at
        : now;
    return pastCharges(end, limit: limit);
  }

  /// Whether the charge on [chargeDate]'s day was marked paid.
  bool isPaid(DateTime chargeDate) {
    final d = DateTime(chargeDate.year, chargeDate.month, chargeDate.day);
    return paidCharges.contains(d);
  }

  /// For a manually paid subscription: its latest charge (today or earlier)
  /// if not marked paid yet; otherwise null.
  DateTime? unpaidCharge(DateTime now) {
    if (autoRenew) return null;
    if (status == SubStatus.paused || status == SubStatus.cancelled) {
      return null;
    }
    final last = pastCharges(now, limit: 1).firstOrNull;
    return last == null || isPaid(last) ? null : last;
  }

  /// An unpaid charge from before today.
  bool isOverdue(DateTime now) {
    final unpaid = unpaidCharge(now);
    return unpaid != null &&
        unpaid.isBefore(DateTime(now.year, now.month, now.day));
  }

  List<PriceChange> get _historyByDate =>
      [...priceHistory]..sort((a, b) => a.until.compareTo(b.until));

  /// The price charged on [chargeDate]: the first earlier price still in
  /// force then, else the current one.
  Price priceOn(DateTime chargeDate) {
    for (final p in _historyByDate) {
      if (chargeDate.isBefore(p.until)) {
        return (amount: p.amount, currency: p.currency);
      }
    }
    return (amount: amount, currency: currency);
  }

  /// [paymentDates] with the price charged on each, newest first.
  List<({DateTime date, double amount, Currency? currency})> paymentHistory(
    DateTime now, {
    int limit = 4,
  }) => [
    for (final d in paymentDates(now, limit: limit))
      (date: d, amount: priceOn(d).amount, currency: priceOn(d).currency),
  ];

  /// Each price change (old -> new), newest first.
  List<({DateTime at, Price from, Price to})> get priceChanges {
    final h = _historyByDate;
    return [
      for (var i = h.length - 1; i >= 0; i--)
        (
          at: h[i].until,
          from: (amount: h[i].amount, currency: h[i].currency),
          to: i + 1 < h.length
              ? (amount: h[i + 1].amount, currency: h[i + 1].currency)
              : (amount: amount, currency: currency),
        ),
    ];
  }

  int _firstIndexOnOrAfter(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final s = _start;
    if (!today.isAfter(s)) return 0;
    // Estimate from below (in periods, then in charges), then step forward
    // (at most a couple of steps).
    final periods = switch (frequency) {
      Frequency.daily => _daysBetween(s, today),
      Frequency.weekly => _daysBetween(s, today) ~/ 7,
      Frequency.monthly =>
        (today.year - s.year) * 12 + today.month - s.month - 1,
      Frequency.yearly => today.year - s.year - 1,
    };
    var k = periods ~/ period;
    if (k < 0) k = 0;
    while (occurrence(k).isBefore(today)) {
      k++;
    }
    return k;
  }
}

DateTime _clamped(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

// Calendar-day difference, immune to DST (UTC has no DST).
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

extension SubListBilling on List<SubSlice> {
  /// Charges of these subscriptions dated within [from]..[to] (inclusive).
  ({int count, double total}) chargesBetween(DateTime from, DateTime to) {
    var count = 0;
    var total = 0.0;
    for (final s in this) {
      final n = s.chargeCountBetween(from, to);
      count += n;
      total += n * s.amount;
    }
    return (count: count, total: total);
  }
}
