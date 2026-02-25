import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/auth_wrapper.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReminderOn = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser?.isAnonymous ?? true;

    setState(() {
      _isReminderOn = prefs.getBool('prayer_reminders_enabled') ?? true;
      _isGuest = isGuestUser;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderOn = value;
    });
    await prefs.setBool('prayer_reminders_enabled', value);

    if (!value) {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().signOut(); // ✅ A كبير - consistent
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  String _getLangName(String code) {
    switch (code) {
      case 'ar': return 'العربية';
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'da': return 'الدارجة';
      default: return 'العربية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          lang.t('settings_title'),
          style: AppFonts.mainStyle(
            context: context,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.background, Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('general'),
                    style: AppFonts.mainStyle(
                      context: context,
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildSettingItem(
                    icon: Icons.language,
                    title: lang.t('lang_title'),
                    subtitle: _getLangName(lang.currentLang),
                    onTap: () => _showLanguageDialog(context),
                    showArrow: true,
                  ),

                  const SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: SwitchListTile(
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      secondary: Icon(
                        _isReminderOn ? Icons.notifications_active : Icons.notifications_off,
                        color: _isReminderOn ? AppColors.accent : Colors.grey,
                      ),
                      title: Text(
                        lang.t('prayer_reminders'),
                        style: AppFonts.mainStyle(context: context, color: Colors.white),
                      ),
                      subtitle: Text(
                        _isReminderOn ? "On" : "Off",
                        style: AppFonts.mainStyle(context: context, color: Colors.grey, fontSize: 12),
                      ),
                      value: _isReminderOn,
                      onChanged: _toggleReminder,
                    ),
                  ),

                  // ✅ إخفاء قسم الحساب إذا كان المستخدم ضيفاً
                  if (!_isGuest) ...[
                    const SizedBox(height: 30),
                    Text(
                      lang.t('account'),
                      style: AppFonts.mainStyle(
                        context: context,
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(
                          lang.t('logout'),
                          style: AppFonts.mainStyle(
                            context: context,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text(
                                lang.t('logout'),
                                style: AppFonts.mainStyle(context: context, color: Colors.white),
                              ),
                              content: Text(
                                lang.t('logout_confirm'),
                                style: AppFonts.mainStyle(context: context, color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    lang.t('cancel'),
                                    style: AppFonts.mainStyle(context: context, color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleLogout();
                                  },
                                  child: Text(
                                    lang.t('exit'),
                                    style: AppFonts.mainStyle(context: context, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Spacer(),
                  Center(
                    child: Text(
                      "${lang.t('version')} 1.0.0",
                      style: AppFonts.mainStyle(context: context, color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: AppFonts.mainStyle(context: context, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: AppFonts.mainStyle(context: context, color: Colors.grey, fontSize: 12),
        ),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.t('lang_title'),
                style: AppFonts.mainStyle(
                  context: context,
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildLangOption(context, lang, 'العربية', 'ar'),
              const Divider(color: Colors.white24),
              _buildLangOption(context, lang, 'English', 'en'),
              const Divider(color: Colors.white24),
              _buildLangOption(context, lang, 'Français', 'fr'),
              const Divider(color: Colors.white24),
              _buildLangOption(context, lang, 'الدارجة 🇲🇦', 'da'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(BuildContext context, LanguageProvider lang, String name, String code) {
    bool isSelected = lang.currentLang == code;
    return ListTile(
      title: Text(
        name,
        style: AppFonts.mainStyle(
          context: context,
          color: isSelected ? AppColors.accent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
      onTap: () {
        lang.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}