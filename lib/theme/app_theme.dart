import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData getTheme(String langCode) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, 
      
      // ✅ الخلفية
      scaffoldBackgroundColor: AppColors.background,
      
      // ✅ الألوان الرئيسية
      primaryColor: AppColors.primary,
      
      // ❌ حيدنا const من هنا احتياطاً
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: Color(0xFFCF6679),
      ),

      // ✅ الخطوط (هذا هو سبب المشكل، GoogleFonts ليس const)
      fontFamily: GoogleFonts.cairo().fontFamily,
      
      // ✅ النصوص (❌ حيدنا const)
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: AppColors.textWhite),
        bodyLarge: TextStyle(color: AppColors.textWhite),
        titleLarge: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
      ),

      // ✅ AppBar (❌ حيدنا const بسبب GoogleFonts)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // ✅ Cards (تم التعديل لتجنب الخطأ)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary, width: 0.5), 
        ),
      ),

      // ✅ Floating Action Button (❌ حيدنا const حسب نصيحة Copilot)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      
      // ✅ Dialogs (❌ حيدنا const بسبب GoogleFonts)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.textWhite, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
        contentTextStyle: GoogleFonts.cairo(
          color: AppColors.textGrey
        ),
      ),
    );
  }
}