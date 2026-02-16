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
import 'package:muslim_way/theme/app_theme.dart'; // ✅ استدعاء ملف الثيم الجديد

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

Future<void> _scheduleTodayPrayers(double lat, double long) async {
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

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);

      if (prayerTime != null && prayerTime.isAfter(now)) {
        await notifService.scheduleNotification(
          id: prayer.index + 1000,
          title: "حان موعد الصلاة 🕌",
          body: _getPrayerName(prayer),
          scheduledTime: prayerTime,
        );
      }
    }
  } catch (e) {
    debugPrint("❌ Prayer scheduling error: $e");
  }
}

String _getPrayerName(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr:
      return "صلاة الفجر - الله أكبر";
    case Prayer.dhuhr:
      return "صلاة الظهر - حي على الصلاة";
    case Prayer.asr:
      return "صلاة العصر - حي على الفلاح";
    case Prayer.maghrib:
      return "صلاة المغرب - الصلاة خير من النوم";
    case Prayer.isha:
      return "صلاة العشاء - الله أكبر";
    default:
      return "حان موعد الصلاة";
  }
}

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

  // 4️⃣ Prayer scheduling
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
    // ✅ الاستماع لتغيير اللغة لتحديث الثيم والاتجاه
    final langCode = context.select<LanguageProvider, String>((p) => p.currentLang);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muslim Way',
      
      // ✅ تطبيق الثيم الجديد (الألوان الثلاثة)
      theme: AppTheme.getTheme(langCode),

      // ✅ إعدادات اللغات (مهم جداً للاتجاه RTL/LTR)
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
      
      // ✅ دالة ذكية: إذا كانت اللغة "الدارجة"، تعامل معها كـ "عربية" في النظام
      // هذا يحل مشاكل اتجاه النص (RTL) وتنسيق التواريخ
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