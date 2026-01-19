import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // ✅ ضروري
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/eveningazkar.dart';
import 'package:muslim_way/morningazkar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/notification_service.dart';

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
    loadBudgetSummary();
    
    // 👇 1. نطلب الإذن هو الأول مباشرة عند الدخول
    _checkPermissionAndCalculate();
  }
  
  Future<void> loadBudgetSummary() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      double bal = prefs.getDouble('wallet_balance') ?? 0.0;
      remainingBudget = bal.toStringAsFixed(2);
    });
  }

  // 👇 دالة كتفرض طلب الإذن فالبداية
  Future<void> _checkPermissionAndCalculate() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // واخا يرفض، كنحاولو نحسبو (يقدر يكون GPS ديجا مسجل)
    calculatePrayers(); 
  }

  // 👇 دالة "الشرطي": كتأكد أن GPS شاعل
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> calculatePrayers() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('lat');
    double? long = prefs.getDouble('long');

    // 👇 إلا ماعندناش الإحداثيات، عيط للشرطي يجيبهم
    if (lat == null || long == null) {
      try {
        Position position = await _determinePosition();
        lat = position.latitude;
        long = position.longitude;
        await prefs.setDouble('lat', lat);
        await prefs.setDouble('long', long);
      } catch (e) {
        print("Error getting location: $e");
        return; 
      }
    }

    if (lat != null && long != null) {
      final myCoordinates = Coordinates(lat, long);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;
      params.fajrAngle = 18.0;
      params.ishaAngle = 17.0;

      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      // --- 🔔 الإشعارات ---
      final notifService = NotificationService();
      await notifService.requestPermissions(); // طلب إذن الإشعارات
      await notifService.cancelAll();
      
      // جدولة الصلوات
      await notifService.schedulePrayer(1, "الفجر", prayerTimes.fajr);
      await notifService.schedulePrayer(2, "الظهر", prayerTimes.dhuhr);
      await notifService.schedulePrayer(3, "العصر", prayerTimes.asr);
      await notifService.schedulePrayer(4, "المغرب", prayerTimes.maghrib);
      await notifService.schedulePrayer(5, "العشاء", prayerTimes.isha);
      // -------------------

      setState(() {
        _todayPrayerTimes = prayerTimes; 
        final next = prayerTimes.nextPrayer();
        final timeFormat = DateFormat.jm();

        if (next != Prayer.none) {
          final nextTime = prayerTimes.timeForPrayer(next);
          nextPrayerTime = timeFormat.format(nextTime!);
           switch (next) {
            case Prayer.fajr: nextPrayerName = "الفجر"; break;
            case Prayer.dhuhr: nextPrayerName = "الظهر"; break;
            case Prayer.asr: nextPrayerName = "العصر"; break;
            case Prayer.maghrib: nextPrayerName = "المغرب"; break;
            case Prayer.isha: nextPrayerName = "العشاء"; break;
            case Prayer.sunrise: nextPrayerName = "الشروق"; break;
            default: nextPrayerName = "-";
          }
        } else {
           nextPrayerName = "الفجر";
           nextPrayerTime = "غداً";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 100),
          
          // بطاقة التاريخ
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("مرحباً بك", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18)),
                    Text(DateFormat('EEEE, d MMM').format(DateTime.now()), style: GoogleFonts.aBeeZee(color: Colors.amber, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),

          // بطاقة الصلاة القادمة
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.black]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("الصلاة القادمة", style: GoogleFonts.cairo(color: Colors.white70)),
                    Text(nextPrayerName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                    Text(nextPrayerTime, style: GoogleFonts.aBeeZee(color: Colors.amber, fontSize: 20)),
                  ],
                ),
                Image.asset('assets/images/logo-muslim-way.png', width: 80), 
              ],
            ),
          ),

          SizedBox(height: 15),

          // شريط أوقات الصلوات
          if (_todayPrayerTimes != null)
            Container(
              height: 90,
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPrayerItem("الفجر", _todayPrayerTimes!.fajr),
                  _buildPrayerItem("الشروق", _todayPrayerTimes!.sunrise),
                  _buildPrayerItem("الظهر", _todayPrayerTimes!.dhuhr),
                  _buildPrayerItem("العصر", _todayPrayerTimes!.asr),
                  _buildPrayerItem("المغرب", _todayPrayerTimes!.maghrib),
                  _buildPrayerItem("العشاء", _todayPrayerTimes!.isha),
                ],
              ),
            ),

          SizedBox(height: 15),

          // ملخص مالي
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$remainingBudget DH", style: GoogleFonts.cairo(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("الميزانية المتبقية", style: GoogleFonts.cairo(color: Colors.white)),
              ],
            ),
          ),

          SizedBox(height: 20),
          Divider(color: Colors.white24),
          SizedBox(height: 10),

          // أزرار الأذكار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               _buildAzkarCard(context, "أذكار الصباح", "assets/images/morning-azkar.png", Morningazkar()),
               _buildAzkarCard(context, "أذكار المساء", "assets/images/evening-azkar.png", Eveningazkar()),
            ],
          ),
          
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String name, DateTime time) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14)),
          SizedBox(height: 5),
          Text(DateFormat.jm().format(time), style: GoogleFonts.aBeeZee(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAzkarCard(BuildContext context, String title, String img, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            width: 150, height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 10),
          Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}