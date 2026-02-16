import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/root.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان

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
      // ✅ الخلفية Navy الأساسية
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ✅ إضافة تدرج خفيف جداً في الخلفية لإعطاء عمق
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background, 
                  Colors.black.withOpacity(0.8)
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🟢 القسم العلوي: الشعار والاسم
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      
                      // ✅ 1. لوغو التطبيق
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            )
                          ]
                        ),
                        child: Image.asset(
                          'assets/images/app_iconuse.png',
                          height: 140, // حجم مناسب
                          width: 140,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // ✅ 2. اسم التطبيق "Zimam"
                      Text(
                        "Zimam", 
                        style: GoogleFonts.cairo(
                          color: Colors.white, 
                          fontSize: 40, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        )
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // وصف بسيط
                      Text(
                        "رفيقك اليومي لتنظيم العبادات والمصاريف",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.grey.shade400, 
                          fontSize: 14
                        ),
                      ),
                    ],
                  ),

                  // 🟢 القسم السفلي: أزرار الدخول
                  Column(
                    children: [
                      if (isLoading)
                        const CircularProgressIndicator(color: AppColors.primary)
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // خلفية بيضاء لزر جوجل (Standard)
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // حواف دائرية عصرية
                              ),
                            ),
                            onPressed: _handleGoogleSignIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ✅ 3. شعار جوجل
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "متابعة باستخدام Google", 
                                  style: GoogleFonts.cairo(
                                    color: Colors.black87, 
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // زر التخطي
                      TextButton(
                        onPressed: _skipLogin,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "تخطي والمتابعة كزائر", 
                              style: GoogleFonts.cairo(
                                color: AppColors.accent, // ✅ لون Cyan الجذاب
                                fontSize: 15,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward, size: 18, color: AppColors.accent)
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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