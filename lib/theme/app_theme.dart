import 'package:flutter/material.dart';
import 'app_colors.dart'; // ✅

class AppTheme {
  static ThemeData getTheme(String langCode) {
    // ✅ اختيار الخط: العربية والدارجة (ar, da) يأخذون الخط العربي
    // أما الإنجليزية والفرنسية يأخذون الخط اللاتيني
    String fontFamily = (langCode == 'ar' || langCode == 'da') 
        ? 'IBMPlexSansArabic' 
        : 'IBMPlexSans';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, 
      
      // ✅ الخلفية
      scaffoldBackgroundColor: AppColors.background,
      
      // ✅ الخط الديناميكي
      fontFamily: fontFamily,
      
      // ✅ الألوان الرئيسية
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
      ),

      // ✅ ستايل النصوص
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textWhite),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textWhite),
        titleLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textWhite, fontWeight: FontWeight.bold),
      ),

      // ✅ ستايل AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // ✅ ستايل Dialogs (باستعمال DialogThemeData كما طلبت)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily, 
          color: AppColors.textWhite, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily, 
          color: AppColors.textGrey
        ),
      ),
    );
  }
}