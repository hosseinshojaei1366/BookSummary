import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import '../db.dart';
import '../util.dart';

class Export {
  /// خروجی پایان کتاب: یک فایل متنی + یک فایل صوتی (ادغام همه ضبط‌ها)
  static Future<List<String>> exportBook(Map<String, Object?> book) async {
    final sessions = await AppDb.db.query('sessions',
        where: 'book_id = ?', whereArgs: [book['id']], orderBy: 'date');
    final dir = Directory(p.join(AppDb.root.path, 'exports'));
    await dir.create(recursive: true);
    final base = 'book_${book['id']}';
    final result = <String>[];

    // ---- متن ----
    final buf = StringBuffer();
    buf.writeln(book['title']);
    final author = (book['author'] as String?) ?? '';
    if (author.isNotEmpty) buf.writeln('نویسنده: $author');
    buf.writeln('شروع مطالعه: ${jDateStr(book['start_date'] as String?)}');
    if (book['end_date'] != null) {
      buf.writeln('پایان مطالعه: ${jDateStr(book['end_date'] as String?)}');
    }
    buf.writeln('\n==============================');
    for (final s in sessions) {
      final t = (s['title'] as String?) ?? '';
      buf.writeln('\n${jDateStr(s['date'] as String?)}  ${t.isEmpty ? 'بخش' : t}');
      buf.writeln((s['transcript'] as String?) ?? '');
    }
    final txt = File(p.join(dir.path, '$base.txt'));
    await txt.writeAsString(buf.toString());
    result.add(txt.path);

    // ---- صوت ----
    final files = <File>[];
    var total = 0;
    for (final s in sessions) {
      final n = s['audio'] as String?;
      if (n == null) continue;
      final f = File(AppDb.path('audio', n));
      if (await f.exists()) {
        final len = await f.length();
        if (len > 44) {
          files.add(f);
          total += len - 44;
        }
      }
    }
    if (files.isNotEmpty) {
      final out = File(p.join(dir.path, '$base.wav'));
      final sink = out.openWrite();
      sink.add(_header(total));
      for (final f in files) {
        await sink.addStream(f.openRead(44));
      }
      await sink.close();
      result.add(out.path);
    }
    return result;
  }

  // هدر WAV: ۱۶kHz، مونو، ۱۶ بیت
  static Uint8List _header(int dataLen) {
    final h = ByteData(44);
    void s(int o, String t) {
      for (var i = 0; i < 4; i++) {
        h.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    s(0, 'RIFF');
    h.setUint32(4, 36 + dataLen, Endian.little);
    s(8, 'WAVE');
    s(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little);
    h.setUint32(24, 16000, Endian.little);
    h.setUint32(28, 32000, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    s(36, 'data');
    h.setUint32(40, dataLen, Endian.little);
    return h.buffer.asUint8List();
  }
}
