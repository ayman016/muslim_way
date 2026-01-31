import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/user_data_provider.dart'; 

class AddTaskPage extends StatefulWidget {
  final String? taskToEdit; 
  final int? taskIndex; 

  const AddTaskPage({super.key, this.taskToEdit, this.taskIndex});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController titleController = TextEditingController();
  String selectedCategoryKey = "cat_personal";
  bool isDaily = false;
  DateTime? reminderTime;
  String? existingNotifId; 
  String lastDoneDate = "null"; 

  final List<String> categoryKeys = [
    "cat_personal", "cat_work", "cat_religion", "cat_study", "cat_shopping"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _loadTaskData();
    }
  }

  void _loadTaskData() {
    List<String> parts = widget.taskToEdit!.split('|');
    titleController.text = parts[0];
    if (parts.length > 1) selectedCategoryKey = parts[1];
    if (parts.length > 2) isDaily = parts[2] == 'true';
    if (parts.length > 4 && parts[4] != "null") {
      reminderTime = DateTime.parse(parts[4]);
    }
    if (parts.length > 5) existingNotifId = parts[5];
    if (parts.length > 6) lastDoneDate = parts[6];
  }

  void saveTask() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("الرجاء إدخال عنوان المهمة", style: GoogleFonts.cairo()), backgroundColor: Colors.red));
      return;
    }
    
    // ✅ استعمال listen: false باش ما يوقعش Loop
    final provider = Provider.of<UserDataProvider>(context, listen: false);

    String createdAt = widget.taskToEdit != null 
        ? widget.taskToEdit!.split('|')[3] 
        : DateTime.now().toString();
        
    String reminderString = reminderTime != null ? reminderTime.toString() : "null";
    String notifIdToUse = existingNotifId ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    String taskData = "${titleController.text}|$selectedCategoryKey|$isDaily|$createdAt|$reminderString|$notifIdToUse|$lastDoneDate";
    
    // ✅ هنا كيوقع التحديث والـ notifyListeners كيتطلق
    if (widget.taskToEdit != null && widget.taskIndex != null) {
      await provider.editTask(widget.taskIndex!, taskData);
    } else {
      await provider.addTask(taskData);
    }

    if (reminderTime != null) {
      await NotificationService().scheduleNotification(id: int.parse(notifIdToUse), title: "تذكير: ${titleController.text}", body: isDaily ? "🔄 عادة يومية" : "📅 مهمة", scheduledTime: reminderTime!);
    } else if (existingNotifId != null) {
      await NotificationService().cancelNotification(int.parse(existingNotifId!));
    }
    
    // ✅ فاش كيرجع، HomeTab و StatsPage غايتحدثو حيت فيهم Consumer
    if (mounted) Navigator.pop(context); 
  }

  // ✅ زر الإتمام من داخل صفحة التعديل
  void _markAsDone() async {
    if (widget.taskIndex != null) {
      final provider = Provider.of<UserDataProvider>(context, listen: false);
      await provider.markTaskAsDone(widget.taskIndex!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ تم إنجاز المهمة!", style: GoogleFonts.cairo()), backgroundColor: Colors.green)
        );
        // Navigator.pop(context);
      }
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now(), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.amber, surface: Color(0xFF1E1E1E))), child: child!));
    if (picked != null) {
      final now = DateTime.now();
      setState(() => reminderTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    bool isDoneToday = lastDoneDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.taskToEdit == null ? lang.t('add_task') : "تعديل المهمة", style: GoogleFonts.cairo(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
        actions: [
          if (widget.taskIndex != null)
          IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () {
    // ✅ بلاصت المسح المباشر، كنعيطو للـ Dialog
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning, // نوع التحذير (صفر/برتقالي)
      animType: AnimType.rightSlide,
      title: 'تأكيد الحذف',
      desc: 'هل أنت متأكد من حذف هذه المهمة نهائياً؟',
      btnCancelText: 'إلغاء',
      btnOkText: 'حذف',
      btnOkColor: Colors.red, // لون زر الحذف أحمر
      btnCancelOnPress: () {
        // ما دير والو، غير سد الـ Dialog
      },
      btnOkOnPress: () {
        // ✅ هنا فين كيمسح بصح
        Provider.of<UserDataProvider>(context, listen: false).deleteTask(widget.taskIndex!);
        Navigator.pop(context); // كيرجع للصفحة السابقة (NotesPage)
      },
    ).show();
  },
)
            // IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { Provider.of<UserDataProvider>(context, listen: false).deleteTask(widget.taskIndex!); Navigator.pop(context); })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: titleController, style: const TextStyle(color: Colors.white, fontSize: 20), decoration: InputDecoration(hintText: lang.t('task_title_hint'), hintStyle: const TextStyle(color: Colors.grey), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2)))),
            const SizedBox(height: 30),
            
            // ✅ زر الإتمام (يظهر عند التعديل)
            if (widget.taskIndex != null)
              GestureDetector(
                onTap: _markAsDone,
                child: Container(width: double.infinity, padding: const EdgeInsets.all(15), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDoneToday ? Colors.green.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDoneToday ? Colors.green : Colors.white24)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isDoneToday ? Icons.check_circle : Icons.circle_outlined, color: isDoneToday ? Colors.green : Colors.grey), const SizedBox(width: 10), Text(isDoneToday ? "✅ المهمة منجزة اليوم" : "تحديد المهمة كمنجزة", style: GoogleFonts.cairo(color: isDoneToday ? Colors.green : Colors.white))])),
              ),

            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDaily ? Colors.amber : Colors.white10)), child: SwitchListTile(title: Text(lang.t('daily_habit'), style: GoogleFonts.cairo(color: Colors.white)), activeColor: Colors.amber, value: isDaily, onChanged: (val) => setState(() => isDaily = val))),
            const SizedBox(height: 20),
            ListTile(onTap: _pickTime, tileColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: reminderTime != null ? Colors.amber : Colors.transparent)), leading: Icon(Icons.alarm, color: reminderTime != null ? Colors.amber : Colors.grey), title: Text(lang.t('set_reminder'), style: GoogleFonts.cairo(color: Colors.white)), subtitle: reminderTime != null ? Text(DateFormat('HH:mm').format(reminderTime!), style: const TextStyle(color: Colors.amber)) : null, trailing: reminderTime != null ? IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => reminderTime = null)) : null),
            const SizedBox(height: 30),
            Wrap(spacing: 10, children: categoryKeys.map((catKey) => ChoiceChip(label: Text(lang.t(catKey), style: GoogleFonts.cairo(color: selectedCategoryKey == catKey ? Colors.black : Colors.black)), selected: selectedCategoryKey == catKey, selectedColor: Colors.amber, backgroundColor: Colors.grey.withOpacity(0.2), onSelected: (val) => setState(() => selectedCategoryKey = catKey))).toList()),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: saveTask, child: Text(lang.t('save'), style: GoogleFonts.cairo(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))))
          ],
        ),
      ),
    );
  }
}