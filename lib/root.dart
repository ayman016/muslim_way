import 'package:flutter/material.dart';
import 'package:muslim_way/StatsPage.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muslim_way/providers/prayer_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/finance_page.dart';
import 'package:muslim_way/qiblapart.dart';
import 'package:muslim_way/home_tab.dart';
import 'package:muslim_way/notes_page.dart';
import 'package:muslim_way/settings_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class SwitchTabNotification extends Notification {
  final int newIndex;
  const SwitchTabNotification(this.newIndex);
}

class _RootState extends State<Root> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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

  String _getTitle(int index, LanguageProvider lang) {
    switch (index) {
      case 0:  return "Zimam";
      case 1:  return lang.t('stats');
      case 2:  return lang.t('finance');
      case 3:  return lang.t('notes');
      default: return "Zimam";
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.background.withOpacity(0.8),
        centerTitle: true,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/app_iconuse.png', height: 35),
            const SizedBox(width: 10),
            Text(
              _getTitle(_currentIndex, lang),
              style: AppFonts.mainStyle(
                context: context,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: () {
                context.read<PrayerProvider>().forceUpdateLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang.t('update'),
                      style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white),
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppColors.accent, size: 20),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: NotificationListener<SwitchTabNotification>(
        onNotification: (notification) {
          _onNavTapped(notification.newIndex);
          return true;
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withAlpha(90), AppColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: _pages,
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavBarItem(index: 0, currentIndex: _currentIndex, icon: Icons.home_rounded,                   label: lang.t('home'),    onTap: _onNavTapped),
                    _NavBarItem(index: 1, currentIndex: _currentIndex, icon: Icons.bar_chart_rounded,              label: lang.t('stats'),   onTap: _onNavTapped),
                    _NavBarItem(index: 2, currentIndex: _currentIndex, icon: Icons.account_balance_wallet_rounded, label: lang.t('finance'), onTap: _onNavTapped),
                    _NavBarItem(index: 3, currentIndex: _currentIndex, icon: Icons.edit_note_rounded,              label: lang.t('notes'),   onTap: _onNavTapped),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.mainStyle(
                  context: context,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showLanguageDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          lang.t('lang_title'),
          style: AppFonts.mainStyle(context: context, listen: false, color: AppColors.accent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption(context, 'العربية', 'ar'),
            _buildLangOption(context, 'English', 'en'),
            _buildLangOption(context, 'Français', 'fr'),
            _buildLangOption(context, 'الدارجة', 'da'),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(BuildContext context, String name, String code) {
    final lang = context.read<LanguageProvider>();
    final isSelected = lang.currentLang == code;
    return ListTile(
      title: Text(
        name,
        style: AppFonts.mainStyle(
          context: context, listen: false,
          color: isSelected ? AppColors.accent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.accent) : null,
      onTap: () {
        context.read<LanguageProvider>().changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  void _logout(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          lang.t('logout'),
          style: AppFonts.mainStyle(context: context, listen: false, color: Colors.redAccent),
        ),
        content: Text(
          lang.t('logout_confirm'),
          style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.t('cancel'),
              style: AppFonts.mainStyle(context: context, listen: false, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut(); // ✅ A كبير - مصلح
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            child: Text(
              lang.t('exit'),
              style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang    = context.watch<LanguageProvider>();
    final user    = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.background,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
            accountName: Text(
              user?.displayName ?? "Zimam",
              style: AppFonts.mainStyle(context: context, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: isGuest
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang.t('guest_mode'),
                      style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 10),
                    ),
                  )
                : Text(
                    user!.email!,
                    style: AppFonts.mainStyle(context: context, color: Colors.white70),
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                _DrawerItem(
                  icon: Icons.explore_outlined,
                  text: lang.t('qibla'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaPage()));
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  text: lang.t('settings_title'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
                _DrawerItem(
                  icon: Icons.language,
                  text: lang.t('lang_title'),
                  trailing: Text(
                    lang.currentLang.toUpperCase(),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showLanguageDialog(context),
                ),
                const Divider(color: Colors.white10, thickness: 1, indent: 20, endIndent: 20),
                _DrawerItem(
                  icon: Icons.camera_alt_outlined,
                  text: lang.t('instagram (zimam.app)'),
                  onTap: () async {
                    final Uri nativeUrl = Uri.parse('instagram://user?username=zimam.app');
                    final Uri webUrl = Uri.parse('https://www.instagram.com/zimam.app/');
                    try {
                      if (!await launchUrl(nativeUrl, mode: LaunchMode.externalApplication)) {
                        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: isGuest
                ? SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: Text(
                        lang.t('start'),
                        style: AppFonts.mainStyle(context: context, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: Text(
                      lang.t('logout'),
                      style: AppFonts.mainStyle(context: context, color: Colors.redAccent),
                    ),
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
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 22),
        ),
        title: Text(
          text,
          style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 16),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: onTap,
        hoverColor: Colors.white10,
      ),
    );
  }
}