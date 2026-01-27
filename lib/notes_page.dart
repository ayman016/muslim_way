import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅
import 'package:muslim_way/add_task_page.dart'; 
import 'package:muslim_way/services/firestore_service.dart';
import 'package:muslim_way/providers/language_provider.dart'; // ✅

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

  Future<void> confirmDelete(int index) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false); // ✅
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(lang.t('delete_task_title'), style: GoogleFonts.cairo(color: Colors.white)),
        content: Text(lang.t('delete_task_ask'), style: GoogleFonts.cairo(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              deleteTask(index);
              Navigator.pop(ctx);
            },
            child: Text(lang.t('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask(int index) async {
    setState(() {
      tasks.removeAt(index);
    });
    await FirestoreService().updateTasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context); // ✅

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
            // ملاحظة: AddTaskPage حتى هي غاتحتاج تعديل للترجمة من بعد، ولكن دابا خلينا نركزو على العرض
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskPage()),
            );
            
            if (result != null && result is String) {
               setState(() {
                 tasks.add(result);
               });
               await FirestoreService().updateTasks(tasks);
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
                    // ✅ تحسين شكل الـ Empty State
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
                          String category = data.length > 1 ? data[1] : "عام";
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                              
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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