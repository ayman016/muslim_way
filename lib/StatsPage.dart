import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // ✅ 1. ضروري لاستدعاء الأنيميشن

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // نقصنا padding الفوقاني شوية حيت زدنا الأنيميشن
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // ✅ 2. هنا زدنا الأنيميشن فالفوق
              Center(
                child: SizedBox(
                  height: 230, // حجم مناسب للأنيميشن
                  child: Lottie.asset(
                    'assets/animation/People interacting with charts and analyzing statistic.json', // تأكد أنك سميتيه هكا فالملفات
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "نظرة عامة 📊",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.amber),
                  )
                ],
              ),
              
              const SizedBox(height: 30),

              // 1️⃣ قسم الميزانية
              const _BudgetSection(),
              
              const SizedBox(height: 30),

              // 2️⃣ قسم تحليل المصاريف (Professional Animation)
              const _ExpenseBreakdownSection(),

              const SizedBox(height: 30),

              // 3️⃣ قسم المهام
              const _TasksSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1️⃣ Budget Section Widget (Professional Look)
// ==========================================
class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "الميزانية الشهرية",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        Selector<UserDataProvider, ({double salary, List<String> transactions})>(
          selector: (_, provider) => (
            salary: provider.salary,
            transactions: provider.transactions,
          ),
          builder: (context, data, child) {
            final now = DateTime.now();
            double totalExpenses = 0.0;

            for (var trans in data.transactions) {
              final parts = trans.split('|');
              final amountStr = parts[0].replaceAll(' ', '');
              if (parts.length > 2) {
                try {
                  final transDate = DateTime.parse(parts[2]);
                  if (transDate.month == now.month && transDate.year == now.year) {
                    if (amountStr.startsWith('-')) {
                      totalExpenses += double.tryParse(amountStr.substring(1)) ?? 0.0;
                    }
                  }
                } catch (_) {}
              }
            }

            final spentPercentage = data.salary > 0 ? (totalExpenses / data.salary) : 0.0;
            final budgetColor = spentPercentage > 1.0 
                ? const Color(0xFFFF5252) 
                : (spentPercentage > 0.8 ? const Color(0xFFFFAB40) : const Color(0xFF69F0AE));

            final currencyFormat = NumberFormat("#,##0", "ar");

            String statusText;
            IconData statusIcon;
            
            if (spentPercentage > 1.0) {
              double overPercent = (spentPercentage * 100) - 100;
              statusText = "تجاوزت الحد بـ ${overPercent.toStringAsFixed(0)}%";
              statusIcon = Icons.warning_amber_rounded;
            } else {
              statusText = "استهلكت ${(spentPercentage * 100).toStringAsFixed(1)}% من الراتب";
              statusIcon = Icons.check_circle_outline_rounded;
            }

            if (data.salary > 0) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         _buildFinanceItem("الدخل", data.salary, Colors.greenAccent, currencyFormat),
                         Container(height: 40, width: 1, color: Colors.white10),
                         _buildFinanceItem("المصروف", totalExpenses, Colors.redAccent, currencyFormat),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: spentPercentage > 1 ? 1 : spentPercentage,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [budgetColor.withOpacity(0.7), budgetColor]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: budgetColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Icon(statusIcon, color: budgetColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: GoogleFonts.cairo(
                            color: budgetColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return _buildEmptyState("لم يتم تحديد الراتب الشهري");
            }
          },
        ),
      ],
    );
  }

  Widget _buildFinanceItem(String label, double amount, Color color, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              fmt.format(amount),
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(" DH", style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}

// ==========================================
// 2️⃣ Expense Breakdown (Staggered Animation 🔥)
// ==========================================
class _ExpenseBreakdownSection extends StatefulWidget {
  const _ExpenseBreakdownSection();

  @override
  State<_ExpenseBreakdownSection> createState() => _ExpenseBreakdownSectionState();
}

class _ExpenseBreakdownSectionState extends State<_ExpenseBreakdownSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({String name, IconData icon, Color color}) _getCategoryDetails(String key) {
    switch (key) {
      case 'cat_food': return (name: "الأكل والشرب", icon: Icons.fastfood_rounded, color: const Color(0xFFFFAB91)); 
      case 'cat_transport': return (name: "النقل", icon: Icons.directions_car_rounded, color: const Color(0xFF90CAF9)); 
      case 'cat_shopping': return (name: "التسوق", icon: Icons.shopping_bag_rounded, color: const Color(0xFFCE93D8)); 
      case 'cat_bills': return (name: "الفواتير", icon: Icons.receipt_long_rounded, color: const Color(0xFFFFF59D)); 
      case 'cat_health': return (name: "الصحة", icon: Icons.medical_services_rounded, color: const Color(0xFFEF9A9A)); 
      case 'cat_salary': return (name: "الراتب", icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFA5D6A7)); 
      default: return (name: "أخرى", icon: Icons.category_rounded, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "أين تذهب أموالك؟ 📉",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        Selector<UserDataProvider, List<String>>(
          selector: (_, provider) => provider.transactions,
          builder: (context, transactions, child) {
            final now = DateTime.now();
            final Map<String, double> categoryTotals = {};
            double totalMonthlyExpenses = 0.0;

            for (var trans in transactions) {
              final parts = trans.split('|');
              final amountStr = parts[0].replaceAll(' ', '');
              if (parts.length > 2 && amountStr.startsWith('-')) {
                try {
                  final transDate = DateTime.parse(parts[2]);
                  if (transDate.month == now.month && transDate.year == now.year) {
                    final amount = double.tryParse(amountStr.substring(1)) ?? 0.0;
                    final catKey = parts.length > 1 ? parts[1] : "cat_other";
                    categoryTotals[catKey] = (categoryTotals[catKey] ?? 0.0) + amount;
                    totalMonthlyExpenses += amount;
                  }
                } catch (_) {}
              }
            }

            if (categoryTotals.isEmpty) {
              return _buildEmptyState("لا توجد مصاريف هذا الشهر");
            }

            final sortedEntries = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final catDetails = _getCategoryDetails(entry.key);
                final amount = entry.value;
                final percentage = totalMonthlyExpenses > 0 ? (amount / totalMonthlyExpenses) : 0.0;

                final Animation<double> itemAnimation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval((1 / sortedEntries.length) * index, 1.0, curve: Curves.easeOutQuart),
                );

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final animatedPercent = percentage * itemAnimation.value;
                    
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - itemAnimation.value)), 
                      child: Opacity(
                        opacity: itemAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: catDetails.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(catDetails.icon, color: catDetails.color, size: 22),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              catDetails.name,
                                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              "${amount.toInt()} DH",
                                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: animatedPercent,
                                                  backgroundColor: Colors.grey.withOpacity(0.1),
                                                  valueColor: AlwaysStoppedAnimation<Color>(catDetails.color),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "${(animatedPercent * 100).toInt()}%",
                                              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ==========================================
// 3️⃣ Tasks Section Widget (Clean Design)
// ==========================================
class _TasksSection extends StatefulWidget {
  const _TasksSection();

  @override
  State<_TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<_TasksSection> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الإنتاجية اليومية ✅",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        Selector<UserDataProvider, List<String>>(
          selector: (_, provider) => provider.tasks,
          builder: (context, tasks, child) {
            final now = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(now);
            int completedTodayCount = 0;

            for (var task in tasks) {
              final parts = task.split('|');
              if (parts.length > 6 && parts[6] == todayStr) {
                completedTodayCount++;
              }
            }

            final totalTasks = tasks.length;
            final taskProgress = totalTasks > 0 ? completedTodayCount / totalTasks : 0.0;

            if (totalTasks < 5) {
              return _buildEmptyState("البيانات غير كافية للتحليل 📉\nأضف مهاماً أكثر");
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(
                              value: taskProgress * _animation.value,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: Colors.blueAccent,
                              strokeCap: StrokeCap.round, 
                            ),
                          ),
                          Text(
                            "${(taskProgress * _animation.value * 100).toInt()}%",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend(Colors.blueAccent, "تمت اليوم: $completedTodayCount"),
                      const SizedBox(height: 12),
                      _buildLegend(Colors.white38, "متبقية: ${totalTasks - completedTodayCount}"),
                      const SizedBox(height: 12),
                      _buildLegend(Colors.white, "المجموع الكلي: $totalTasks"),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

Widget _buildEmptyState(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      children: [
        const Icon(Icons.info_outline_rounded, size: 40, color: Colors.white38),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white60, fontSize: 14),
        ),
      ],
    ),
  );
}