import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/morningazkar.dart';
import 'package:muslim_way/eveningazkar.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ✅ ضروري

class HomeTab extends StatefulWidget {
  const HomeTab({super.key}); 

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrayerProvider>(context, listen: false).fetchAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrayerProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 100),
            
            // 1. Next Prayer Card (انيميشن: ظهور + صعود مع نقزة خفيفة)
            _buildNextPrayerCard(provider)
                .animate()
                .fade(duration: 600.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack), // Bounce Effect
            
            const SizedBox(height: 10),
            
            // 2. Budget Header (انيميشن: جاية من اليسار)
            _buildHeader(provider)
                .animate()
                .fade(duration: 500.ms, delay: 200.ms) // معطلة شوية
                .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
            
            const SizedBox(height: 10),
            
            // 3. Prayer List
            if (provider.todayPrayerTimes != null) 
              _buildPrayerList(provider.todayPrayerTimes!),
            
            const SizedBox(height: 35),
            
            // 4. Azkar (انيميشن: طلوع من التحت)
            _buildAzkarSection()
                .animate()
                .fade(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
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
              .scaleXY(begin: 1, end: 1.1, duration: 2.seconds), // ✅ المسجد كيتنفس (Pulse)
        ],
      ),
    );
  }

  Widget _buildHeader(PrayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("الميزانية المتبقية", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
              Text("${provider.remainingBudget} DH", style: GoogleFonts.cairo(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            onPressed: () => provider.fetchAllData(),
            icon: const Icon(Icons.refresh, color: Colors.amber)
          ).animate().rotate(duration: 1.seconds, curve: Curves.easeInOut), // ✅ الايقونة كدور فاش تبان
        ],
      ),
    );
  }

  Widget _buildPrayerList(PrayerTimes times) {
    // لائحة العناصر اللي غانعرضو
    List<Widget> items = [
      _prayerItem("الفجر", times.fajr),
      _prayerItem("الشروق", times.sunrise),
      _prayerItem("الظهر", times.dhuhr),
      _prayerItem("العصر", times.asr),
      _prayerItem("المغرب", times.maghrib),
      _prayerItem("العشاء", times.isha),
    ];

    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        physics: const BouncingScrollPhysics(),
        children: items
            .animate(interval: 100.ms) // ✅ سحر: كل عنصر كيبان مورا لاخور بـ 100ms
            .fade(duration: 400.ms)
            .slideX(begin: 0.5, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  Widget _prayerItem(String name, DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
          Text(DateFormat.jm().format(time), style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAzkarSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _azkarCard("أذكار الصباح", "assets/images/morning-azkar.png", const Morningazkar()),
        _azkarCard("أذكار المساء", "assets/images/evening-azkar.png", const Eveningazkar()),
      ],
    );
  }

  Widget _azkarCard(String title, String img, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          // استعملنا Hero باش التصويرة "طير" للصفحة الجاية (خاصك تزيد Hero فالصفحة الاخرى باش تكمل)
          Hero(
            tag: title, // Tag فريد
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
                boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}