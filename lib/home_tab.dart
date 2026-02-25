import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/morningazkar.dart';
import 'package:muslim_way/eveningazkar.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isDataLoaded = false;
  late AnimationController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDataLoaded) {
        _precacheImages();
        context.read<PrayerProvider>().fetchPrayerData();

        final provider = context.read<UserDataProvider>();
        // ✅ إيلا الداتا مازال ما تحملاتش — نحملوها ونستنى
        if (!provider.dataLoaded) {
          provider.fetchData().then((_) {
            if (mounted) _pageController.forward();
          });
        } else {
          _pageController.forward();
        }

        _isDataLoaded = true;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _precacheImages() {
    try {
      precacheImage(const AssetImage('assets/images/morning-azkar.png'), context);
      precacheImage(const AssetImage('assets/images/evening-azkar.png'), context);
      precacheImage(const AssetImage('assets/images/streak.png'), context);
      precacheImage(const AssetImage('assets/images/streakoff.png'), context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _SlideIn(
              controller: _pageController,
              delay: 0.0,
              direction: _SlideDirection.top,
              child: const _NextPrayerCard(),
            ),
            const SizedBox(height: 14),
            _SlideIn(
              controller: _pageController,
              delay: 0.15,
              direction: _SlideDirection.right,
              child: const _PrayerTimesList(),
            ),
            const SizedBox(height: 22),
            _SlideIn(
              controller: _pageController,
              delay: 0.3,
              direction: _SlideDirection.left,
              child: const _StreakSection(),
            ),
            const SizedBox(height: 22),
            _SlideIn(
              controller: _pageController,
              delay: 0.45,
              direction: _SlideDirection.bottom,
              child: const _AzkarSection(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🎞️ Animation Helpers
// ============================================================

enum _SlideDirection { top, bottom, left, right }

class _SlideIn extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final _SlideDirection direction;
  final Widget child;

  const _SlideIn({
    required this.controller,
    required this.delay,
    required this.direction,
    required this.child,
  });

  Offset get _begin {
    switch (direction) {
      case _SlideDirection.top:    return const Offset(0, -0.4);
      case _SlideDirection.bottom: return const Offset(0, 0.4);
      case _SlideDirection.left:   return const Offset(-0.4, 0);
      case _SlideDirection.right:  return const Offset(0.4, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final start  = delay.clamp(0.0, 0.95);
    final end    = (delay + 0.55).clamp(0.05, 1.0);
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(begin: _begin, end: Offset.zero).animate(curved);
    final fade  = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}

class _BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BounceTap({required this.child, required this.onTap});

  @override
  State<_BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<_BounceTap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

// ============================================================
// 🕌 Next Prayer Card
// ============================================================

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard();

  String _getTranslatedPrayerName(String rawName, LanguageProvider lang) {
    String name = rawName.trim().toLowerCase();
    if (name.contains('fajr')    || name.contains('الفجر'))   return lang.t('fajr');
    if (name.contains('sunrise') || name.contains('الشروق'))  return lang.t('sunrise');
    if (name.contains('dhuhr')   || name.contains('الظهر'))   return lang.t('dhuhr');
    if (name.contains('asr')     || name.contains('العصر'))   return lang.t('asr');
    if (name.contains('maghrib') || name.contains('المغرب'))  return lang.t('maghrib');
    if (name.contains('isha')    || name.contains('العشاء'))  return lang.t('isha');
    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<PrayerProvider, ({String name, String time})>(
      selector: (_, p) => (name: p.nextPrayerName, time: p.nextPrayerTime),
      shouldRebuild: (prev, next) => prev.name != next.name || prev.time != next.time,
      builder: (context, data, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.9),
                AppColors.primary.withOpacity(0.6),
                AppColors.background.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 30, spreadRadius: 2, offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.accent.withOpacity(0.08),
                blurRadius: 60, spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned(
                  top: -30, right: -30,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20, left: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, size: 11, color: AppColors.accent),
                                const SizedBox(width: 5),
                                Text(
                                  lang.t('next_prayer'),
                                  style: AppFonts.mainStyle(
                                    context: context,
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _getTranslatedPrayerName(data.name, lang),
                            style: AppFonts.mainStyle(
                              context: context,
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.time,
                                style: AppFonts.mainStyle(
                                  context: context,
                                  color: AppColors.accent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent.withOpacity(0.08), width: 1),
                              color: Colors.white.withOpacity(0.03),
                            ),
                          ),
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent.withOpacity(0.14), width: 1),
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                              border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
                            ),
                            child: const Icon(Icons.mosque_rounded, size: 26, color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 🕐 Prayer Times List
// ============================================================

class _PrayerTimesList extends StatelessWidget {
  const _PrayerTimesList();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<PrayerProvider, ApiPrayerTimes?>(
      selector: (_, p) => p.todayPrayerTimes,
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, times, child) {
        if (times == null) return const SizedBox.shrink();
        final items = [
          _PrayerItem(name: lang.t('fajr'),    time: times.fajr,    index: 0),
          _PrayerItem(name: lang.t('sunrise'), time: times.sunrise,  index: 1),
          _PrayerItem(name: lang.t('dhuhr'),   time: times.dhuhr,   index: 2),
          _PrayerItem(name: lang.t('asr'),     time: times.asr,     index: 3),
          _PrayerItem(name: lang.t('maghrib'), time: times.maghrib, index: 4),
          _PrayerItem(name: lang.t('isha'),    time: times.isha,    index: 5),
        ];
        return SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            cacheExtent: 500,
            children: items,
          ),
        );
      },
    );
  }
}

class _PrayerItem extends StatefulWidget {
  final String name;
  final DateTime time;
  final int index;

  const _PrayerItem({required this.name, required this.time, required this.index});

  @override
  State<_PrayerItem> createState() => _PrayerItemState();
}

class _PrayerItemState extends State<_PrayerItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _icons = [
    Icons.brightness_3_rounded,
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.light_mode_outlined,
    Icons.wb_cloudy_rounded,
    Icons.nights_stay_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: 80 + widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icons[widget.index.clamp(0, _icons.length - 1)];
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface.withOpacity(0.95),
                AppColors.surface.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.accent.withOpacity(0.8)),
              const SizedBox(height: 5),
              Text(
                widget.name,
                style: AppFonts.mainStyle(context: context, color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.jm().format(widget.time),
                style: AppFonts.mainStyle(
                  context: context,
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🔥 Streak Section
// ============================================================

class _StreakSection extends StatelessWidget {
  const _StreakSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Selector<UserDataProvider, ({int streak, int level, List<String> tasks, bool isLoading, bool dataLoaded})>(
      selector: (_, p) => (
        streak: p.streakCount,
        level: p.userLevel,
        tasks: p.tasks,
        isLoading: p.isLoading,
        dataLoaded: p.dataLoaded,
      ),
      builder: (context, data, child) {

        // ✅ Loading state — كنستنى الداتا
        if (data.isLoading || !data.dataLoaded) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: AppColors.surface.withOpacity(0.4),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.1), width: 1),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.orangeAccent,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final dailyTasks = data.tasks.where((t) {
          final p = t.split('|');
          return p.length > 2 && p[2] == 'true';
        }).toList();

        return GestureDetector(
          onTap: () => SwitchTabNotification(3).dispatch(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  AppColors.surface.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.08),
                  blurRadius: 30, spreadRadius: 2, offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('streak_title'),
                              style: AppFonts.mainStyle(
                                context: context,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dailyTasks.isEmpty ? lang.t('streak_empty') : lang.t('streak_desc'),
                              style: AppFonts.mainStyle(
                                context: context,
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orangeAccent.withOpacity(0.25),
                            Colors.deepOrangeAccent.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        "${lang.t('level')} ${data.level}",
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Streak Counter ───────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          "${data.streak}",
                          style: AppFonts.mainStyle(
                            context: context,
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          "/ 7",
                          style: AppFonts.mainStyle(
                            context: context,
                            color: Colors.white24,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 7 أيام ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final isActive = index < data.streak;
                    final isNext   = index == data.streak;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            Container(
                              width: isActive ? 36 : 30,
                              height: isActive ? 36 : 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isActive ? null : Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.orangeAccent.withOpacity(0.6)
                                      : isNext
                                          ? Colors.white24
                                          : Colors.white12,
                                  width: isActive ? 1.5 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.orangeAccent.withOpacity(0.45),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: isActive
                                    ? const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : Icon(
                                        Icons.circle_outlined,
                                        color: isNext ? Colors.white38 : Colors.white12,
                                        size: 14,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${index + 1}",
                              style: AppFonts.mainStyle(
                                context: context,
                                color: isActive ? Colors.orangeAccent : Colors.white24,
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 📿 Azkar Section
// ============================================================

class _AzkarSection extends StatelessWidget {
  const _AzkarSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _AzkarCard(
              title: lang.currentLang == 'ar' || lang.currentLang == 'da'
                  ? "أذكار الصباح"
                  : (lang.currentLang == 'fr' ? "Azkar Matin" : "Morning Azkar"),
              image: "assets/images/morning-azkar.png",
              page: const Morningazkar(),
              heroTag: "morning",
              accentColor: const Color(0xFFFFC66D),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _AzkarCard(
              title: lang.currentLang == 'ar' || lang.currentLang == 'da'
                  ? "أذكار المساء"
                  : (lang.currentLang == 'fr' ? "Azkar Soir" : "Evening Azkar"),
              image: "assets/images/evening-azkar.png",
              page: const Eveningazkar(),
              heroTag: "evening",
              accentColor: const Color(0xFF81C4FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _AzkarCard extends StatelessWidget {
  final String title;
  final String image;
  final Widget page;
  final String heroTag;
  final Color accentColor;

  const _AzkarCard({
    required this.title,
    required this.image,
    required this.page,
    required this.heroTag,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _BounceTap(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  image,
                  height: 145,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 420,
                  cacheHeight: 420,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 145,
                    color: AppColors.primary.withOpacity(0.3),
                    child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.08), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppFonts.mainStyle(
                        context: context,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: accentColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔔 Notification class
class SwitchTabNotification extends Notification {
  final int newIndex;
  SwitchTabNotification(this.newIndex);
}