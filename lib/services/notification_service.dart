import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Two daily reminders: morning and night. Text has emoji.
/// Prayer text and feelings are never put in a notification.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Set by main.dart: called when the person taps the morning or night reminder.
  static void Function(String kind)? onOpenPrayer;

  /// 'morning' or 'night' if the app was started by tapping a reminder.
  static String? launchKind;

  static void _tapped(NotificationResponse r) {
    final p = r.payload;
    if (p == 'morning' || p == 'night') onOpenPrayer?.call(p!);
  }

  static const _morningId = 101;
  static const _nightId = 102;

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _tapped,
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final p = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && (p == 'morning' || p == 'night')) {
        launchKind = p;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// Ask the user. Call this after onboarding, not at app start.
  static Future<bool> askPermission() async {
    await init();
    try {
      final a = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final i = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return (a ?? i ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Are notifications allowed right now?
  static Future<bool> areEnabled() async {
    await init();
    try {
      final a = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      if (a != null) return a;
      final i = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return i?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_prayer',
          'Daily prayer',
          channelDescription: 'Morning and night prayer reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  static tz.TZDateTime _next(int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  static Future<void> schedule({
    required bool enabled,
    required int morningMin,
    required int nightMin,
    required int streak,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _morningId);
      await _plugin.cancel(id: _nightId);
      if (!enabled) return;

      await _plugin.zonedSchedule(
        id: _morningId,
        scheduledDate: _next(morningMin),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning',
        title: '☀️ Good morning. Meet Jesus first.',
        body: 'Take a breath 🙏 and begin today with prayer before the world asks anything of you.',
      );
      await _plugin.zonedSchedule(
        id: _nightId,
        scheduledDate: _next(nightMin),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'night',
        title: '🌙 Come as you are.',
        body: streak > 0
            ? 'Leave your worries with Him. Keep your $streak 🔥 day streak glowing before bed.'
            : 'Leave your worries with Him. A quiet moment before sleep 💛',
      );
    } catch (e) {
      debugPrint('Schedule failed: $e');
    }
  }

  static const _comebackId = 104;
  static const _comebackLateId = 105;

  /// Gentle "come back" messages if the person has not opened Prayer Lock
  /// for 3 days (and once more after 6 days). Every time the app is opened,
  /// this is scheduled again from that moment, so it only ever fires after
  /// real inactivity. Nothing is sent if reminders are off.
  static Future<void> scheduleComeback({
    required bool enabled,
    required DateTime lastActive,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _comebackId);
      await _plugin.cancel(id: _comebackLateId);
      if (!enabled) return;

      tz.TZDateTime at(int days) {
        final d = lastActive.add(Duration(days: days));
        var t = tz.TZDateTime(tz.local, d.year, d.month, d.day, 18, 0);
        final now = tz.TZDateTime.now(tz.local);
        if (!t.isAfter(now)) t = now.add(const Duration(minutes: 5));
        return t;
      }

      await _plugin.zonedSchedule(
        id: _comebackId,
        scheduledDate: at(3),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: "🙏 There's always time to come back to God",
        body: "It's been a little while. Take a quiet moment with Jesus today. You can always begin again 💛",
      );
      await _plugin.zonedSchedule(
        id: _comebackLateId,
        scheduledDate: at(6),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: '🕊️ Your prayer time is still here',
        body: 'No pressure, no guilt. Open Prayer Lock whenever you are ready 🌅',
      );
    } catch (e) {
      debugPrint('Comeback schedule failed: $e');
    }
  }


  /// Right after a prayer: tell the person their apps are unlocked.
  /// Shows even if they left the Prayer Lock screen.
  static Future<void> unlocked({required int minutes, required bool ios}) async {
    await init();
    if (!_ready) return;
    final open = minutes % 60 == 0
        ? (minutes == 60 ? '1 hour' : '${minutes ~/ 60} hours')
        : '$minutes minutes';
    try {
      await _plugin.show(
        id: 106,
        title: '🔓 Your apps are unlocked',
        body: ios
            ? 'Open for $open. Go back to your app: swipe up and hold, or press Home.'
            : 'Open for $open. They lock again after that.',
        notificationDetails: _details,
      );
    } catch (_) {}
  }
  /// Short celebration shown right after a prayer.
  static Future<void> celebrate(int streak) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 103,
        title: '🔥 $streak ${streak == 1 ? 'day' : 'days'} in a row!',
        body: 'Your faithfulness adds up 🙌',
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
