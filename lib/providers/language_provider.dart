import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLang = 'ar';

  String get currentLang => _currentLang;

  final Map<String, Map<String, String>> _localizedValues = {
    // 🇸🇦 العربية
    'ar': {
      // General
      'settings_title': 'الإعدادات',
      'home': 'الرئيسية',
      'prayers': 'صلاتي',
      'finance': 'مالي',
      'notes': 'أفكاري',
      'lang_title': 'لغة التطبيق',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد أنك تريد الخروج؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'save': 'حفظ',
      'exit': 'خروج',
      'general': 'عام',
      'account': 'الحساب',
      'version': 'الإصدار 1.0.0',
      'qibla': 'اتجاه القبلة',
      'quran': 'القرآن الكريم',
      
      // Finance
      'current_balance': 'الرصيد الحالي',
      'money_quote': 'المال زينة الحياة الدنيا',
      'add_transaction': 'إضافة معاملة',
      'recent_transactions': 'آخر المعاملات',
      'income': 'دخل',
      'expense': 'مصروف',
      'start_balance_title': 'مرحباً بك في قسم المال',
      'start_balance_ask': 'كم هو رصيدك الحالي لتبدأ به؟',
      'start': 'بدء',
      'skip': 'تخطي',
      'empty_finance': 'لا توجد معاملات بعد',
      
      // Notes
      'my_tasks': 'مهامي وأفكاري',
      'add_task': 'مهمة جديدة',
      'delete_task_title': 'مسح الملاحظة؟',
      'delete_task_ask': 'هل أنت متأكد أنك تريد حذف هذه المهمة؟',
      'empty_notes': 'لا توجد مهام حالياً',
    },
    
    // 🇺🇸 English
    'en': {
      'settings_title': 'Settings',
      'home': 'Home',
      'prayers': 'Prayers',
      'finance': 'Finance',
      'notes': 'Notes',
      'lang_title': 'App Language',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'exit': 'Exit',
      'general': 'General',
      'account': 'Account',
      'version': 'Version 1.0.0',
      'qibla': 'Qibla Direction',
      'quran': 'Holy Quran',
      
      // Finance
      'current_balance': 'Current Balance',
      'money_quote': 'Money is the adornment of life',
      'add_transaction': 'Add Transaction',
      'recent_transactions': 'Recent Transactions',
      'income': 'Income',
      'expense': 'Expense',
      'start_balance_title': 'Welcome to Finance',
      'start_balance_ask': 'What is your current balance?',
      'start': 'Start',
      'skip': 'Skip',
      'empty_finance': 'No transactions yet',

      // Notes
      'my_tasks': 'My Tasks & Ideas',
      'add_task': 'New Task',
      'delete_task_title': 'Delete Note?',
      'delete_task_ask': 'Are you sure you want to delete this task?',
      'empty_notes': 'No tasks yet',
    },

    // 🇫🇷 Français
    'fr': {
      'settings_title': 'Paramètres',
      'home': 'Accueil',
      'prayers': 'Prières',
      'finance': 'Finance',
      'notes': 'Notes',
      'lang_title': 'Langue',
      'logout': 'Déconnexion',
      'logout_confirm': 'Voulez-vous vraiment vous déconnecter ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'save': 'Enregistrer',
      'exit': 'Quitter',
      'general': 'Général',
      'account': 'Compte',
      'version': 'Version 1.0.0',
      'qibla': 'Direction Qibla',
      'quran': 'Saint Coran',
      
      // Finance
      'current_balance': 'Solde Actuel',
      'money_quote': 'L\'argent est la parure de la vie',
      'add_transaction': 'Ajouter Transaction',
      'recent_transactions': 'Transactions Récentes',
      'income': 'Revenu',
      'expense': 'Dépense',
      'start_balance_title': 'Bienvenue',
      'start_balance_ask': 'Quel est votre solde actuel ?',
      'start': 'Commencer',
      'skip': 'Passer',
      'empty_finance': 'Aucune transaction',

      // Notes
      'my_tasks': 'Mes Tâches',
      'add_task': 'Nouvelle Tâche',
      'delete_task_title': 'Supprimer la note ?',
      'delete_task_ask': 'Êtes-vous sûr de vouloir supprimer ?',
      'empty_notes': 'Aucune tâche',
    },

    // 🇲🇦 الدارجة
    'da': {
      'settings_title': 'الإعدادات',
      'home': 'الرئيسية',
      'prayers': 'صلاتي',
      'finance': 'فلوسي',
      'notes': 'مذكراتي',
      'lang_title': 'اللغة',
      'logout': 'خرج من الحساب',
      'logout_confirm': 'واش بصح بغيتي تخرج؟',
      'cancel': 'رجع',
      'delete': 'مسح',
      'save': 'سجل',
      'exit': 'خرج',
      'general': 'عام',
      'account': 'الكونت',
      'version': 'نسخة 1.0.0',
      'qibla': 'القبلة',
      'quran': 'القرآن',
      
      // Finance
      'current_balance': 'شحال عندي',
      'money_quote': 'المال والبنون زينة الحياة',
      'add_transaction': 'زيد شي حاجة',
      'recent_transactions': 'فين خسرتي فلوسك',
      'income': 'دخل',
      'expense': 'مصروف',
      'start_balance_title': 'مرحباً بك فـ فلوسي',
      'start_balance_ask': 'بشحال باغي تبدا الرصيد؟',
      'start': 'بدا',
      'skip': 'دوز',
      'empty_finance': 'مازال ما دخلتي والو',

      // Notes
      'my_tasks': 'التقياد والملاحظات',
      'add_task': 'زيد ملاحظة',
      'delete_task_title': 'تمسح هادي؟',
      'delete_task_ask': 'واش متأكد باغي تمسحها؟',
      'empty_notes': 'ما عندك حتى ملاحظة',
    },
  };

  String t(String key) {
    return _localizedValues[_currentLang]?[key] ?? key;
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString('app_lang') ?? 'ar';
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
    _currentLang = langCode;
    notifyListeners();
  }
}