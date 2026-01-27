import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 👈 ضروري

class Morningazkar extends StatefulWidget {
  const Morningazkar({super.key});

  @override
  State<Morningazkar> createState() => _MorningazkarState();
}

class _MorningazkarState extends State<Morningazkar> {
  // قائمة الأذكار
  List<Map<String, dynamic>> azkarList = [
    {
      "text": "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ",
      "count": 1,
      "current_count": 1
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
          // 1. الخلفية
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/drawerbg.jpg', 
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
              physics: const BouncingScrollPhysics(), // سكرول رطب
              padding: const EdgeInsets.all(16),
              itemCount: azkarList.length,
              itemBuilder: (context, index) {
                int count = azkarList[index]['count'];
                int currentCount = azkarList[index]['current_count'];
                String text = azkarList[index]['text'];
                bool isFinished = currentCount == 0;

                return GestureDetector(
                  onTap: () {
                    if (currentCount > 0) {
                      setState(() {
                        azkarList[index]['current_count'] = currentCount - 1;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isFinished 
                          ? Colors.green.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFinished ? Colors.green : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: isFinished 
                          ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 15)]
                          : [],
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
                            decoration: isFinished ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white24),
                        
                        // العداد وشريط التقدم
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // دائرة العداد (مع انيميشن Pop)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                              child: Text(
                                '$currentCount', 
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16
                                ),
                              )
                              .animate(key: ValueKey(currentCount)) // 👈 كلما تبدل الرقم، كيتعاود الانيميشن
                              .scale(duration: 200.ms, curve: Curves.easeOutBack), 
                            ),
                            
                            // شريط التقدم
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    tween: Tween<double>(
                                      begin: 0, 
                                      end: isFinished ? 1 : (count - currentCount) / count
                                    ),
                                    builder: (context, value, _) => LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      color: isFinished ? Colors.white : Colors.amber,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // نص التكرار
                            Text(
                              isFinished ? "تم ✅" : "تكرار: $count",
                              style: const TextStyle(color: Colors.white70),
                            )
                            .animate(target: isFinished ? 1 : 0) // إلا سالا، دير هاد الحركة
                            .shake(hz: 4, curve: Curves.easeInOut), // اهتزاز بسيط للفرحة
                          ],
                        )
                      ],
                    ),
                  )
                  .animate() // 👈 هذا هو الانيميشن ديال الدخول
                  .fade(duration: 500.ms, delay: (100 * index).ms) // كل واحد كيتعطل على لاخور بـ 100ms
                  .slideX(begin: 0.2, end: 0, curve: Curves.easeOut), 
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}