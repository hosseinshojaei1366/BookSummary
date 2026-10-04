import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db.dart';
import '../util.dart';

class Backup {
  /// ساخت فایل ZIP شامل دیتابیس + صوت‌ها + جلدها؛ مسیر فایل را برمی‌گرداند
  static Future<String> create() async {
    await AppDb.close();
    try {
      final tmp = await getTemporaryDirectory();
      final name =
          'booksummary-backup-${jDate(DateTime.now()).replaceAll('/', '-')}.zip';
      final out = p.join(tmp.path, name);
      final dynamic enc = ZipFileEncoder();
      await enc.create(out);
      await enc.addFile(File(p.join(AppDb.root.path, 'app.db')), 'app.db');
      for (final d in ['audio', 'covers']) {
        final dir = Directory(p.join(AppDb.root.path, d));
        if (!await dir.exists()) continue;
        await for (final e in dir.list()) {
          if (e is File) {
            await enc.addFile(e, '$d/${p.basename(e.path)}');
          }
        }
      }
      await enc.close();
      return out;
    } finally {
      await AppDb.open();
    }
  }

  /// بازیابی از فایل ZIP پشتیبان
  static Future<void> restore(String zipPath) async {
    await AppDb.close();
    try {
      final dynamic extract = extractFileToDisk;
      await extract(zipPath, AppDb.root.path);
    } finally {
      await AppDb.open();
    }
  }
}
