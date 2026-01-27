import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅
import 'package:muslim_way/services/firestore_service.dart';
import 'package:muslim_way/providers/language_provider.dart'; // ✅

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
         // تأخير بسيط باش مايطلعش الديالوج قبل ما تبنا الصفحة
         Future.delayed(Duration.zero, () => _showInitialBalanceDialog());
      }
    }
  }
  
  void _showInitialBalanceDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false); // ✅
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
                addTransaction(double.parse(controller.text), true, lang.t('current_balance')); // رصيد أولي
                Navigator.pop(context);
              }
            }, 
            child: Text(lang.t('start'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
  
  Future<void> addTransaction(double amount, bool isIncome, String category) async {
    setState(() {
      if (isIncome) {
        balance += amount;
      } else {
        balance -= amount;
      }
      String typeSymbol = isIncome ? "+" : "-";
      // نسجلو التاريخ والوقت
      transactions.insert(0, "$typeSymbol $amount|$category|${DateTime.now().toString()}");
    });
    await FirestoreService().updateFinance(balance, transactions);
  }

  void showAddTransactionSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false); // ✅
    bool isIncome = false;
    TextEditingController amountController = TextEditingController();
    String selectedCategory = "أخرى";
    
    // هادو ممكن تزيد ليهم الترجمة حتى هما فالمستقبل
    final categories = [
      {'icon': Icons.fastfood, 'name': 'أكل'},
      {'icon': Icons.directions_bus, 'name': 'مواصلات'},
      {'icon': Icons.shopping_bag, 'name': 'تسوق'},
      {'icon': Icons.work, 'name': 'راتب'},
      {'icon': Icons.lightbulb, 'name': 'فواتير'},
      {'icon': Icons.health_and_safety, 'name': 'صحة'},
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
                        bool isSelected = selectedCategory == categories[index]['name'];
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = categories[index]['name'] as String),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(categories[index]['icon'] as IconData, color: isSelected ? Colors.black : Colors.white),
                                Text(categories[index]['name'] as String, style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
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
                        addTransaction(double.parse(amountController.text), isIncome, selectedCategory);
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
    final lang = Provider.of<LanguageProvider>(context); // ✅ استدعاء المترجم

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
              // بطاقة الرصيد
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
                child: transactions.isEmpty 
                  // ✅ تحسين شكل الـ Empty State
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 70, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 10),
                          Text(lang.t('empty_finance'), style: GoogleFonts.cairo(color: Colors.white54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      List<String> data = transactions[index].split('|');
                      bool isIncome = data[0].contains("+");
                      return Card(
                        color: Colors.grey.withOpacity(0.1),
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: ListTile(
                          leading: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                          title: Text(data[1], style: GoogleFonts.cairo(color: Colors.white)),
                          trailing: Text(
                            data[0],
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