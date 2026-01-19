import 'package:flutter/material.dart';
import 'package:muslim_way/root.dart';
import 'package:muslim_way/notification_service.dart'; // 1. زدنا هاد الـ Import

void main() async { // 2. ردينا الدالة async
  // 3. هاد السطر ضروري باش نضمنو كلشي واجد
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. هنا كنديمارويو خدمة الإشعارات
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muslim Way', // بدلت Title بمرة
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber), // درت Amber باش يواتي الديزاين
        useMaterial3: true,
      ),
      home: Root(),
    );
  }
}