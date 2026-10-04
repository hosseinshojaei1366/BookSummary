import 'dart:io';
import 'package:flutter/material.dart';
import 'db.dart';

/// جلد کتاب: عکس کاربر، یا یک جلد رنگی زیبا با حرف اول نام کتاب
class Cover extends StatelessWidget {
  final Map<String, Object?> book;
  final double? width, height;
  const Cover(this.book, {super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final name = book['cover'] as String?;
    final title = (book['title'] as String?) ?? '?';
    Widget child;
    if (name != null && File(AppDb.path('covers', name)).existsSync()) {
      child = Image.file(File(AppDb.path('covers', name)),
          fit: BoxFit.cover, width: width, height: height);
    } else {
      final hue = (title.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
      final c1 = HSLColor.fromAHSL(1, hue.toDouble(), .55, .38).toColor();
      final c2 =
          HSLColor.fromAHSL(1, ((hue + 40) % 360).toDouble(), .6, .28).toColor();
      child = Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
        ),
        child: Text(title.isEmpty ? '?' : title.substring(0, 1),
            style: const TextStyle(
                fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: child);
  }
}
