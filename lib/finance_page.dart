import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // ✅ لتنسيق التاريخ
import 'package:muslim_way/services/firestore_service.dart';
import 'package:muslim_way/providers/language_provider.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  double balance = 0.0;
  List<String> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFinanceData();
  }

  Future<void> loadFinanceData() async {
    setState(() => isLoading = true);
    await FirestoreService().createUserIfNotExists();
    final data = await FirestoreService().getUserData();
    
    if (mounted) {
      setState(() {
        if (data != null) {
          balance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
          transactions = List<String>.from(data['wallet_transactions'] ?? []);
        }
        isLoading = false;
      });
      if (balance == 0.0 && transactions.isEmpty) {
         Future.delayed(Duration.zero, () => _showInitialBalanceDialog());
      }
    }
  }

  // ✅ دالة تنسيق التاريخ
  String _formatDate(String isoString, LanguageProvider lang) {
    try {
      DateTime date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      String time = DateFormat('HH:mm').format(date);

      if (difference == 0 && date.day == now.day) {
        return "${lang.t('today')} $time";
      } else if (difference == 1 || (difference == 0 && date.day != now.day)) {
        return "${lang.t('yesterday')} $time";
      } else {
        return DateFormat('dd/MM HH:mm').format(date);
      }
    } catch (e) {
      return "";
    }
  }
  
  void _showInitialBalanceDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(lang.t('start_balance_title'), style: GoogleFonts.cairo(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(lang.t('start_balance_ask'), style: GoogleFonts.cairo(color: Colors.white)),
             const SizedBox(height: 10),
             TextField(
               controller: controller,
               keyboardType: TextInputType.number,
               style: const TextStyle(color: Colors.white),
               decoration: const InputDecoration(
                 hintText: "500",
                 hintStyle: TextStyle(color: Colors.grey),
                 enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
               ),
             )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(lang.t('skip'), style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                addTransaction(double.parse(controller.text), true, "cat_other");
                Navigator.pop(context);
              }
            }, 
            child: Text(lang.t('start'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
  
  Future<void> addTransaction(double amount, bool isIncome, String categoryKey) async {
    setState(() {
      if (isIncome) {
        balance += amount;
      } else {
        balance -= amount;
      }
      String typeSymbol = isIncome ? "+" : "-";
      // المبلغ | مفتاح التصنيف | التاريخ
      transactions.insert(0, "$typeSymbol $amount|$categoryKey|${DateTime.now().toString()}");
    });
    await FirestoreService().updateFinance(balance, transactions);
  }

  void showAddTransactionSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    bool isIncome = false;
    TextEditingController amountController = TextEditingController();
    String selectedCategoryKey = "cat_other";
    
    // قائمة المفاتيح
    final categories = [
      {'icon': Icons.fastfood, 'key': 'cat_food'},
      {'icon': Icons.directions_bus, 'key': 'cat_transport'},
      {'icon': Icons.shopping_bag, 'key': 'cat_shopping'},
      {'icon': Icons.work, 'key': 'cat_salary'},
      {'icon': Icons.lightbulb, 'key': 'cat_bills'},
      {'icon': Icons.health_and_safety, 'key': 'cat_health'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 600,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(height: 5, width: 50, color: Colors.grey, margin: const EdgeInsets.only(bottom: 20)),
                  Text(lang.t('add_transaction'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 20),
                  // أزرار دخل/مصروف (نفس الكود السابق...)
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
                            child: Center(child: Text(lang.t('expense'), style: GoogleFonts.cairo(color: Colors.red))),
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
                            child: Center(child: Text(lang.t('income'), style: GoogleFonts.cairo(color: Colors.green))),
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
                        String key = categories[index]['key'] as String;
                        bool isSelected = selectedCategoryKey == key;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategoryKey = key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(categories[index]['icon'] as IconData, color: isSelected ? Colors.black : Colors.white),
                                Text(lang.t(key), style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () {
                      if (amountController.text.isNotEmpty) {
                        addTransaction(double.parse(amountController.text), isIncome, selectedCategoryKey);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(lang.t('save'), style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // (نفس كود بطاقة الرصيد...)
              Container(
                margin: const EdgeInsets.all(20),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lang.t('current_balance'), style: GoogleFonts.cairo(color: Colors.black54, fontSize: 18)),
                    Text(
                      "${balance.toStringAsFixed(2)} DH",
                      style: GoogleFonts.cairo(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
                      child: Text(lang.t('money_quote'), style: GoogleFonts.reemKufi(color: Colors.black87)),
                    )
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: showAddTransactionSheet, icon: const Icon(Icons.add_circle, color: Colors.amber, size: 30)),
                    Text(lang.t('recent_transactions'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    List<String> data = transactions[index].split('|');
                    // حماية البيانات
                    String amountType = data[0];
                    String catKey = data.length > 1 ? data[1] : "cat_other";
                    String dateStr = data.length > 2 ? data[2] : DateTime.now().toString();

                    bool isIncome = amountType.contains("+");
                    
                    return Card(
                      color: Colors.grey.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(lang.t(catKey), style: GoogleFonts.cairo(color: Colors.white)), // ✅ الترجمة
                        subtitle: Text(_formatDate(dateStr, lang), style: const TextStyle(color: Colors.grey, fontSize: 12)), // ✅ التاريخ
                        trailing: Text(
                          amountType,
                          style: GoogleFonts.cairo(color: isIncome ? Colors.green : Colors.red, fontSize: 18),
                        ),
                      ),
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