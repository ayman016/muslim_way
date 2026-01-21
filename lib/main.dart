import 'package:flutter/material.dart';
import 'package:muslim_way/root.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'notification_service.dart';

@pragma('vm:entry-point') // 👈 ضرورية جداً
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('lat');
    final double? long = prefs.getDouble('long');

    if (lat != null && long != null) {
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      final currentPrayer = prayerTimes.currentPrayer();
      if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
        final notifService = NotificationService();
        await notifService.init();
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
  await NotificationService().init();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Root()))); 
}