import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Morningazkar extends StatefulWidget {
  const Morningazkar({super.key});

  @override
  State<Morningazkar> createState() => _MorningazkarState();
}

class _MorningazkarState extends State<Morningazkar> {
  // قائمة الأذكار مع العدد المطلوب لكل ذكر
  // List of Maps: كل عنصر يحتوي على النص والعدد
  List<Map<String, dynamic>> azkarList = [
    {
      "text": "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ",
      "count": 1,
      "current_count": 1 // هذا العداد الذي سنقوم بإنقاصه
    },
    {
      "text": "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
      "count": 1,
      "current_count": 1
    },
    {
      "text": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      "count": 100,
      "current_count": 100
    },
    {
      "text": "حَسْبِيَ اللَّهُ لا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
      "count": 7,
      "current_count": 7
    },
    {
      "text": "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ",
      "count": 1,
      "current_count": 1
    },
     {
      "text": "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
      "count": 3,
      "current_count": 3
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // لا نحتاج للون خلفية لأننا سنستخدم صورة
      extendBodyBehindAppBar: true, // يجعل الـ AppBar شفافاً فوق الخلفية
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'أذكار الصباح',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. الخلفية (صورة + طبقة سوداء)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/drawerbg.jpg', // تأكد من وجود الصورة أو غير الاسم
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.blueAccent.withOpacity(0.3)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 2. قائمة الأذكار
          SafeArea(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: azkarList.length,
              itemBuilder: (context, index) {
                // استخراج البيانات لتسهيل الاستخدام
                int count = azkarList[index]['count'];
                int currentCount = azkarList[index]['current_count'];
                String text = azkarList[index]['text'];
                bool isFinished = currentCount == 0;

                return GestureDetector(
                  onTap: () {
                    // منطق إنقاص العدد
                    setState(() {
                      if (currentCount > 0) {
                        azkarList[index]['current_count'] = currentCount - 1;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // تغيير اللون إذا انتهى الذكر
                      color: isFinished 
                          ? Colors.green.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFinished ? Colors.green : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // نص الذكر
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                            decoration: isFinished ? TextDecoration.lineThrough : null, // شطب النص عند الانتهاء
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Colors.white24),
                        
                        // العداد وشريط التقدم
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // دائرة العداد
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                              child: Text(
                                '$currentCount', // عرض العدد المتبقي
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16
                                ),
                              ),
                            ),
                            
                            // شريط التقدم (Progress Bar)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: isFinished ? 1 : (count - currentCount) / count,
                                    backgroundColor: Colors.grey.withOpacity(0.3),
                                    color: Colors.amber,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ),
                            
                            // نص توضيحي صغير
                            Text(
                              isFinished ? "تم" : "تكرار: $count",
                              style: TextStyle(color: Colors.white70),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}