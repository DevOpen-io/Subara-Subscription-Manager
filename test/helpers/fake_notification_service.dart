import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:subs_tracker/utils/mark_paid_payload.dart';
import 'package:subs_tracker/utils/notification_service.dart';

/// Records scheduling calls instead of talking to the platform plugin.
class FakeNotificationService implements NotificationService {
  final scheduled =
      <
        ({
          int id,
          String body,
          DateTime date,
          DateTimeComponents? repeat,
          MarkPaidAction? markPaid,
        })
      >[];
  int cancelAllCount = 0;
  int permissionRequests = 0;

  /// Emit here to simulate a "Paid" tap on a notification.
  // ignore: close_sinks, lives as long as the test.
  final markPaidTaps = StreamController<MarkPaidRequest>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    MarkPaidAction? markPaid,
  }) async {
    scheduled.add((
      id: id,
      body: body,
      date: scheduledDate,
      repeat: matchDateTimeComponents,
      markPaid: markPaid,
    ));
  }

  @override
  Stream<MarkPaidRequest> get markPaidRequests => markPaidTaps.stream;

  @override
  Future<bool?> exactRemindersAllowed() async => null;

  @override
  Future<void> requestExactReminders() async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCount++;
    scheduled.clear();
  }
}
