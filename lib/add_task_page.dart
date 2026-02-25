import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:muslim_way/providers/language_provider.dart';
import 'package:muslim_way/notification_service.dart';
import 'package:muslim_way/providers/user_data_provider.dart';
import 'package:muslim_way/theme/app_colors.dart';
import 'package:muslim_way/theme/app_fonts.dart';

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

  // category icons
  final Map<String, IconData> _categoryIcons = {
    "cat_personal": Icons.person_rounded,
    "cat_work": Icons.work_rounded,
    "cat_religion": Icons.mosque_rounded,
    "cat_study": Icons.menu_book_rounded,
    "cat_shopping": Icons.shopping_cart_rounded,
  };

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
          content: Text(
            lang.t('task_title_hint'),
            style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
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
        scheduledTime: reminderTime!,
      );
    } else if (existingNotifId != null) {
      await NotificationService().cancelNotification(int.parse(existingNotifId!));
    }

    if (mounted) Navigator.pop(context);
  }

  void _toggleDoneStatus() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (widget.taskIndex != null) {
      final provider = Provider.of<UserDataProvider>(context, listen: false);
      await provider.toggleTaskStatus(widget.taskIndex!);

      setState(() {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (lastDoneDate == today) {
          lastDoneDate = "null";
        } else {
          lastDoneDate = today;
        }
      });

      if (mounted) {
        bool isDone = lastDoneDate != "null";
        if (isDone) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 800),
              content: Text(
                lang.t('success_update'),
                style: AppFonts.mainStyle(context: context, listen: false, color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
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
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
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
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? lang.t('edit_task') : lang.t('add_task'),
          style: AppFonts.mainStyle(
            context: context,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.taskIndex != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                ),
                onPressed: () {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.warning,
                    dialogBackgroundColor: AppColors.surface,
                    animType: AnimType.rightSlide,
                    title: lang.t('confirm_delete'),
                    desc: lang.t('delete_task_ask'),
                    titleTextStyle: AppFonts.mainStyle(
                      context: context,
                      listen: false,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    descTextStyle: AppFonts.mainStyle(
                      context: context,
                      listen: false,
                      color: Colors.white70,
                    ),
                    btnCancelText: lang.t('cancel'),
                    btnOkText: lang.t('delete'),
                    btnOkColor: Colors.redAccent,
                    buttonsTextStyle: AppFonts.mainStyle(
                      context: context,
                      listen: false,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    btnCancelOnPress: () {},
                    btnOkOnPress: () {
                      Provider.of<UserDataProvider>(context, listen: false).deleteTask(widget.taskIndex!);
                      Navigator.pop(context);
                    },
                  ).show();
                },
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title Input ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: titleController,
                style: AppFonts.mainStyle(context: context, color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: lang.t('task_title_hint'),
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_rounded, color: AppColors.accent.withOpacity(0.6), size: 20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Mark as Done (edit mode) ─────────────────
            if (widget.taskIndex != null) ...[
              GestureDetector(
                onTap: _toggleDoneStatus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: isDoneToday
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF1B5E20).withOpacity(0.6),
                              const Color(0xFF2E7D32).withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [AppColors.surface, AppColors.surface],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDoneToday ? Colors.greenAccent.withOpacity(0.4) : AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: isDoneToday
                        ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 16)]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isDoneToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(isDoneToday),
                          color: isDoneToday ? Colors.greenAccent : AppColors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDoneToday ? lang.t('task_done_today') : lang.t('mark_as_done'),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: isDoneToday ? Colors.greenAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Daily Habit Toggle ───────────────────────
            _SectionLabel(label: lang.t('daily_habit'), icon: Icons.repeat_rounded),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => isDaily = !isDaily),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDaily ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDaily ? AppColors.primary.withOpacity(0.5) : Colors.white10,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      color: isDaily ? AppColors.accent : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.t('daily_habit'),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: isDaily ? Colors.white : Colors.white60,
                          fontWeight: isDaily ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    // custom switch look
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 46,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDaily ? AppColors.primary : Colors.white12,
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            alignment: isDaily ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Reminder ────────────────────────────────
            _SectionLabel(label: lang.t('set_reminder'), icon: Icons.alarm_rounded),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: reminderTime != null ? AppColors.accent.withOpacity(0.08) : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: reminderTime != null ? AppColors.accent.withOpacity(0.4) : Colors.white10,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm_rounded,
                      color: reminderTime != null ? AppColors.accent : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reminderTime != null
                            ? DateFormat('HH:mm').format(reminderTime!)
                            : lang.t('set_reminder'),
                        style: AppFonts.mainStyle(
                          context: context,
                          color: reminderTime != null ? AppColors.accent : Colors.white60,
                          fontWeight: reminderTime != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (reminderTime != null)
                      GestureDetector(
                        onTap: () => setState(() => reminderTime = null),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Category ────────────────────────────────
            _SectionLabel(label: lang.t('cat_personal').split('').first.toUpperCase() + 'ategory', icon: Icons.label_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryKeys.map((catKey) {
                final isSelected = selectedCategoryKey == catKey;
                final icon = _categoryIcons[catKey] ?? Icons.label_rounded;

                return GestureDetector(
                  onTap: () => setState(() => selectedCategoryKey = catKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.25) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary.withOpacity(0.6) : Colors.white10,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected ? AppColors.accent : Colors.white38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.t(catKey),
                          style: AppFonts.mainStyle(
                            context: context,
                            color: isSelected ? Colors.white : Colors.white54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // ── Save Button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
                ),
                onPressed: saveTask,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      lang.t('save'),
                      style: AppFonts.mainStyle(
                        context: context,
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Section Label ────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.mainStyle(
            context: context,
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}