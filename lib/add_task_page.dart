import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController titleController = TextEditingController();
  String selectedCategoryKey = "cat_personal";
  bool isDaily = false;
  DateTime? reminderTime;

  final List<String> categoryKeys = [
    "cat_personal", "cat_work", "cat_religion", "cat_study", "cat_shopping"
  ];

  // ✅ دالة الحفظ المحسنة
  void saveTask() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("الرجاء إدخال عنوان المهمة", style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String createdAt = DateTime.now().toString();
    String reminderString = reminderTime != null ? reminderTime.toString() : "null";
    
    String newTask = "${titleController.text}|$selectedCategoryKey|$isDaily|$createdAt|$reminderString";
    
    // ✅ جدولة الإشعار
    if (reminderTime != null) {
      try {
        final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        // ✅ اختبار: إشعار فوري للتأكد
        await NotificationService().showImmediateNotification(
          "تم حفظ المهمة ✅",
          "المهمة: ${titleController.text}",
        );
        
        // ✅ جدولة التذكير
        await NotificationService().scheduleNotification(
          id: notifId,
          title: "تذكير: ${titleController.text}",
          body: isDaily ? "🔄 عادة يومية" : "📅 مهمة",
          scheduledTime: reminderTime!,
        );
        
        print("✅ تم ضبط التذكير للمهمة: ${titleController.text}");
        
        // حفظ الـ ID
        newTask = "$newTask|$notifId";
        
      } catch (e) {
        print("❌ فشل ضبط التذكير: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("تعذر ضبط التذكير", style: GoogleFonts.cairo()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
    
    Navigator.pop(context, newTask); 
  }

  // دالة اختيار الوقت
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber, 
              surface: Color(0xFF1E1E1E)
            ),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        reminderTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(lang.t('add_task'), style: GoogleFonts.cairo(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. العنوان
              Text(lang.t('task_title_hint'), style: GoogleFonts.cairo(color: Colors.grey)),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2)),
                ),
              ),
              const SizedBox(height: 30),
              
              // 2. نوع المهمة
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDaily ? Colors.amber : Colors.white10),
                ),
                child: SwitchListTile(
                  title: Text(
                    lang.t('daily_habit'), 
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    isDaily ? "🔄 ${lang.t('daily_habit')}" : "📅 ${lang.t('one_time_task')}", 
                    style: const TextStyle(color: Colors.grey)
                  ),
                  activeColor: Colors.amber,
                  value: isDaily,
                  onChanged: (val) => setState(() => isDaily = val),
                ),
              ),
              const SizedBox(height: 20),

              // 3. التذكير
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: reminderTime != null ? Colors.amber : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: reminderTime != null ? Colors.amber : Colors.grey),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('set_reminder'), 
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          if (reminderTime != null)
                            Text(
                              "${lang.t('reminder_set')} ${DateFormat('HH:mm').format(reminderTime!)}", 
                              style: const TextStyle(color: Colors.amber, fontSize: 12)
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (reminderTime != null) 
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => reminderTime = null),
                        )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 4. التصنيف
              Text(lang.t('task_type'), style: GoogleFonts.cairo(color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: categoryKeys.map((catKey) {
                  bool isSelected = selectedCategoryKey == catKey;
                  return ChoiceChip(
                    label: Text(
                      lang.t(catKey), 
                      style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.black)
                    ),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    onSelected: (val) {
                      setState(() {
                        selectedCategoryKey = catKey;
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
              
              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: saveTask,
                  child: Text(
                    lang.t('save'), 
                    style: GoogleFonts.cairo(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}