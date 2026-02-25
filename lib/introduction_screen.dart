import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/auth_wrapper.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _step = 0;
  String _selectedLang = '';

  static const _green   = Color(0xFF2E7D32);
  static const _greenLt = Color(0xFF66BB6A);
  static const _bg      = Color(0xFFF8F9F8);
  static const _dark    = Color(0xFF0D1B0F);
  static const _grey    = Color(0xFF9E9E9E);

  static const Map<String, Map<String, String>> _tr = {
    'ar': {
      'choose_sub': 'اختر اللغة المفضلة للمتابعة',
      'welcome_title': 'مرحباً بك في Zimam',
      'welcome_desc': 'تطبيق صُمم لمساعدتك على إدارة أموالك، مهامك اليومية، وحياتك الدينية بشكل فعّال.',
      'start': 'ابدأ الآن',
      'next': 'التالي',
      'ready': 'أنت جاهز!',
      'ready_sub': 'كل ما تحتاجه في مكان واحد',
    },
    'en': {
      'choose_sub': 'Select your preferred language to continue',
      'welcome_title': 'Welcome to Zimam',
      'welcome_desc': 'An app designed to help you manage your finances, daily tasks, and spiritual life effectively.',
      'start': 'Get Started',
      'next': 'Next',
      'ready': "You're all set!",
      'ready_sub': 'Everything you need in one place',
    },
    'fr': {
      'choose_sub': 'Sélectionnez votre langue préférée pour continuer',
      'welcome_title': 'Bienvenue sur Zimam',
      'welcome_desc': 'Une application pour gérer vos finances, tâches quotidiennes et vie spirituelle efficacement.',
      'start': 'Commencer',
      'next': 'Suivant',
      'ready': 'Vous êtes prêt !',
      'ready_sub': 'Tout ce dont vous avez besoin en un seul endroit',
    },
    'da': {
      'choose_sub': 'اختار اللغة ديالك باش تكمل',
      'welcome_title': 'مرحبا بك ف Zimam',
      'welcome_desc': 'تطبيق دارتو باش يعاونك تسير فلوسك، مهامك اليومية، والجانب الديني ديالك.',
      'start': 'بدا دابا',
      'next': 'التالي',
      'ready': 'واخا حضرتي!',
      'ready_sub': 'كلشي لي محتاجو ف بلاصة وحدة',
    },
  };

  String _t(String key) {
    final lang = _selectedLang.isEmpty ? 'en' : _selectedLang;
    return _tr[lang]?[key] ?? _tr['en']![key]!;
  }

  bool get _isRtl => _selectedLang == 'ar' || _selectedLang == 'da';

  final _languages = [
    {'code': 'ar', 'label': 'العربية',  'flag': '🇸🇦', 'sub': 'Arabic'},
    {'code': 'en', 'label': 'English',  'flag': '🇬🇧', 'sub': 'English'},
    {'code': 'fr', 'label': 'Français', 'flag': '🇫🇷', 'sub': 'French'},
    {'code': 'da', 'label': 'الدارجة', 'flag': '🇲🇦', 'sub': 'Moroccan'},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    if (step < 0 || step > 2) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _selectLanguage(String code) async {
    HapticFeedback.selectionClick();
    setState(() => _selectedLang = code);
    await context.read<LanguageProvider>().changeLanguage(code);
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const AuthWrapper(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canNext = _selectedLang.isNotEmpty;
    final bool isLast  = _step == 2;

    return Directionality(
      // ✅ كل الـ UI يتغير حسب اللغة
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [

              // ── Logo + Name — وسط فوق — بدون خلفية ──
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 4),
                child: Column(
                  children: [
                    // ✅ بدون container — بدون خلفية — واضح
                    Image.asset(
                      'assets/images/app_iconuse.png',
                      width: 52,
                      height: 52,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Zimam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pages ─────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // ✅ بدون reverse — Directionality وحده كيحل RTL
                  physics: canNext
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _LanguagePage(
                      languages: _languages,
                      selectedLang: _selectedLang,
                      onSelect: _selectLanguage,
                      t: _t,
                      green: _green,
                      dark: _dark,
                      grey: _grey,
                    ),
                    _WelcomePage(t: _t, dark: _dark, grey: _grey),
                    _ReadyPage(
                      t: _t,
                      green: _green,
                      greenLt: _greenLt,
                      dark: _dark,
                      grey: _grey,
                      onStart: _finish,
                    ),
                  ],
                ),
              ),

              // ── Dots ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = _step == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? _green : _green.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // ── Buttons ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
                child: Row(
                  children: [
                    // Back (مخفي فالصفحة الأولى)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: _step > 0
                          ? Padding(
                              padding: EdgeInsetsDirectional.only(end: 12),
                              child: GestureDetector(
                                onTap: () => _goTo(_step - 1),
                                child: Container(
                                  height: 54,
                                  width: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ✅ نفس الزر — التالي أو ابدأ الآن حسب الصفحة
                    Expanded(
                      child: GestureDetector(
                        onTap: isLast
                            ? _finish
                            : (canNext ? () => _goTo(_step + 1) : null),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: (isLast || canNext) ? _green : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              isLast
                                  ? _t('start')
                                  : (canNext ? _t('next') : 'Choose / اختر'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: (isLast || canNext)
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// Page 0 — Language
// ============================================================
class _LanguagePage extends StatelessWidget {
  final List<Map<String, String>> languages;
  final String selectedLang;
  final ValueChanged<String> onSelect;
  final String Function(String) t;
  final Color green, dark, grey;

  const _LanguagePage({
    required this.languages,
    required this.selectedLang,
    required this.onSelect,
    required this.t,
    required this.green,
    required this.dark,
    required this.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('choose_sub'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: dark,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 26),
          ...languages.map((lang) {
            final isSelected = selectedLang == lang['code'];
            return GestureDetector(
              onTap: () => onSelect(lang['code']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: BoxDecoration(
                  color: isSelected ? green : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? green : Colors.grey.withOpacity(0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? green.withOpacity(0.22)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: isSelected ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : dark,
                            ),
                          ),
                          Text(
                            lang['sub']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white60 : grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded, size: 13, color: green)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// Page 1 — Welcome (نص فقط، وسط، negative space)
// ============================================================
class _WelcomePage extends StatelessWidget {
  final String Function(String) t;
  final Color dark, grey;

  const _WelcomePage({
    required this.t,
    required this.dark,
    required this.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // ✅ عنوان + نص فقط — وسط — بدون list
          Text(
            t('welcome_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            t('welcome_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              color: grey,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ============================================================
// Page 2 — Ready (negative space واسع)
// ============================================================
class _ReadyPage extends StatelessWidget {
  final String Function(String) t;
  final Color green, greenLt, dark, grey;
  final VoidCallback onStart;

  const _ReadyPage({
    required this.t,
    required this.green,
    required this.greenLt,
    required this.dark,
    required this.grey,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Column(
        children: [
          // ✅ negative space فوق كبير
          const Spacer(flex: 2),

          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.18),
                  blurRadius: 50,
                  spreadRadius: 8,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/images/app_iconuse.png'),
            ),
          ),

          const SizedBox(height: 36),

          Text(
            t('ready'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            t('ready_sub'),
            style: TextStyle(fontSize: 15, color: grey),
            textAlign: TextAlign.center,
          ),

          // ✅ negative space تحت واسع
          const Spacer(flex: 3),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}