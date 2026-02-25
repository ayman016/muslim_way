import 'package:flutter/material.dart';
// ❌ تم الاستغناء عن google_fonts تماماً لضمان العمل Offline
import 'app_colors.dart';

class AppTheme {
  static ThemeData getTheme(String langCode) {
    // ✅ تحديد الخط المحلي بناءً على اللغة للحفاظ على الهوية البصرية لتطبيق Zimam
    final String localFontFamily = (langCode == 'ar' || langCode == 'da') 
        ? 'IBMPlexSansArabic' 
        : 'IBMPlexSans';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, 
      
      // ✅ الخلفية
      scaffoldBackgroundColor: AppColors.background,
      
      // ✅ الألوان الرئيسية
      primaryColor: AppColors.primary,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: Color(0xFFCF6679),
      ),

      // ✅ الخطوط (تم ربطها بالخطوط المحلية المدمجة في التطبيق)
      fontFamily: localFontFamily,
      
      // ✅ النصوص 
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textWhite),
        bodyLarge: TextStyle(color: AppColors.textWhite),
        titleLarge: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
      ),

      // ✅ AppBar 
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        titleTextStyle: TextStyle( // ✅ استخدام TextStyle العادي مع الخط المحلي
          fontFamily: localFontFamily,
          color: AppColors.textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // ✅ Cards 
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary, width: 0.5), 
        ),
      ),

      // ✅ Floating Action Button 
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      
      // ✅ Dialogs 
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: TextStyle( // ✅ استخدام TextStyle العادي مع الخط المحلي
          fontFamily: localFontFamily,
          color: AppColors.textWhite, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
        contentTextStyle: TextStyle( // ✅ استخدام TextStyle العادي مع الخط المحلي
          fontFamily: localFontFamily,
          color: AppColors.textGrey
        ),
      ),
    );
  }
}