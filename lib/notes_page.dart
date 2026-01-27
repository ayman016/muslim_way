import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart'; 
import 'package:muslim_way/services/firestore_service.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart'; // ✅ ضروري للتذكير

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<String> tasks = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => isLoading = true);
    await FirestoreService().createUserIfNotExists();
    final data = await FirestoreService().getUserData();
    if (mounted) {
      setState(() {
        if (data != null) {
          tasks = List<String>.from(data['user_tasks'] ?? []);
        }
        isLoading = false;
      });
    }
  }



  Future<void> deleteTask(int index) async {
    setState(() {
      tasks.removeAt(index);
    });
    await FirestoreService().updateTasks(tasks);
  }

  // ✅ دالة لتنسيق التاريخ (اليوم، الأمس...)
  String _formatDate(String isoString, LanguageProvider lang) {
    if (isoString == "null") return "";
    DateTime date = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    String time = DateFormat('HH:mm').format(date);

    if (difference == 0 && date.day == now.day) {
      return "${lang.t('today')} $time";
    } else if (difference == 1 || (difference == 0 && date.day != now.day)) {
      return "${lang.t('yesterday')} $time";
    } else {
      return DateFormat('dd/MM HH:mm').format(date);
    }
  }

  // ✅ دالة للحصول على أيقونة التصنيف
  IconData _getIconForCategory(String catKey) {
    switch (catKey) {
      case 'cat_religion': return Icons.mosque;
      case 'cat_work': return Icons.work;
      case 'cat_personal': return Icons.person;
      case 'cat_study': return Icons.book;
      case 'cat_shopping': return Icons.shopping_cart;
      default: return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    if (isLoading) {
       return const Scaffold(
         backgroundColor: Colors.transparent,
         body: Center(child: CircularProgressIndicator(color: Colors.amber)),
       );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.add, color: Colors.black, size: 30),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskPage()),
            );
            
            if (result != null && result is String) {
               setState(() {
                 tasks.add(result);
               });
               await FirestoreService().updateTasks(tasks);

               // ✅ برمجة التذكير إذا كان موجوداً
               List<String> parts = result.split('|');
               // نتأكد أن البيانات كاملة (5 عناصر)
               if (parts.length >= 5 && parts[4] != "null") {
                 DateTime reminder = DateTime.parse(parts[4]);
                 if (reminder.isAfter(DateTime.now())) {
                   NotificationService().scheduleNotification(
                     id: DateTime.now().millisecond, // ID عشوائي
                     title: "تذكير: ${parts[0]}",
                     body: "حان موعد القيام بمهمتك: ${lang.t(parts[1])}",
                     scheduledTime: reminder,
                   );
                 }
               }
            } else {
               loadTasks();
            }
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(lang.t('my_tasks'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.note_alt_outlined, size: 80, color: Colors.white24),
                            const SizedBox(height: 10),
                            Text(lang.t('empty_notes'), style: GoogleFonts.cairo(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 120),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          // تحليل البيانات: العنوان|المفتاح|يومية|الإنشاء|التذكير
                          List<String> data = tasks[index].split('|');
                          
                          // حماية من الأخطاء في البيانات القديمة
                          String title = data[0];
                          String catKey = data.length > 1 ? data[1] : "cat_personal";
                          bool isDaily = data.length > 2 ? data[2] == 'true' : false;
                          String createdDate = data.length > 3 ? data[3] : "null";
                          String reminderDate = data.length > 4 ? data[4] : "null";
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDaily ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.1), // تمييز العادة اليومية
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isDaily ? Colors.amber.withOpacity(0.3) : Colors.white12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDaily ? Colors.amber : Colors.grey.withOpacity(0.5),
                                child: Icon(_getIconForCategory(catKey), color: Colors.black, size: 20),
                              ),
                              title: Text(
                                title, 
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang.t(catKey), style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                                  
                                  // ✅ عرض وقت التذكير إذا وجد
                                  if (reminderDate != "null")
                                    Row(
                                      children: [
                                        const Icon(Icons.alarm, size: 12, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${lang.t('at')} ${_formatDate(reminderDate, lang)}",
                                          style: const TextStyle(color: Colors.amber, fontSize: 11),
                                        ),
                                      ],
                                    )
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                   showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.grey.shade900,
                                        title: Text(lang.t('delete_task_title'), style: GoogleFonts.cairo(color: Colors.white)),
                                        content: Text(lang.t('delete_task_ask'), style: GoogleFonts.cairo(color: Colors.white70)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.t('cancel'), style: const TextStyle(color: Colors.grey))),
                                          TextButton(onPressed: () { deleteTask(index); Navigator.pop(ctx); }, child: Text(lang.t('delete'), style: const TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                },
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
  }
}