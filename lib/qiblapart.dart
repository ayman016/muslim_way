import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:google_fonts/google_fonts.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  // التحقق من دعم الجهاز للبوصلة
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();

  @override
  void initState() {
    super.initState();
    // 🔴 حيدنا دالة طلب الإذن من هنا
    // حيت ديجا خدينا الإذن فاش يلاه تفتح التطبيق (Root Page)
    // هكا الصفحة غاتحل دغيا بلا ما دير Refresh للـ GPS
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // الخلفية
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/morningbg.jpg', // تأكد أن الصورة كاينة
              fit: BoxFit.cover,
            ),
          ),
          // طبقة سوداء شفافة
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: Colors.black.withAlpha(150)),
          ),

          FutureBuilder(
            future: _deviceSupport,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "حدث خطأ: ${snapshot.error}",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              if (snapshot.data == true) {
                // الجهاز يدعم البوصلة -> عرض القبلة
                return QiblaCompass();
              } else {
                return Center(
                  child: Text(
                    "للأسف، جهازك لا يدعم مستشعر البوصلة",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
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
          // هنا واخا يطلع Loading غايكون سريع جداً حيت ماكيطلبش الإذن
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  "جاري ضبط البوصلة...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          final qiblahDirection = snapshot.data!;
          // معادلة حساب زاوية الدوران
          var angle = ((qiblahDirection.qiblah) * (pi / 180) * -1);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // صورة السهم تدور حسب الزاوية
                Transform.rotate(
                  angle: angle,
                  child: Image.asset(
                    'assets/images/qiblaarrow.png', // تأكد أن الصورة مفرغة
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "${qiblahDirection.qiblah.toStringAsFixed(0)}°",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "درجة نحو الكعبة",
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Text(
              "تأكد من تفعيل GPS",
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      },
    );
  }
}
