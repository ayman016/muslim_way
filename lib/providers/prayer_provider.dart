import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/services/firestore_service.dart'; // ✅ Import ضروري

class PrayerProvider with ChangeNotifier {
  // المتغيرات (State)
  String _nextPrayerName = "--";
  String _nextPrayerTime = "--";
  String _remainingBudget = "0.00";
  PrayerTimes? _todayPrayerTimes;
  bool _isLoading = false;

  // Getters
  String get nextPrayerName => _nextPrayerName;
  String get nextPrayerTime => _nextPrayerTime;
  String get remainingBudget => _remainingBudget;
  PrayerTimes? get todayPrayerTimes => _todayPrayerTimes;
  bool get isLoading => _isLoading;

  // دالة واحدة كتجمع كلشي
  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    await _loadBudget(); // ✅ تبدلات باش تقرا من السحاب
    await _calculatePrayersAndLocation();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshBudgetOnly() async {
    await _loadBudget();
    notifyListeners();
  }

  // ✅ دالة التحميل المعدلة (Firebase First)
  Future<void> _loadBudget() async {
    try {
      final data = await FirestoreService().getUserData();
      if (data != null && data.containsKey('wallet_balance')) {
        // تحويل الرقم لـ Double
        double bal = (data['wallet_balance'] as num).toDouble();
        _remainingBudget = bal.toStringAsFixed(2);
      } else {
        _remainingBudget = "0.00";
      }
    } catch (e) {
      // في حالة ماكاينش انترنت، ممكن تخليها 0.00 أو دير كاش
      print("Error loading budget: $e");
    }
  }

  Future<void> _calculatePrayersAndLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('lat');
    double? long = prefs.getDouble('long');

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
      } catch (e) { return; }
    }

    if (lat != null && long != null) {
      await Workmanager().registerPeriodicTask(
        "prayer_check_task",
        "checkPrayerTime",
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
      
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);

      _todayPrayerTimes = prayerTimes;
      final next = prayerTimes.nextPrayer();
      
      if (next != Prayer.none) {
        _nextPrayerTime = DateFormat.jm().format(prayerTimes.timeForPrayer(next)!);
        _nextPrayerName = _getPrayerArabicName(next);
      } else {
        _nextPrayerName = "الفجر";
        _nextPrayerTime = DateFormat.jm().format(prayerTimes.fajr);
      }
    }
  }

  Future<void> forceUpdateLocation() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('lat'); 
     await prefs.remove('long');
     await fetchAllData();
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