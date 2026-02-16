import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:muslim_way/auth_service.dart';
import 'package:muslim_way/auth_wrapper.dart';
import 'package:muslim_way/providers/language_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  
  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  // دالة مساعدة باش نعرفو سمية اللغة الحالية للعرض
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
                
                _buildSettingItem(
                  icon: Icons.language, 
                  title: lang.t('lang_title'), 
                  subtitle: _getLangName(lang.currentLang), // هنا كتطلع اللغة المختارة
                  onTap: () => _showLanguageDialog(context),
                ),
                
                const SizedBox(height: 30),
                Text(lang.t('account'), style: GoogleFonts.cairo(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

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
                // زيد هاد الزر فين ما بغيتي فشي صفحة
// ElevatedButton(
//   onPressed: () async {
//     await NotificationService().showImmediateNotification(
//       "تجربة", 
//       "واش وصلك هاد الإشعار؟"
//     );
//   },
//   child: Text("جرب الإشعار دابا"),
// )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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
              
              // 🇸🇦 العربية
              _buildLangOption(context, lang, 'العربية', 'ar'),
              const Divider(color: Colors.white24),

              // 🇺🇸 English
              _buildLangOption(context, lang, 'English', 'en'),
              const Divider(color: Colors.white24),

              // 🇫🇷 Français
              _buildLangOption(context, lang, 'Français', 'fr'),
              const Divider(color: Colors.white24),

              // 🇲🇦 الدارجة
              _buildLangOption(context, lang, 'الدارجة 🇲🇦', 'da'),
              
              const SizedBox(height: 20),
            ],

          ),
        );
      },
    );
  }

  // ودجت صغيرة للاختصارات
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