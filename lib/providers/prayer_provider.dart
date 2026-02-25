import 'dart:convert';
import 'package:adhan/adhan.dart' show CalculationMethod, CalculationMethodExtensions, Coordinates, Madhab, PrayerTimes;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/notification_service.dart';

// ============================================================
// Model
// ============================================================
class ApiPrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const ApiPrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

// ============================================================
// Provider
// ============================================================
class PrayerProvider with ChangeNotifier {
  // ── State ─────────────────────────────────────────
  String _nextPrayerName = "--";
  String _nextPrayerTime = "--";
  ApiPrayerTimes? _todayPrayerTimes;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────
  String get nextPrayerName => _nextPrayerName;
  String get nextPrayerTime => _nextPrayerTime;
  ApiPrayerTimes? get todayPrayerTimes => _todayPrayerTimes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Fetch ─────────────────────────────────────────
  Future<void> fetchPrayerData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null; // تصفير الخطأ في كل محاولة
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      double? lat;
      double? long;

      try {
        // 1️⃣ محاولة جلب الموقع الحالي
        final position = await _getLocation();
        lat = position.latitude;
        long = position.longitude;

        // حفظ الإحداثيات للاستخدام المستقبلي (Fallback)
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('long', long);
      } catch (e) {
        // 2️⃣ في حالة فشل الـ GPS، نحاول جلب آخر موقع مسجل
        debugPrint("⚠️ فشل جلب الموقع الحالي، جاري محاولة استخدام آخر موقع محفوظ. السبب: $e");
        lat = prefs.getDouble('lat');
        long = prefs.getDouble('long');

        if (lat == null || long == null) {
          // 3️⃣ إذا لم نجد أي موقع
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // 4️⃣ جيب الأوقات من aladhan API
      final times = await _fetchFromApi(
        lat: lat,
        long: long,
      );

      if (times != null) {
        _todayPrayerTimes = times;
        _calculateNextPrayer(times);

        // جدول الإشعارات
        await _schedulePrayerNotifications(
          times,
          prefs.getString('app_lang') ?? 'ar',
        );
      } else {
        // Fallback لـ adhan package إذا فشل الـ API
        debugPrint("⚠️ API failed — using adhan fallback");
        _fallbackToAdhan(lat, long);
      }

    } catch (e) {
      debugPrint("❌ PrayerProvider error: $e");
      _errorMessage = "حدث خطأ غير متوقع";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── aladhan API Request ───────────────────────────
  Future<ApiPrayerTimes?> _fetchFromApi({
    required double lat,
    required double long,
  }) async {
    try {
      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

      // ✅ تم التعديل هنا:
      // method=20  → وزارة الأوقاف والشؤون الإسلامية (المغرب)
      // school=0   → المذهب المالكي (لصلاة العصر)
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr'
        '?latitude=$lat&longitude=$long&method=20&school=0',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'] as Map<String, dynamic>;
        final now = DateTime.now();

        // API يرجع "05:30" أو "05:30 (WEST)" — نأخذ فقط HH:mm
        DateTime parseTime(String timeStr) {
          final clean = timeStr.split(' ')[0];
          final parts = clean.split(':');
          return DateTime(
            now.year, now.month, now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        debugPrint("✅ aladhan API success");
        return ApiPrayerTimes(
          fajr:    parseTime(timings['Fajr']),
          sunrise: parseTime(timings['Sunrise']),
          dhuhr:   parseTime(timings['Dhuhr']),
          asr:     parseTime(timings['Asr']),
          maghrib: parseTime(timings['Maghrib']),
          isha:    parseTime(timings['Isha']),
        );
      } else {
        debugPrint("❌ API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ API fetch error: $e");
      return null;
    }
  }

  // ── Fallback: adhan package (offline) ─────────────
  void _fallbackToAdhan(double lat, double long) {
    try {
      final coordinates = Coordinates(lat, long);
      // استخدمنا رابطة العالم الإسلامي كبديل أوفلاين مؤقت (مع ضبط الزوايا)
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.fajrAngle = 19.0;
      params.ishaAngle = 17.0;
      params.madhab = Madhab.shafi; // شافعي/مالكي

      final pt = PrayerTimes.today(coordinates, params);

      _todayPrayerTimes = ApiPrayerTimes(
        fajr:    pt.fajr,
        sunrise: pt.sunrise,
        dhuhr:   pt.dhuhr,
        asr:     pt.asr,
        maghrib: pt.maghrib,
        isha:    pt.isha,
      );

      _calculateNextPrayer(_todayPrayerTimes!);
    } catch (e) {
      debugPrint("❌ Fallback adhan error: $e");
    }
  }

  // ── تحديث الموقع يدوياً ───────────────────────────
  Future<void> forceUpdateLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lat');
    await prefs.remove('long');
    await fetchPrayerData();
  }

  // ── الصلاة القادمة ────────────────────────────────
  void _calculateNextPrayer(ApiPrayerTimes times) {
    final now = DateTime.now();

    final prayersList = [
      {'name': 'الفجر',   'time': times.fajr},
      {'name': 'الشروق',  'time': times.sunrise},
      {'name': 'الظهر',   'time': times.dhuhr},
      {'name': 'العصر',   'time': times.asr},
      {'name': 'المغرب',  'time': times.maghrib},
      {'name': 'العشاء',  'time': times.isha},
    ];

    bool foundNext = false;
    for (var prayer in prayersList) {
      final pTime = prayer['time'] as DateTime;
      if (pTime.isAfter(now)) {
        _nextPrayerName = prayer['name'] as String;
        _nextPrayerTime = DateFormat.jm().format(pTime);
        foundNext = true;
        break;
      }
    }

    if (!foundNext) {
      _nextPrayerName = "الفجر";
      _nextPrayerTime = DateFormat.jm().format(times.fajr);
    }
  }

  // ── جلب الموقع ───────────────────────────────────
  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('الرجاء تشغيل الـ GPS (الموقع) للحصول على أوقات الصلاة الدقيقة');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الوصول للموقع');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض إذن الوصول للموقع نهائياً، يرجى تفعيله من الإعدادات');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  // ── جدولة الإشعارات ──────────────────────────────
  Future<void> _schedulePrayerNotifications(
    ApiPrayerTimes times,
    String lang,
  ) async {
    try {
      final notifService = NotificationService();
      await notifService.init();
      final now = DateTime.now();

      final prayers = [
        {'key': 'fajr',    'time': times.fajr,    'id': 0},
        {'key': 'dhuhr',   'time': times.dhuhr,   'id': 1},
        {'key': 'asr',     'time': times.asr,     'id': 2},
        {'key': 'maghrib', 'time': times.maghrib, 'id': 3},
        {'key': 'isha',    'time': times.isha,    'id': 4},
      ];

      for (var prayer in prayers) {
        final prayerTime = prayer['time'] as DateTime;
        final id         = prayer['id'] as int;
        final name       = _getPrayerName(prayer['key'] as String, lang);

        final reminderTime = prayerTime.subtract(const Duration(minutes: 20));
        if (reminderTime.isAfter(now)) {
          await notifService.scheduleNotification(
            id: id + 1000,
            title: _getNotifTitle(lang),
            body: _getNotifBody(lang, name),
            scheduledTime: reminderTime,
          );
        }

        if (prayerTime.isAfter(now)) {
          await notifService.scheduleNotification(
            id: id + 2000,
            title: _getAdhanTitle(lang, name),
            body: _getAdhanBody(lang, name),
            scheduledTime: prayerTime,
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Notification scheduling error: $e");
    }
  }

  // ── أسماء الصلوات ────────────────────────────────
  String _getPrayerName(String key, String lang) {
    if (lang == 'ar' || lang == 'da') {
      switch (key) {
        case 'fajr':    return "الفجر";
        case 'dhuhr':   return "الظهر";
        case 'asr':     return "العصر";
        case 'maghrib': return "المغرب";
        case 'isha':    return "العشاء";
        default:        return "";
      }
    } else {
      switch (key) {
        case 'fajr':    return "Fajr";
        case 'dhuhr':   return "Dhuhr";
        case 'asr':     return "Asr";
        case 'maghrib': return "Maghrib";
        case 'isha':    return "Isha";
        default:        return "";
      }
    }
  }

  // ── نصوص الإشعارات ───────────────────────────────
  String _getNotifTitle(String lang) {
    switch (lang) {
      case 'ar': return "اقترب موعد الصلاة ⏳";
      case 'da': return "قربات الصلاة ⏳";
      case 'fr': return "La prière approche ⏳";
      default:   return "Prayer Approaching ⏳";
    }
  }

  String _getNotifBody(String lang, String name) {
    switch (lang) {
      case 'ar': return "بقي 20 دقيقة على صلاة $name";
      case 'da': return "بقات 20 دقيقة لـ $name";
      case 'fr': return "20 minutes restantes pour $name";
      default:   return "20 minutes remaining for $name";
    }
  }

  String _getAdhanTitle(String lang, String name) {
    switch (lang) {
      case 'ar': return "حان وقت صلاة $name 🕌";
      case 'da': return "جاء وقت صلاة $name 🕌";
      case 'fr': return "L'heure de $name est arrivée 🕌";
      default:   return "Time for $name Prayer 🕌";
    }
  }

  String _getAdhanBody(String lang, String name) {
    switch (lang) {
      case 'ar': return "الله أكبر — حان موعد صلاة $name";
      case 'da': return "الله أكبر — وقت صلاة $name دبا";
      case 'fr': return "Allahu Akbar — C'est l'heure de $name";
      default:   return "Allahu Akbar — $name prayer time has begun";
    }
  }
}