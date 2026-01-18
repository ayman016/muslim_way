import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> {
  // قائمة الصلوات وحالتها
  List<Map<String, dynamic>> prayers = [
    {"name": "الفجر", "done": false},
    {"name": "الظهر", "done": false},
    {"name": "العصر", "done": false},
    {"name": "المغرب", "done": false},
    {"name": "العشاء", "done": false},
  ];
  
  String todayDate = "";

  @override
  void initState() {
    super.initState();
    checkDateAndLoad();
  }

  Future<void> checkDateAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    String currentDay = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? savedDay = prefs.getString('prayers_last_date');

    setState(() {
      todayDate = currentDay;
    });

    if (savedDay != currentDay) {
      // يوم جديد: تصفير كل شيء
      await prefs.setString('prayers_last_date', currentDay);
      for (int i = 0; i < 5; i++) {
        await prefs.setBool('prayer_done_$i', false);
      }
      setState(() {
        for (var p in prayers) p['done'] = false;
      });
    } else {
      // نفس اليوم: تحميل الحالة
      setState(() {
        for (int i = 0; i < 5; i++) {
          prayers[i]['done'] = prefs.getBool('prayer_done_$i') ?? false;
        }
      });
    }
  }

  Future<void> togglePrayer(int index, bool? val) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prayers[index]['done'] = val;
    });
    await prefs.setBool('prayer_done_$index', val ?? false);
  }

  double getProgress() {
    int doneCount = prayers.where((p) => p['done'] == true).length;
    return doneCount / 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/drawerbg.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text("جدول صلوات اليوم", style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(todayDate, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
                  SizedBox(height: 30),
                  
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: getProgress(),
                      minHeight: 20,
                      backgroundColor: Colors.white24,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("${(getProgress() * 100).toInt()}% مكتملة", style: TextStyle(color: Colors.white)),
                  
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (c, i) => SizedBox(height: 15),
                      itemCount: prayers.length,
                      itemBuilder: (context, index) {
                        bool isDone = prayers[index]['done'];
                        return Container(
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isDone ? Colors.green : Colors.white24),
                          ),
                          child: CheckboxListTile(
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            title: Text(
                              prayers[index]['name'],
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 20,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            secondary: Image.asset('assets/images/praye.png', width: 30, color: Colors.white),
                            value: isDone,
                            onChanged: (val) => togglePrayer(index, val),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}