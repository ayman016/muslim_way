import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern باش نعيطو للسرفيس من أي بلاصة
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. دالة البداية (Initialization)
  Future<void> init() async {
    // تهيئة التوقيت
    tz.initializeTimeZones();

    // إعدادات الأندرويد (تأكد أن أيقونة التطبيق موجودة)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات الأيفون (iOS)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // 2. دالة طلب الإذن (مهمة لـ Android 13+)
Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // 👇 هاد السطر هو اللي كيطلع الـ Pop-up ديال "Allow Notifications"
    await androidImplementation?.requestNotificationsPermission();

    // ❌ حيدنا السطر ديال requestExactAlarmsPermission
    // حيت هو اللي كان كيديك للـ Settings بزز
  }

  // 3. دالة جدولة الصلاة
  Future<void> schedulePrayer(int id, String title, DateTime time) async {
    final now = DateTime.now();
    
    // إذا كان وقت الصلاة فات اليوم، ما نجدولوش
    if (time.isBefore(now)) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // رقم فريد لكل صلاة
      title, // العنوان (مثلاً: الفجر)
      "حان موعد صلاة $title", // محتوى الإشعار
      tz.TZDateTime.from(time, tz.local), // الوقت
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel', // Channel ID
          'Prayer Notifications', // Channel Name
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // 👇 بدلنا exact بـ inexact باش ما يطلبش منك تمشي للـ Settings
androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // 4. دالة إلغاء الإشعارات القديمة
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}