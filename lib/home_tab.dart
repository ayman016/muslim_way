import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart'; 
import 'package:muslim_way/morningazkar.dart';
import 'package:muslim_way/eveningazkar.dart';
import 'package:muslim_way/add_task_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key}); 

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  @override
  void initState() {
    super.initState();
    // تحميل البيانات مرة واحدة عند فتح التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrayerProvider>(context, listen: false).fetchPrayerData();
      Provider.of<UserDataProvider>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ هنا الحل: Consumer كيراقب جوج حوايج: الصلاة والداتا ديال المستخدم
    return Consumer2<PrayerProvider, UserDataProvider>(
      builder: (context, prayerProvider, userProvider, child) {
        
        if (prayerProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 100),
                
                // 1. Next Prayer Card
                _buildNextPrayerCard(prayerProvider)
                    .animate().fade(duration: 600.ms).slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 10),
                
                // 2. Budget Header
                // _buildHeader(userProvider)
                //     .animate().fade(duration: 500.ms, delay: 200.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 10),
                
                // 3. Prayer List
                if (prayerProvider.todayPrayerTimes != null) 
                  _buildPrayerList(prayerProvider.todayPrayerTimes!),
                
                const SizedBox(height: 25),

                // ✅ 4. قسم المهام (دابا كيوصلو التحديث فوراً حيت وسط Consumer)
                _buildTasksSection(context, userProvider),

                const SizedBox(height: 25),
                
                // 5. Azkar
                _buildAzkarSection()
                    .animate().fade(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          // زر الإضافة العائم
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.amber,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskPage())),
            child: const Icon(Icons.add_task, color: Colors.black),
          ),
        );
      },
    );
  }

  // ✅ قسم المهام
  Widget _buildTasksSection(BuildContext context, UserDataProvider userData) {
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("مهامي اليوم 📝", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (userData.tasks.isNotEmpty)
                Text("${userData.tasks.length} مهام", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        if (userData.tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("لا توجد مهام، أضف واحدة!", style: GoogleFonts.cairo(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: userData.tasks.length > 3 ? 3 : userData.tasks.length, 
            itemBuilder: (context, index) {
              String task = userData.tasks[index];
              List<String> parts = task.split('|');
              String title = parts[0];
              String lastDone = parts.length > 6 ? parts[6] : "null";
              bool isDoneToday = lastDone == todayStr;

              return Card(
                color: isDoneToday ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.08),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(isDoneToday ? Icons.check_circle : Icons.circle_outlined, color: isDoneToday ? Colors.green : Colors.amber),
                    onPressed: () {
                      // ✅ التحديث الفوري
                      userData.markTaskAsDone(index);
                    },
                  ),
                  title: Text(
                    title, 
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      decoration: isDoneToday ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white54
                    )
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(taskToEdit: task, taskIndex: index)));
                    },
                  ),
                ),
              );
            },
          ),
          
         
         
      ],
    );
  }

  Widget _buildNextPrayerCard(PrayerProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.black]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text("الصلاة القادمة", style: GoogleFonts.cairo(color: Colors.white60)),
              Text(provider.nextPrayerName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text(provider.nextPrayerTime, style: GoogleFonts.cairo(color: Colors.amber, fontSize: 20)),
            ],
          ),
          const Icon(Icons.mosque, size: 70, color: Colors.white24)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.1, duration: 2.seconds),
        ],
      ),
    );
  }

  // Widget _buildHeader(UserDataProvider provider) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text("الميزانية المتبقية", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
  //             Text("${provider.balance.toStringAsFixed(2)} DH", style: GoogleFonts.cairo(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
  //           ],
  //         ),
  //         IconButton(
  //           onPressed: () => provider.fetchData(),
  //           icon: const Icon(Icons.refresh, color: Colors.amber)
  //         ).animate().rotate(duration: 1.seconds, curve: Curves.easeInOut),
  //       ],
  //     ),
  //   );
  // }

  // ... (باقي الودجتس PrayerList و Azkar بحال الكود القديم - ما تبدلوش) ...
  // باش ما نعمرش عليك الكود بزاف، خلي دوك الدوال الصغار لي فالتحت كيف ما هوما.
  
  Widget _buildPrayerList(PrayerTimes times) {
    List<Widget> items = [
      _prayerItem("الفجر", times.fajr),
      _prayerItem("الشروق", times.sunrise),
      _prayerItem("الظهر", times.dhuhr),
      _prayerItem("العصر", times.asr),
      _prayerItem("المغرب", times.maghrib),
      _prayerItem("العشاء", times.isha),
    ];
    return SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), physics: const BouncingScrollPhysics(), children: items.animate(interval: 100.ms).fade().slideX(begin: 0.5, end: 0)));
  }

  Widget _prayerItem(String name, DateTime time) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)), Text(DateFormat.jm().format(time), style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold))]));
  }

  Widget _buildAzkarSection() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_azkarCard("أذكار الصباح", "assets/images/morning-azkar.png", const Morningazkar()), _azkarCard("أذكار المساء", "assets/images/evening-azkar.png", const Eveningazkar())]);
  }

  Widget _azkarCard(String title, String img, Widget page) {
    return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)), child: Column(children: [Hero(tag: title, child: Container(width: 140, height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover), boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))]))), const SizedBox(height: 8), Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold))]));
  }
}