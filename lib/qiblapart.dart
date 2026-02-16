import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان الجديدة

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with WidgetsBindingObserver {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
  
  // مفتاح التحديث
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

  // دالة المراقبة: عند العودة من الإعدادات، نقوم بالتحديث
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _refreshKey++; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      key: ValueKey(_refreshKey), 
      backgroundColor: AppColors.background, // ✅ استخدام لون الخلفية الموحد (Navy)
      appBar: AppBar(
        // ✅ استخدام مفتاح الترجمة للعنوان
        title: Text(lang.t('qibla_direction'), style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
           // ✅ الخلفية
           SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/morningbg.jpg', 
              fit: BoxFit.cover,
              color: AppColors.background.withOpacity(0.7), // ✅ دمج الصورة مع لون الخلفية
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          FutureBuilder(
            future: _deviceSupport,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent)); // ✅ Cyan Loader
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "${lang.t('error')}: ${snapshot.error}", 
                    style: GoogleFonts.cairo(color: Colors.white)
                  )
                );
              }
              if (snapshot.data == true) {
                return const LocationChecker(); 
              } else {
                return Center(
                  child: Text(
                    lang.t('device_not_supported'), 
                    style: GoogleFonts.cairo(color: Colors.white)
                  )
                );
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
    final lang = context.watch<LanguageProvider>();

    if (isGpsEnabled == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (isGpsEnabled == false) {
      // واجهة "شعل GPS"
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.redAccent, size: 60),
            const SizedBox(height: 20),
            Text(
              lang.t('enable_gps_msg'), // ✅ رسالة تفعيل GPS مترجمة
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // ✅ Royal Blue Button
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: Text(
                lang.t('enable_gps'), // ✅ زر تفعيل GPS مترجم
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)
              ),
            )
          ],
        ),
      );
    }

    return const QiblaCompass();
  }
}

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        
        if (snapshot.hasData) {
          final qiblahDirection = snapshot.data!;
          var angle = ((qiblahDirection.qiblah) * (pi / 180) * -1);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // ✅ خلفية دائرية للبوصلة
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                        color: AppColors.surface.withOpacity(0.2),
                      ),
                    ),
                    Transform.rotate(
                      angle: angle,
                      child: Image.asset(
                        'assets/images/qiblaarrow.png', 
                        height: 300,
                        // يمكنك تلوين الصورة إذا كانت شفافة وتدعم ذلك، وإلا اتركها كما هي
                        // color: AppColors.accent, 
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "${qiblahDirection.qiblah.toStringAsFixed(0)}°", 
                  style: GoogleFonts.cairo(
                    color: AppColors.accent, // ✅ درجة الزاوية بـ Cyan
                    fontSize: 40, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  lang.t('degree_to_kaaba'), // ✅ نص "درجة نحو الكعبة" مترجم
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16)
                ),
              ],
            ),
          );
        }
        return Center(
          child: Text(
            lang.t('searching_location'), // ✅ نص "جاري البحث" مترجم
            style: GoogleFonts.cairo(color: Colors.white)
          )
        );
      },
    );
  }
}