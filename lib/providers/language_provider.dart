import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLang = 'ar';

  String get currentLang => _currentLang;

  final Map<String, Map<String, String>> _localizedValues = {
    // 🇸🇦 العربية
    'ar': {
      // General & App Structure
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
      
      // Finance & Tasks Categories (المفاتيح)
      'cat_food': 'أكل',
      'cat_transport': 'مواصلات',
      'cat_shopping': 'تسوق',
      'cat_salary': 'راتب',
      'cat_bills': 'فواتير',
      'cat_health': 'صحة',
      'cat_personal': 'شخصي',
      'cat_work': 'عمل',
      'cat_religion': 'دين',
      'cat_study': 'دراسة',
      'cat_other': 'أخرى',

      // Finance UI
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
      
      // Notes & Tasks UI
      'my_tasks': 'مهامي وأفكاري',
      'add_task': 'مهمة جديدة',
      'task_title_hint': 'ماذا تريد أن تنجز؟',
      'task_type': 'نوع المهمة',
      'daily_habit': 'عادة يومية',
      'one_time_task': 'مهمة مرة واحدة',
      'set_reminder': 'ضبط تذكير',
      'reminder_set': 'تم ضبط التذكير على',
      'delete_task_title': 'مسح الملاحظة؟',
      'delete_task_ask': 'هل أنت متأكد أنك تريد حذف هذه المهمة؟',
      'empty_notes': 'لا توجد مهام حالياً',
      
      // Time
      'today': 'اليوم',
      'yesterday': 'الأمس',
      'at': 'على الساعة',
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
      
      // Categories
      'cat_food': 'Food',
      'cat_transport': 'Transport',
      'cat_shopping': 'Shopping',
      'cat_salary': 'Salary',
      'cat_bills': 'Bills',
      'cat_health': 'Health',
      'cat_personal': 'Personal',
      'cat_work': 'Work',
      'cat_religion': 'Religion',
      'cat_study': 'Study',
      'cat_other': 'Other',

      // Finance UI
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

      // Notes UI
      'my_tasks': 'My Tasks & Ideas',
      'add_task': 'New Task',
      'task_title_hint': 'What do you want to do?',
      'task_type': 'Task Type',
      'daily_habit': 'Daily Habit',
      'one_time_task': 'One-time Task',
      'set_reminder': 'Set Reminder',
      'reminder_set': 'Reminder set for',
      'delete_task_title': 'Delete Note?',
      'delete_task_ask': 'Delete this task?',
      'empty_notes': 'No tasks yet',
      
      // Time
      'today': 'Today',
      'yesterday': 'Yesterday',
      'at': 'at',
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
      
      // Categories
      'cat_food': 'Nourriture',
      'cat_transport': 'Transport',
      'cat_shopping': 'Achats',
      'cat_salary': 'Salaire',
      'cat_bills': 'Factures',
      'cat_health': 'Santé',
      'cat_personal': 'Personnel',
      'cat_work': 'Travail',
      'cat_religion': 'Religion',
      'cat_study': 'Études',
      'cat_other': 'Autre',
      
      // Finance UI
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

      // Notes UI
      'my_tasks': 'Mes Tâches',
      'add_task': 'Nouvelle Tâche',
      'task_title_hint': 'Que voulez-vous faire ?',
      'task_type': 'Type de tâche',
      'daily_habit': 'Habitude Quotidienne',
      'one_time_task': 'Tâche Unique',
      'set_reminder': 'Définir un rappel',
      'reminder_set': 'Rappel défini pour',
      'delete_task_title': 'Supprimer la note ?',
      'delete_task_ask': 'Supprimer cette tâche ?',
      'empty_notes': 'Aucune tâche',
      
      // Time
      'today': 'Aujourd\'hui',
      'yesterday': 'Hier',
      'at': 'à',
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
      
      // Categories
      'cat_food': 'ماكلة',
      'cat_transport': 'طرقان',
      'cat_shopping': 'تقضية',
      'cat_salary': 'مانضة',
      'cat_bills': 'الماء والضو',
      'cat_health': 'طبيب',
      'cat_personal': 'ديالي',
      'cat_work': 'خدمة',
      'cat_religion': 'دين',
      'cat_study': 'قراية',
      'cat_other': 'شي حاجة أخرى',
      
      // Finance UI
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

      // Notes UI
      'my_tasks': 'التقياد والملاحظات',
      'add_task': 'زيد ملاحظة',
      'task_title_hint': 'شنو باغي دير؟',
      'task_type': 'نوع المهمة',
      'daily_habit': 'عادة يومية (ديما)',
      'one_time_task': 'مهمة مرة وحدة',
      'set_reminder': 'فكرني فالوقت',
      'reminder_set': 'غانفكرك مع',
      'delete_task_title': 'تمسح هادي؟',
      'delete_task_ask': 'واش متأكد باغي تمسحها؟',
      'empty_notes': 'ما عندك حتى ملاحظة',
      
      // Time
      'today': 'اليوم',
      'yesterday': 'البارح',
      'at': 'مع',
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