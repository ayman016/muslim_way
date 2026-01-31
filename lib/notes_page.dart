import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // 🆕 Keep state alive

  bool _isDoneToday(String taskData) {
    final parts = taskData.split('|');
    if (parts.length <= 6) return false;
    final lastDone = parts[6];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastDone == today;
  }

  String _formatDate(String isoString, LanguageProvider lang) {
    if (isoString == "null") return "";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return "";
    }
  }

  IconData _getIconForCategory(String catKey) {
    switch (catKey) {
      case 'cat_religion':
        return Icons.mosque;
      case 'cat_work':
        return Icons.work;
      case 'cat_study':
        return Icons.book;
      case 'cat_shopping':
        return Icons.shopping_cart;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          heroTag: 'fab_add_task', // ✅ الحل: heroTag فريد باش ما يوقع conflict مع أي FAB آخر
          backgroundColor: Colors.amber,
          child: const Icon(Icons.add, color: Colors.black, size: 30),
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
              
              // 🆕 Use Selector instead of Consumer
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
                      // 🆕 Performance optimizations
                      cacheExtent: 500,
                      itemExtent: 100, // Fixed height for better performance
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
                              dialogType: DialogType.question,
                              animType: AnimType.bottomSlide,
                              title: 'تأكيد الحذف',
                              desc: 'هل أنت متأكد من حذف هذه المهمة؟',
                              btnCancelText: 'إلغاء',
                              btnOkText: 'حذف',
                              btnOkColor: Colors.red,
                              btnCancelColor: Colors.grey,
                              btnCancelOnPress: () {},
                              btnOkOnPress: () {
                                context.read<UserDataProvider>().deleteTask(index);
                              },
                            ).show();
                          },
                          lang: lang,
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

// 🆕 Separate widget to prevent rebuilds
class _TaskItem extends StatelessWidget {
  final String title;
  final String catKey;
  final bool isDaily;
  final String reminderDate;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final LanguageProvider lang;

  const _TaskItem({
    required this.title,
    required this.catKey,
    required this.isDaily,
    required this.reminderDate,
    required this.isDone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.lang,
  });

  IconData _getIconForCategory(String key) {
    switch (key) {
      case 'cat_religion':
        return Icons.mosque;
      case 'cat_work':
        return Icons.work;
      case 'cat_study':
        return Icons.book;
      case 'cat_shopping':
        return Icons.shopping_cart;
      default:
        return Icons.person;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.grey.withOpacity(0.1)
            : (isDaily ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDone
              ? Colors.grey
              : (isDaily ? Colors.amber.withOpacity(0.5) : Colors.white12),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
          ),
          child: Icon(
            _getIconForCategory(catKey),
            color: Colors.amber,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: isDone ? Colors.grey : Colors.white,
            fontSize: 18,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white54,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDaily ? "🔄 عادة يومية" : "📅 مهمة",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (reminderDate != "null")
              Row(
                children: [
                  const Icon(Icons.alarm, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(reminderDate),
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ],
              )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isDone ? Icons.check_circle : Icons.check_circle_outline,
                color: isDone ? Colors.green : Colors.grey,
              ),
              onPressed: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}