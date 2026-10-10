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
      );
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
        title: '☀️ Good morning. Meet Jesus first.',
        body: 'Take a breath 🙏 and begin today with prayer before the world asks anything of you.',
      );
      await _plugin.zonedSchedule(
        id: _nightId,
        scheduledDate: _next(nightMin),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        title: '🌙 Come as you are.',
        body: streak > 0
            ? 'Leave your worries with Him. Keep your $streak 🔥 day streak glowing before bed.'
            : 'Leave your worries with Him. A quiet moment before sleep 💛',
      );
    } catch (e) {
      debugPrint('Schedule failed: $e');
    }
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
