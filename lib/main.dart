import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ زدنا هادي ضروري
import 'package:muslim_way/auth_wrapper.dart'; 
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/language_provider.dart'; 

// ✅ 1. دالة العمل في الخلفية (عمرناها بالكود الجديد)
@pragma('vm:entry-point') 
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // جلب الإحداثيات المحفوظة
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('lat');
    final double? long = prefs.getDouble('long');

    // إلا لقينا الموقع مسجل، نحسبو الصلاة
    if (lat != null && long != null) {
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      final currentPrayer = prayerTimes.currentPrayer();
      
      // إلا كان وقت صلاة دابا (من غير الشروق)
      if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
        final notifService = NotificationService();
        await notifService.init(); // نهيئو الإشعارات فالخلفية
        
        // نصيفطو الإشعار
        await notifService.showImmediateNotification(
          "حان موعد الصلاة 🕌",
          "الله أكبر، الله أكبر.. حي على الصلاة",
        );
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1️⃣ تهيئة Firebase
  try {
    await Firebase.initializeApp(); 
    print("✅ Firebase Connected Successfully");
  } catch (e) {
    print("❌ Firebase Error: $e");
  }

  // 2️⃣ تهيئة الخدمات
  await NotificationService().init();
  await NotificationService().requestPermissions(); 

  // تهيئة Workmanager مع الدالة الجديدة
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  // 3️⃣ تهيئة اللغة
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