import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان الجديدة

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  bool _isDoneToday(String taskData) {
    final parts = taskData.split('|');
    if (parts.length <= 6) return false;
    final lastDone = parts[6];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastDone == today;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          heroTag: 'fab_add_task',
          backgroundColor: AppColors.primary, // ✅ Royal Blue FAB
          child: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskPage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 15, right: 15),
          child: Column(
            children: [
              Text(
                lang.t('my_tasks'),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Selector<UserDataProvider, List<String>>(
                  selector: (_, provider) => provider.tasks,
                  builder: (context, tasks, child) {
                    if (tasks.isEmpty) {
                      return Center(
                        child: Text(
                          lang.t('empty_notes'),
                          style: GoogleFonts.cairo(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: tasks.length,
                      cacheExtent: 500,
                      itemBuilder: (context, index) {
                        final taskData = tasks[index];
                        final data = taskData.split('|');
                        final title = data[0];
                        final catKey = data.length > 1 ? data[1] : "cat_personal";
                        final isDaily = data.length > 2 ? data[2] == 'true' : false;
                        final reminderDate = data.length > 4 ? data[4] : "null";
                        final done = _isDoneToday(taskData);

                        return _TaskItem(
                          title: title,
                          catKey: catKey,
                          isDaily: isDaily,
                          reminderDate: reminderDate,
                          isDone: done,
                          onToggle: () {
                            context.read<UserDataProvider>().toggleTaskStatus(index);
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTaskPage(
                                  taskToEdit: taskData,
                                  taskIndex: index,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              dialogBackgroundColor: AppColors.surface, // ✅ لون الخلفية للحوار
                              animType: AnimType.bottomSlide,
                              title: lang.t('confirm_delete'),
                              desc: lang.t('delete_task_ask'),
                              titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                              descTextStyle: GoogleFonts.cairo(color: Colors.white70),
                              btnCancelText: lang.t('cancel'),
                              btnOkText: lang.t('delete'),
                              btnOkColor: Colors.redAccent,
                              btnCancelOnPress: () {},
                              btnOkOnPress: () {
                                context.read<UserDataProvider>().deleteTask(index);
                              },
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
    );
  }
}

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
      case 'cat_work': return Icons.work;
      case 'cat_study': return Icons.book;
      case 'cat_shopping': return Icons.shopping_cart;
      default: return Icons.person;
    }
  }

  String _formatDate(String isoString) {
    if (isoString == "null") return "";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        // ✅ الخلفية حسب الحالة (Surface للعادية، أخضر داكن للمنجزة)
        color: isDone
            ? const Color(0xFF1B5E20).withOpacity(0.5) 
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        // ✅ حدود Royal Blue خفيفة جداً
        border: Border.all(
          color: isDone
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1️⃣ الأيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ✅ خلفية الأيقونة Cyan خافتة
              color: isDone ? Colors.transparent : AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForCategory(catKey),
              // ✅ لون الأيقونة Cyan
              color: isDone ? Colors.grey : AppColors.accent,
              size: 22,
            ),
          ),
          
          const SizedBox(width: 15),

          // 2️⃣ النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: isDone ? Colors.grey : Colors.white,
                    fontSize: 16,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white54,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
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
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                      ),
                    ),
                    
                    if (reminderDate != "null") ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.accent), // ✅ Cyan icon
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(reminderDate),
                        style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold), // ✅ Cyan text
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          // 3️⃣ أزرار التحكم
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.edit_rounded,
                color: Colors.blueAccent,
                onTap: onEdit,
              ),
              const SizedBox(width: 5),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                onTap: onDelete,
              ),
              const SizedBox(width: 5),
              // ✅ Checkbox (Styled)
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      // ✅ أخضر عند الإنجاز، رمادي عند الانتظار
                      color: isDone ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: isDone ? Colors.green.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: isDone ? Colors.green : Colors.transparent,
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
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color.withOpacity(0.8), size: 20),
      ),
    );
  }
}