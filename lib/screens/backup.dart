import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/backup.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupState();
}

class _BackupState extends State<BackupScreen> {
  bool busy = false;
  String msg = '';

  Future<void> create() async {
    setState(() {
      busy = true;
      msg = 'در حال ساخت فایل پشتیبان...';
    });
    try {
      final path = await Backup.create();
      setState(() => msg = 'فایل پشتیبان ساخته شد. محل ذخیره را انتخاب کنید (مثلاً Google Drive یا Files).');
      await Share.shareXFiles([XFile(path)], text: 'پشتیبان خلاصه‌یار کتاب');
    } catch (e) {
      setState(() => msg = 'خطا: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> restore() async {
    final r = await FilePicker.platform.pickFiles();
    final path = r?.files.single.path;
    if (path == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی'),
        content: const Text(
            'اطلاعات فایل پشتیبان جایگزین اطلاعات فعلی می‌شود. ادامه می‌دهید؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('بازیابی')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      busy = true;
      msg = 'در حال بازیابی...';
    });
    try {
      await Backup.restore(path);
      setState(() => msg = 'بازیابی با موفقیت انجام شد ✓');
    } catch (e) {
      setState(() => msg = 'خطا: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget card(IconData i, String t, String d, VoidCallback f) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(i, size: 36, color: cs.primary),
            title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(d),
            onTap: busy ? null : f,
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('پشتیبان‌گیری')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        card(Icons.cloud_upload_outlined, 'ساخت پشتیبان',
            'همه کتاب‌ها، صوت‌ها، متن‌ها و جلدها در یک فایل ZIP', create),
        card(Icons.settings_backup_restore, 'بازیابی از پشتیبان',
            'انتخاب فایل ZIP پشتیبان', restore),
        if (busy) const Padding(
            padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        if (msg.isNotEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(msg)),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
              'پیشنهاد: هر هفته یک پشتیبان بسازید و در Google Drive ذخیره کنید. بعد از بازیابی، اپ را یک بار ببندید و دوباره باز کنید.',
              style: TextStyle(fontSize: 13)),
        ),
      ]),
    );
  }
}
