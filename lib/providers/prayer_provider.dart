import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';

class PrayerProvider with ChangeNotifier {
  // المتغيرات (خاصة بالصلاة والموقع فقط)
  String _nextPrayerName = "--";
  String _nextPrayerTime = "--";
  PrayerTimes? _todayPrayerTimes;
  bool _isLoading = false;

  // Getters
  String get nextPrayerName => _nextPrayerName;
  String get nextPrayerTime => _nextPrayerTime;
  PrayerTimes? get todayPrayerTimes => _todayPrayerTimes;
  bool get isLoading => _isLoading;

  // دالة جلب بيانات الصلاة
  Future<void> fetchPrayerData() async {
    _isLoading = true;
    notifyListeners(); // نعلمو الواجهة بلي التحميل بدا

    await _calculatePrayersAndLocation();

    _isLoading = false;
    notifyListeners(); // نعلمو الواجهة بلي سالينا
  }

  Future<void> _calculatePrayersAndLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('lat');
    double? long = prefs.getDouble('long');

    // 1. إلا ماكانش الموقع مسجل، نجيبوه من GPS
    if (lat == null || long == null) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        lat = position.latitude;
        long = position.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('long', long);
      } catch (e) { 
        print("❌ Error getting location: $e");
        return; 
      }
    }

    // 2. حساب أوقات الصلاة
    if (lat != null && long != null) {
      // تسجيل العمل فالخلفية (باش يخدم الأذان)
      await Workmanager().registerPeriodicTask(
        "prayer_check_task",
        "checkPrayerTime",
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
      
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi; // أو hanafi حسب الرغبة
      final prayerTimes = PrayerTimes.today(myCoordinates, params);

      _todayPrayerTimes = prayerTimes;
      final next = prayerTimes.nextPrayer();
      
      if (next != Prayer.none) {
        _nextPrayerTime = DateFormat.jm().format(prayerTimes.timeForPrayer(next)!);
        _nextPrayerName = _getPrayerArabicName(next);
      } else {
        // إلا سالاو صلوات اليوم، الجاي هو الفجر ديال غدا
        _nextPrayerName = "الفجر";
        _nextPrayerTime = DateFormat.jm().format(prayerTimes.fajr);
      }
    }
  }

  // تحديث الموقع يدوياً
  Future<void> forceUpdateLocation() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('lat'); 
     await prefs.remove('long');
     await fetchPrayerData();
  }

  String _getPrayerArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return "الفجر";
      case Prayer.dhuhr: return "الظهر";
      case Prayer.asr: return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha: return "العشاء";
      case Prayer.sunrise: return "الشروق";
      default: return "--";
    }
  }
}