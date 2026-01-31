import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserDataProvider>(context, listen: false);
      if (provider.balance == 0 && provider.salary == 0 && !provider.isLoading) {
         _showInitialBalanceDialog();
      }
    });
  }

  // 1. تجميع المعاملات حسب الشهر (Grouping)
  Map<String, List<String>> _groupTransactionsByMonth(List<String> transactions) {
    Map<String, List<String>> grouped = {};
    for (var trans in transactions) {
      List<String> parts = trans.split('|');
      if (parts.length > 2) {
        try {
          DateTime date = DateTime.parse(parts[2]);
          String key = DateFormat('yyyy-MM').format(date); // مفتاح: 2024-02
          if (!grouped.containsKey(key)) grouped[key] = [];
          grouped[key]!.add(trans);
        } catch (e) {}
      }
    }
    return grouped;
  }

  // 2. حساب المتبقي لكل شهر
  double _calculateMonthlySavings(List<String> monthTransactions) {
    double income = 0.0;
    double expense = 0.0;
    for (var trans in monthTransactions) {
      List<String> parts = trans.split('|');
      String amountStr = parts[0].replaceAll(' ', '');
      double amount = double.tryParse(amountStr.substring(1)) ?? 0.0;
      if (amountStr.startsWith('+')) income += amount; else expense += amount;
    }
    return income - expense;
  }

  void _showInitialBalanceDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final provider = Provider.of<UserDataProvider>(context, listen: false);
    TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("بكم تريد بدأ الشهر؟", style: GoogleFonts.cairo(color: Colors.amber)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "مثلاً: 5000", hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('skip'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                double amount = double.parse(controller.text);
                // إضافة كدخل أولي
                provider.addTransaction(amount, true, "cat_salary");
                Navigator.pop(context);
              }
            }, 
            child: Text(lang.t('start'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  void _editSalaryDialog() {
    final provider = Provider.of<UserDataProvider>(context, listen: false);
    TextEditingController controller = TextEditingController(text: provider.salary > 0 ? provider.salary.toStringAsFixed(0) : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("تعديل الدخل الشهري", style: GoogleFonts.cairo(color: Colors.amber)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "0.00", hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.updateSalary(double.parse(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text("تحديث", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showTransactionOptions(int originalIndex, String transactionData) {
    final provider = Provider.of<UserDataProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text("تعديل المعاملة", style: GoogleFonts.cairo(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showAddTransactionSheet(editIndex: originalIndex, editData: transactionData); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text("حذف المعاملة", style: GoogleFonts.cairo(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: Colors.grey.shade900,
                    title: Text("تأكيد الحذف", style: GoogleFonts.cairo(color: Colors.white)),
                    content: Text("سيتم استرجاع المبلغ.", style: GoogleFonts.cairo(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text("إلغاء")),
                      TextButton(onPressed: () {
                        provider.deleteTransaction(originalIndex);
                        Navigator.pop(ctx2);
                      }, child: const Text("حذف", style: TextStyle(color: Colors.red))),
                    ],
                  )
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showAddTransactionSheet({int? editIndex, String? editData}) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final provider = Provider.of<UserDataProvider>(context, listen: false);
    
    bool isIncome = false;
    TextEditingController amountController = TextEditingController();
    String selectedCategoryKey = "cat_other";

    if (editData != null) {
      List<String> parts = editData.split('|');
      String amountStr = parts[0].replaceAll(' ', '');
      isIncome = amountStr.startsWith('+');
      amountController.text = amountStr.substring(1);
      selectedCategoryKey = parts.length > 1 ? parts[1] : "cat_other";
    }
    
    final categories = [{'icon': Icons.fastfood, 'key': 'cat_food'}, {'icon': Icons.directions_bus, 'key': 'cat_transport'}, {'icon': Icons.shopping_bag, 'key': 'cat_shopping'}, {'icon': Icons.work, 'key': 'cat_salary'}, {'icon': Icons.lightbulb, 'key': 'cat_bills'}, {'icon': Icons.health_and_safety, 'key': 'cat_health'}];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 600, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(height: 5, width: 50, color: Colors.grey, margin: const EdgeInsets.only(bottom: 20)),
                  Text(editIndex != null ? "تعديل" : lang.t('add_transaction'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: GestureDetector(onTap: () => setModalState(() => isIncome = false), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !isIncome ? Colors.red.withOpacity(0.2) : Colors.transparent, border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(lang.t('expense'), style: GoogleFonts.cairo(color: Colors.red)))))),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(onTap: () => setModalState(() => isIncome = true), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isIncome ? Colors.green.withOpacity(0.2) : Colors.transparent, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(lang.t('income'), style: GoogleFonts.cairo(color: Colors.green)))))),
                  ]),
                  const SizedBox(height: 20),
                  TextField(controller: amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 30), textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "0.00", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none)),
                  const SizedBox(height: 20),
                  Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: categories.length, itemBuilder: (context, index) { String key = categories[index]['key'] as String; bool isSelected = selectedCategoryKey == key; return GestureDetector(onTap: () => setModalState(() => selectedCategoryKey = key), child: Container(decoration: BoxDecoration(color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(categories[index]['icon'] as IconData, color: isSelected ? Colors.black : Colors.white), Text(lang.t(key), style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.white, fontSize: 12))]))); })),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      double amount = double.parse(amountController.text);
                      if (editIndex != null) provider.editTransaction(editIndex, amount, isIncome, selectedCategoryKey);
                      else provider.addTransaction(amount, isIncome, selectedCategoryKey);
                      Navigator.pop(context);
                    }
                  }, child: Text(lang.t('save'), style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatFullDate(String isoString) {
    try { DateTime date = DateTime.parse(isoString); return DateFormat('dd MMM HH:mm', 'ar').format(date); } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    
    // ✅ تجميع المعاملات حسب الشهر
    Map<String, List<String>> groupedTransactions = _groupTransactionsByMonth(userData.transactions);
    List<String> monthKeys = groupedTransactions.keys.toList();

    if (userData.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              // البطاقة الذهبية (الرصيد الكلي الحالي)
              Container(
                margin: const EdgeInsets.all(20), height: 160, width: double.infinity,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Stack(
                  children: [
                    Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(lang.t('current_balance'), style: GoogleFonts.cairo(color: Colors.black54, fontSize: 18)), Text("${userData.balance.toStringAsFixed(2)} DH", style: GoogleFonts.cairo(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold))])),
                    Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.settings, color: Colors.black45), onPressed: _editSalaryDialog, tooltip: "تغيير الدخل الشهري"))
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => showAddTransactionSheet(), icon: const Icon(Icons.add_circle, color: Colors.amber, size: 30)),
                    Text(lang.t('recent_transactions'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              
              // ✅ القائمة المقسمة (Grouped List)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: monthKeys.length,
                  itemBuilder: (context, sectionIndex) {
                    String monthKey = monthKeys[sectionIndex];
                    List<String> monthTrans = groupedTransactions[monthKey]!;
                    double monthlySavings = _calculateMonthlySavings(monthTrans);
                    String monthName = DateFormat('MMMM yyyy', 'ar').format(DateFormat('yyyy-MM').parse(monthKey));

                    return Column(
                      children: [
                        // 📅 رأس الشهر (شحال شاط فيه)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("📅 $monthName", style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("المتبقي:", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 10)),
                                  Text("${monthlySavings > 0 ? '+' : ''}${monthlySavings.toStringAsFixed(0)} DH", style: GoogleFonts.cairo(color: monthlySavings >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        ),
                        // 📜 معاملات هذا الشهر
                        ...monthTrans.map((transData) {
                          int originalIndex = userData.transactions.indexOf(transData);
                          List<String> parts = transData.split('|');
                          String amountType = parts[0];
                          String catKey = parts.length > 1 ? parts[1] : "cat_other";
                          String dateStr = parts.length > 2 ? parts[2] : "";
                          String snapshot = parts.length > 3 ? parts[3] : "--"; // ✅ الرصيد المحفوظ
                          bool isIncome = amountType.contains("+");

                          return GestureDetector(
                            onLongPress: () => _showTransactionOptions(originalIndex, transData),
                            child: Card(
                              color: Colors.grey.withOpacity(0.1),
                              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              child: ListTile(
                                leading: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red),
                                title: Text(lang.t(catKey), style: GoogleFonts.cairo(color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatFullDate(dateStr), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    // ✅ إظهار الرصيد المحفوظ (Snapshot)
                                    if(snapshot != "--") Text("الرصيد بعد: $snapshot DH", style: const TextStyle(color: Colors.amber, fontSize: 10)),
                                  ],
                                ),
                                trailing: Text(amountType, style: GoogleFonts.cairo(color: isIncome ? Colors.green : Colors.red, fontSize: 18)),
                              ),
                            ),
                          );
                        }).toList()
                      ],
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}