import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Eveningazkar extends StatefulWidget {
  const Eveningazkar({super.key});

  @override
  State<Eveningazkar> createState() => _EveningazkarState();
}

class _EveningazkarState extends State<Eveningazkar> {
  // قائمة أذكار المساء
  List<Map<String, dynamic>> azkarList = [
    {
      "text": "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
      "count": 1,
      "current_count": 1
    },
    {
      "text": "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ",
      "count": 1,
      "current_count": 1
    },
    {
      "text": "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
      "count": 1,
      "current_count": 1
    },
    {
      "text": "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      "count": 3,
      "current_count": 3
    },
    {
      "text": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      "count": 100,
      "current_count": 100
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
          'أذكار المساء',
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
              'assets/images/drawerbg.jpg', // يمكنك تغيير الصورة هنا لتتميز عن الصباح
              fit: BoxFit.cover,
            ),
          ),
          // طبقة داكنة فوق الصورة لتوضيح النص
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9), // لون أغمق قليلاً للمساء
                  Colors.deepPurple.withOpacity(0.5) // لمسة بنفسجية للمساء
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 2. القائمة
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: azkarList.length,
              itemBuilder: (context, index) {
                int count = azkarList[index]['count'];
                int currentCount = azkarList[index]['current_count'];
                String text = azkarList[index]['text'];
                bool isFinished = currentCount == 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (currentCount > 0) {
                        azkarList[index]['current_count'] = currentCount - 1;
                      }
                    });
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
                        color: isFinished
                            ? Colors.green
                            : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.6, // تباعد الأسطر للقراءة المريحة
                            decoration:
                                isFinished ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: isFinished
                                        ? 1
                                        : (count - currentCount) / count,
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.3),
                                    color: Colors.amber,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              isFinished ? "تم" : "تكرار: $count",
                              style: const TextStyle(color: Colors.white70),
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