import 'dart:ui';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/finance_page.dart';
import 'package:muslim_way/qiblapart.dart';
import 'package:muslim_way/home_tab.dart';
import 'package:muslim_way/notes_page.dart';
import 'package:muslim_way/prayers_page.dart';
import 'package:muslim_way/quran_page.dart';
import 'package:muslim_way/settings_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/login_page.dart'; // ✅ تأكد باش تديه لصفحة الدخول
import 'package:url_launcher/url_launcher.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomeTab(),
    const PrayersPage(),
    const FinancePage(),
    const NotesPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context); 

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.black.withOpacity(0.2), // شفافية أكثر
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
                      Provider.of<PrayerProvider>(context, listen: false).forceUpdateLocation();
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
          ),
        ),
      ),

      drawer: _buildDrawer(context, lang),

      body: Stack(
        children: [
          // الخلفية
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/mainbg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
          ),
          
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _pages,
          ),

          // النافبار العائمة بتصميم أنظف
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavBtn(0, Icons.home_rounded, lang.t('home')),
                      _buildNavBtn(1, Icons.mosque_rounded, lang.t('prayers')),
                      _buildNavBtn(2, Icons.account_balance_wallet_rounded, lang.t('finance')),
                      _buildNavBtn(3, Icons.edit_note_rounded, lang.t('notes')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBtn(int index, IconData icon, String text) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
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
                text,
                style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ]
          ],
        ),
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

  // ✅✅✅ التصميم الجديد للـ Drawer
  Widget _buildDrawer(BuildContext context, LanguageProvider lang) {
      final user = FirebaseAuth.instance.currentUser;
      final bool isGuest = user == null;

      return Drawer(
      backgroundColor: Colors.transparent, // مهم باش تبان الخلفية والBlur
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Stack(
        children: [
          // 1. خلفية Drawer مع Blur
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. المحتوى
          Column(
            children: [
              // Header
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight
                  )
                ),
                currentAccountPicture: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.amber,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null 
                      ? Icon(Icons.person, size: 40, color: Colors.black) 
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

              // القائمة
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.explore_outlined, 
                      text: lang.t('qibla'), 
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => QiblaPage()));
                      }
                    ),
                    _buildDrawerItem(
                      icon: Icons.menu_book_rounded, 
                      text: lang.t('quran'), 
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => QuranPage()));
                      }
                    ),
                    const Divider(color: Colors.white10, thickness: 1, indent: 20, endIndent: 20),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined, 
                      text: lang.t('settings_title'), 
                      onTap: () {
                        Navigator.pop(context); 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); 
                      }
                    ),
                    _buildDrawerItem(
                      icon: Icons.camera_alt_outlined, // Instagram icon replacement
                      text: 'Instagram', 
                      onTap: () async {
                         final Uri url = Uri.parse('https://www.instagram.com/ayman__016_?igsh=MW1qeW1qc2ZlMnE2bA==');
                         await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    ),
                  ],
                ),
              ),

              // ✅✅✅ 3. زر تسجيل الدخول للزائر (لتحت)
              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "سجل دخولك الآن",
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "احفظ بياناتك (الصلاة، المال، الملاحظات) في السحاب.",
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
                            elevation: 5,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // سد Drawer
                            // سير لصفحة الدخول
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())); 
                          },
                          icon: const Icon(Icons.login, color: Colors.black),
                          label: Text("تسجيل الدخول", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ] else ...[
                 // مساحة فارغة بسيطة للمستخدم المسجل
                 const SizedBox(height: 20),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // ودجت صغيرة لتصميم عناصر القائمة
  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
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
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: onTap,
        hoverColor: Colors.white10,
      ),
    );
  }
}