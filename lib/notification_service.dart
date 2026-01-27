import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. تهيئة التوقيت
    tzData.initializeTimeZones();

    // 2. إعدادات الأندرويد
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 3. إعدادات iOS
    const DarwinInitializationSettings initializationSettingsDarwin = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 قام المستخدم بالضغط على الإشعار: ${details.payload}");
      },
    );
  }

  // ✅ دالة طلب الإذن العادي
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ✅✅ دالة محدثة لطلب إذن Exact Alarms
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // 1️⃣ التحقق من الإذن
          final bool? canSchedule = await androidPlugin.canScheduleExactNotifications();
          print("📋 حالة إذن المنبهات الدقيقة: $canSchedule");
          
          if (canSchedule == null || canSchedule == false) {
            print("⚠️ الإذن غير ممنوح، جاري الطلب...");
            
            // 2️⃣ طلب الإذن
            final bool? granted = await androidPlugin.requestExactAlarmsPermission();
            
            if (granted == true) {
              print("✅ تم منح إذن المنبهات الدقيقة");
              return true;
            } else {
              print("❌ المستخدم رفض إذن المنبهات الدقيقة");
              print("💡 سيتم استخدام المنبهات العادية (Inexact) كبديل");
              return false;
            }
          } else {
            print("✅ إذن المنبهات الدقيقة ممنوح مسبقاً");
            return true;
          }
        } else {
          print("❌ فشل الوصول إلى AndroidFlutterLocalNotificationsPlugin");
          return false;
        }
      } catch (e) {
        print("❌ خطأ في طلب إذن Exact Alarms: $e");
        return false;
      }
    }
    return true; // iOS ما عندوش هاد المشكل
  }

  // ✅ إشعار فوري
  Future<void> showImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'muslim_way_urgent_v1',
      'تنبيهات فورية',
      channelDescription: 'إشعارات فورية مهمة',
      importance: Importance.max, 
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, 
      title, 
      body, 
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  // ✅ دالة التذكير المحسنة
  Future<void> scheduleNotification({
    required int id, 
    required String title, 
    required String body, 
    required DateTime scheduledTime
  }) async {
    
    // تحويل الوقت
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print("🕒 محاولة ضبط تذكير على: $tzScheduledTime");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_v3', 
      'تذكير المهام',
      channelDescription: 'قناة التذكير بمهام تطبيق Muslim Way',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      // 1️⃣ المحاولة الأولى: منبه دقيق (Exact)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("✅ تم ضبط التذكير (Exact) بنجاح");
      
    } catch (e) {
      print("⚠️ النظام منع المنبه الدقيق: $e");
      print("🔄 جاري التحويل إلى منبه عادي (Inexact)...");

      // 2️⃣ الخطة البديلة: منبه عادي (Inexact)
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          const NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        print("✅ تم ضبط التذكير (Inexact) بنجاح");
      } catch (e2) {
        print("❌ فشل ضبط التذكير نهائياً: $e2");
      }
    }
  }

  // ✅ إلغاء تذكير معين
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("🗑️ تم إلغاء التذكير رقم: $id");
  }

  // ✅ إلغاء كل التذكيرات
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ تم إلغاء جميع التذكيرات");
  }
}