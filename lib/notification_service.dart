import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. تهيئة التوقيت
    tzData.initializeTimeZones();

    // 2. إعدادات الأندرويد
    // تأكد أنك تستخدم الأيقونة الافتراضية الصحيحة لتجنب مشاكل الموارد
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 3. إعدادات iOS
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // هنا تقدر تدير شي حاجة إلا ضغط المستخدم على الإشعار
        print("🔔 قام المستخدم بالضغط على الإشعار: ${details.payload}");
      },
    );
  }

  // ✅ دالة طلب الإذن (Android 13+)
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // إشعار فوري
  Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'muslim_way_urgent_v1', // قناة جديدة
      'تنبيهات فورية',
      importance: Importance.max, 
      priority: Priority.high,
      playSound: true,
    );
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, title, body, const NotificationDetails(android: androidDetails),
    );
  }

  // ✅ دالة التذكير (المصححة)
  Future<void> scheduleNotification({
    required int id, 
    required String title, 
    required String body, 
    required DateTime scheduledTime
  }) async {
    
    // تحويل الوقت
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print("🕒 محاولة ضبط تذكير على: $tzScheduledTime");

    // ⚠️ تغيير اسم القناة ضروري لأن الأندرويد يحفظ الإعدادات القديمة
    // إذا كانت القناة القديمة "بدون صوت"، ستظل بدون صوت حتى لو غيرت الكود
    // لذلك نستخدم ID جديد: 'task_reminder_v3'
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_v3', // ✅ غيرنا الـ ID باش نضمنو الصوت يخدم
      'تذكير المهام',
      channelDescription: 'قناة التذكير بمهام تطبيق Muslim Way',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    try {
      // 1️⃣ المحاولة الأولى: منبه دقيق (Exact)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        const NotificationDetails(android: androidDetails),
        // ✅ هذا هو الخيار الأفضل
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // اختياري: إذا بغيتي التذكير يتعاود يومياً نفس الوقت
      );
      print("✅ تم ضبط التذكير (Exact) بنجاح");
      
    } catch (e) {
      print("⚠️ النظام منع المنبه الدقيق: $e");
      print("🔄 جاري التحويل إلى منبه عادي (Inexact)...");

      // 2️⃣ الخطة البديلة: منبه عادي (Inexact)
      // ❌ هنا كان عندك الخطأ، كنتي داير exact مرة أخرى
      // ✅ التصحيح:
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          const NotificationDetails(android: androidDetails),
          // 👇👇👇 هنا التغيير المهم
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, 
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        print("✅ تم ضبط التذكير (Inexact) بنجاح");
      } catch (e2) {
        print("❌ فشل ضبط التذكير نهائياً: $e2");
      }
    }
  }
}