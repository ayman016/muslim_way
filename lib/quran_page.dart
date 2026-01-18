import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class QuranPage extends StatelessWidget {
  QuranPage({super.key});

  final List<Map<String, String>> surahs = [
    {"name": "سورة الفاتحة", "url": "https://quran.com/1"},
    {"name": "سورة البقرة", "url": "https://quran.com/2"},
    {"name": "سورة آل عمران", "url": "https://quran.com/3"},
    {"name": "سورة النساء", "url": "https://quran.com/4"},
    {"name": "سورة الكهف", "url": "https://quran.com/18"},
    {"name": "سورة يس", "url": "https://quran.com/36"},
    {"name": "سورة الواقعة", "url": "https://quran.com/56"},
    {"name": "سورة الملك", "url": "https://quran.com/67"},
    // يمكنك إضافة باقي السور هنا
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("القرآن الكريم", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: surahs.length + 1, // +1 للزر الكامل
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == surahs.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.open_in_browser, color: Colors.black),
                label: Text("فتح المصحف الكامل", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.all(15)),
                onPressed: () => launchUrl(Uri.parse("https://quran.com"), mode: LaunchMode.externalApplication),
              ),
            );
          }
          
          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(Icons.menu_book, color: Colors.amber),
              title: Text(surahs[index]['name']!, style: GoogleFonts.cairo(color: Colors.white)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 15),
              onTap: () async {
                final Uri url = Uri.parse(surahs[index]['url']!);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          );
        },
      ),
    );
  }
}