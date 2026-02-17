import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/auth_wrapper.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ضروري لحفظ الإعدادات

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ✅ متغير حالة التذكير (الافتراضي true)
  bool _isReminderOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // ✅ تحميل الإعدادات عند البدء
  }

  // ✅ دالة تحميل الإعداد المحفوظ
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // ?? true تعني: إذا لم نجد قيمة محفوظة (أول مرة)، اجعلها true
      _isReminderOn = prefs.getBool('prayer_reminders_enabled') ?? true;
    });
  }

  // ✅ دالة تغيير الإعداد وحفظه
  Future<void> _toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderOn = value;
    });
    await prefs.setBool('prayer_reminders_enabled', value);

    // 💡 هنا يمكنك إضافة منطق لتفعيل/إيقاف الإشعارات فعلياً
    if (value) {
      print("تم تفعيل التذكيرات");
      // NotificationService().schedulePrayers(...); // مثال
    } else {
      print("تم إيقاف التذكيرات");
      await NotificationService().cancelAllNotifications(); // إيقاف الإشعارات
    }
  }
  
  Future<void> _handleLogout() async {
    await AuthService().signOut();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(lang.t('settings_title'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Stack(
        children: [
          
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/drawerbg.jpg', fit: BoxFit.cover),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.t('general'), style: GoogleFonts.cairo(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // 1️⃣ خيار اللغة
                _buildSettingItem(
                  icon: Icons.language, 
                  title: lang.t('lang_title'), 
                  subtitle: _getLangName(lang.currentLang),
                  onTap: () => _showLanguageDialog(context),
                  showArrow: true,
                ),

                const SizedBox(height: 15),

                // 2️⃣ ✅ خيار التذكير بمواعيد الصلاة (Switch)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SwitchListTile(
                    activeColor: Colors.amber, // لون الزر عند التفعيل
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    secondary: Icon(_isReminderOn ? Icons.notifications_active : Icons.notifications_off, color: _isReminderOn ? Colors.amber : Colors.grey),
                    title: Text(
                      // تأكد من إضافة 'prayer_reminders' في ملف الترجمة أو استعمل نص مباشر مؤقتاً
                      lang.t('prayer_reminders'), 
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                    subtitle: Text(
                      _isReminderOn ? "مفعل" : "معطل", // يمكنك ترجمتها أيضاً
                      style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                    ),
                    value: _isReminderOn,
                    onChanged: _toggleReminder, // استدعاء دالة التغيير
                  ),
                ),
                
                const SizedBox(height: 30),
                Text(lang.t('account'), style: GoogleFonts.cairo(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // زر تسجيل الخروج
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(lang.t('logout'), style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                       showDialog(
                         context: context, 
                         builder: (ctx) => AlertDialog(
                           backgroundColor: Colors.grey.shade900,
                           title: Text(lang.t('logout'), style: GoogleFonts.cairo(color: Colors.white)),
                           content: Text(lang.t('logout_confirm'), style: GoogleFonts.cairo(color: Colors.white70)),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.t('cancel'), style: const TextStyle(color: Colors.grey))),
                             TextButton(onPressed: () {
                               Navigator.pop(ctx);
                               _handleLogout();
                             }, child: Text(lang.t('exit'), style: const TextStyle(color: Colors.red))),
                           ],
                         )
                       );
                    },
                  ),
                ),
                
                const Spacer(),
                Center(child: Text(lang.t('version'), style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // قمت بتعديل الـ Widget لاستقبال showArrow للتحكم في ظهور السهم
  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool showArrow = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: GoogleFonts.cairo(color: Colors.white)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
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
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.t('lang_title'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
      title: Text(name, style: GoogleFonts.cairo(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.amber) : null,
      onTap: () {
        lang.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}