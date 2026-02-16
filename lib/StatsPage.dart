import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; 
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان الجديدة

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
    final lang = context.watch<LanguageProvider>();

    // ✅ إصلاح التاريخ للدارجة
    final String dateLocale = lang.currentLang == 'da' ? 'ar' : lang.currentLang;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const SizedBox(height: 10),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${lang.t('overview')} 📊",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', dateLocale).format(DateTime.now()),
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
                      color: AppColors.surface.withOpacity(0.5), // ✅ Surface
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)), // ✅ Royal Blue border
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.accent), // ✅ Cyan icon
                  )
                ],
              ),
              
              // Animation
              Center(
                child: SizedBox(
                  height: 130, 
                  child: Image.asset(
                    'assets/animation/be.gif',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              const _BudgetSection(),
              const SizedBox(height: 30),
              const _ExpenseBreakdownSection(),
              const SizedBox(height: 30),
              const _TasksSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1️⃣ Budget Section Widget (Styled)
// ==========================================
class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            lang.t('monthly_budget'),
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
            
            // ✅ ألوان الميزانية الجديدة
            final budgetColor = spentPercentage > 1.0 
                ? const Color(0xFFFF5252) // أحمر للخطر
                : (spentPercentage > 0.8 ? const Color(0xFFFFAB40) : AppColors.accent); // Cyan للحالة الجيدة

            final currencyFormat = NumberFormat("#,##0", lang.currentLang == 'ar' || lang.currentLang == 'da' ? "ar" : "en_US");

            String statusText;
            IconData statusIcon;
            
            if (spentPercentage > 1.0) {
              statusText = "${lang.t('spent_ratio')} ${(spentPercentage * 100).toStringAsFixed(0)}%";
              statusIcon = Icons.warning_amber_rounded;
            } else {
              statusText = "${lang.t('spent_ratio')} ${(spentPercentage * 100).toStringAsFixed(1)}%";
              statusIcon = Icons.check_circle_outline_rounded;
            }

            if (data.salary > 0) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // ✅ خلفية متدرجة خفيفة بلمسة Navy
                  gradient: LinearGradient(
                    colors: [AppColors.surface, AppColors.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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
                         _buildFinanceItem(lang.t('income'), data.salary, AppColors.accent, currencyFormat), // ✅ Dakhil Cyan
                         Container(height: 40, width: 1, color: Colors.white10),
                         _buildFinanceItem(lang.t('expense'), totalExpenses, const Color(0xFFFF5252), currencyFormat), // Masrouf Red
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
              return _buildEmptyState(lang.t('salary_not_set'));
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
// 2️⃣ Expense Breakdown (Styled)
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

  ({String name, IconData icon, Color color}) _getCategoryDetails(String key, LanguageProvider lang) {
    String translatedName = lang.t(key);
    
    // ✅ ألوان الفئات تم تعديلها لتكون متناسقة (أكثر زرقة وبرودة)
    switch (key) {
      case 'cat_food': return (name: translatedName, icon: Icons.fastfood_rounded, color: const Color(0xFFFFAB91)); 
      case 'cat_transport': return (name: translatedName, icon: Icons.directions_car_rounded, color: const Color(0xFF64B5F6)); // Blue
      case 'cat_shopping': return (name: translatedName, icon: Icons.shopping_bag_rounded, color: const Color(0xFFBA68C8)); // Purple
      case 'cat_bills': return (name: translatedName, icon: Icons.receipt_long_rounded, color: const Color(0xFFFFD54F)); // Yellow
      case 'cat_health': return (name: translatedName, icon: Icons.medical_services_rounded, color: const Color(0xFFE57373)); // Red
      case 'cat_salary': return (name: translatedName, icon: Icons.account_balance_wallet_rounded, color: AppColors.accent); // Cyan
      default: return (name: lang.t('cat_other'), icon: Icons.category_rounded, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${lang.t('expense_breakdown')} 📉", 
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
              return _buildEmptyState(lang.t('no_expenses'));
            }

            final sortedEntries = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final catDetails = _getCategoryDetails(entry.key, lang);
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
                            // ✅ خلفية البطاقات Surface (Navy فاتح)
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
// 3️⃣ Tasks Section Widget (Styled)
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
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${lang.t('productivity')} ✅", 
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
              return _buildEmptyState(lang.t('no_tasks_stats'));
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // ✅ Surface Color
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                              color: AppColors.primary, // ✅ Royal Blue progress
                              strokeCap: StrokeCap.round, 
                            ),
                          ),
                          Text(
                            "${(taskProgress * _animation.value * 100).toInt()}%",
                            style: GoogleFonts.cairo(
                              color: AppColors.accent, // ✅ Cyan text
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
                      _buildLegend(AppColors.primary, "${lang.t('completed_today')}: $completedTodayCount"),
                      const SizedBox(height: 12),
                      _buildLegend(Colors.white38, "${lang.t('remaining')}: ${totalTasks - completedTodayCount}"),
                      const SizedBox(height: 12),
                      _buildLegend(Colors.white, "${lang.t('total')}: $totalTasks"),
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
      color: AppColors.surface.withOpacity(0.5),
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