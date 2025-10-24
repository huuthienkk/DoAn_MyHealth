import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios =
        DarwinInitializationSettings(); // đổi từ IOSInitializationSettings
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      'channel1',
      'Reminder',
      importance: Importance.max,
    );
    const ios = DarwinNotificationDetails(); // đổi từ IOSNotificationDetails
    const platform = NotificationDetails(android: android, iOS: ios);
    await _notificationsPlugin.show(0, title, body, platform);
  }
}
