import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/finance_page.dart';
import 'package:muslim_way/qiblapart.dart';
import 'package:muslim_way/home_tab.dart';
import 'package:muslim_way/notes_page.dart';
import 'package:muslim_way/StatsPage.dart';
import 'package:muslim_way/settings_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // ✅ استعملنا const باش ما يتعاودش البناء ديالهم
  final List<Widget> _pages = const [
    HomeTab(),
    StatsPage(),
    FinancePage(),
    NotesPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ استعملنا select باش نسمعو فقط لتغيير اللغة، ماشي أي تغيير
    final lang = context.select<LanguageProvider, LanguageProvider>((p) => p);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      // ✅ AppBar خفيف بدون Blur ثقيل
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black.withOpacity(0.7), // لون شفاف خفيف بلا Blur
        centerTitle: true,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/muslimwayperfect.png', height: 35),
            const SizedBox(width: 10),
            Text(
              _getTitle(_currentIndex, lang),
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: () {
                // استدعاء Provider بلا listen باش ما يديرش Rebuild
                context.read<PrayerProvider>().forceUpdateLocation();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.location_on, color: Colors.amber, size: 20),
              ),
            )
        ],
      ),

      // ✅ Drawer مفصول ومحسن الأداء
      drawer: const AppDrawer(),

      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/images/eveningbg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          // الصفحات
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(), // سكرول ناعم
            onPageChanged: _onPageChanged,
            children: _pages,
          ),

          // النافبار العائمة
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.95), // لون داكن وشبه شفاف
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavBarItem(index: 0, currentIndex: _currentIndex, icon: Icons.home_rounded, label: lang.t('home'), onTap: _onNavTapped),
                  _NavBarItem(index: 1, currentIndex: _currentIndex, icon: Icons.insights, label: lang.t('prayers'), onTap: _onNavTapped),
                  _NavBarItem(index: 2, currentIndex: _currentIndex, icon: Icons.account_balance_wallet_rounded, label: lang.t('finance'), onTap: _onNavTapped),
                  _NavBarItem(index: 3, currentIndex: _currentIndex, icon: Icons.edit_note_rounded, label: lang.t('notes'), onTap: _onNavTapped),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index, LanguageProvider lang) {
      switch (index) {
      case 0: return "Muslim Way";
      case 1: return lang.t('prayers');
      case 2: return lang.t('finance');
      case 3: return lang.t('notes');
      default: return "Muslim Way";
    }
  }
}

// ==========================================
// ✅ Widget 1: Optimized Navbar Item
// ==========================================
class _NavBarItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Function(int) onTap;

  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ✅ Widget 2: Optimized App Drawer (No Blur)
// ==========================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null;

    return Drawer(
      // 🚀 السر هنا: لون خلفية عادي بلا BackdropFilter
      backgroundColor: const Color(0xFF121212), 
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.75, // نقصنا العرض شوية باش يبان أخف
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E), // لون خلفية Header
            ),
            currentAccountPicture: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.amber,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null 
                  ? const Icon(Icons.person, size: 40, color: Colors.black) 
                  : null,
            ),
            accountName: Text(
              user?.displayName ?? "مرحباً بك، زائر",
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: isGuest 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Text("نسخة تجريبية", style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10)),
                )
              : Text(user!.email!, style: GoogleFonts.cairo(color: Colors.white54)),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                _DrawerItem(
                  icon: Icons.explore_outlined, 
                  text: lang.t('qibla'), 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QiblaPage()));
                  }
                ),
                const Divider(color: Colors.white10, thickness: 1, indent: 20, endIndent: 20),
                _DrawerItem(
                  icon: Icons.settings_outlined, 
                  text: lang.t('settings_title'), 
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); 
                  }
                ),
                _DrawerItem(
                  icon: Icons.camera_alt_outlined, 
                  text: 'Instagram', 
                  onTap: () async {
                     final Uri url = Uri.parse('https://www.instagram.com/ayman__016_?igsh=MW1qeW1qc2ZlMnE2bA==');
                     await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                ),
              ],
            ),
          ),

          // Login/Logout Button
          if (isGuest) 
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "سجل دخولك الآن",
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "احفظ بياناتك في السحاب.",
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())); 
                      },
                      icon: const Icon(Icons.login, color: Colors.black),
                      label: Text("تسجيل الدخول", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          else 
            // زر تسجيل الخروج للمستخدم المسجل (إضافة صغيرة من عندي 😉)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextButton.icon(
                onPressed: () async {
                   await FirebaseAuth.instance.signOut();
                   // هنا تقدر تزيد لوجيك باش ترجعو لصفحة الدخول أو تعاود تحمل التطبيق
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: Text("تسجيل الخروج", style: GoogleFonts.cairo(color: Colors.redAccent)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.amber, size: 22),
        ),
        title: Text(text, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: onTap,
        hoverColor: Colors.white10,
      ),
    );
  }
}