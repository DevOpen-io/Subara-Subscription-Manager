import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'mark_paid_payload.dart';

part 'notification_service.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) =>
    LocalNotificationService.instance;

abstract class NotificationService {
  Future<void> init();

  /// Asks the OS for permission to post notifications. Called after
  /// onboarding, not at launch, so the user has context for the prompt.
  Future<void> requestPermission();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    MarkPaidAction? markPaid,
  });

  /// "Paid" taps on reminders, including the one that launched the app.
  Stream<MarkPaidRequest> get markPaidRequests;

  /// Android 12+: whether reminders may fire at their exact time (otherwise
  /// the OS can delay them). Null where there is no such setting.
  Future<bool?> exactRemindersAllowed();

  /// Android: opens the system screen that allows (or stops) exact
  /// reminders. Returns right away; re-read [exactRemindersAllowed] when the
  /// app resumes.
  Future<void> requestExactReminders();

  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService._privateConstructor();

  static final LocalNotificationService instance =
      LocalNotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _markPaidTaps = StreamController<MarkPaidRequest>.broadcast();

  /// The "Paid" tap that launched the app, handed to the first listener.
  MarkPaidRequest? _launchTap;

  static MarkPaidRequest? _markPaidFrom(NotificationResponse? r) =>
      r?.actionId == markPaidActionId ? decodeMarkPaid(r?.payload) : null;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  Future<List<PendingNotificationRequest>> get scheduledNotifications =>
      flutterLocalNotificationsPlugin.pendingNotificationRequests();
  @override
  Future<void> init() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Don't prompt at launch; see [requestPermission].
    // iOS registers button titles here, before translations load, so they
    // follow the device language.
    final paidTitle = PlatformDispatcher.instance.locale.languageCode == 'tr'
        ? 'Ödendi'
        : 'Paid';
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          markPaidCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              markPaidActionId,
              paidTitle,
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();
    // Without this tz.local stays UTC and reminders fire at 12:00 UTC.
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Could not resolve local timezone, using UTC: $e');
    }

    // "Paid" buttons open the app (showsUserInterface / foreground), so taps
    // arrive here in the main isolate, never in a background one that would
    // race the app's own writes to subs.db.
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (r) {
        if (_markPaidFrom(r) case final tap?) _markPaidTaps.add(tap);
      },
    );
    try {
      final launch = await flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchTap = _markPaidFrom(launch!.notificationResponse);
      }
    } catch (e) {
      debugPrint('Could not read notification launch details: $e');
    }
  }

  @override
  Stream<MarkPaidRequest> get markPaidRequests async* {
    final launch = _launchTap;
    _launchTap = null;
    if (launch != null) yield launch;
    yield* _markPaidTaps.stream;
  }

  @override
  Future<bool?> exactRemindersAllowed() async {
    final android = _android;
    if (android == null) return null;
    try {
      if (await _exactAlarms.invokeMethod<bool>('hasSettings') != true) {
        return null;
      }
    } on PlatformException {
      return null;
    }
    return android.canScheduleExactNotifications();
  }

  static const _exactAlarms = MethodChannel('io.devopen.subzilla/exact_alarms');

  @override
  Future<void> requestExactReminders() async {
    if (_android == null) return;
    try {
      await _exactAlarms.invokeMethod<bool>('openSettings');
    } on PlatformException catch (e) {
      debugPrint('Could not open exact alarm settings: $e');
    }
  }

  @override
  Future<void> requestPermission() async {
    // ANDROID 13+: ask for runtime permission
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    // iOS: ask for alert/badge/sound permissions
    final iosImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    MarkPaidAction? markPaid,
  }) async {
    // Exact only when allowed: scheduling an exact alarm without the
    // permission throws, which would leave no reminders at all.
    // (Always allowed before Android 12.)
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      payload: markPaid == null
          ? null
          : encodeMarkPaid((subId: markPaid.subId, charge: markPaid.charge)),
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          categoryIdentifier: markPaid == null ? null : markPaidCategoryId,
        ),
        android: AndroidNotificationDetails(
          'subscription_channel_id',
          'Subscription Notifications',
          channelDescription:
              'Notifications for subscription updates to show you the upcoming subscriptions',
          actions: [
            if (markPaid != null)
              AndroidNotificationAction(
                markPaidActionId,
                markPaid.label,
                showsUserInterface: true,
              ),
          ],
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
