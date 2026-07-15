import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/sub_slice.dart';

class LiveActivityService {
  LiveActivityService._();
  static final instance = LiveActivityService._();

  static const _channel = MethodChannel('io.devopen.subzilla/live_activity');

  Future<void> startIfDueToday(List<SubSlice> subs, String currencySymbol) async {
    final today = DateTime.now();
    final dueToday = subs.where((s) => _isDueToday(s, today)).toList();
    if (dueToday.isEmpty) return;

    final subsJson = jsonEncode(dueToday.map((s) => {
      'name': s.name,
      'amount': s.amount,
      'currency': currencySymbol,
      'color': s.color,
    }).toList());

    try {
      await _channel.invokeMethod('startActivity', {'subsJson': subsJson});
    } on PlatformException {
      // Live Activities not supported or denied — silently ignore
    }
  }

  Future<void> startRaw(String subsJson) async {
    try {
      await _channel.invokeMethod('startActivity', {'subsJson': subsJson});
    } on PlatformException {
      // ignore
    }
  }

  Future<void> end() async {
    try {
      await _channel.invokeMethod('endActivity');
    } on PlatformException {
      // ignore
    }
  }

  bool _isDueToday(SubSlice sub, DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);
    var candidate = DateTime(sub.startDate.year, sub.startDate.month, sub.startDate.day);
    final anchorDay = sub.startDate.day;
    // Advance until we pass today or land on today
    while (candidate.isBefore(todayDate)) {
      candidate = _advance(candidate, sub.frequency, anchorDay);
    }
    return candidate == todayDate;
  }

  DateTime _advance(DateTime date, Frequency freq, int anchorDay) {
    switch (freq) {
      case Frequency.daily:
        return date.add(const Duration(days: 1));
      case Frequency.weekly:
        return date.add(const Duration(days: 7));
      case Frequency.monthly:
        final nextMonth = date.month == 12 ? 1 : date.month + 1;
        final nextYear = date.month == 12 ? date.year + 1 : date.year;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        return DateTime(nextYear, nextMonth, anchorDay.clamp(1, lastDay));
      case Frequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}
