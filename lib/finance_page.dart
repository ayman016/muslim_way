import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart';

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

  void _editSalaryDialog() {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<UserDataProvider>(); 
    
    final controller = TextEditingController(
      text: provider.balance > 0 ? provider.balance.toStringAsFixed(0) : "",
    );
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(lang.t('edit_balance_title'), style: const TextStyle(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.t('edit_balance_desc'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 2)),
                suffixText: "DH",
                suffixStyle: TextStyle(color: AppColors.accent)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                double newAmount = double.parse(controller.text);
                await provider.updateSalary(newAmount);
                Navigator.pop(ctx);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.t('success_update'), style: GoogleFonts.cairo()), backgroundColor: Colors.green)
                  );
                }
              }
            },
            child: Text(lang.t('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showInitialBalanceDialog() {
    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(lang.t('start_balance_ask'), style: const TextStyle(color: AppColors.primary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "0.00",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.t('skip'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final amount = double.parse(controller.text);
                context.read<UserDataProvider>().updateSalary(amount);
                Navigator.pop(ctx);
              }
            },
            child: Text(lang.t('start'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Map<String, List<String>> _groupTransactionsByMonth(List<String> transactions) {
    final grouped = <String, List<String>>{};
    for (var trans in transactions) {
      final parts = trans.split('|');
      if (parts.length > 2) {
        try {
          final date = DateTime.parse(parts[2]);
          final key = DateFormat('yyyy-MM').format(date);
          grouped.putIfAbsent(key, () => []).add(trans);
        } catch (_) {}
      }
    }
    return grouped;
  }

  double _calculateMonthlySavings(List<String> monthTransactions) {
    double income = 0.0, expense = 0.0;
    for (var trans in monthTransactions) {
      final parts = trans.split('|');
      final amountStr = parts[0].replaceAll(' ', '');
      final amount = double.tryParse(amountStr.substring(1)) ?? 0.0;
      if (amountStr.startsWith('+')) {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return income - expense;
  }
  
  void _showTransactionOptions(int originalIndex, String transactionData) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: 200,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: Text(lang.t('save'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showAddTransactionSheet(editIndex: originalIndex, editData: transactionData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(lang.t('delete'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(lang.t('delete'), style: const TextStyle(color: Colors.white)),
                    content: Text(lang.t('delete_task_ask'), style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx2), child: Text(lang.t('cancel'))),
                      TextButton(
                        onPressed: () {
                          context.read<UserDataProvider>().deleteTransaction(originalIndex);
                          Navigator.pop(ctx2);
                        },
                        child: Text(lang.t('delete'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
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
      final parts = editData.split('|');
      final amountStr = parts[0].replaceAll(' ', '');
      isIncome = amountStr.startsWith('+');
      amountController.text = amountStr.substring(1);
      selectedCategoryKey = parts.length > 1 ? parts[1] : "cat_other";
    }
    
    const categories = [
      {'icon': Icons.fastfood, 'key': 'cat_food'},
      {'icon': Icons.directions_bus, 'key': 'cat_transport'},
      {'icon': Icons.shopping_bag, 'key': 'cat_shopping'},
      {'icon': Icons.work, 'key': 'cat_salary'},
      {'icon': Icons.lightbulb, 'key': 'cat_bills'},
      {'icon': Icons.health_and_safety, 'key': 'cat_health'}
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(height: 5, width: 50, color: Colors.grey, margin: const EdgeInsets.only(bottom: 20)),
              Text(editIndex != null ? lang.t('save') : lang.t('add_transaction'), style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isIncome ? Colors.red.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(lang.t('expense'), style: const TextStyle(color: Colors.red))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isIncome ? Colors.green.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(lang.t('income'), style: const TextStyle(color: Colors.green))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 30),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final key = categories[index]['key'] as String;
                    final isSelected = selectedCategoryKey == key;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategoryKey = key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(categories[index]['icon'] as IconData, color: isSelected ? Colors.black : Colors.white),
                            Text(lang.t(key), style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final amount = double.parse(amountController.text);
                      final provider = context.read<UserDataProvider>();
                      if (editIndex != null) provider.editTransaction(editIndex, amount, isIncome, selectedCategoryKey);
                      else provider.addTransaction(amount, isIncome, selectedCategoryKey);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(lang.t('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ الدالة المساعدة مع إصلاح التاريخ
  String _formatFullDate(String isoString, String locale) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM HH:mm', locale).format(date);
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>();
    
    // ✅ إصلاح التاريخ للدارجة
    final String dateLocale = lang.currentLang == 'da' ? 'ar' : lang.currentLang;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Consumer<UserDataProvider>(
                builder: (context, provider, child) => Container(
                  margin: const EdgeInsets.all(20),
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang.t('current_balance'),
                              style: const TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                            Text(
                              "${provider.balance.toStringAsFixed(2)} DH",
                              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white54),
                          onPressed: _editSalaryDialog,
                          tooltip: lang.t('cat_salary'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => showAddTransactionSheet(),
                      icon: const Icon(Icons.add_circle, color: AppColors.accent, size: 30),
                    ),
                    Text(
                      lang.t('recent_transactions'),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Consumer<UserDataProvider>(
                  builder: (context, provider, child) {
                    final grouped = _groupTransactionsByMonth(provider.transactions);
                    final monthKeys = grouped.keys.toList();

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: monthKeys.length,
                      cacheExtent: 500,
                      itemBuilder: (context, sectionIndex) {
                        final monthKey = monthKeys[sectionIndex];
                        final monthTrans = grouped[monthKey]!;
                        final monthlySavings = _calculateMonthlySavings(monthTrans);
                        
                        // ✅ تطبيق إصلاح التاريخ هنا
                        final monthName = DateFormat('MMMM yyyy', dateLocale).format(
                          DateFormat('yyyy-MM').parse(monthKey),
                        );

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "📅 $monthName",
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(lang.t('budget_spent') + ":", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text(
                                        "${monthlySavings > 0 ? '+' : ''}${monthlySavings.toStringAsFixed(0)} DH",
                                        style: TextStyle(
                                          color: monthlySavings >= 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            ...monthTrans.map((transData) {
                              final parts = transData.split('|');
                              final amountType = parts[0];
                              final catKey = parts.length > 1 ? parts[1] : "cat_other";
                              final dateStr = parts.length > 2 ? parts[2] : "";
                              final snapshot = parts.length > 3 ? parts[3] : "--";
                              final isIncome = amountType.contains("+");
                              final originalIndex = provider.transactions.indexOf(transData);

                              return GestureDetector(
                                onLongPress: () => _showTransactionOptions(originalIndex, transData),
                                child: Card(
                                  color: AppColors.surface.withOpacity(0.5),
                                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                  child: ListTile(
                                    leading: Icon(
                                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isIncome ? Colors.green : Colors.red,
                                    ),
                                    title: Text(lang.t(catKey), style: const TextStyle(color: Colors.white)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ✅ وتطبيق إصلاح التاريخ هنا أيضاً
                                        Text(_formatFullDate(dateStr, dateLocale), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        if (snapshot != "--")
                                          Text("${lang.t('current_balance')}: $snapshot DH", style: const TextStyle(color: AppColors.accent, fontSize: 10)),
                                      ],
                                    ),
                                    trailing: Text(
                                      amountType,
                                      style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontSize: 18),
                                    ),
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