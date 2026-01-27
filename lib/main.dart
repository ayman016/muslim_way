import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/auth_wrapper.dart'; 
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/language_provider.dart'; 

// ✅ دالة العمل في الخلفية
@pragma('vm:entry-point') 
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // جلب الإحداثيات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      final double? lat = prefs.getDouble('lat');
      final double? long = prefs.getDouble('long');

      if (lat != null && long != null) {
        final myCoordinates = Coordinates(lat, long);
        final params = CalculationMethod.muslim_world_league.getParameters();
        final prayerTimes = PrayerTimes.today(myCoordinates, params);
        
        final currentPrayer = prayerTimes.currentPrayer();
        
        // 1. إشعار الصلاة الحالية
        if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
          final notifService = NotificationService();
          await notifService.init();
          
          await notifService.showImmediateNotification(
            "حان موعد الصلاة 🕌",
            "الله أكبر، الله أكبر.. حي على الصلاة",
          );
          
          print("✅ تم إرسال إشعار الصلاة: ${currentPrayer.name}");
        }
        
        // 2. جدولة الصلاة القادمة
        final nextPrayer = prayerTimes.nextPrayer();
        final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
        
        if (nextPrayerTime != null && nextPrayer != Prayer.sunrise) {
          final notifService = NotificationService();
          await notifService.init();
          
          await notifService.scheduleNotification(
            id: nextPrayer.index + 1000,
            title: "حان موعد الصلاة 🕌",
            body: "الله أكبر، الله أكبر.. حي على الصلاة",
            scheduledTime: nextPrayerTime,
          );
          
          print("✅ تم جدولة الصلاة القادمة: ${nextPrayer.name} على ${nextPrayerTime}");
        }
      }
      
      return Future.value(true);
    } catch (e) {
      print("❌ خطأ في callbackDispatcher: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1️⃣ Firebase
  try {
    await Firebase.initializeApp(); 
    print("✅ Firebase Connected Successfully");
  } catch (e) {
    print("❌ Firebase Error: $e");
  }

  // 2️⃣ تهيئة الإشعارات
  print("🔄 جاري تهيئة خدمة الإشعارات...");
  await NotificationService().init();
  print("✅ تم تهيئة خدمة الإشعارات");
  
  // 3️⃣ طلب أذونات الإشعارات الأساسية
  print("🔄 جاري طلب أذونات الإشعارات...");
  await NotificationService().requestPermissions();
  print("✅ تم طلب أذونات الإشعارات");
  
  // 4️⃣ طلب إذن Exact Alarms
  print("🔄 جاري طلب إذن المنبهات الدقيقة...");
  final exactAlarmGranted = await NotificationService().requestExactAlarmPermission();
  if (exactAlarmGranted) {
    print("✅✅ تم منح إذن المنبهات الدقيقة");
  } else {
    print("⚠️⚠️ لم يتم منح إذن المنبهات الدقيقة");
  }
  
  // 5️⃣ اختبار إشعار فوري
  print("🔄 جاري اختبار الإشعار الفوري...");
  await NotificationService().showImmediateNotification(
    "مرحباً بك في Muslim Way 🌙",
    "التطبيق جاهز للاستخدام",
  );
  print("✅ تم إرسال إشعار الاختبار");

  // 6️⃣ Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  await Workmanager().registerPeriodicTask(
    "prayerTimeChecker",
    "prayerTimeChecker",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );
  
  print("✅ تم تفعيل مراقبة أوقات الصلاة");
  
  // 7️⃣ اللغة
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => languageProvider), 
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(), 
      ),
    ),
  );
}