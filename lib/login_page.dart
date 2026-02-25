import 'package:flutter/material.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/language_provider.dart';

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      final service = AuthService(); // ✅ A كبير + اسم مختلف عن الكلاس — مصلح
      final userCred = await service.signInWithGoogle();
      if (mounted) {
        setState(() => isLoading = false);
        if (userCred != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('seen_login', true);
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "حدث خطأ في تسجيل الدخول",
              style: AppFonts.mainStyle(context: context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: lang.currentLang,
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.language, color: Colors.white, size: 20),
                          style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 14),
                          onChanged: (String? newValue) {
                            if (newValue != null) lang.changeLanguage(newValue);
                          },
                          items: const [
                            DropdownMenuItem(value: 'ar', child: Text("العربية")),
                            DropdownMenuItem(value: 'da', child: Text("الدارجة")),
                            DropdownMenuItem(value: 'en', child: Text("English")),
                            DropdownMenuItem(value: 'fr', child: Text("Français")),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/app_iconuse.png', height: 140, width: 140),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Zimam",
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lang.t('login_welcome'),
                        textAlign: TextAlign.center,
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lang.t('login_desc'),
                        textAlign: TextAlign.center,
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      SizedBox(
                        height: 55,
                        width: double.infinity,
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: _handleGoogleSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset('assets/images/google.png', height: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      lang.t('google_login'),
                                      style: AppFonts.mainStyle(
                                        context: context,
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: isLoading ? null : _skipLogin,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.t('guest_login'),
                              style: AppFonts.mainStyle(
                                context: context,
                                color: isLoading ? Colors.grey : AppColors.accent,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.arrow_forward, size: 18, color: isLoading ? Colors.grey : AppColors.accent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}