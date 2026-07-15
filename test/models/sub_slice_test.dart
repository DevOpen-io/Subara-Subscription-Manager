import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';

void main() {
  group('SubSlice', () {
    test('monthlyAmount calculates correctly for Daily', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 10,
        color: 0,
        startDate: DateTime.now(),
        frequency: Frequency.daily,
      );
      expect(slice.monthlyAmount, 300); // 10 * 30
    });

    test('monthlyAmount calculates correctly for Weekly', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 10,
        color: 0,
        startDate: DateTime.now(),
        frequency: Frequency.weekly,
      );
      expect(slice.monthlyAmount, 43.3); // 10 * 4.33
    });

    test('monthlyAmount calculates correctly for Monthly', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 10,
        color: 0,
        startDate: DateTime.now(),
      );
      expect(slice.monthlyAmount, 10);
    });

    test('monthlyAmount calculates correctly for Yearly', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 120,
        color: 0,
        startDate: DateTime.now(),
        frequency: Frequency.yearly,
      );
      expect(slice.monthlyAmount, 10); // 120 / 12
    });

    test('default frequency is Monthly', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 10,
        color: 0,
        startDate: DateTime.now(),
      );
      expect(slice.frequency, Frequency.monthly);
    });

    test('default status is active', () {
      final slice = SubSlice(
        name: 'Test',
        amount: 10,
        color: 0,
        startDate: DateTime.now(),
      );
      expect(slice.status, SubStatus.active);
    });
  });

  group('SubSliceListX.activeOnly', () {
    SubSlice makeSlice(String name, SubStatus status) => SubSlice(
          name: name,
          amount: 10,
          color: 0,
          startDate: DateTime.now(),
          status: status,
        );

    test('keeps only active subscriptions', () {
      final slices = [
        makeSlice('Active', SubStatus.active),
        makeSlice('Trial', SubStatus.freeTrial),
        makeSlice('Paused', SubStatus.paused),
        makeSlice('Cancelled', SubStatus.cancelled),
      ];

      expect(slices.activeOnly.map((s) => s.name), ['Active']);
    });

    test('empty list stays empty', () {
      expect(<SubSlice>[].activeOnly, isEmpty);
    });
  });
}
