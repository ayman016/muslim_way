import 'dart:ui';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:muslim_way/finance_page.dart';
import 'package:muslim_way/qiblapart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim_way/home_tab.dart';
import 'package:muslim_way/notes_page.dart';
import 'package:muslim_way/prayers_page.dart';
import 'package:muslim_way/quran_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(onLocationRefresh: forceUpdateLocation),
      PrayersPage(),
      FinancePage(),
      NotesPage(),
    ];
    checkSavedLocation();
  }

  Future<void> checkSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getDouble('lat') == null) {
      forceUpdateLocation();
    }
  }

  Future<void> forceUpdateLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', position.latitude);
    await prefs.setDouble('long', position.longitude);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      // AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: Colors.black.withOpacity(0.2),
              centerTitle: true,
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/muslimwayperfect.png', height: 40),
                  SizedBox(width: 10),
                  Text(
                    _getTitle(_currentIndex),
                    style: GoogleFonts.aBeeZee(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                if (_currentIndex == 0)
                  IconButton(
                    onPressed: forceUpdateLocation,
                    icon: Icon(Icons.location_on, color: Colors.amber),
                  )
              ],
            ),
          ),
        ),
      ),

      drawer: _buildDrawer(context),

      body: Stack(
        children: [
          // 1. الخلفية
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/mainbg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
              ),
            ),
          ),
          
          // 2. الصفحة الحالية
          _pages[_currentIndex],

          // 3. النافبار العائمة (Floating Navbar) - الإضافة الجديدة
          Positioned(
            bottom: 25, // المسافة من التحت باش تبان عايمة
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // تأثير الزجاج
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // لون شفاف
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavBtn(0, Icons.home_rounded, "الرئيسية"),
                      _buildNavBtn(1, Icons.mosque_rounded, "صلاتي"),
                      _buildNavBtn(2, Icons.account_balance_wallet_rounded, "مالي"),
                      _buildNavBtn(3, Icons.edit_note_rounded, "أفكاري"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // حيدنا bottomNavigationBar القديم من هنا
    );
  }

  // --- Widget خاص بالأزرار المتحركة ---
  Widget _buildNavBtn(int index, IconData icon, String text) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300), // سرعة الانيميشن
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.transparent, // اللون الذهبي عند الاختيار
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.black : Colors.white,
              size: 26,
            ),
            if (isSelected) ...[ // إظهار النص فقط عند الاختيار
              SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.cairo(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return "Muslim Way";
      case 1: return "جدول الصلاة";
      case 2: return "إدارة المال";
      case 3: return "ملاحظاتي";
      default: return "Muslim Way";
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Image.asset('assets/images/drawerbg.jpg', width: double.infinity, height: double.infinity, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.8)),
          ListView(
            children: [
              SizedBox(height: 50),
              ListTile(
                leading: Icon(Icons.explore, color: Colors.white, size: 30),
                title: Text('اتجاه القبلة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                onTap: () {
                  Navigator.pop(context);
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.question,
                    animType: AnimType.scale,
                    title: 'الذهاب للقبلة؟',
                    desc: 'سيتم فتح بوصلة القبلة',
                    btnCancelOnPress: () {},
                    btnOkOnPress: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => QiblaPage()));
                    },
                  ).show();
                },
              ),
              Divider(color: Colors.white24),
              ListTile(
                leading: Icon(Icons.book, color: Colors.white, size: 30),
                title: Text('القرآن الكريم', style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuranPage()));
                },
              ),
              Divider(color: Colors.white24),
              ListTile(
                leading: Image.asset('assets/images/Instagram.png', width: 30),
                title: Text('Instagram', style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                onTap: () async {
                   final Uri url = Uri.parse('https://www.instagram.com/ayman__016_?igsh=MW1qeW1qc2ZlMnE2bA==');
                   await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}