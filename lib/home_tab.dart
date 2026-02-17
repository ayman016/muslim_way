import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/morningazkar.dart';
import 'package:muslim_way/eveningazkar.dart';
import 'package:muslim_way/add_task_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان الجديدة

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().fetchPrayerData();
      context.read<UserDataProvider>().fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 100),
            _NextPrayerCard(),
            SizedBox(height: 10),
            _PrayerTimesList(),
            SizedBox(height: 25),
            _TasksSection(),
            SizedBox(height: 25),
            _AzkarSection(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ==============================
// 🆕 Widgets (Translated & Styled)
// ==============================

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard();

  String _getTranslatedPrayerName(String rawName, LanguageProvider lang) {
    String name = rawName.trim().toLowerCase();
    
    // ✅ بما أننا ضفنا الترجمة في البروفايدر، دابا نقدرو نعيطو عليهم بالمفاتيح
    if (name.contains('fajr') || name.contains('الفجر')) return lang.t('fajr');
    if (name.contains('sunrise') || name.contains('shuruq') || name.contains('الشروق')) return lang.t('sunrise');
    if (name.contains('dhuhr') || name.contains('zuhr') || name.contains('الظهر')) return lang.t('dhuhr');
    if (name.contains('asr') || name.contains('العصر')) return lang.t('asr');
    if (name.contains('maghrib') || name.contains('المغرب')) return lang.t('maghrib');
    if (name.contains('isha') || name.contains('العشاء')) return lang.t('isha');
    
    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<PrayerProvider, ({String name, String time})>(
      selector: (_, provider) => (
        name: provider.nextPrayerName,
        time: provider.nextPrayerTime,
      ),
      builder: (context, data, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.9), 
                AppColors.background
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4), 
                blurRadius: 15, 
                offset: const Offset(0, 8)
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  // ✅ استعمال المفتاح المترجم 'next_prayer'
                  Text(
                    lang.t('next_prayer'),
                    style: GoogleFonts.cairo(color: Colors.white70),
                  ),
                  Text(
                    _getTranslatedPrayerName(data.name, lang), 
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    data.time, 
                    style: GoogleFonts.cairo(color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              const Icon(Icons.mosque, size: 70, color: Colors.white12)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.05, duration: 2.seconds),
            ],
          ),
        )
        .animate()
        .fade(duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
      },
    );
  }
}

class _PrayerTimesList extends StatelessWidget {
  const _PrayerTimesList();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<PrayerProvider, PrayerTimes?>(
      selector: (_, provider) => provider.todayPrayerTimes,
      builder: (context, times, child) {
        if (times == null) return const SizedBox.shrink();

        final items = [
          _PrayerItem(name: lang.t('fajr'), time: times.fajr),
          _PrayerItem(name: lang.t('sunrise'), time: times.sunrise),
          _PrayerItem(name: lang.t('dhuhr'), time: times.dhuhr),
          _PrayerItem(name: lang.t('asr'), time: times.asr),
          _PrayerItem(name: lang.t('maghrib'), time: times.maghrib),
          _PrayerItem(name: lang.t('isha'), time: times.isha),
        ];

        return SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            physics: const BouncingScrollPhysics(),
            children: items
                .animate(interval: 100.ms)
                .fade()
                .slideX(begin: 0.5, end: 0),
          ),
        );
      },
    );
  }
}

class _PrayerItem extends StatelessWidget {
  final String name;
  final DateTime time;

  const _PrayerItem({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
          Text(
            DateFormat.jm().format(time),
            style: GoogleFonts.cairo(color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<UserDataProvider, List<String>>(
      selector: (_, provider) => provider.tasks,
      builder: (context, tasks, child) {
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final displayTasks = tasks.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ استعمال المفتاح المترجم 'tasks_title'
                  Text(
                    "${lang.t('tasks_title')} 📝", 
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tasks.isNotEmpty)
                    Text(
                      "${tasks.length} ${lang.t('notes_count')}", // استعمال مفتاح 'notes_count'
                      style: GoogleFonts.cairo(color: AppColors.textGrey, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    lang.t('empty_notes'),
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: displayTasks.length,
                itemBuilder: (context, index) {
                  final task = displayTasks[index];
                  final parts = task.split('|');
                  final title = parts[0];
                  final lastDone = parts.length > 6 ? parts[6] : "null";
                  final isDoneToday = lastDone == todayStr;

                  return _TaskCard(
                    title: title,
                    isDone: isDoneToday,
                    onToggle: () => context.read<UserDataProvider>().toggleTaskStatus(index),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTaskPage(taskToEdit: task, taskIndex: index),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.title,
    required this.isDone,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDone ? const Color(0xFF1B5E20).withOpacity(0.5) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone ? Colors.transparent : AppColors.primary.withOpacity(0.2),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            color: isDone ? Colors.greenAccent : AppColors.accent, 
          ),
          onPressed: onToggle,
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.white,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white54,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _AzkarSection extends StatelessWidget {
  const _AzkarSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AzkarCard(
          title: lang.currentLang == 'ar' || lang.currentLang == 'da' ? "أذكار الصباح" : 
                 (lang.currentLang == 'fr' ? "Azkar Matin" : "Morning Azkar"),
          image: "assets/images/morning-azkar.png",
          page: const Morningazkar(),
        ),
        _AzkarCard(
          title: lang.currentLang == 'ar' || lang.currentLang == 'da' ? "أذكار المساء" : 
                 (lang.currentLang == 'fr' ? "Azkar Soir" : "Evening Azkar"),
          image: "assets/images/evening-azkar.png",
          page: const Eveningazkar(),
        ),
      ],
    )
    .animate()
    .fade(duration: 600.ms, delay: 400.ms)
    .slideY(begin: 0.2, end: 0);
  }
}

class _AzkarCard extends StatelessWidget {
  final String title;
  final String image;
  final Widget page;

  const _AzkarCard({
    required this.title,
    required this.image,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Hero(
            tag: title,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))
                ],
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}