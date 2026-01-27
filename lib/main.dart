import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:adhan/adhan.dart';
import 'package:muslim_way/auth_wrapper.dart'; // ✅ البداية من هنا
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/language_provider.dart'; // ✅ ضروري

// --- (دوال Workmanager القديمة ديالك خليناها كيف ما هي) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // ... (الكود القديم ديالك هنا ديال التنبيهات) ...
    return Future.value(true);
  });
}

String _getPrayerNameArabic(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr: return "الفجر";
    case Prayer.dhuhr: return "الظهر";
    case Prayer.asr: return "العصر";
    case Prayer.maghrib: return "المغرب";
    case Prayer.isha: return "العشاء";
    case Prayer.sunrise: return "الشروق";
    default: return "الصلاة";
  }
}
// -----------------------------------------------------------

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
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  // 3️⃣ تهيئة اللغة (ضروري قبل runApp)
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage(); // 📥 كنشارجيو اللغة المحفوظة

  runApp(
    MultiProvider(
      providers: [
        // بروفايدر الصلاة
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        
        // ✅ بروفايدر اللغة (هذا هو لي كان ناقصك)
        ChangeNotifierProvider(create: (_) => languageProvider), 
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        // البداية ديما من AuthWrapper باش يشوف واش كاين Login
        home: AuthWrapper(), 
      ),
    ),
  );
}