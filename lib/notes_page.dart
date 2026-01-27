import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/add_task_page.dart'; 
import 'package:muslim_way/services/firestore_service.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart';

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

  // ✅ دالة الحذف المحسنة
  Future<void> deleteTask(int index) async {
    List<String> parts = tasks[index].split('|');
    
    // إلغاء الإشعار إذا كان موجود
    if (parts.length >= 6) {
      int notifId = int.tryParse(parts[5]) ?? 0;
      if (notifId > 0) {
        await NotificationService().cancelNotification(notifId);
        print("🗑️ تم إلغاء الإشعار رقم: $notifId");
      }
    }
    
    setState(() {
      tasks.removeAt(index);
    });
    await FirestoreService().updateTasks(tasks);
  }

  // دالة لتنسيق التاريخ
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

  // دالة للحصول على أيقونة التصنيف
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

               // جدولة الإشعار
               List<String> parts = result.split('|');
               
               if (parts.length >= 5 && parts[4] != "null") {
                 try {
                   DateTime reminder = DateTime.parse(parts[4]);
                   
                   if (reminder.isAfter(DateTime.now())) {
                     int notifId = parts.length >= 6 
                         ? (int.tryParse(parts[5]) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000)
                         : DateTime.now().millisecondsSinceEpoch ~/ 1000;
                     
                     await NotificationService().scheduleNotification(
                       id: notifId,
                       title: "تذكير: ${parts[0]}",
                       body: "حان موعد القيام بمهمتك: ${lang.t(parts[1])}",
                       scheduledTime: reminder,
                     );
                     
                     print("✅ تم جدولة الإشعار للمهمة: ${parts[0]}");
                   }
                 } catch (e) {
                   print("❌ خطأ في جدولة الإشعار: $e");
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
              Text(
                lang.t('my_tasks'), 
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)
              ),
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
                          List<String> data = tasks[index].split('|');
                          
                          String title = data[0];
                          String catKey = data.length > 1 ? data[1] : "cat_personal";
                          bool isDaily = data.length > 2 ? data[2] == 'true' : false;
                          String createdDate = data.length > 3 ? data[3] : "null";
                          String reminderDate = data.length > 4 ? data[4] : "null";
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDaily 
                                  ? Colors.amber.withOpacity(0.1) 
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDaily 
                                    ? Colors.amber.withOpacity(0.3) 
                                    : Colors.white12
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDaily 
                                    ? Colors.amber 
                                    : Colors.grey.withOpacity(0.5),
                                child: Icon(
                                  _getIconForCategory(catKey), 
                                  color: Colors.black, 
                                  size: 20
                                ),
                              ),
                              title: Text(
                                title, 
                                style: GoogleFonts.cairo(
                                  color: Colors.white, 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t(catKey), 
                                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)
                                  ),
                                  
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
                                        title: Text(
                                          lang.t('delete_task_title'), 
                                          style: GoogleFonts.cairo(color: Colors.white)
                                        ),
                                        content: Text(
                                          lang.t('delete_task_ask'), 
                                          style: GoogleFonts.cairo(color: Colors.white70)
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx), 
                                            child: Text(
                                              lang.t('cancel'), 
                                              style: const TextStyle(color: Colors.grey)
                                            )
                                          ),
                                          TextButton(
                                            onPressed: () { 
                                              deleteTask(index); 
                                              Navigator.pop(ctx); 
                                            }, 
                                            child: Text(
                                              lang.t('delete'), 
                                              style: const TextStyle(color: Colors.red)
                                            )
                                          ),
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