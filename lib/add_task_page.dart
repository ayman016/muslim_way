import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ❌ ما بقيناش محتاجين shared_preferences هنا

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController titleController = TextEditingController();
  String selectedCategory = "شخصي";

  final List<String> categories = ["شخصي", "عمل", "دين", "دراسة", "تسوق"];

  void saveTask() {
    if (titleController.text.isEmpty) return;
    
    // 1. تنسيق المهمة كيف ما اتفقنا: العنوان|التصنيف
    String newTask = "${titleController.text}|$selectedCategory";
    
    // 2. إرجاع المهمة للصفحة السابقة (NotesPage)
    // NotesPage هو اللي غايتكلف بالحفظ فـ Firestore
    Navigator.pop(context, newTask); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("مهمة جديدة", style: GoogleFonts.cairo(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عنوان المهمة", style: GoogleFonts.cairo(color: Colors.grey)),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                hintText: "ماذا تريد أن تنجز؟",
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2)),
              ),
            ),
            const SizedBox(height: 30),
            
            Text("نوع المهمة", style: GoogleFonts.cairo(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: categories.map((cat) {
                bool isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat, style: GoogleFonts.cairo(color: isSelected ? Colors.black : Colors.black)),
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
            
            const Spacer(),
            
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