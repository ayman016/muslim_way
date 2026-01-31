import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => true; // 🆕 Keep state alive

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "لوحة التحكم 📊",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "إحصائيات شهر ${DateFormat('MMMM', 'ar').format(DateTime.now())}",
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Budget Section
              const _BudgetSection(),
              
              const SizedBox(height: 40),

              // Tasks Section
              const _TasksSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// 🆕 Budget Section Widget
class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "تتبع الميزانية 💰",
          style: GoogleFonts.cairo(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        // 🆕 Use Selector instead of Consumer for better performance
        Selector<UserDataProvider, ({double salary, List<String> transactions})>(
          selector: (_, provider) => (
            salary: provider.salary,
            transactions: provider.transactions,
          ),
          builder: (context, data, child) {
            final now = DateTime.now();
            double totalExpenses = 0.0;

            // Calculate expenses
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
            final budgetColor = spentPercentage > 0.8
                ? Colors.red
                : (spentPercentage > 0.5 ? Colors.orange : Colors.green);

            if (data.salary > 0) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "الدخل:  DH ${data.salary.toInt()}",
                          style: GoogleFonts.cairo(color: Colors.white70),
                        ),
                        Text(
                          "المصروف:  DH ${totalExpenses.toInt()}",
                          style: GoogleFonts.cairo(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Stack(
                      children: [
                        Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: spentPercentage > 1 ? 1 : spentPercentage,
                          child: Container(
                            height: 15,
                            decoration: BoxDecoration(
                              color: budgetColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      spentPercentage > 0.8 ? "🚨 تجاوزت 80%!" : "✅ وضعك المالي ممتاز.",
                      style: GoogleFonts.cairo(
                        color: budgetColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.amber.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    "لم تحدد الراتب الشهري بعد.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Colors.amber),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

// 🆕 Tasks Section Widget
class _TasksSection extends StatefulWidget {
  const _TasksSection();

  @override
  State<_TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<_TasksSection>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
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
          "إنتاجية اليوم ✅",
          style: GoogleFonts.cairo(
            color: Colors.blueAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

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
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 15),
                    Text(
                      "البيانات غير كافية 📉",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "أضف 5 مهام على الأقل للتحليل.\nلديك حالياً: $totalTasks",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
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
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade800,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            "${(taskProgress * _animation.value * 100).toInt()}%",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
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
                      _buildLegend(Colors.blueAccent, "تمت: $completedTodayCount"),
                      const SizedBox(height: 10),
                      _buildLegend(Colors.grey, "متبقية: ${totalTasks - completedTodayCount}"),
                      const SizedBox(height: 10),
                      _buildLegend(Colors.white, "المجموع: $totalTasks"),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.cairo(color: Colors.white70)),
      ],
    );
  }
}
