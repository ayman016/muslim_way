import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:muslim_way/firebase_options.dart'; 
import 'package:muslim_way/auth_wrapper.dart';
import 'package:muslim_way/introduction_screen.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_theme.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("🔔 Workmanager task: $task");
      final prefs = await SharedPreferences.getInstance();

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
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString('app_lang') ?? 'ar';
    final myCoordinates = Coordinates(lat, long);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.fajrAngle = 19.0;
    params.ishaAngle = 17.0;
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    final notifService = NotificationService();
    await notifService.init();
    final now = DateTime.now();
    final prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      if (prayerTime == null) continue;
      final String prayerName = _getTranslatedPrayerName(prayer, lang);
      final reminderTime = prayerTime.subtract(const Duration(minutes: 20));
      if (reminderTime.isAfter(now)) {
        await notifService.scheduleNotification(
          id: prayer.index + 1000,
          title: _getNotifTitle(lang),
          body: _getNotifBody(lang, prayerName),
          scheduledTime: reminderTime,
        );
      }
      if (prayerTime.isAfter(now)) {
        await notifService.scheduleNotification(
          id: prayer.index + 2000,
          title: _getAdhanTitle(lang, prayerName),
          body: _getAdhanBody(lang, prayerName),
          scheduledTime: prayerTime,
        );
      }
    }
  } catch (e) {
    debugPrint("❌ Prayer scheduling error: $e");
  }
}

String _getAdhanTitle(String lang, String prayerName) {
  switch (lang) {
    case 'ar': return "حان وقت صلاة $prayerName 🕌";
    case 'da': return "جاء وقت صلاة $prayerName 🕌";
    case 'fr': return "L'heure de $prayerName est arrivée 🕌";
    default:   return "Time for $prayerName Prayer 🕌";
  }
}

String _getAdhanBody(String lang, String prayerName) {
  switch (lang) {
    case 'ar': return "الله أكبر — حان موعد صلاة $prayerName";
    case 'da': return "الله أكبر — وقت صلاة $prayerName دبا";
    case 'fr': return "Allahu Akbar — C'est l'heure de $prayerName";
    default:   return "Allahu Akbar — $prayerName prayer time has begun";
  }
}

String _getTranslatedPrayerName(Prayer prayer, String lang) {
  if (lang == 'ar' || lang == 'da') {
    switch (prayer) {
      case Prayer.fajr:    return "الفجر";
      case Prayer.dhuhr:   return "الظهر";
      case Prayer.asr:     return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha:    return "العشاء";
      default:             return "";
    }
  }
  switch (prayer) {
    case Prayer.fajr:    return "Fajr";
    case Prayer.dhuhr:   return "Dhuhr";
    case Prayer.asr:     return "Asr";
    case Prayer.maghrib: return "Maghrib";
    case Prayer.isha:    return "Isha";
    default:             return "";
  }
}

String _getNotifTitle(String lang) {
  switch (lang) {
    case 'ar': return "اقترب موعد الصلاة ⏳";
    case 'da': return "قربات الصلاة ⏳";
    case 'fr': return "La prière approche ⏳";
    default:   return "Prayer Approaching ⏳";
  }
}

String _getNotifBody(String lang, String prayerName) {
  switch (lang) {
    case 'ar': return "بقي 20 دقيقة على صلاة $prayerName";
    case 'da': return "بقات 20 دقيقة ل $prayerName";
    case 'fr': return "20 minutes restantes pour $prayerName";
    default:   return "20 minutes remaining for $prayerName";
  }
}

void _handleNotificationClick(RemoteMessage message) async {
  if (message.data.containsKey('link')) {
    final String urlStr = message.data['link'];
    final Uri url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ Could not launch $urlStr");
    }
  }
}

void _initFirebaseMessagingInBackground() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('all_users');

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.infoReverse,
            animType: AnimType.bottomSlide,
            dialogBackgroundColor: AppColors.surface,
            title: message.notification!.title ?? "رسالة جديدة",
            desc: message.notification!.body ?? "",
            // ✅ استخدام AppFonts.mainStyle لتجنب الـ Crash وضمان العمل Offline
            titleTextStyle: AppFonts.mainStyle(
              context: context,
              listen: false,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            descTextStyle: AppFonts.mainStyle(
              context: context,
              listen: false,
              color: Colors.white70,
              fontSize: 15,
            ),
            btnOkText: 'حسناً',
            btnOkColor: AppColors.accent,
            btnOkOnPress: () {
              _handleNotificationClick(message);
            },
          ).show();
        }
      }
    });
  } catch (e) {
    debugPrint("⚠️ FCM Init Warning (Likely Offline): $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    debugPrint("✅ Firebase initialized with offline persistence");

    _initFirebaseMessagingInBackground();

  } catch (e) {
    debugPrint("❌ Firebase error: $e");
  }

  try {
    await NotificationService().init();
    await NotificationService().requestPermissions();
    await NotificationService().requestExactAlarmPermission();
    debugPrint("✅ Notifications initialized");
  } catch (e) {
    debugPrint("❌ Notification error: $e");
  }

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

  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Zimam',
      theme: AppTheme.getTheme(langCode),
      locale: Locale(langCode == 'da' ? 'ar' : langCode),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _HomeRouter(),
    );
  }
}

class _HomeRouter extends StatefulWidget {
  const _HomeRouter();

  @override
  State<_HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<_HomeRouter> {
  bool? _introDone;

  @override
  void initState() {
    super.initState();
    _checkIntro();
  }

  Future<void> _checkIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('intro_done') ?? false;
    if (mounted) setState(() => _introDone = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_introDone == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return _introDone! ? const AuthWrapper() : const IntroductionScreen();
  }
}