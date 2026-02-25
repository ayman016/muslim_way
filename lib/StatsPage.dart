import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

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
    final String dateLocale = lang.currentLang == 'da' ? 'ar' : lang.currentLang;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 20, left: 18, right: 18, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ── Header ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('overview'),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('MMMM yyyy', dateLocale).format(DateTime.now()),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.5),
                          AppColors.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 22),
                  ),
                ],
              ),

              // ── GIF ─────────────────────────────────
              Center(
                child: SizedBox(
                  height: 120,
                  child: Image.asset(
                    'assets/animation/be.gif',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const _BudgetSection(),
              const SizedBox(height: 28),
              const _ExpenseBreakdownSection(),
              const SizedBox(height: 28),
              const _TasksSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 1️⃣ Budget Section — Redesigned
// ============================================================
class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.accent,
          label: lang.t('monthly_budget'),
        ),
        const SizedBox(height: 14),

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
                : (spentPercentage > 0.8 ? const Color(0xFFFFAB40) : AppColors.accent);

            final currencyFormat = NumberFormat(
              "#,##0",
              lang.currentLang == 'ar' || lang.currentLang == 'da' ? "ar" : "en_US",
            );

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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.background.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Income / Expense cards side by side
                    Row(
                      children: [
                        Expanded(
                          child: _FinanceMiniCard(
                            label: lang.t('income'),
                            amount: data.salary,
                            color: AppColors.accent,
                            icon: Icons.arrow_downward_rounded,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FinanceMiniCard(
                            label: lang.t('expense'),
                            amount: totalExpenses,
                            color: const Color(0xFFFF5252),
                            icon: Icons.arrow_upward_rounded,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: spentPercentage > 1 ? 1 : spentPercentage,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [budgetColor.withOpacity(0.6), budgetColor],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: budgetColor.withOpacity(0.45),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Icon(statusIcon, color: budgetColor, size: 15),
                        const SizedBox(width: 7),
                        Text(
                          statusText,
                          style: AppFonts.mainStyle(
                            context: context,
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
              return _buildEmptyState(context, lang.t('salary_not_set'));
            }
          },
        ),
      ],
    );
  }
}

// Mini finance card widget
class _FinanceMiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currencyFormat;

  const _FinanceMiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.mainStyle(
                    context: context,
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        currencyFormat.format(amount),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " DH",
                        style: AppFonts.mainStyle(
                          context: context,
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2️⃣ Expense Breakdown — Redesigned
// ============================================================
class _ExpenseBreakdownSection extends StatefulWidget {
  const _ExpenseBreakdownSection();

  @override
  State<_ExpenseBreakdownSection> createState() => _ExpenseBreakdownSectionState();
}

class _ExpenseBreakdownSectionState extends State<_ExpenseBreakdownSection>
    with SingleTickerProviderStateMixin {
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

  ({String name, IconData icon, Color color}) _getCategoryDetails(
      String key, LanguageProvider lang) {
    String translatedName = lang.t(key);
    switch (key) {
      case 'cat_food':
        return (name: translatedName, icon: Icons.fastfood_rounded, color: const Color(0xFFFFAB91));
      case 'cat_transport':
        return (name: translatedName, icon: Icons.directions_car_rounded, color: const Color(0xFF64B5F6));
      case 'cat_shopping':
        return (name: translatedName, icon: Icons.shopping_bag_rounded, color: const Color(0xFFBA68C8));
      case 'cat_bills':
        return (name: translatedName, icon: Icons.receipt_long_rounded, color: const Color(0xFFFFD54F));
      case 'cat_health':
        return (name: translatedName, icon: Icons.medical_services_rounded, color: const Color(0xFFE57373));
      case 'cat_salary':
        return (name: translatedName, icon: Icons.account_balance_wallet_rounded, color: AppColors.accent);
      default:
        return (name: lang.t('cat_other'), icon: Icons.category_rounded, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.pie_chart_rounded,
          iconColor: const Color(0xFFBA68C8),
          label: lang.t('expense_breakdown'),
        ),
        const SizedBox(height: 14),

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
              return _buildEmptyState(context, lang.t('no_expenses'));
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
                final percentage =
                    totalMonthlyExpenses > 0 ? (amount / totalMonthlyExpenses) : 0.0;

                final Animation<double> itemAnimation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    (1 / sortedEntries.length) * index,
                    1.0,
                    curve: Curves.easeOutQuart,
                  ),
                );

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final animatedPercent = percentage * itemAnimation.value;
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - itemAnimation.value)),
                      child: Opacity(
                        opacity: itemAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: catDetails.color.withOpacity(0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: catDetails.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(catDetails.icon, color: catDetails.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          catDetails.name,
                                          style: AppFonts.mainStyle(
                                            context: context,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: catDetails.color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "${amount.toInt()} DH",
                                            style: AppFonts.mainStyle(
                                              context: context,
                                              color: catDetails.color,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: animatedPercent,
                                              backgroundColor: Colors.white.withOpacity(0.06),
                                              valueColor: AlwaysStoppedAnimation<Color>(catDetails.color),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "${(animatedPercent * 100).toInt()}%",
                                          style: AppFonts.mainStyle(
                                            context: context,
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

// ============================================================
// 3️⃣ Tasks Section — Redesigned
// ============================================================
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
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double percent) {
    if (percent >= 1.0) return Colors.greenAccent;
    if (percent >= 0.5) return Colors.blueAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.task_alt_rounded,
          iconColor: Colors.greenAccent,
          label: lang.t('productivity'),
        ),
        const SizedBox(height: 14),

        Selector<UserDataProvider, List<String>>(
          selector: (_, provider) => provider.tasks,
          builder: (context, allTasks, child) {
            final dailyTasks = allTasks.where((task) {
              final parts = task.split('|');
              return parts.length > 2 && parts[2] == 'true';
            }).toList();

            final now = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(now);
            int completedTodayCount = 0;

            for (var task in dailyTasks) {
              final parts = task.split('|');
              if (parts.length > 6 && parts[6] == todayStr) {
                completedTodayCount++;
              }
            }

            final totalDailyTasks = dailyTasks.length;
            final taskProgress =
                totalDailyTasks > 0 ? completedTodayCount / totalDailyTasks : 0.0;

            if (totalDailyTasks == 0) {
              return _buildEmptyState(context, lang.t('no_tasks_stats'));
            }

            // ✅ All tasks done — Lottie celebration
            if (taskProgress >= 1.0) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.withOpacity(0.07),
                      AppColors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.08),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/Game asset.json',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang.t('all_tasks_done'),
                      textAlign: TextAlign.center,
                      style: AppFonts.mainStyle(
                        context: context,
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Normal state — circular progress + legend
            final progressColor = _getProgressColor(taskProgress);

            return Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular progress
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 106,
                            width: 106,
                            child: CircularProgressIndicator(
                              value: taskProgress * _animation.value,
                              strokeWidth: 9,
                              backgroundColor: Colors.white.withOpacity(0.07),
                              color: progressColor,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${(taskProgress * _animation.value * 100).toInt()}%",
                                style: AppFonts.mainStyle(
                                  context: context,
                                  color: progressColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                lang.t('done'),
                                style: AppFonts.mainStyle(
                                  context: context,
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 24),

                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(
                          color: Colors.greenAccent,
                          label: lang.t('completed_today'),
                          value: "$completedTodayCount",
                        ),
                        const SizedBox(height: 10),
                        _LegendItem(
                          color: Colors.orangeAccent,
                          label: lang.t('remaining'),
                          value: "${totalDailyTasks - completedTodayCount}",
                        ),
                        const SizedBox(height: 10),
                        _LegendItem(
                          color: Colors.white54,
                          label: lang.t('total'),
                          value: "$totalDailyTasks",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppFonts.mainStyle(
            context: context,
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppFonts.mainStyle(
              context: context,
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: AppFonts.mainStyle(
            context: context,
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.45),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(
      children: [
        Icon(Icons.info_outline_rounded, size: 36, color: Colors.white24),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppFonts.mainStyle(
            context: context,
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}