import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/widgets/exchange_rate_dialog.dart';

void main() {
  test('formatRate trims trailing zeros', () {
    expect(formatRate(34.5), '34.5');
    expect(formatRate(30), '30');
    expect(formatRate(1250), '1250');
    expect(formatRate(1000), '1000');
    expect(formatRate(0.5), '0.5');
    expect(formatRate(1 / 33), '0.0303');
    expect(formatRate(30 / 33, decimals: 6), '0.909091');
  });
}
