import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_theme.dart';

// ✅ Background dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("🔔 Workmanager task: $task");

      final prefs = await SharedPreferences.getInstance();

      // Task reminders check
      if (task == "taskRemindersChecker") {
        final savedTasks = prefs.getStringList('cached_tasks');

        if (savedTasks != null && savedTasks.isNotEmpty) {
          final now = DateTime.now();

          for (var taskData in savedTasks) {
            final parts = taskData.split('|');

            if (parts.length >= 5 && parts[4] != "null") {
              try {
                final reminderTime = DateTime.parse(parts[4]);
                final difference = now.difference(reminderTime).abs();

                if (difference.inMinutes <= 5 &&
                    reminderTime.isBefore(now.add(const Duration(minutes: 1)))) {
                  final notif = NotificationService();
                  await notif.init();
                  await notif.showImmediateNotification(
                    "تذكير: ${parts[0]}",
                    "حان موعد القيام بمهمتك! 📝",
                  );
                }
              } catch (e) {
                debugPrint("❌ Reminder error: $e");
              }
            }
          }
        }
      }

      // Prayer time check
      if (task == "prayerTimeChecker") {
        final double? lat = prefs.getDouble('lat');
        final double? long = prefs.getDouble('long');

        if (lat != null && long != null) {
          await _scheduleTodayPrayers(lat, long);
        }
      }

      return Future.value(true);
    } catch (e) {
      debugPrint("❌ Workmanager error: $e");
      return Future.value(false);
    }
  });
}

// 🔻🔻 دالة جدولة الإشعارات (المعدلة) 🔻🔻
Future<void> _scheduleTodayPrayers(double lat, double long) async {
  try {
    // 1. جلب اللغة المحفوظة
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString('app_lang') ?? 'ar';

    // 2. إعداد حسابات الصلاة (تعديل يدوي للمغرب)
    final myCoordinates = Coordinates(lat, long);
    
    // ضبط الحساب على توقيت وزارة الأوقاف المغربية
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.fajrAngle = 19.0; 
    params.ishaAngle = 17.0; 
    params.madhab = Madhab.shafi; 
    
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

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);

      if (prayerTime != null) {
        // 🔥 إنقاص 20 دقيقة من وقت الصلاة
        final reminderTime = prayerTime.subtract(const Duration(minutes: 20));

        // التحقق أن وقت التذكير لم يمر بعد
        if (reminderTime.isAfter(now)) {
          // ✅ جلب النصوص حسب اللغة المختارة
          String prayerName = _getTranslatedPrayerName(prayer, lang);
          String title = _getNotifTitle(lang);
          String body = _getNotifBody(lang, prayerName);

          await notifService.scheduleNotification(
            id: prayer.index + 1000,
            title: title, 
            body: body, 
            scheduledTime: reminderTime, 
          );
        }
      }
    }
  } catch (e) {
    debugPrint("❌ Prayer scheduling error: $e");
  }
}

// ==========================================
// 🌍 Helper Functions (هادو اللي كانوا ناقصينك)
// ==========================================

// 1. ترجمة اسم الصلاة
String _getTranslatedPrayerName(Prayer prayer, String lang) {
  if (lang == 'ar' || lang == 'da') {
    switch (prayer) {
      case Prayer.fajr: return "الفجر";
      case Prayer.dhuhr: return "الظهر";
      case Prayer.asr: return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha: return "العشاء";
      default: return "";
    }
  } else if (lang == 'fr') {
    switch (prayer) {
      case Prayer.fajr: return "Fajr";
      case Prayer.dhuhr: return "Dhuhr";
      case Prayer.asr: return "Asr";
      case Prayer.maghrib: return "Maghrib";
      case Prayer.isha: return "Isha";
      default: return "";
    }
  } else { // English
    switch (prayer) {
      case Prayer.fajr: return "Fajr";
      case Prayer.dhuhr: return "Dhuhr";
      case Prayer.asr: return "Asr";
      case Prayer.maghrib: return "Maghrib";
      case Prayer.isha: return "Isha";
      default: return "";
    }
  }
}

// 2. عنوان الإشعار حسب اللغة
String _getNotifTitle(String lang) {
  switch (lang) {
    case 'ar': return "اقترب موعد الصلاة ⏳";
    case 'da': return "قربات الصلاة ⏳"; 
    case 'fr': return "La prière approche ⏳";
    case 'en': return "Prayer Approaching ⏳";
    default: return "Prayer Approaching ⏳";
  }
}

// 3. نص الإشعار حسب اللغة
String _getNotifBody(String lang, String prayerName) {
  switch (lang) {
    case 'ar': return "بقي 20 دقيقة على صلاة $prayerName";
    case 'da': return "بقات 20 دقيقة ل $prayerName";
    case 'fr': return "20 minutes restantes pour $prayerName";
    case 'en': return "20 minutes remaining for $prayerName";
    default: return "20 minutes remaining for $prayerName";
  }
}

// ==========================================
// 🚀 Main Function
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  // 1️⃣ Firebase
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint("✅ Firebase initialized");
  } catch (e) {
    debugPrint("❌ Firebase error: $e");
  }

  // 2️⃣ Notifications
  try {
    await NotificationService().init();
    await NotificationService().requestPermissions();
    await NotificationService().requestExactAlarmPermission();
    debugPrint("✅ Notifications initialized");
  } catch (e) {
    debugPrint("❌ Notification error: $e");
  }

  // 3️⃣ Battery optimization
  if (Platform.isAndroid) {
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      debugPrint("⚠️ Battery optimization: $e");
    }
  }

  // 4️⃣ Prayer scheduling (Initial run)
  try {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('lat');
    final double? long = prefs.getDouble('long');

    if (lat != null && long != null) {
      await _scheduleTodayPrayers(lat, long);
    }
  } catch (e) {
    debugPrint("❌ Prayer init error: $e");
  }

  // 5️⃣ Workmanager
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
      "prayerTimeChecker",
      "prayerTimeChecker",
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );

    await Workmanager().registerPeriodicTask(
      "taskRemindersChecker",
      "taskRemindersChecker",
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
    );

    debugPrint("✅ Workmanager initialized");
  } catch (e) {
    debugPrint("❌ Workmanager error: $e");
  }

  // 6️⃣ Language Setup
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  // 🚀 Run app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    final langCode = context.select<LanguageProvider, String>((p) => p.currentLang);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muslim Way',
      
      // ✅ تطبيق الثيم الجديد (الألوان الثلاثة)
      theme: AppTheme.getTheme(langCode),

      // ✅ إعدادات اللغات
      locale: Locale(langCode),
      supportedLocales: const [
        Locale('ar'), 
        Locale('en'),
        Locale('fr'),
        Locale('da'), // الدارجة
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale?.languageCode == 'da') {
          return const Locale('ar'); 
        }
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      home: const AuthWrapper(),
    );
  }
}