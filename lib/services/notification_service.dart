import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 🚀 Khởi tạo hệ thống thông báo
  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);
  }

  /// 🔔 Thông báo ngay (test/debug)
  Future<void> showInstantNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        channelDescription: 'Thông báo ngay lập tức',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(0, title, body, details);
  }

  /// 💧 Nhắc uống nước (8h → 20h)
  Future<void> scheduleWaterReminders(int intervalMinutes) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    const startHour = 8, endHour = 20;

    final startTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
    );

    int id = 0;
    for (int m = 0; m < (12 * 60); m += intervalMinutes) {
      final time = startTime.add(Duration(minutes: m));
      if (time.isAfter(now) && time.hour <= endHour) {
        await _plugin.zonedSchedule(
          id++,
          '💧 Uống nước nào!',
          'Hãy uống thêm 250ml nước để đủ 2 lít mỗi ngày 💦',
          time,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_channel',
              'Water Reminder',
              channelDescription: 'Nhắc nhở uống nước định kỳ',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  /// 😴 Nhắc ngủ (giờ cố định, ví dụ 22h)
  Future<void> scheduleSleepReminder(int hour) async {
    final now = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );
    final time =
        target.isBefore(now) ? target.add(const Duration(days: 1)) : target;

    await _plugin.zonedSchedule(
      200,
      '😴 Đến giờ đi ngủ rồi!',
      'Hãy nghỉ ngơi sớm để có giấc ngủ chất lượng 💫',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_channel',
          'Sleep Reminder',
          channelDescription: 'Nhắc ngủ đúng giờ',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 🚶 Nhắc vận động
  Future<void> scheduleMoveReminders(int intervalMinutes) async {
    final now = tz.TZDateTime.now(tz.local);
    const startHour = 9, endHour = 18;
    final start = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
    );

    int id = 300;
    for (int m = 0; m < (9 * 60); m += intervalMinutes) {
      final time = start.add(Duration(minutes: m));
      if (time.isAfter(now) && time.hour <= endHour) {
        await _plugin.zonedSchedule(
          id++,
          '🚶 Hãy vận động nào!',
          'Đứng dậy, vươn vai hoặc đi lại một chút nhé 💪',
          time,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'move_channel',
              'Move Reminder',
              channelDescription: 'Nhắc vận động định kỳ',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  /// 😊 Nhắc ghi tâm trạng (9h sáng & 20h tối)
  Future<void> scheduleMoodReminders() async {
    final now = tz.TZDateTime.now(tz.local);
    final times = [
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 9),
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 20),
    ];

    int id = 400;
    for (var t in times) {
      final time = t.isBefore(now) ? t.add(const Duration(days: 1)) : t;
      await _plugin.zonedSchedule(
        id++,
        '😊 Ghi lại tâm trạng của bạn',
        'Hôm nay bạn cảm thấy thế nào? Hãy ghi lại nhé 💬',
        time,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mood_channel',
            'Mood Reminder',
            channelDescription: 'Nhắc ghi tâm trạng buổi sáng & tối',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// ❌ Hủy tất cả thông báo
  Future<void> cancelAll() async => _plugin.cancelAll();
}
