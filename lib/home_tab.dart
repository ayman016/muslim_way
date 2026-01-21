import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/morningazkar.dart'; // تأكد من المسار
import 'package:muslim_way/eveningazkar.dart'; // تأكد من المسار

class HomeTab extends StatefulWidget {
  final Function onLocationRefresh;
  const HomeTab({super.key, required this.onLocationRefresh});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String nextPrayerName = "--";
  String nextPrayerTime = "--";
  String remainingBudget = "0.00";
  PrayerTimes? _todayPrayerTimes;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    await loadBudgetSummary();
    await _checkPermissionAndCalculate();
  }

  Future<void> loadBudgetSummary() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      double bal = prefs.getDouble('wallet_balance') ?? 0.0;
      remainingBudget = bal.toStringAsFixed(2);
    });
  }

  Future<void> _checkPermissionAndCalculate() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    calculatePrayers();
  }

  Future<void> calculatePrayers() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('lat');
    double? long = prefs.getDouble('long');

    if (lat == null || long == null) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        long = position.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('long', long);
      } catch (e) { return; }
    }

    if (lat != null && long != null) {
      // 🚀 تفعيل خدمة الخلفية (Workmanager)
      await Workmanager().registerPeriodicTask(
        "prayer_check_task",
        "checkPrayerTime",
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(myCoordinates, params);

      setState(() {
        _todayPrayerTimes = prayerTimes;
        final next = prayerTimes.nextPrayer();
        if (next != Prayer.none) {
          nextPrayerTime = DateFormat.jm().format(prayerTimes.timeForPrayer(next)!);
          nextPrayerName = _getPrayerArabicName(next);
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // 1. Header & Budget
            _buildHeader(),
            const SizedBox(height: 20),
            // 2. Next Prayer Card
            _buildNextPrayerCard(),
            const SizedBox(height: 20),
            // 3. Prayer Times List (Scrollable)
            if (_todayPrayerTimes != null) _buildPrayerList(),
            const SizedBox(height: 25),
            // 4. Azkar Section (إرجاع أذكار الصباح والمساء)
            _buildAzkarSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.amber,
  onPressed: () async {
    // 1. إظهار رسالة بسيطة للمستخدم باش يعرف أن الاختبار بدأ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("سيرسل الإشعار بعد 10 ثوانٍ..."), duration: Duration(seconds: 2)),
    );

    // 2. الانتظار لمدة 10 ثوانٍ
    await Future.delayed(const Duration(seconds: 10));

    // 3. إطلاق الإشعار الفوري
    final notifService = NotificationService();
    await notifService.init(); // التأكد من التهيئة
    await notifService.showImmediateNotification(
      "اختبار الإشعار المجدول 🔔",
      "لقد مرت 10 ثوانٍ بنجاح، خدمة الإشعارات تعمل!",
    );
  },
  child: const Icon(Icons.notifications_active, color: Colors.black),
),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("الميزانية المتبقية", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
              Text("$remainingBudget DH", style: GoogleFonts.cairo(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(onPressed: calculatePrayers, icon: const Icon(Icons.refresh, color: Colors.amber)),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.black]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text("الصلاة القادمة", style: GoogleFonts.cairo(color: Colors.white60)),
              Text(nextPrayerName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text(nextPrayerTime, style: GoogleFonts.cairo(color: Colors.amber, fontSize: 20)),
            ],
          ),
          const Icon(Icons.mosque, size: 70, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildPrayerList() {
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _prayerItem("الفجر", _todayPrayerTimes!.fajr),
          _prayerItem("الشروق", _todayPrayerTimes!.sunrise),
          _prayerItem("الظهر", _todayPrayerTimes!.dhuhr),
          _prayerItem("العصر", _todayPrayerTimes!.asr),
          _prayerItem("المغرب", _todayPrayerTimes!.maghrib),
          _prayerItem("العشاء", _todayPrayerTimes!.isha),
        ],
      ),
    );
  }

  Widget _prayerItem(String name, DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
          Text(DateFormat.jm().format(time), style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAzkarSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _azkarCard("أذكار الصباح", "assets/images/morning-azkar.png", const Morningazkar()),
        _azkarCard("أذكار المساء", "assets/images/evening-azkar.png", const Eveningazkar()),
      ],
    );
  }

  Widget _azkarCard(String title, String img, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}