import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/billing.dart';
import 'package:subs_tracker/models/currency.dart';
import 'package:subs_tracker/models/sub_slice.dart';

void main() {
  final sub = SubSlice(
    name: 'x',
    amount: 15,
    color: 0,
    startDate: DateTime(2026, 1, 10),
    priceHistory: [
      PriceChange(amount: 10, until: DateTime(2026, 3, 5, 14)),
      PriceChange(
        amount: 12,
        until: DateTime(2026, 5, 10, 9),
        currency: Currency.usd,
      ),
    ],
  );

  test('price in force on each charge date', () {
    expect(sub.priceOn(DateTime(2026, 1, 10)), (amount: 10.0, currency: null));
    expect(sub.priceOn(DateTime(2026, 3, 10)), (
      amount: 12.0,
      currency: Currency.usd,
    ));
    // Charged on May 10 before the 09:00 change: old price.
    expect(sub.priceOn(DateTime(2026, 5, 10)), (
      amount: 12.0,
      currency: Currency.usd,
    ));
    expect(sub.priceOn(DateTime(2026, 6, 10)), (amount: 15.0, currency: null));
  });

  test('payment history uses the price of each charge', () {
    expect(sub.paymentHistory(DateTime(2026, 6, 20), limit: 6), [
      (date: DateTime(2026, 6, 10), amount: 15.0, currency: null),
      (date: DateTime(2026, 5, 10), amount: 12.0, currency: Currency.usd),
      (date: DateTime(2026, 4, 10), amount: 12.0, currency: Currency.usd),
      (date: DateTime(2026, 3, 10), amount: 12.0, currency: Currency.usd),
      (date: DateTime(2026, 2, 10), amount: 10.0, currency: null),
      (date: DateTime(2026, 1, 10), amount: 10.0, currency: null),
    ]);
  });

  test('price changes list old -> new, newest first', () {
    expect(sub.priceChanges, [
      (
        at: DateTime(2026, 5, 10, 9),
        from: (amount: 12.0, currency: Currency.usd),
        to: (amount: 15.0, currency: null),
      ),
      (
        at: DateTime(2026, 3, 5, 14),
        from: (amount: 10.0, currency: null),
        to: (amount: 12.0, currency: Currency.usd),
      ),
    ]);
  });

  test('history decoding skips bad entries instead of failing', () {
    final json = sub.toJson()
      ..['priceHistory'] = [
        {'amount': 10, 'until': '2026-03-05T14:00:00.000'},
        {'amount': 'oops', 'until': '2026-04-01T00:00:00.000'},
        {'amount': 11},
        'garbage',
        {'amount': 12, 'until': '2026-05-10T09:00:00.000', 'currency': 'xyz'},
      ];
    final decoded = SubSlice.fromJson(json);
    expect(decoded.priceHistory.map((p) => (p.amount, p.currency)), [
      (10.0, null),
      (12.0, null),
    ]);
  });

  test('legacy JSON without history decodes with none', () {
    final json = sub.toJson()..remove('priceHistory');
    expect(SubSlice.fromJson(json).priceHistory, isEmpty);
  });
}
