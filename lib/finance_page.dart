import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<UserDataProvider>();
      await provider.fetchData();

      if (provider.salary == 0 &&
          provider.balance == 0 &&
          provider.transactions.isEmpty &&
          !provider.isLoading) {
        if (mounted) _showInitialBalanceDialog();
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // Dialog: تعديل الرصيد الحالي + الدخل الشهري
  // ─────────────────────────────────────────────────────────
  void _editSalaryDialog() {
    final lang     = context.read<LanguageProvider>();
    final provider = context.read<UserDataProvider>();

    final balanceController = TextEditingController(
      text: provider.balance > 0 ? provider.balance.toStringAsFixed(0) : "",
    );
    final salaryController = TextEditingController(
      text: provider.salary > 0 ? provider.salary.toStringAsFixed(0) : "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          lang.t('edit_balance_title'),
          style: AppFonts.mainStyle(
            context: context, listen: false,
            color: AppColors.accent, fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── الرصيد الحالي ──────────────────────────
            _FieldLabel(
              icon: Icons.account_balance_wallet_rounded,
              label: lang.t('current_balance'),
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            _AmountField(controller: balanceController),

            const SizedBox(height: 20),

            // ── الدخل الشهري ───────────────────────────
            _FieldLabel(
              icon: Icons.calendar_month_rounded,
              label: lang.t('monthly_salary'),
              color: Colors.greenAccent,
              subtitle: lang.t('monthly_salary_desc'),
            ),
            const SizedBox(height: 8),
            _AmountField(controller: salaryController, accentColor: Colors.greenAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.t('cancel'),
              style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final newBalance = double.tryParse(balanceController.text);
              final newSalary  = double.tryParse(salaryController.text);

              if (newBalance != null) await provider.updateBalanceOnly(newBalance);
              if (newSalary  != null) await provider.updateSalaryOnly(newSalary);

              Navigator.pop(ctx);
              if (mounted) _showSuccessSnack(lang.t('success_update'));
            },
            child: Text(
              lang.t('save'),
              style: AppFonts.mainStyle(
                context: context, listen: false,
                color: Colors.white, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Dialog: الرصيد الأولي (أول مرة)
  // ─────────────────────────────────────────────────────────
  void _showInitialBalanceDialog() {
    final lang              = context.read<LanguageProvider>();
    final balanceController = TextEditingController();
    final salaryController  = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          lang.t('start_balance_ask'),
          style: AppFonts.mainStyle(
            context: context, listen: false,
            color: AppColors.accent, fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FieldLabel(
              icon: Icons.account_balance_wallet_rounded,
              label: lang.t('current_balance'),
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            _AmountField(controller: balanceController),

            const SizedBox(height: 20),

            _FieldLabel(
              icon: Icons.calendar_month_rounded,
              label: lang.t('monthly_salary'),
              color: Colors.greenAccent,
              subtitle: lang.t('monthly_salary_desc'),
            ),
            const SizedBox(height: 8),
            _AmountField(controller: salaryController, accentColor: Colors.greenAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.t('skip'),
              style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final newBalance = double.tryParse(balanceController.text);
              final newSalary  = double.tryParse(salaryController.text);
              final provider   = context.read<UserDataProvider>();

              if (newBalance != null) await provider.updateBalanceOnly(newBalance);
              if (newSalary  != null) await provider.updateSalaryOnly(newSalary);

              Navigator.pop(ctx);
            },
            child: Text(
              lang.t('start'),
              style: AppFonts.mainStyle(
                context: context, listen: false,
                color: Colors.white, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────
  Map<String, List<String>> _groupTransactionsByMonth(List<String> transactions) {
    final grouped = <String, List<String>>{};
    for (var trans in transactions) {
      final parts = trans.split('|');
      if (parts.length > 2) {
        try {
          final date = DateTime.parse(parts[2]);
          final key  = DateFormat('yyyy-MM').format(date);
          grouped.putIfAbsent(key, () => []).add(trans);
        } catch (_) {}
      }
    }
    return grouped;
  }

  String _getLastSnapshotOfMonth(List<String> monthTransactions) {
    for (int i = monthTransactions.length - 1; i >= 0; i--) {
      final parts = monthTransactions[i].split('|');
      if (parts.length > 3 && parts[3] != "--") return parts[3];
    }
    return "--";
  }

  String _formatFullDate(String isoString, String locale) {
    try {
      return DateFormat('dd MMM HH:mm', locale).format(DateTime.parse(isoString));
    } catch (_) {
      return "";
    }
  }

  // ─────────────────────────────────────────────────────────
  // Bottom sheets
  // ─────────────────────────────────────────────────────────
  void _showTransactionOptions(int originalIndex, String transactionData) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            _BottomSheetOption(
              icon: Icons.edit_rounded,
              label: lang.t('save'),
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(ctx);
                showAddTransactionSheet(editIndex: originalIndex, editData: transactionData);
              },
            ),
            const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
            _BottomSheetOption(
              icon: Icons.delete_rounded,
              label: lang.t('delete'),
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (ctx2) => _StyledDialog(
                    title: lang.t('delete'),
                    titleColor: Colors.redAccent,
                    content: Text(
                      lang.t('delete_task_ask'),
                      style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white60),
                    ),
                    cancelText: lang.t('cancel'),
                    confirmText: lang.t('delete'),
                    confirmColor: Colors.redAccent,
                    onCancel: () => Navigator.pop(ctx2),
                    onConfirm: () {
                      context.read<UserDataProvider>().deleteTransaction(originalIndex);
                      Navigator.pop(ctx2);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void showAddTransactionSheet({int? editIndex, String? editData}) {
    final lang = context.read<LanguageProvider>();
    bool isIncome = false;
    final amountController = TextEditingController();
    String selectedCategoryKey = "cat_other";

    if (editData != null) {
      final parts     = editData.split('|');
      final amountStr = parts[0].replaceAll(' ', '');
      isIncome            = amountStr.startsWith('+');
      amountController.text = amountStr.substring(1);
      selectedCategoryKey = parts.length > 1 ? parts[1] : "cat_other";
    }

    const categories = [
      {'icon': Icons.fastfood_rounded,              'key': 'cat_food'},
      {'icon': Icons.directions_bus_rounded,        'key': 'cat_transport'},
      {'icon': Icons.shopping_bag_rounded,          'key': 'cat_shopping'},
      {'icon': Icons.account_balance_wallet_rounded,'key': 'cat_salary'},
      {'icon': Icons.lightbulb_rounded,             'key': 'cat_bills'},
      {'icon': Icons.health_and_safety_rounded,     'key': 'cat_health'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: 600,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              // Handle
              Container(
                width: 44, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),

              Text(
                editIndex != null ? lang.t('save') : lang.t('add_transaction'),
                style: AppFonts.mainStyle(
                  context: context, listen: false,
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              // Income / Expense toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => isIncome = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: !isIncome ? Colors.redAccent.withOpacity(0.5) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(lang.t('expense'), style: AppFonts.mainStyle(context: context, listen: false, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => isIncome = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.greenAccent.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: isIncome ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward_rounded, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(lang.t('income'), style: AppFonts.mainStyle(context: context, listen: false, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Amount field
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: AppFonts.mainStyle(
                  context: context, listen: false,
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  suffixText: "DH",
                  suffixStyle: AppFonts.mainStyle(context: context, listen: false, color: AppColors.accent, fontSize: 18),
                ),
              ),

              const SizedBox(height: 12),

              // Categories grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final key        = categories[index]['key'] as String;
                    final isSelected = selectedCategoryKey == key;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategoryKey = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.accent.withOpacity(0.6) : Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(categories[index]['icon'] as IconData, color: isSelected ? AppColors.accent : Colors.white38, size: 24),
                            const SizedBox(height: 5),
                            Text(
                              lang.t(key),
                              style: AppFonts.mainStyle(
                                context: context, listen: false,
                                color: isSelected ? AppColors.accent : Colors.white54,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final amount   = double.parse(amountController.text);
                      final provider = context.read<UserDataProvider>();
                      if (editIndex != null) {
                        provider.editTransaction(editIndex, amount, isIncome, selectedCategoryKey);
                      } else {
                        provider.addTransaction(amount, isIncome, selectedCategoryKey);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    lang.t('save'),
                    style: AppFonts.mainStyle(
                      context: context, listen: false,
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang       = context.watch<LanguageProvider>();
    final dateLocale = lang.currentLang == 'da' ? 'ar' : lang.currentLang;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [

              // ── Balance Card ──────────────────────────
              Consumer<UserDataProvider>(
                builder: (context, provider, child) => Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30, right: -30,
                          child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05))),
                        ),
                        Positioned(
                          bottom: -20, left: -10,
                          child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04))),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t('current_balance'),
                                    style: AppFonts.mainStyle(context: context, color: Colors.white60, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        provider.balance.toStringAsFixed(2),
                                        style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6, left: 6),
                                        child: Text(
                                          "DH",
                                          style: AppFonts.mainStyle(context: context, color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // ✅ الدخل الشهري تحت الرصيد
                                  if (provider.salary > 0) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_month_rounded, size: 11, color: Colors.greenAccent.withOpacity(0.8)),
                                          const SizedBox(width: 5),
                                          Text(
                                            "${provider.salary.toStringAsFixed(0)} DH / ${lang.t('month')}",
                                            style: AppFonts.mainStyle(context: context, color: Colors.greenAccent.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Settings button
                              GestureDetector(
                                onTap: _editSalaryDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white24, width: 1),
                                  ),
                                  child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Header Row ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.t('recent_transactions'),
                      style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => showAddTransactionSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, color: AppColors.accent, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              lang.t('add_transaction'),
                              style: AppFonts.mainStyle(context: context, color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Transactions List ─────────────────────
              Expanded(
                child: Consumer<UserDataProvider>(
                  builder: (context, provider, child) {
                    final grouped   = _groupTransactionsByMonth(provider.transactions);
                    final monthKeys = grouped.keys.toList();

                    if (monthKeys.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.white12),
                            const SizedBox(height: 12),
                            Text(lang.t('no_expenses'), style: AppFonts.mainStyle(context: context, color: Colors.white24, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: monthKeys.length,
                      cacheExtent: 500,
                      itemBuilder: (context, sectionIndex) {
                        final monthKey    = monthKeys[sectionIndex];
                        final monthTrans  = grouped[monthKey]!;
                        final lastSnapshot = _getLastSnapshotOfMonth(monthTrans);
                        final monthName   = DateFormat('MMMM yyyy', dateLocale).format(
                          DateFormat('yyyy-MM').parse(monthKey),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month header
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        monthName,
                                        style: AppFonts.mainStyle(context: context, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  if (lastSnapshot != "--")
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          lang.t('current_balance'),
                                          style: AppFonts.mainStyle(context: context, color: Colors.white30, fontSize: 10),
                                        ),
                                        Text(
                                          "$lastSnapshot DH",
                                          style: AppFonts.mainStyle(context: context, color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Transactions
                            ...monthTrans.map((transData) {
                              final parts       = transData.split('|');
                              final amountType  = parts[0];
                              final catKey      = parts.length > 1 ? parts[1] : "cat_other";
                              final dateStr     = parts.length > 2 ? parts[2] : "";
                              final snapshot    = parts.length > 3 ? parts[3] : "--";
                              final isIncome    = amountType.contains("+");
                              final originalIndex = provider.transactions.indexOf(transData);
                              final amountColor = isIncome ? Colors.greenAccent : Colors.redAccent;

                              return GestureDetector(
                                onLongPress: () => _showTransactionOptions(originalIndex, transData),
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(color: amountColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: amountColor, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(lang.t(catKey), style: AppFonts.mainStyle(context: context, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                            const SizedBox(height: 3),
                                            Text(_formatFullDate(dateStr, dateLocale), style: AppFonts.mainStyle(context: context, color: Colors.white30, fontSize: 11)),
                                            if (snapshot != "--") ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                "${lang.t('current_balance')}: $snapshot DH",
                                                style: AppFonts.mainStyle(context: context, color: AppColors.accent.withOpacity(0.7), fontSize: 10),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: amountColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                        child: Text(amountType, style: AppFonts.mainStyle(context: context, color: amountColor, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? subtitle;

  const _FieldLabel({required this.icon, required this.label, required this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppFonts.mainStyle(context: context, listen: false, color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            if (subtitle != null)
              Text(subtitle!, style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white30, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color? accentColor;

  const _AmountField({required this.controller, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accent;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: "0.00",
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 1.5)),
        suffixText: "DH",
        suffixStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _StyledDialog extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget content;
  final String cancelText;
  final String confirmText;
  final Color? confirmColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _StyledDialog({
    required this.title, required this.titleColor, required this.content,
    required this.cancelText, required this.confirmText,
    required this.onCancel, required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: AppFonts.mainStyle(context: context, listen: false, color: titleColor, fontWeight: FontWeight.bold)),
      content: content,
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelText, style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: onConfirm,
          child: Text(confirmText, style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}