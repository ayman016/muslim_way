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
      'stats': 'إحصائيات',
      'lang_title': 'لغة التطبيق',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد أنك تريد الخروج؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'save': 'حفظ',
      'update': 'تحديث',
      'edit': 'تعديل',
      'confirm_delete': 'تأكيد الحذف',
      
      // Categories
      'cat_food': 'أكل وشرب',
      'cat_transport': 'مواصلات',
      'cat_shopping': 'تسوق',
      'cat_salary': 'الراتب',
      'cat_bills': 'فواتير',
      'cat_health': 'صحة',
      'cat_personal': 'شخصي',
      'cat_work': 'عمل',
      'cat_religion': 'دين',
      'cat_study': 'دراسة',
      'cat_other': 'أخرى',

      // Finance UI
      'current_balance': 'الرصيد الحالي',
      'budget_spent': 'المتبقي',
      'add_transaction': 'إضافة معاملة',
      'recent_transactions': 'آخر المعاملات',
      'income': 'دخل',
      'expense': 'مصروف',
      'start_balance_title': 'مرحباً بك',
      'start_balance_ask': 'كم هو رصيدك الحالي؟',
      'salary_dialog_title': 'تعديل الدخل الشهري',
      'salary_hint': 'أدخل الراتب هنا',
      'start': 'بدء',
      'skip': 'تخطي',
      'empty_finance': 'لا توجد معاملات بعد',
      'edit_balance_title': 'تعديل الرصيد الحالي',
      'edit_balance_desc': 'سيتم تحديث رصيدك وراتبك لهذه القيمة.',
      'success_update': 'تم التحديث بنجاح',

      // Stats UI (جديد)
      'overview': 'نظرة عامة',
      'monthly_budget': 'الميزانية الشهرية',
      'expense_breakdown': 'أين تذهب أموالك؟',
      'productivity': 'الإنتاجية اليومية',
      'completed_today': 'تمت اليوم',
      'remaining': 'متبقية',
      'total': 'المجموع الكلي',
      'spent_ratio': 'استهلكت',
      'salary_not_set': 'لم يتم تحديد الراتب',
      'no_expenses': 'لا توجد مصاريف هذا الشهر',
      'no_tasks_stats': 'البيانات غير كافية للتحليل',

      // Notes & Tasks UI
      'my_tasks': 'مهامي',
      'add_task': 'مهمة جديدة',
      'edit_task': 'تعديل المهمة',
      'task_title_hint': 'ماذا تريد أن تنجز؟',
      'daily_habit': 'عادة يومية',
      'one_time_task': 'مهمة عادية',
      'set_reminder': 'ضبط تذكير',
      'task_done_today': '✅ المهمة منجزة اليوم',
      'mark_as_done': 'تحديد المهمة كمنجزة',
      'delete_task_ask': 'هل أنت متأكد من حذف هذه المهمة نهائياً؟',
      'empty_notes': 'لا توجد مهام حالياً',
      
      // Time
      'today': 'اليوم',
      'yesterday': 'الأمس',

      'qibla_direction': 'اتجاه القبلة',
  'enable_gps_msg': 'المرجو تفعيل GPS لتحديد القبلة',
  'enable_gps': 'تفعيل GPS',
  'degree_to_kaaba': 'درجة نحو الكعبة',
  'searching_location': 'جاري البحث عن الموقع...',
  'device_not_supported': 'جهازك لا يدعم البوصلة',
  'error': 'خطأ',
    },
    
    // 🇺🇸 English
    'en': {
      // General
      'settings_title': 'Settings',
      'home': 'Home',
      'prayers': 'Prayers',
      'finance': 'Finance',
      'notes': 'Tasks',
      'stats': 'Stats',
      'lang_title': 'Language',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'update': 'Update',
      'edit': 'Edit',
      'confirm_delete': 'Confirm Delete',
      
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

      //qibla 
      'qibla_direction': 'Qibla Direction',
  'enable_gps_msg': 'Please enable GPS to find Qibla',
  'enable_gps': 'Enable GPS',
  'degree_to_kaaba': 'degrees to Kaaba',
  'searching_location': 'Searching for location...',
  'device_not_supported': 'Device not supported',
  'error': 'Error',

      // Finance UI
      'current_balance': 'Current Balance',
      'budget_spent': 'Remaining',
      'add_transaction': 'Add Transaction',
      'recent_transactions': 'Recent Transactions',
      'income': 'Income',
      'expense': 'Expense',
      'start_balance_title': 'Welcome',
      'start_balance_ask': 'What is your current balance?',
      'salary_dialog_title': 'Edit Monthly Salary',
      'salary_hint': 'Enter salary here',
      'start': 'Start',
      'skip': 'Skip',
      'empty_finance': 'No transactions yet',
      'edit_balance_title': 'Edit Current Balance',
      'edit_balance_desc': 'Your balance and salary will be updated.',
      'success_update': 'Updated successfully',

      // Stats UI
      'overview': 'Overview',
      'monthly_budget': 'Monthly Budget',
      'expense_breakdown': 'Where your money goes?',
      'productivity': 'Daily Productivity',
      'completed_today': 'Done Today',
      'remaining': 'Remaining',
      'total': 'Total',
      'spent_ratio': 'Spent',
      'salary_not_set': 'Salary not set',
      'no_expenses': 'No expenses this month',
      'no_tasks_stats': 'Not enough data to analyze',

      // Notes UI
      'my_tasks': 'My Tasks',
      'add_task': 'New Task',
      'edit_task': 'Edit Task',
      'task_title_hint': 'What do you want to do?',
      'daily_habit': 'Daily Habit',
      'one_time_task': 'One-time Task',
      'set_reminder': 'Set Reminder',
      'task_done_today': '✅ Done Today',
      'mark_as_done': 'Mark as Done',
      'delete_task_ask': 'Are you sure you want to delete this task?',
      'empty_notes': 'No tasks yet',
      
      // Time
      'today': 'Today',
      'yesterday': 'Yesterday',
    },

    // 🇫🇷 Français
    'fr': {
      // General
      'settings_title': 'Paramètres',
      'home': 'Accueil',
      'prayers': 'Prières',
      'finance': 'Finance',
      'notes': 'Tâches',
      'stats': 'Stats',
      'lang_title': 'Langue',
      'logout': 'Déconnexion',
      'logout_confirm': 'Voulez-vous vraiment vous déconnecter ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'save': 'Enregistrer',
      'update': 'Mettre à jour',
      'edit': 'Modifier',
      'confirm_delete': 'Confirmer la suppression',
      
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
      'budget_spent': 'Restant',
      'add_transaction': 'Ajouter Transaction',
      'recent_transactions': 'Transactions Récentes',
      'income': 'Revenu',
      'expense': 'Dépense',
      'start_balance_title': 'Bienvenue',
      'start_balance_ask': 'Quel est votre solde actuel ?',
      'salary_dialog_title': 'Modifier le Salaire',
      'salary_hint': 'Entrez le salaire ici',
      'start': 'Commencer',
      'skip': 'Passer',
      'empty_finance': 'Aucune transaction',
      'edit_balance_title': 'Modifier le Solde',
      'edit_balance_desc': 'Votre solde et salaire seront mis à jour.',
      'success_update': 'Mis à jour avec succès',
      //qibla 
      'qibla_direction': 'Direction Qibla',
  'enable_gps_msg': 'Veuillez activer le GPS',
  'enable_gps': 'Activer GPS',
  'degree_to_kaaba': 'degrés vers la Kaaba',
  'searching_location': 'Recherche de position...',
  'device_not_supported': 'Appareil non supporté',
  'error': 'Erreur',

      // Stats UI
      'overview': 'Aperçu',
      'monthly_budget': 'Budget Mensuel',
      'expense_breakdown': 'Où va votre argent ?',
      'productivity': 'Productivité',
      'completed_today': 'Fait aujourd\'hui',
      'remaining': 'Restant',
      'total': 'Total',
      'spent_ratio': 'Dépensé',
      'salary_not_set': 'Salaire non défini',
      'no_expenses': 'Aucune dépense ce mois',
      'no_tasks_stats': 'Pas assez de données',

      // Notes UI
      'my_tasks': 'Mes Tâches',
      'add_task': 'Nouvelle Tâche',
      'edit_task': 'Modifier Tâche',
      'task_title_hint': 'Que voulez-vous faire ?',
      'daily_habit': 'Habitude Quotidienne',
      'one_time_task': 'Tâche Unique',
      'set_reminder': 'Définir un rappel',
      'task_done_today': '✅ Fait aujourd\'hui',
      'mark_as_done': 'Marquer comme fait',
      'delete_task_ask': 'Supprimer cette tâche définitivement ?',
      'empty_notes': 'Aucune tâche',
      
      // Time
      'today': 'Aujourd\'hui',
      'yesterday': 'Hier',
    },

    // 🇲🇦 الدارجة
    'da': {
      // General
      'settings_title': 'الإعدادات',
      'home': 'الرئيسية',
      'prayers': 'صلاتي',
      'finance': 'فلوسي',
      'notes': 'مذكراتي',
      'stats': 'الإحصائيات',
      'lang_title': 'اللغة',
      'logout': 'خرج من الحساب',
      'logout_confirm': 'واش بصح بغيتي تخرج؟',
      'cancel': 'رجع',
      'delete': 'مسح',
      'save': 'سجل',
      'update': 'بدل',
      'edit': 'عدل',
      'confirm_delete': 'أكد المسح',
      
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
      //qibla 
      'qibla_direction': 'اتجاه القبلة',
  'enable_gps_msg': 'شعل GPS باش تلقى القبلة',
  'enable_gps': 'شعل GPS',
  'degree_to_kaaba': 'درجة للكعبة',
  'searching_location': 'كانقلب على البلاصة...',
  'device_not_supported': 'تلفونك ما فيهش البوصلة',
  'error': 'مشكل',
      
      // Finance UI
      'current_balance': 'شحال عندي',
      'budget_spent': 'شحال بقى',
      'add_transaction': 'زيد شي حاجة',
      'recent_transactions': 'فين خسرتي فلوسك',
      'income': 'دخل',
      'expense': 'مصروف',
      'start_balance_title': 'مرحباً بك فـ فلوسي',
      'start_balance_ask': 'بشحال باغي تبدا الرصيد؟',
      'salary_dialog_title': 'عدل المانضة الشهرية',
      'salary_hint': 'كتب المانضة هنا',
      'start': 'بدا',
      'skip': 'دوز',
      'empty_finance': 'مازال ما دخلتي والو',
      'edit_balance_title': 'عدل الرصيد الحالي',
      'edit_balance_desc': 'غادي يتبدل الرصيد والمانضة بجوج.',
      'success_update': 'تصايبات بنجاح',

      // Stats UI
      'overview': 'نظرة عامة',
      'monthly_budget': 'الميزانية د الشهر',
      'expense_breakdown': 'فين كتمشي فلوسك؟',
      'productivity': 'الجهد ديال اليوم',
      'completed_today': 'ساليتي اليوم',
      'remaining': 'بقات ليك',
      'total': 'المجموع',
      'spent_ratio': 'خسرتي',
      'salary_not_set': 'ماحددتيش المانضة',
      'no_expenses': 'ما خسرتي والو هاد الشهر',
      'no_tasks_stats': 'معندكش داتا كافية',

      // Notes UI
      'my_tasks': ' الملاحظات',
      'add_task': 'زيد ملاحظة',
      'edit_task': 'عدل الملاحظة',
      'task_title_hint': 'شنو باغي دير؟',
      'daily_habit': 'عادة يومية (ديما)',
      'one_time_task': 'مهمة مرة وحدة',
      'set_reminder': 'فكرني فالوقت',
      'task_done_today': '✅ ناضي، ساليتيها اليوم',
      'mark_as_done': 'صافي ساليتها',
      'delete_task_ask': 'واش متأكد باغي تمسحها بمرة؟',
      'empty_notes': 'ما عندك حتى ملاحظة',
      
      // Time
      'today': 'اليوم',
      'yesterday': 'البارح',
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