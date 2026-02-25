import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';
import 'package:muslim_way/root.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  @override
  bool get wantKeepAlive => true;

  bool _showCelebration  = false;
  bool _wasAllDoneBefore = false;

  bool _isDoneToday(String taskData) {
    final parts = taskData.split('|');
    if (parts.length <= 6) return false;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return parts[6] == today;
  }

  bool _isAllDailyDone(List<String> tasks) {
    final dailyTasks = tasks.where((t) {
      final p = t.split('|');
      return p.length > 2 && p[2] == 'true';
    }).toList();
    if (dailyTasks.isEmpty) return false;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dailyTasks.every((t) {
      final p = t.split('|');
      return p.length > 6 && p[6] == today;
    });
  }

  void _handleTaskToggle(
    BuildContext context,
    int index,
    List<String> tasks,
    LanguageProvider lang,
  ) {
    final isDone = _isDoneToday(tasks[index]);

    if (!isDone) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.question,
        dialogBackgroundColor: AppColors.surface,
        animType: AnimType.scale,
        title: lang.t('confirm_done_title'),
        desc: lang.t('confirm_done_desc'),
        titleTextStyle: AppFonts.mainStyle(
          context: context, listen: false,
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17,
        ),
        descTextStyle: AppFonts.mainStyle(
          context: context, listen: false,
          color: Colors.white70, fontSize: 13,
        ),
        btnCancelText: lang.t('cancel'),
        btnOkText: lang.t('yes'),
        btnOkColor: AppColors.primary,
        buttonsTextStyle: AppFonts.mainStyle(
          context: context, listen: false,
          fontWeight: FontWeight.bold, color: Colors.white,
        ),
        btnCancelOnPress: () {},
        btnOkOnPress: () async {
          await context.read<UserDataProvider>().toggleTaskStatus(index);

          final updatedTasks = context.read<UserDataProvider>().tasks;
          final allDone = _isAllDailyDone(updatedTasks);

          if (allDone && !_wasAllDoneBefore) {
            _wasAllDoneBefore = true;
            setState(() => _showCelebration = true);
            Future.delayed(const Duration(seconds: 6), () {
              if (mounted) setState(() => _showCelebration = false);
            });
          }
        },
      ).show();
    } else {
      context.read<UserDataProvider>().toggleTaskStatus(index);
      _wasAllDoneBefore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          heroTag: 'fab_add_task',
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white, size: 25),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskPage()),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 15, right: 15),
              child: Column(
                children: [
                  Text(
                    lang.t('my_tasks'),
                    style: AppFonts.mainStyle(
                      context: context,
                      color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Selector<UserDataProvider, List<String>>(
                      selector: (_, p) => p.tasks,
                      builder: (context, tasks, _) {
                        final allDone = _isAllDailyDone(tasks);
                        if (!allDone) _wasAllDoneBefore = false;

                        if (tasks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/animation/Man with task list.json',
                                  width: 220, height: 220,
                                  fit: BoxFit.contain, repeat: true,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  lang.t('empty_notes'),
                                  style: AppFonts.mainStyle(
                                    context: context, color: Colors.white54, fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: tasks.length,
                          cacheExtent: 500,
                          itemBuilder: (context, index) {
                            final taskData     = tasks[index];
                            final data         = taskData.split('|');
                            final title        = data[0];
                            final catKey       = data.length > 1 ? data[1] : "cat_personal";
                            final isDaily      = data.length > 2 ? data[2] == 'true' : false;
                            final reminderDate = data.length > 4 ? data[4] : "null";
                            final done         = _isDoneToday(taskData);

                            return _TaskItem(
                              title: title,
                              catKey: catKey,
                              isDaily: isDaily,
                              reminderDate: reminderDate,
                              isDone: done,
                              onToggle: () => _handleTaskToggle(context, index, tasks, lang),
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTaskPage(
                                    taskToEdit: taskData,
                                    taskIndex: index,
                                  ),
                                ),
                              ),
                              onDelete: () {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.warning,
                                  dialogBackgroundColor: AppColors.surface,
                                  animType: AnimType.bottomSlide,
                                  title: lang.t('confirm_delete'),
                                  desc: lang.t('delete_task_ask'),
                                  titleTextStyle: AppFonts.mainStyle(
                                    context: context, listen: false,
                                    color: Colors.white, fontWeight: FontWeight.bold,
                                  ),
                                  descTextStyle: AppFonts.mainStyle(
                                    context: context, listen: false,
                                    color: Colors.white70,
                                  ),
                                  btnCancelText: lang.t('cancel'),
                                  btnOkText: lang.t('delete'),
                                  btnOkColor: Colors.redAccent,
                                  buttonsTextStyle: AppFonts.mainStyle(
                                    context: context, listen: false,
                                    fontWeight: FontWeight.bold, color: Colors.white,
                                  ),
                                  btnCancelOnPress: () {},
                                  btnOkOnPress: () =>
                                      context.read<UserDataProvider>().deleteTask(index),
                                ).show();
                              },
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

          // ── Celebration — فوق كلشي ────────────────────────
          if (_showCelebration)
            Positioned.fill(
              child: _CelebrationOverlay(
                lang: lang,
                onDismiss: () => setState(() => _showCelebration = false),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// 🎉 Celebration Overlay
// ============================================================
class _CelebrationOverlay extends StatefulWidget {
  final LanguageProvider lang;
  final VoidCallback onDismiss;

  const _CelebrationOverlay({required this.lang, required this.onDismiss});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade   = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideY = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.88),
          child: Stack(
            children: [

              // ── Lottie فالمنتصف بالضبط ──────────────────
              Align(
                alignment: const Alignment(0, -0.15),
                child: Lottie.asset(
                  'assets/animation/Neko Gojo Satoru.json',
                  width: double.infinity,
                  height: screenH * 0.60,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),

              // ── gradient فالأسفل ─────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.97),
                      ],
                      stops: const [0.0, 0.48, 0.68, 1.0],
                    ),
                  ),
                ),
              ),

              // ── النص الذهبي فالأسفل ──────────────────────
              Positioned(
                bottom: 130,
                left: 24,
                right: 24,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideY.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // 🏆 العنوان الذهبي
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFF176),
                            Color(0xFFFFD700),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.lang.t('celebration_title'),
                          textAlign: TextAlign.center,
                          style: AppFonts.mainStyle(
                            context: context, listen: false,
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // subtitle
                      Text(
                        widget.lang.t('celebration_subtitle'),
                        textAlign: TextAlign.center,
                        style: AppFonts.mainStyle(
                          context: context, listen: false,
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
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
// Task Item Widget
// ============================================================
class _TaskItem extends StatelessWidget {
  final String title;
  final String catKey;
  final bool isDaily;
  final String reminderDate;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskItem({
    required this.title,
    required this.catKey,
    required this.isDaily,
    required this.reminderDate,
    required this.isDone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getIconForCategory(String key) {
    switch (key) {
      case 'cat_religion': return Icons.mosque;
      case 'cat_work':     return Icons.work;
      case 'cat_study':    return Icons.book;
      case 'cat_shopping': return Icons.shopping_cart;
      default:             return Icons.person;
    }
  }

  String _formatDate(String isoString) {
    if (isoString == "null") return "";
    try { return DateFormat('HH:mm').format(DateTime.parse(isoString)); }
    catch (_) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF1B5E20).withOpacity(0.45)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? Colors.greenAccent.withOpacity(0.25)
              : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDone
            ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.06), blurRadius: 12, spreadRadius: 0)]
            : [const BoxShadow(color: Colors.transparent, blurRadius: 12, spreadRadius: 0)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone ? Colors.transparent : AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForCategory(catKey),
              color: isDone ? Colors.grey : AppColors.accent, size: 22,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.mainStyle(
                    context: context,
                    color: isDone ? Colors.grey : Colors.white,
                    fontSize: 16,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDaily ? lang.t('daily_habit') : lang.t('one_time_task'),
                        style: AppFonts.mainStyle(
                          context: context, color: Colors.grey.shade400, fontSize: 10,
                        ),
                      ),
                    ),
                    if (reminderDate != "null") ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(reminderDate),
                        style: AppFonts.mainStyle(
                          context: context, color: AppColors.accent,
                          fontSize: 11, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(icon: Icons.edit_rounded,           color: Colors.blueAccent, onTap: onEdit),
              const SizedBox(width: 5),
              _ActionButton(icon: Icons.delete_outline_rounded, color: Colors.redAccent,  onTap: onDelete),
              const SizedBox(width: 5),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? Colors.greenAccent : Colors.grey,
                          width: 2,
                        ),
                        color: isDone
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.transparent,
                        boxShadow: isDone
                            ? [BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 8,
                              )]
                            : [],
                      ),
                      child: Icon(
                        Icons.check, size: 18,
                        color: isDone ? Colors.greenAccent : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Action Button Widget
// ============================================================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Icon(icon, color: color.withOpacity(0.8), size: 20),
      ),
    );
  }
}