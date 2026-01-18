import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  double balance = 0.0;
  List<String> transactions = [];

  @override
  void initState() {
    super.initState();
    loadFinanceData();
  }

  Future<void> loadFinanceData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      balance = prefs.getDouble('wallet_balance') ?? 0.0;
      transactions = prefs.getStringList('wallet_transactions') ?? [];
    });

    // --- جديد: السؤال عن الرصيد إذا كان 0 ---
    if (balance == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialBalanceDialog();
      });
    }
  }
  
  // دالة نافذة الرصيد الأولي
  void _showInitialBalanceDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن إغلاقها بالضغط خارجاً
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("مرحباً بك في قسم المال", style: GoogleFonts.cairo(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text("كم هو رصيدك الحالي لتبدأ به؟", style: GoogleFonts.cairo(color: Colors.white)),
             SizedBox(height: 10),
             TextField(
               controller: controller,
               keyboardType: TextInputType.number,
               style: TextStyle(color: Colors.white),
               decoration: InputDecoration(
                 hintText: "مثلاً: 500",
                 hintStyle: TextStyle(color: Colors.grey),
                 enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
               ),
             )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context); // إغلاق بدون حفظ (يبقى 0)
            }, 
            child: Text("تخطي", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                addTransaction(double.parse(controller.text), true, "رصيد أولي");
                Navigator.pop(context);
              }
            }, 
            child: Text("بدء", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
  // -------------------------------------

  Future<void> addTransaction(double amount, bool isIncome, String category) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (isIncome) {
        balance += amount;
      } else {
        balance -= amount;
      }
      String typeSymbol = isIncome ? "+" : "-";
      transactions.insert(0, "$typeSymbol $amount|$category|${DateTime.now().toString()}");
    });
    
    await prefs.setDouble('wallet_balance', balance);
    await prefs.setStringList('wallet_transactions', transactions);
  }

  // ... (باقي الكود كما هو: showAddTransactionSheet و build)
  // سأختصر هنا، فقط انسخ دالة showAddTransactionSheet والـ build من الكود القديم وضعهما هنا
  // ...
  
  // (ضع هنا دالة showAddTransactionSheet القديمة كاملة)
  void showAddTransactionSheet() {
    bool isIncome = false;
    TextEditingController amountController = TextEditingController();
    String selectedCategory = "أخرى";
    
    final categories = [
      {'icon': Icons.fastfood, 'name': 'أكل'},
      {'icon': Icons.directions_bus, 'name': 'مواصلات'},
      {'icon': Icons.shopping_bag, 'name': 'تسوق'},
      {'icon': Icons.work, 'name': 'راتب'},
      {'icon': Icons.lightbulb, 'name': 'فواتير'},
      {'icon': Icons.health_and_safety, 'name': 'صحة'},
      {'icon': Icons.account_balance, 'name': 'رصيد أولي'},
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
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(height: 5, width: 50, color: Colors.grey, margin: EdgeInsets.only(bottom: 20)),
                  Text("إضافة معاملة", style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 20),
                  
                  // Toggle Income/Expense
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isIncome = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isIncome ? Colors.red.withOpacity(0.2) : Colors.transparent,
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text("مصروف", style: GoogleFonts.cairo(color: Colors.red))),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => isIncome = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.green.withOpacity(0.2) : Colors.transparent,
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text("دخل", style: GoogleFonts.cairo(color: Colors.green))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white, fontSize: 30),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
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
                    child: Text("حفظ", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
           Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/mainbg.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.all(20),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("الرصيد الحالي", style: GoogleFonts.cairo(color: Colors.black54, fontSize: 18)),
                      Text(
                        "${balance.toStringAsFixed(2)} DH",
                        style: GoogleFonts.cairo(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
                        child: Text("المال زينة الحياة الدنيا", style: GoogleFonts.reemKufi(color: Colors.black87)),
                      )
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: showAddTransactionSheet, icon: Icon(Icons.add_circle, color: Colors.amber, size: 30)),
                      Text("آخر المعاملات", style: GoogleFonts.cairo(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      List<String> data = transactions[index].split('|');
                      bool isIncome = data[0].contains("+");
                      return Card(
                        color: Colors.grey.withOpacity(0.1),
                        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: ListTile(
                          leading: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                          title: Text(data[1], style: GoogleFonts.cairo(color: Colors.white)), // Category
                          trailing: Text(
                            data[0], // Amount
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
        ],
      ),
    );
  }
}