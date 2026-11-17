import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/utils/mark_paid_payload.dart';

void main() {
  test('payload round-trips the sub and the charge day', () {
    final payload = encodeMarkPaid((
      subId: 'abc',
      charge: DateTime(2026, 11, 10, 12, 30),
    ));
    expect(decodeMarkPaid(payload), (
      subId: 'abc',
      charge: DateTime(2026, 11, 10),
    ));
  });

  test('foreign or broken payloads are ignored', () {
    for (final p in [
      null,
      '',
      'nope',
      '[]',
      '{"sub":"a"}',
      '{"sub":"","charge":"2026-11-10"}',
      '{"sub":"a","charge":"x"}',
      '{"sub":3,"charge":"2026-11-10"}',
    ]) {
      expect(decodeMarkPaid(p), isNull, reason: p);
    }
  });
}
