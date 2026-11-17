import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/utils/payment_methods.dart';

SubSlice _sub(double amount, {String? method, String? card}) => SubSlice(
  name: 'x',
  amount: amount,
  color: 0,
  startDate: DateTime(2026),
  paymentMethod: method,
  cardLastFour: card,
);

void main() {
  test('groups by method and card, biggest first', () {
    final groups = groupByPaymentMethod([
      _sub(10, method: 'Credit card', card: '1234'),
      _sub(5, method: 'credit card ', card: '1234'),
      _sub(30, method: 'PayPal'),
      _sub(2),
      _sub(4, card: '9999'),
    ]);
    expect(groups.map((g) => (g.method, g.card, g.monthly, g.count)), [
      ('PayPal', null, 30.0, 1),
      ('Credit card', '1234', 15.0, 2),
      (null, '9999', 4.0, 1),
      (null, null, 2.0, 1),
    ]);
  });

  test('label combines method and card', () {
    expect(paymentLabel('Visa', '1234', notSet: '—'), 'Visa •••• 1234');
    expect(paymentLabel(null, '1234', notSet: '—'), '•••• 1234');
    expect(paymentLabel('  ', null, notSet: '—'), '—');
  });
}
