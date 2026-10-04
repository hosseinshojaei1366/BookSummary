import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../db.dart';
import '../services/export.dart';
import '../util.dart';
import '../widgets.dart';
import 'record.dart';
import 'session.dart';

class BookScreen extends StatefulWidget {
  final Map<String, Object?> book;
  const BookScreen(this.book, {super.key});
  @override
  State<BookScreen> createState() => _BookState();
}

class _BookState extends State<BookScreen> {
  late Map<String, Object?> book = widget.book;
  List<Map<String, Object?>> sessions = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final b = await AppDb.db
        .query('books', where: 'id = ?', whereArgs: [book['id']]);
    final s = await AppDb.db.query('sessions',
        where: 'book_id = ?', whereArgs: [book['id']], orderBy: 'date DESC');
    if (!mounted) return;
    setState(() {
      if (b.isNotEmpty) book = b.first;
      sessions = s;
    });
  }

  Future<void> push(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    load();
  }

  Future<void> export() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('در حال ساخت خروجی...')));
    final files = await Export.exportBook(book);
    await Share.shareXFiles(files.map((f) => XFile(f)).toList(),
        text: 'خلاصه کتاب ${book['title']}');
  }

  Future<void> finish() async {
    final ok = await confirm('پایان کتاب',
        'کتاب تمام‌شده علامت می‌خورد و خروجی صوتی و متنی ساخته می‌شود.');
    if (!ok) return;
    await AppDb.db.update(
        'books',
        {'finished': 1, 'end_date': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [book['id']]);
    await load();
    await export();
  }

  Future<void> remove() async {
    final ok = await confirm(
        'حذف کتاب', 'کتاب و همه خلاصه‌ها و صوت‌های آن حذف می‌شود. مطمئنید؟');
    if (!ok) return;
    for (final s in sessions) {
      final n = s['audio'] as String?;
      if (n != null) {
        final f = File(AppDb.path('audio', n));
        if (await f.exists()) await f.delete();
      }
    }
    await AppDb.db
        .delete('sessions', where: 'book_id = ?', whereArgs: [book['id']]);
    await AppDb.db.delete('books', where: 'id = ?', whereArgs: [book['id']]);
    if (mounted) Navigator.pop(context);
  }

  Future<bool> confirm(String t, String m) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t),
        content: Text(m),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأیید')),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = book['finished'] == 1;
    final totalSec =
        sessions.fold<int>(0, (a, s) => a + ((s['duration'] as int?) ?? 0));
    return Scaffold(
      appBar: AppBar(
        title: Text('${book['title']}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'export') export();
              if (v == 'finish') finish();
              if (v == 'delete') remove();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'export', child: Text('خروجی صوتی و متنی')),
              if (!done)
                const PopupMenuItem(value: 'finish', child: Text('پایان کتاب')),
              const PopupMenuItem(value: 'delete', child: Text('حذف کتاب')),
            ],
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(.5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Cover(book, width: 100, height: 150),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${book['title']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (((book['author'] as String?) ?? '').isNotEmpty)
                  Text('${book['author']}'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  Chip(label: Text('${sessions.length} خلاصه')),
                  Chip(label: Text(minutesText(totalSec))),
                  if (done) const Chip(label: Text('تمام شد ✓')),
                ]),
                Text('شروع: ${jDateStr(book['start_date'] as String?)}',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('هنوز خلاصه‌ای ضبط نشده'))),
        for (final s in sessions)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.mic_rounded, color: cs.primary)),
              title: Text(((s['title'] as String?) ?? '').isEmpty
                  ? 'بخش'
                  : '${s['title']}'),
              subtitle: Text(
                  '${jDateStr(s['date'] as String?)} • ${((s['transcript'] as String?) ?? '').replaceAll('\n', ' ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              onTap: () => push(SessionScreen(s)),
            ),
          ),
      ]),
      floatingActionButton: done
          ? null
          : FloatingActionButton.extended(
              onPressed: () => push(RecordScreen(book)),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('ضبط خلاصه امروز')),
    );
  }
}
