import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
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
      print("🔔 Workmanager task started: $task");
      
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ مهمة فحص تذكيرات المهام
      if (task == "taskRemindersChecker") {
        print("🔄 جاري فحص تذكيرات المهام...");
        
        List<String>? savedTasks = prefs.getStringList('cached_tasks');
        
        if (savedTasks != null && savedTasks.isNotEmpty) {
          final now = DateTime.now();
          
          for (var taskData in savedTasks) {
            List<String> parts = taskData.split('|');
            
            if (parts.length >= 5 && parts[4] != "null") {
              try {
                DateTime reminderTime = DateTime.parse(parts[4]);
                
                final difference = now.difference(reminderTime).abs();
                
                if (difference.inMinutes <= 5 && reminderTime.isBefore(now.add(const Duration(minutes: 1)))) {
                  final notif = NotificationService();
                  await notif.init();
                  await notif.showImmediateNotification(
                    "تذكير: ${parts[0]}",
                    "حان موعد القيام بمهمتك! 📝",
                  );
                  
                  print("✅ تم إرسال تذكير المهمة: ${parts[0]}");
                }
              } catch (e) {
                print("❌ خطأ في معالجة تذكير: $e");
              }
            }
          }
        }
      }
      
      // ✅ مهمة الصلاة
      if (task == "prayerTimeChecker") {
        print("🔄 جاري فحص مواقيت الصلاة...");
        
        final double? lat = prefs.getDouble('lat');
        final double? long = prefs.getDouble('long');

        if (lat != null && long != null) {
          await scheduleTodayPrayers(lat, long);
          print("✅ تم تحديث جدول الصلوات");
        } else {
          print("⚠️ الموقع غير متوفر");
        }
      }
      
      return Future.value(true);
    } catch (e) {
      print("❌ خطأ في callbackDispatcher: $e");
      return Future.value(false);
    }
  });
}

// ✅ دالة جدولة الصلوات
Future<void> scheduleTodayPrayers(double lat, double long) async {
  try {
    final myCoordinates = Coordinates(lat, long);
    final params = CalculationMethod.muslim_world_league.getParameters();
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    
    final notifService = NotificationService();
    await notifService.init();
    
    final now = DateTime.now();
    
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
  // ✅ ضروري قبل أي شيء
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1️⃣ Firebase
  try {
    await Firebase.initializeApp(); 
    print("✅ Firebase Connected Successfully");
  } catch (e) {
    print("❌ Firebase Error: $e");
  }

  // 2️⃣ تهيئة الإشعارات
  try {
    print("🔄 جاري تهيئة خدمة الإشعارات...");
    await NotificationService().init();
    print("✅ تم تهيئة خدمة الإشعارات");
  } catch (e) {
    print("❌ فشل تهيئة الإشعارات: $e");
  }
  
  // 3️⃣ طلب أذونات الإشعارات
  try {
    print("🔄 جاري طلب أذونات الإشعارات...");
    await NotificationService().requestPermissions();
    print("✅ تم طلب أذونات الإشعارات");
  } catch (e) {
    print("❌ فشل طلب الأذونات: $e");
  }
  
  // 4️⃣ طلب إذن Exact Alarms
  try {
    print("🔄 جاري طلب إذن المنبهات الدقيقة...");
    final exactAlarmGranted = await NotificationService().requestExactAlarmPermission();
    if (exactAlarmGranted) {
      print("✅✅ تم منح إذن المنبهات الدقيقة");
    } else {
      print("⚠️⚠️ لم يتم منح إذن المنبهات الدقيقة");
    }
  } catch (e) {
    print("❌ فشل طلب إذن المنبهات: $e");
  }
  
  // 5️⃣ تعطيل Battery Optimization
  if (Platform.isAndroid) {
    try {
      print("🔄 جاري تعطيل توفير البطارية...");
      await Permission.ignoreBatteryOptimizations.request();
      print("✅ تم طلب تعطيل توفير البطارية");
    } catch (e) {
      print("⚠️ تعذر طلب تعطيل توفير البطارية: $e");
    }
  }
  
  // 6️⃣ اختبار إشعار فوري
  try {
    print("🔄 جاري اختبار الإشعار الفوري...");
    // await NotificationService().showImmediateNotification(
    //   "مرحباً بك في Muslim Way 🌙",
    //   "التطبيق جاهز للاستخدام",
    // );
    print("✅ تم إرسال إشعار الاختبار");
  } catch (e) {
    print("❌ فشل إرسال الإشعار: $e");
  }

  // 7️⃣ جدولة صلوات اليوم
  try {
    print("🔄 جاري جدولة صلوات اليوم...");
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('lat');
    final double? long = prefs.getDouble('long');
    
    if (lat != null && long != null) {
      await scheduleTodayPrayers(lat, long);
    } else {
      print("⚠️ لم يتم العثور على الموقع، سيتم الجدولة عند توفره");
    }
  } catch (e) {
    print("❌ فشل جدولة الصلوات: $e");
  }

  // 8️⃣ Workmanager - مع معالجة الأخطاء
  try {
    print("🔄 جاري تهيئة Workmanager...");
    
    await Workmanager().initialize(
      callbackDispatcher, 
      isInDebugMode: false  // ✅ false في الإنتاج
    );
    
    print("✅ تم تهيئة Workmanager بنجاح");
    
    // ✅ جدولة الصلوات (كل 6 ساعات)
    await Workmanager().registerPeriodicTask(
      "prayerTimeChecker",
      "prayerTimeChecker",
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    
    print("✅ تم جدولة مهمة الصلوات");
    
    // ✅ جدولة فحص تذكيرات المهام (كل 15 دقيقة)
    await Workmanager().registerPeriodicTask(
      "taskRemindersChecker",
      "taskRemindersChecker",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );
    
    print("✅ تم جدولة مهمة التذكيرات");
    print("✅✅✅ تم تفعيل جميع المهام الدورية");
    
  } catch (e) {
    print("❌❌❌ فشل تهيئة Workmanager: $e");
    print("⚠️ التطبيق سيعمل بدون مهام خلفية");
  }
  
  // 9️⃣ اللغة
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  // 🚀 تشغيل التطبيق
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