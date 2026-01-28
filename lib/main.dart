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

// ✅ دالة العمل في الخلفية (محسنة)
@pragma('vm:entry-point') 
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? lat = prefs.getDouble('lat');
      final double? long = prefs.getDouble('long');

      if (lat != null && long != null) {
        // ✅ جدولة جميع صلوات اليوم
        await scheduleTodayPrayers(lat, long);
      }
      
      return Future.value(true);
    } catch (e) {
      print("❌ خطأ في callbackDispatcher: $e");
      return Future.value(false);
    }
  });
}

// ✅✅ دالة جديدة: جدولة جميع صلوات اليوم
Future<void> scheduleTodayPrayers(double lat, double long) async {
  try {
    final myCoordinates = Coordinates(lat, long);
    final params = CalculationMethod.muslim_world_league.getParameters();
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    
    final notifService = NotificationService();
    await notifService.init();
    
    final now = DateTime.now();
    
    // قائمة الصلوات (بدون الشروق)
    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];
    
    int scheduledCount = 0;
    
    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      
      if (prayerTime != null && prayerTime.isAfter(now)) {
        // ✅ جدولة الصلاة
        await notifService.scheduleNotification(
          id: prayer.index + 1000,
          title: "حان موعد الصلاة 🕌",
          body: _getPrayerName(prayer),
          scheduledTime: prayerTime,
        );
        
        scheduledCount++;
        print("✅ تم جدولة ${_getPrayerName(prayer)} على ${prayerTime.hour}:${prayerTime.minute.toString().padLeft(2, '0')}");
      }
    }
    
    print("✅ تم جدولة $scheduledCount صلاة لليوم");
    
  } catch (e) {
    print("❌ خطأ في جدولة الصلوات: $e");
  }
}

// ✅ دالة مساعدة للحصول على اسم الصلاة
String _getPrayerName(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr: return "صلاة الفجر - الله أكبر";
    case Prayer.dhuhr: return "صلاة الظهر - حي على الصلاة";
    case Prayer.asr: return "صلاة العصر - حي على الفلاح";
    case Prayer.maghrib: return "صلاة المغرب - الصلاة خير من النوم";
    case Prayer.isha: return "صلاة العشاء - الله أكبر";
    default: return "حان موعد الصلاة";
  }
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
  
  // 3️⃣ طلب أذونات الإشعارات
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

  // ✅✅ 6️⃣ جدولة صلوات اليوم مباشرة عند التشغيل
  print("🔄 جاري جدولة صلوات اليوم...");
  final prefs = await SharedPreferences.getInstance();
  final double? lat = prefs.getDouble('lat');
  final double? long = prefs.getDouble('long');
  
  if (lat != null && long != null) {
    await scheduleTodayPrayers(lat, long);
  } else {
    print("⚠️ لم يتم العثور على الموقع، سيتم الجدولة عند توفره");
  }

  // 7️⃣ Workmanager - يجدد الجدولة كل يوم
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  // ✅ كل 6 ساعات بدل 15 دقيقة (توفير للبطارية)
  await Workmanager().registerPeriodicTask(
    "prayerTimeChecker",
    "prayerTimeChecker",
    frequency: const Duration(hours: 6), // ✅ تحديث كل 6 ساعات
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );
  
  print("✅ تم تفعيل مراقبة أوقات الصلاة");
  
  // 8️⃣ اللغة
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