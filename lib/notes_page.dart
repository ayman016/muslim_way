import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart'; 
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/providers/user_data_provider.dart'; // ✅ ضروري

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {

  // التحقق هل العادة منجزة اليوم
  bool isDoneToday(String taskData) {
    List<String> parts = taskData.split('|');
    if (parts.length <= 6) return false;
    String lastDone = parts[6];
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastDone == today;
  }

  // تنسيق تاريخ التذكير
  String _formatDate(String isoString, LanguageProvider lang) {
    if (isoString == "null") return "";
    try {
      DateTime date = DateTime.parse(isoString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return "";
    }
  }

  IconData _getIconForCategory(String catKey) {
    switch (catKey) {
      case 'cat_religion': return Icons.mosque;
      case 'cat_work': return Icons.work;
      case 'cat_study': return Icons.book;
      case 'cat_shopping': return Icons.shopping_cart;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    // ✅ استعمال Consumer للاستماع للتغييرات الفورية
    return Consumer<UserDataProvider>(
      builder: (context, userData, child) {
        
        if (userData.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90.0), 
            child: FloatingActionButton(
              backgroundColor: Colors.amber,
              child: const Icon(Icons.add, color: Colors.black, size: 30),
              onPressed: () {
                // ✅ ننتقل للصفحة فقط، والـ Provider سيتكفل بالتحديث
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskPage()));
              },
            ),
          ),
          
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 15, right: 15),
              child: Column(
                children: [
                  Text(lang.t('my_tasks'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: userData.tasks.isEmpty // ✅ القراءة من Provider
                        ? Center(child: Text(lang.t('empty_notes'), style: GoogleFonts.cairo(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: userData.tasks.length,
                            itemBuilder: (context, index) {
                              String taskData = userData.tasks[index]; // ✅ المهمة من Provider
                              List<String> data = taskData.split('|');
                              String title = data[0];
                              String catKey = data.length > 1 ? data[1] : "cat_personal";
                              bool isDaily = data.length > 2 ? data[2] == 'true' : false;
                              String reminderDate = data.length > 4 ? data[4] : "null";
                              bool done = isDoneToday(taskData);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: done ? Colors.grey.withOpacity(0.1) : (isDaily ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: done ? Colors.grey : (isDaily ? Colors.amber.withOpacity(0.5) : Colors.white12)),
                                ),
                                child: ListTile(
                                  leading: GestureDetector(
                                    onTap: () {
                                      // ✅ استعمال دالة Provider للقيام بـ "تمت"
                                      userData.markTaskAsDone(index);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: done ? Colors.green : Colors.transparent,
                                        border: Border.all(color: done ? Colors.green : Colors.amber),
                                      ),
                                      child: Icon(
                                        done ? Icons.check : _getIconForCategory(catKey), 
                                        color: done ? Colors.white : Colors.amber, size: 20
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    title, 
                                    style: GoogleFonts.cairo(
                                      color: done ? Colors.grey : Colors.white, 
                                      fontSize: 18, 
                                      decoration: done ? TextDecoration.lineThrough : null,
                                      decorationColor: Colors.white54,
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isDaily ? "🔄 عادة يومية" : "📅 مهمة", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      if (reminderDate != "null")
                                        Row(
                                          children: [
                                            const Icon(Icons.alarm, size: 12, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(_formatDate(reminderDate, lang), style: const TextStyle(color: Colors.amber, fontSize: 11)),
                                          ],
                                        )
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // زر التعديل
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskPage(taskToEdit: taskData, taskIndex: index)));
                                        },
                                      ),
                                      // زر الحذف (مباشرة عبر Provider)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () {
                                          userData.deleteTask(index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}