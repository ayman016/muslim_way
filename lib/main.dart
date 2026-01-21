import 'package:flutter/material.dart';
import 'package:muslim_way/root.dart';
import 'package:workmanager/workmanager.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('lat');
    final double? long = prefs.getDouble('long');

    if (lat != null && long != null) {
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      // الحصول على الصلاة القادمة
      final nextPrayer = prayerTimes.nextPrayer();
      if (nextPrayer != Prayer.none) {
        final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer)!;
        final differenceInMinutes = nextPrayerTime.difference(DateTime.now()).inMinutes;

        final notifService = NotificationService();
        await notifService.init();

        String prayerName = _getPrayerNameArabic(nextPrayer);

        // 💡 الحالة 1: تنبيه قبل بـ 20 دقيقة
        // (كنستعملو مجال مابين 19 و 21 دقيقة حيت العمل كيتنفذ كل 15 دقيقة)
        if (differenceInMinutes <= 20 && differenceInMinutes > 15) {
          await notifService.showImmediateNotification(
            "تذكير بالصلاة 🕌",
            "بقيت 20 دقيقة على صلاة $prayerName. توضأ واستعد!",
          );
        }

        // 💡 الحالة 2: تنبيه قبل بـ 5 دقائق
        if (differenceInMinutes <= 5 && differenceInMinutes > 0) {
          await notifService.showImmediateNotification(
            "اقتربت الصلاة ✨",
            "5 دقائق فقط على صلاة $prayerName. حي على الصلاة.",
          );
        }
        
        // 💡 الحالة 3: وقت الصلاة (الآذان)
        if (differenceInMinutes == 0) {
           await notifService.showImmediateNotification(
            "حان الآن موعد صلاة $prayerName",
            "الله أكبر، الله أكبر...",
          );
        }
      }
    }
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
    default: return "الصلاة";
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Root())); // استبدل MyApp بكلاس تطبيقك
}