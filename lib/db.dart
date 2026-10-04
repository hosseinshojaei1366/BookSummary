import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;
  static late Directory root;

  static Future<void> init() async {
    root = await getApplicationDocumentsDirectory();
    for (final d in ['audio', 'covers']) {
      await Directory(p.join(root.path, d)).create(recursive: true);
    }
    await open();
  }

  static Future<void> open() async {
    _db = await openDatabase(
      p.join(root.path, 'app.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute(
            'CREATE TABLE books(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, author TEXT, cover TEXT, start_date TEXT, end_date TEXT, finished INTEGER DEFAULT 0)');
        await db.execute(
            'CREATE TABLE sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, book_id INTEGER NOT NULL, date TEXT NOT NULL, title TEXT, audio TEXT, transcript TEXT, duration INTEGER DEFAULT 0)');
      },
    );
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Database get db => _db!;

  /// مسیر فایل داخل پوشه audio یا covers
  static String path(String sub, String name) =>
      p.join(root.path, sub, name);
}
