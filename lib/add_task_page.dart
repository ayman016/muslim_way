import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController titleController = TextEditingController();
  String selectedCategory = "شخصي";

  final List<String> categories = ["شخصي", "عمل", "دين", "دراسة", "تسوق"];

  Future<void> saveTask() async {
    if (titleController.text.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> tasks = prefs.getStringList('user_tasks') ?? [];
    
    // حفظ بصيغة: العنوان|التصنيف
    String newTask = "${titleController.text}|$selectedCategory";
    tasks.add(newTask);
    
    await prefs.setStringList('user_tasks', tasks);
    Navigator.pop(context, true); // الرجوع مع نتيجة نجاح
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("مهمة جديدة", style: GoogleFonts.cairo(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عنوان المهمة", style: GoogleFonts.cairo(color: Colors.grey)),
            TextField(
              controller: titleController,
              style: TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                hintText: "ماذا تريد أن تنجز؟",
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2)),
              ),
            ),
            SizedBox(height: 30),
            
            Text("نوع المهمة", style: GoogleFonts.cairo(color: Colors.grey)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: categories.map((cat) {
                bool isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat, style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.white)),
                  selected: isSelected,
                  selectedColor: Colors.amber,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  onSelected: (val) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                );
              }).toList(),
            ),
            
            Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: saveTask,
                child: Text("إضافة", style: GoogleFonts.cairo(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}