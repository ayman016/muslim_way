import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_way/add_task_page.dart'; // تأكد أن هذا الملف موجود

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<String> tasks = []; // تخزين المهام كنصوص: "عنوان|تصنيف"

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks = prefs.getStringList('user_tasks') ?? [];
    });
  }

  // دالة المسح مع رسالة تأكيد
  Future<void> confirmDelete(int index) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("مسح الملاحظة؟", style: GoogleFonts.cairo(color: Colors.white)),
        content: Text("هل أنت متأكد أنك تريد حذف هذه المهمة؟", style: GoogleFonts.cairo(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              deleteTask(index);
              Navigator.pop(ctx);
            },
            child: Text("حذف", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks.removeAt(index);
    });
    await prefs.setStringList('user_tasks', tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- حل مشكلة الزر المخفي ---
      // زدنا Padding من التحت باش نطلعو الزر فوق النافبار العائمة
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // 90 بيكسل كافية باش تبعد على النافبار
        child: FloatingActionButton(
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Icon(Icons.add, color: Colors.black, size: 30),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskPage()),
            );
            if (result == true) {
              loadTasks();
            }
          },
        ),
      ),

      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
             child: Opacity(
               opacity: 0.3, 
               child: Image.asset('assets/images/drawerbg.jpg', fit: BoxFit.cover)
             ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                Text("مهامي وأفكاري", style: GoogleFonts.cairo(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt_outlined, size: 80, color: Colors.white24),
                              SizedBox(height: 10),
                              Text("لا توجد مهام حالياً", style: GoogleFonts.cairo(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          // زدنا padding لتحت (bottom: 120) باش آخر عنصر يبان كامل ومايتغطاش بالنافبار
                          padding: EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 120),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            List<String> data = tasks[index].split('|');
                            String title = data[0];
                            String category = data.length > 1 ? data[1] : "عام";
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber.withOpacity(0.8),
                                  child: Icon(_getIconForCategory(category), color: Colors.black, size: 20),
                                ),
                                title: Text(
                                  title, 
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 18)
                                ),
                                subtitle: Text(category, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                                
                                // زر الحذف الواضح
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => confirmDelete(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case 'دين': return Icons.mosque;
      case 'عمل': return Icons.work;
      case 'شخصي': return Icons.person;
      case 'دراسة': return Icons.book;
      case 'تسوق': return Icons.shopping_cart;
      default: return Icons.task_alt;
    }
  }
}