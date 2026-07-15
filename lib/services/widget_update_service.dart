import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/sub_slice.dart';

class WidgetUpdateService {
  WidgetUpdateService._();

  static final instance = WidgetUpdateService._();

  static Map<String, dynamic> buildWidgetData(
    List<SubSlice> allSubs,
    String currency,
  ) {
    final subs = allSubs.activeOnly;
    final subsJson = subs
        .map((s) => {
              'name': s.name,
              'amount': s.amount,
              'monthlyAmount': s.monthlyAmount,
              'startDate': s.startDate.toIso8601String(),
              'frequency': s.frequency.name,
              'color': s.color,
            })
        .toList();

    final monthlyTotal = subs.fold<double>(0, (sum, s) => sum + s.monthlyAmount);

    return {
      'subs': subsJson,
      'currency': currency,
      'monthlyTotal': monthlyTotal,
    };
  }

  Future<void> update(List<SubSlice> subs, String currencySymbol) async {
    try {
      final data = buildWidgetData(subs, currencySymbol);
      await HomeWidget.saveWidgetData('subs_data', jsonEncode(data));
      await Future.wait([
        HomeWidget.updateWidget(
          iOSName: 'MonthlySpendWidget',
          qualifiedAndroidName: 'io.devopen.subzilla.widget.MonthlySpendWidgetReceiver',
        ),
        HomeWidget.updateWidget(
          iOSName: 'NextDueWidget',
          qualifiedAndroidName: 'io.devopen.subzilla.widget.NextDueWidgetReceiver',
        ),
        HomeWidget.updateWidget(
          iOSName: 'UpcomingWidget',
          qualifiedAndroidName: 'io.devopen.subzilla.widget.UpcomingWidgetReceiver',
        ),
      ]);
    } catch (_) {
      // Widgets are non-critical — silently ignore errors.
    }
  }
}
