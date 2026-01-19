import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with WidgetsBindingObserver {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
  
  // 👇 مفتاح التحديث
  int _refreshKey = 0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 👇 دالة المراقبة: غير يرجع المستخدم من Settings، دير Refresh
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("User returned to app, refreshing Qibla page...");
      setState(() {
        _refreshKey++; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 استعملنا المفتاح هنا باش الصفحة تعاود تبدا من 0
    return Scaffold(
      key: ValueKey(_refreshKey), 
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text('اتجاه القبلة', style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
           SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset('assets/images/morningbg.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          FutureBuilder(
            future: _deviceSupport,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.amber));
              }
              if (snapshot.hasError) {
                return Center(child: Text("خطأ: ${snapshot.error}", style: TextStyle(color: Colors.white)));
              }
              if (snapshot.data == true) {
                // 👇 عيطنا للويدجت اللي كتأكد من GPS
                return LocationChecker(); 
              } else {
                return Center(child: Text("جهازك لا يدعم البوصلة", style: TextStyle(color: Colors.white)));
              }
            },
          ),
        ],
      ),
    );
  }
}

// 👇 ويدجت مستقلة للتأكد من GPS
class LocationChecker extends StatefulWidget {
  const LocationChecker({super.key});

  @override
  State<LocationChecker> createState() => _LocationCheckerState();
}

class _LocationCheckerState extends State<LocationChecker> {
  bool? isGpsEnabled;

  @override
  void initState() {
    super.initState();
    checkGps();
  }

  Future<void> checkGps() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
       permission = await Geolocator.requestPermission();
    }
    
    if (mounted) {
      setState(() {
        isGpsEnabled = isEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGpsEnabled == null) {
      return Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    if (isGpsEnabled == false) {
      // واجهة "شعل GPS"
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.redAccent, size: 60),
            SizedBox(height: 20),
            Text(
              "المرجو تفعيل GPS لتحديد القبلة",
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: Text("تفعيل GPS", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    return QiblaCompass();
  }
}

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasData) {
          final qiblahDirection = snapshot.data!;
          var angle = ((qiblahDirection.qiblah) * (pi / 180) * -1);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: angle,
                  child: Image.asset('assets/images/qiblaarrow.png', height: 300),
                ),
                SizedBox(height: 30),
                Text("${qiblahDirection.qiblah.toStringAsFixed(0)}°", style: GoogleFonts.cairo(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                Text("درجة نحو الكعبة", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return Center(child: Text("جاري البحث عن الموقع...", style: TextStyle(color: Colors.white)));
      },
    );
  }
}