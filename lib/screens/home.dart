import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db.dart';
import '../widgets.dart';
import 'add_book.dart';
import 'backup.dart';
import 'book.dart';
import 'reports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  List<Map<String, Object?>> books = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await AppDb.db.rawQuery(
        'SELECT b.*, (SELECT COUNT(*) FROM sessions s WHERE s.book_id = b.id) AS cnt '
        'FROM books b ORDER BY finished, id DESC');
    if (mounted) setState(() => books = r);
  }

  Future<void> go(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    load();
  }

  Future<void> settings() async {
    final prefs = await SharedPreferences.getInstance();
    final c = TextEditingController(text: prefs.getString('openai_key') ?? '');
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنظیمات تبدیل صوت به متن'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'پیش‌فرض: تبدیل آفلاین با Vosk.\nبرای دقت بالاتر می‌توانید کلید OpenAI (Whisper) را وارد کنید. خالی بگذارید تا آفلاین بماند.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
              controller: c,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'کلید OpenAI (اختیاری)',
                  border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
          FilledButton(
              onPressed: () async {
                await prefs.setString('openai_key', c.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ذخیره')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('خلاصه‌یار کتاب',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              tooltip: 'گزارش‌ها',
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => go(const ReportsScreen())),
          IconButton(
              tooltip: 'پشتیبان‌گیری',
              icon: const Icon(Icons.cloud_upload_outlined),
              onPressed: () => go(const BackupScreen())),
          IconButton(
              tooltip: 'تنظیمات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: settings),
        ],
      ),
      body: books.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_stories_rounded, size: 90, color: cs.primary),
                const SizedBox(height: 12),
                const Text('هنوز کتابی اضافه نکرده‌اید',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('با دکمه «کتاب جدید» شروع کنید'),
              ]),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14),
              itemCount: books.length,
              itemBuilder: (_, i) {
                final b = books[i];
                final done = b['finished'] == 1;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => go(BookScreen(b)),
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(fit: StackFit.expand, children: [
                            Cover(b),
                            if (done)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Text('تمام شد',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b['title']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('${b['cnt']} خلاصه',
                                    style: TextStyle(
                                        fontSize: 12, color: cs.outline)),
                              ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => go(const AddBookScreen()),
        icon: const Icon(Icons.add),
        label: const Text('کتاب جدید'),
      ),
    );
  }
}
