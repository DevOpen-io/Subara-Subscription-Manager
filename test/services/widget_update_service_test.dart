import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/services/widget_update_service.dart';

void main() {
  group('WidgetUpdateService.buildWidgetData', () {
    test('empty subs list produces correct shape with empty array and 0.0 total', () {
      final data = WidgetUpdateService.buildWidgetData([], r'$');

      expect(data['subs'], isEmpty);
      expect(data['currency'], r'$');
      expect(data['monthlyTotal'], 0.0);
    });

    test('monthly sub has correct monthlyAmount, startDate format, frequency string', () {
      final start = DateTime(2025, 1, 15);
      final sub = SubSlice(
        name: 'Netflix',
        amount: 9.99,
        color: 0xFFFF0000,
        startDate: start,
      );

      final data = WidgetUpdateService.buildWidgetData([sub], r'$');

      final subs = data['subs'] as List;
      expect(subs.length, 1);
      final entry = subs[0] as Map<String, dynamic>;
      expect(entry['name'], 'Netflix');
      expect(entry['amount'], 9.99);
      expect(entry['monthlyAmount'], 9.99);
      expect(entry['startDate'], start.toIso8601String());
      expect(entry['frequency'], 'monthly');
      expect(entry['color'], 0xFFFF0000);
      expect(data['monthlyTotal'], 9.99);
    });

    test('yearly sub has correct monthlyAmount (amount / 12)', () {
      final start = DateTime(2025, 3);
      final sub = SubSlice(
        name: 'iCloud',
        amount: 119.88,
        color: 0xFF0000FF,
        startDate: start,
        frequency: Frequency.yearly,
      );

      final data = WidgetUpdateService.buildWidgetData([sub], '€');

      final subs = data['subs'] as List;
      final entry = subs[0] as Map<String, dynamic>;
      expect(entry['frequency'], 'yearly');
      expect(entry['monthlyAmount'], closeTo(9.99, 0.001));
      expect(data['monthlyTotal'], closeTo(9.99, 0.001));
    });

    test('currency symbol is passed through correctly', () {
      final data = WidgetUpdateService.buildWidgetData([], '₺');
      expect(data['currency'], '₺');
    });

    test('multiple subs monthlyTotal is sum of all monthlyAmounts', () {
      final subs = [
        SubSlice(
          name: 'Netflix',
          amount: 9.99,
          color: 0xFF000000,
          startDate: DateTime(2025),
        ),
        SubSlice(
          name: 'Spotify',
          amount: 119.88,
          color: 0xFF000001,
          startDate: DateTime(2025, 2),
          frequency: Frequency.yearly, // 9.99/month
        ),
      ];

      final data = WidgetUpdateService.buildWidgetData(subs, r'$');
      expect(data['monthlyTotal'], closeTo(19.98, 0.001));
    });

    test('cancelled and paused subs are excluded from subs list and total', () {
      final subs = [
        SubSlice(
          name: 'Netflix',
          amount: 9.99,
          color: 0xFF000000,
          startDate: DateTime(2025),
        ),
        SubSlice(
          name: 'Old Gym',
          amount: 30,
          color: 0xFF000001,
          startDate: DateTime(2025),
          status: SubStatus.cancelled,
        ),
        SubSlice(
          name: 'Paused Box',
          amount: 20,
          color: 0xFF000002,
          startDate: DateTime(2025),
          status: SubStatus.paused,
        ),
      ];

      final data = WidgetUpdateService.buildWidgetData(subs, r'$');
      final subsJson = data['subs'] as List;

      expect(subsJson.length, 1);
      expect((subsJson.first as Map<String, dynamic>)['name'], 'Netflix');
      expect(data['monthlyTotal'], 9.99);
    });
  });
}
