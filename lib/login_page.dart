import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/root.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> _skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_login', true);
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Root()));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    
    final authService = AuthService();
    final userCred = await authService.signInWithGoogle();

    setState(() => isLoading = false);

    if (userCred != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_login', true);
      
      if (mounted) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Root()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey.shade900],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 50),
                      // 👇 بدلت Image بـ Icon مؤقتاً باش ما يتكوانساش التطبيق
                      // إلا عندك اللوغو بصح، حيد هاد Icon ورجع Image.asset
                      const Icon(Icons.mosque, size: 100, color: Colors.amber), 
                      
                      const SizedBox(height: 20),
                      Text("مرحباً بك في Muslim Way", 
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        "لحفظ بياناتك (الأذكار، المصاريف...) وعدم ضياعها،\nننصحك بتسجيل الدخول.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      isLoading 
                      ? const CircularProgressIndicator(color: Colors.amber)
                      : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _handleGoogleSignIn,
                          // 👇 درت ليك أيقونة ديال Google (حرف G) موجودة فـ Flutter
                          // بلا ما تحتاج تصويرة png دابا
                          icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 40), 
                          
                          // 👇 هذا هو الحل ديال Overflow: درنا FittedBox
                          label: FittedBox(
                            child: Text("تسجيل الدخول عبر Google", 
                              style: GoogleFonts.cairo(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      TextButton(
                        onPressed: _skipLogin,
                        child: Text("تخطي والمتابعة كزائر", 
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16, decoration: TextDecoration.underline)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}