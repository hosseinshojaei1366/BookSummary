import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../db.dart';
import '../util.dart';

class _R {
  final Jalali j;
  final int dur;
  final String title;
  _R(this.j, this.dur, this.title);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsState();
}

class _ReportsState extends State<ReportsScreen> {
  List<_R> rows = [];
  List<_R> finished = [];
  final now = Jalali.now();
  late int y = now.year;
  late int m = now.month;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.db.rawQuery(
        'SELECT s.date, s.duration, b.title FROM sessions s JOIN books b ON b.id = s.book_id');
    final f = await AppDb.db
        .query('books', where: 'finished = 1 AND end_date IS NOT NULL');
    if (!mounted) return;
    setState(() {
      rows = s
          .map((e) => _R(Jalali.fromDateTime(DateTime.parse(e['date'] as String)),
              (e['duration'] as int?) ?? 0, '${e['title']}'))
          .toList();
      finished = f
          .map((e) => _R(
              Jalali.fromDateTime(DateTime.parse(e['end_date'] as String)),
              0,
              '${e['title']}'))
          .toList();
    });
  }

  Widget stat(String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget nav(String label, VoidCallback prev, VoidCallback next) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: prev, icon: const Icon(Icons.chevron_right)),
          Text(label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: next, icon: const Icon(Icons.chevron_left)),
        ],
      );

  Widget monthly() {
    final items = rows.where((r) => r.j.year == y && r.j.month == m).toList();
    final byBook = <String, int>{};
    for (final r in items) {
      byBook[r.title] = (byBook[r.title] ?? 0) + 1;
    }
    final fin =
        finished.where((r) => r.j.year == y && r.j.month == m).toList();
    final sec = items.fold<int>(0, (a, r) => a + r.dur);
    return ListView(padding: const EdgeInsets.all(16), children: [
      nav('${monthNames[m - 1]} $y', () {
        setState(() {
          m--;
          if (m < 1) {
            m = 12;
            y--;
          }
        });
      }, () {
        setState(() {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
        });
      }),
      Row(children: [
        stat('خلاصه', '${items.length}'),
        stat('دقیقه ضبط', '${(sec / 60).ceil()}'),
        stat('کتاب', '${byBook.length}'),
      ]),
      const SizedBox(height: 8),
      const Text('کتاب‌های این ماه',
          style: TextStyle(fontWeight: FontWeight.bold)),
      if (byBook.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('—')),
      for (final e in byBook.entries)
        ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(e.key),
            trailing: Text('${e.value} خلاصه')),
      const SizedBox(height: 8),
      const Text('کتاب‌های تمام‌شده در این ماه',
          style: TextStyle(fontWeight: FontWeight.bold)),
      if (fin.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('—')),
      for (final r in fin)
        ListTile(
            leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
            title: Text(r.title)),
    ]);
  }

  Widget yearly() {
    final items = rows.where((r) => r.j.year == y).toList();
    final fin = finished.where((r) => r.j.year == y).toList();
    final perMonth = List<int>.filled(12, 0);
    final cnt = List<int>.filled(12, 0);
    for (final r in items) {
      perMonth[r.j.month - 1] += r.dur;
      cnt[r.j.month - 1]++;
    }
    final maxSec = perMonth.fold<int>(1, (a, b) => b > a ? b : a);
    final books = items.map((r) => r.title).toSet().length;
    final sec = items.fold<int>(0, (a, r) => a + r.dur);
    return ListView(padding: const EdgeInsets.all(16), children: [
      nav('سال $y', () => setState(() => y--), () => setState(() => y++)),
      Row(children: [
        stat('خلاصه', '${items.length}'),
        stat('ساعت ضبط', (sec / 3600).toStringAsFixed(1)),
        stat('کتاب', '$books'),
        stat('تمام‌شده', '${fin.length}'),
      ]),
      const SizedBox(height: 12),
      for (var i = 0; i < 12; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 70, child: Text(monthNames[i])),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    minHeight: 14, value: perMonth[i] / maxSec),
              ),
            ),
            SizedBox(
                width: 60,
                child: Text('${cnt[i]} خلاصه',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12))),
          ]),
        ),
      const SizedBox(height: 12),
      const Text('کتاب‌های تمام‌شده',
          style: TextStyle(fontWeight: FontWeight.bold)),
      if (fin.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('—')),
      for (final r in fin)
        ListTile(
            leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
            title: Text(r.title),
            trailing: Text(monthNames[r.j.month - 1])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('گزارش‌ها'),
          bottom: const TabBar(
              tabs: [Tab(text: 'ماهانه'), Tab(text: 'سالانه')]),
        ),
        body: TabBarView(children: [monthly(), yearly()]),
      ),
    );
  }
}
