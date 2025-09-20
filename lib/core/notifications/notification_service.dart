import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService I = NotificationService._();
  NotificationService._();

  final _noti = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _noti.initialize(const InitializationSettings(android: android));

    // Android 13+ cần xin quyền
    await _noti
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // TZ
    tz.initializeTimeZones();
    // Nếu bạn ở VN:
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var time = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (time.isBefore(now)) time = time.add(const Duration(days: 1));

    await _noti.zonedSchedule(
      1001, // id cố định
      'Học từ vựng hôm nay',
      'Mở app để ôn những thẻ đến hạn nhé!',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // lặp hằng ngày
    );
  }

  Future<void> cancelDaily() => _noti.cancel(1001);
}
