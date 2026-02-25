import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/language_provider.dart';

class AppFonts {
  /// دالة كترد ليك الستايل المناسب على حساب اللغة المختارة
  static TextStyle mainStyle({
    required BuildContext context,
    bool listen = true, 
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
  }) {
    // كنستعملو Provider.of باش نتحكمو فـ listen
    final langCode = Provider.of<LanguageProvider>(context, listen: listen).currentLang;

    // 2. إلا كانت العربية أو الدارجة -> كنخدمو بـ IBMPlexSansArabic (خط محلي)
    if (langCode == 'ar' || langCode == 'da') {
      return TextStyle(
        fontFamily: 'IBMPlexSansArabic', // ✅ السمية اللي حطيتي ف pubspec.yaml
        fontSize: fontSize,
        fontWeight: fontWeight, // غيخدم أوتوماتيك بـ Medium إلا عطيتيه FontWeight.w500
        color: color,
        height: height,
        decoration: decoration,
        decorationColor: decorationColor,
        letterSpacing: letterSpacing,
      );
    } 
    // 3. إلا كانت الإنجليزية أو الفرنسية -> كنخدمو بـ IBMPlexSans (خط محلي)
    else {
      return TextStyle(
        fontFamily: 'IBMPlexSans', // ✅ السمية اللي حطيتي ف pubspec.yaml
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
        decorationColor: decorationColor,
        letterSpacing: letterSpacing,
      );
    }
  }
}