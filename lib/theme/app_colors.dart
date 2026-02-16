import 'package:flutter/material.dart';

class AppColors {
  // 1. الخلفية (60%) - Deep Slate Navy
  static const Color background = Color(0xFF1A202C);
  
  // 2. اللون الرئيسي (30%) - Royal Blue
  // يستخدم للأزرار، الأيقونات النشطة، والعناوين الرئيسية
  static const Color primary = Color(0xFF0056D2);
  
  // 3. لون التمييز (10%) - Bright Cyan (حسب الكود الذي أعطيتني)
  // يستخدم للتفاصيل الصغيرة، الحواف، أو التنبيهات الهادئة
  static const Color accent = Color(0xFF00C2CB); 

  // ألوان إضافية مساعدة (للتباين مع الخلفية الداكنة)
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.white70;
  
  // لون للبطاقات (أفتح قليلاً من الخلفية لإنشاء تباين)
  // قمت باشتقاقه من الخلفية ليكون متناسقاً
  static const Color surface = Color(0xFF2D3748); 
}