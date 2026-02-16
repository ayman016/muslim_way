import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/user_data_provider.dart'; 
import 'package:muslim_way/theme/app_colors.dart'; // ✅ استدعاء الألوان الجديدة

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
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('task_title_hint'), style: GoogleFonts.cairo(color: Colors.white)), 
          backgroundColor: Colors.redAccent // أحمر خافت قليلاً
        )
      );
      return;
    }
    
    final provider = Provider.of<UserDataProvider>(context, listen: false);

    String createdAt = widget.taskToEdit != null 
        ? widget.taskToEdit!.split('|')[3] 
        : DateTime.now().toString();
        
    String reminderString = reminderTime != null ? reminderTime.toString() : "null";
    String notifIdToUse = existingNotifId ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    String taskData = "${titleController.text}|$selectedCategoryKey|$isDaily|$createdAt|$reminderString|$notifIdToUse|$lastDoneDate";
    
    if (widget.taskToEdit != null && widget.taskIndex != null) {
      await provider.editTask(widget.taskIndex!, taskData);
    } else {
      await provider.addTask(taskData);
    }

    if (reminderTime != null) {
      await NotificationService().scheduleNotification(
        id: int.parse(notifIdToUse), 
        title: "${lang.t('set_reminder')}: ${titleController.text}", 
        body: isDaily ? lang.t('daily_habit') : lang.t('one_time_task'), 
        scheduledTime: reminderTime!
      );
    } else if (existingNotifId != null) {
      await NotificationService().cancelNotification(int.parse(existingNotifId!));
    }
    
    if (mounted) Navigator.pop(context); 
  }

  void _markAsDone() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    
    if (widget.taskIndex != null) {
      final provider = Provider.of<UserDataProvider>(context, listen: false);
      
      await provider.markTaskAsDone(widget.taskIndex!); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('success_update'), style: GoogleFonts.cairo(color: Colors.white)), 
            backgroundColor: Colors.green
          )
        );
        setState(() {
          lastDoneDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        });
      }
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(), 
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary, // ✅ Royal Blue picker
            surface: AppColors.surface, // ✅ Surface picker bg
            onSurface: Colors.white,
          )
        ), 
        child: child!
      )
    );
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
      // ✅ الخلفية الأساسية (Navy)
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.taskToEdit == null ? lang.t('add_task') : lang.t('edit_task'), 
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // أيقونات بيضاء
        actions: [
          if (widget.taskIndex != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.warning,
                  dialogBackgroundColor: AppColors.surface, // ✅ لون الخلفية للحوار
                  animType: AnimType.rightSlide,
                  title: lang.t('confirm_delete'),
                  desc: lang.t('delete_task_ask'),
                  titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                  descTextStyle: GoogleFonts.cairo(color: Colors.white70),
                  btnCancelText: lang.t('cancel'),
                  btnOkText: lang.t('delete'),
                  btnOkColor: Colors.redAccent,
                  btnCancelOnPress: () {},
                  btnOkOnPress: () {
                    Provider.of<UserDataProvider>(context, listen: false).deleteTask(widget.taskIndex!);
                    Navigator.pop(context);
                  },
                ).show();
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: titleController, 
              style: const TextStyle(color: Colors.white, fontSize: 20), 
              decoration: InputDecoration(
                hintText: lang.t('task_title_hint'), 
                hintStyle: const TextStyle(color: Colors.grey), 
                // ✅ Underline بلون Royal Blue
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5))), 
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2))
              )
            ),
            const SizedBox(height: 30),
            
            // ✅ زر الإتمام (Styled)
            if (widget.taskIndex != null)
              GestureDetector(
                onTap: _markAsDone,
                child: Container(
                  width: double.infinity, 
                  padding: const EdgeInsets.all(15), 
                  margin: const EdgeInsets.only(bottom: 20), 
                  decoration: BoxDecoration(
                    // ✅ أخضر خافت عند الإنجاز، Surface عند الانتظار
                    color: isDoneToday ? const Color(0xFF1B5E20).withOpacity(0.5) : AppColors.surface, 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: isDoneToday ? Colors.transparent : AppColors.primary.withOpacity(0.2))
                  ), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(
                        isDoneToday ? Icons.check_circle : Icons.circle_outlined, 
                        // ✅ أيقونة Cyan عند الانتظار، أخضر عند الإنجاز
                        color: isDoneToday ? Colors.greenAccent : AppColors.accent
                      ), 
                      const SizedBox(width: 10), 
                      Text(
                        isDoneToday ? lang.t('task_done_today') : lang.t('mark_as_done'), 
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)
                      )
                    ]
                  )
                ),
              ),

            Container(
              padding: const EdgeInsets.all(5), 
              decoration: BoxDecoration(
                color: AppColors.surface, // ✅ Surface bg
                borderRadius: BorderRadius.circular(15), 
                border: Border.all(color: isDaily ? AppColors.primary : Colors.transparent)
              ), 
              child: SwitchListTile(
                title: Text(lang.t('daily_habit'), style: GoogleFonts.cairo(color: Colors.white)), 
                // ✅ Switch بلون Royal Blue
                activeColor: AppColors.primary, 
                value: isDaily, 
                onChanged: (val) => setState(() => isDaily = val)
              )
            ),
            const SizedBox(height: 20),
            
            ListTile(
              onTap: _pickTime, 
              tileColor: AppColors.surface, // ✅ Surface bg
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), 
                side: BorderSide(color: reminderTime != null ? AppColors.primary : Colors.transparent)
              ), 
              leading: Icon(Icons.alarm, color: reminderTime != null ? AppColors.accent : Colors.grey), 
              title: Text(lang.t('set_reminder'), style: GoogleFonts.cairo(color: Colors.white)), 
              subtitle: reminderTime != null ? Text(DateFormat('HH:mm').format(reminderTime!), style: const TextStyle(color: AppColors.accent)) : null, 
              trailing: reminderTime != null ? IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => setState(() => reminderTime = null)) : null
            ),
            const SizedBox(height: 30),
            
            // ✅ الفئات (Styled Chips)
            Wrap(
              spacing: 10, 
              children: categoryKeys.map((catKey) => ChoiceChip(
                label: Text(
                  lang.t(catKey), 
                  style: GoogleFonts.cairo(
                    color: selectedCategoryKey == catKey ? Colors.white : Colors.white70,
                    fontWeight: selectedCategoryKey == catKey ? FontWeight.bold : FontWeight.normal
                  )
                ), 
                selected: selectedCategoryKey == catKey, 
                // ✅ Chip Selected -> Royal Blue
                selectedColor: AppColors.primary, 
                backgroundColor: AppColors.surface, 
                side: BorderSide(color: selectedCategoryKey == catKey ? Colors.transparent : Colors.white10),
                onSelected: (val) => setState(() => selectedCategoryKey = catKey)
              )).toList()
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // ✅ Royal Blue Button
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ), 
                onPressed: saveTask, 
                child: Text(
                  lang.t('save'), 
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                )
              )
            )
          ],
        ),
      ),
    );
  }
}