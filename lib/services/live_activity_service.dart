import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/billing.dart';
import '../models/sub_slice.dart';

class LiveActivityService {
  LiveActivityService._();
  static final instance = LiveActivityService._();

  static const _channel = MethodChannel('io.devopen.subzilla/live_activity');

  /// [symbolOf] gives each subscription's own currency symbol (the JSON
  /// already carries a currency per entry).
  Future<void> startIfDueToday(
    List<SubSlice> subs,
    String Function(SubSlice) symbolOf,
  ) async {
    final today = DateTime.now();
    final dueToday = subs.where((s) => _isDueToday(s, today)).toList();
    if (dueToday.isEmpty) return;

    final subsJson = jsonEncode(
      dueToday
          .map(
            (s) => {
              'name': s.name,
              'amount': s.amount,
              'currency': symbolOf(s),
              'color': s.color,
            },
          )
          .toList(),
    );

    try {
      await _channel.invokeMethod('startActivity', {'subsJson': subsJson});
    } on PlatformException {
      // Live Activities not supported or denied — silently ignore
    } on MissingPluginException {
      // No Live Activity channel (Android) — nothing to start.
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

  bool _isDueToday(SubSlice sub, DateTime today) =>
      sub.status != SubStatus.paused &&
      sub.status != SubStatus.cancelled &&
      sub.isDueOn(today);
}
