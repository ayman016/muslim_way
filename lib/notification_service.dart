import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
  }

  Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'prayer_service_channel', 'تنبيهات الصلاة',
      importance: Importance.max, priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
    );
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, title, body, const NotificationDetails(android: androidDetails),
    );
  }
}