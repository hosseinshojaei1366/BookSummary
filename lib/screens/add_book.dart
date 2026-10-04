import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db.dart';
import '../widgets.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});
  @override
  State<AddBookScreen> createState() => _AddBookState();
}

class _AddBookState extends State<AddBookScreen> {
  final titleC = TextEditingController();
  final authorC = TextEditingController();
  String? cover;

  Future<void> pick() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 900, imageQuality: 85);
    if (x == null) return;
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy(AppDb.path('covers', name));
    setState(() => cover = name);
  }

  Future<void> save() async {
    if (titleC.text.trim().isEmpty) return;
    await AppDb.db.insert('books', {
      'title': titleC.text.trim(),
      'author': authorC.text.trim(),
      'cover': cover,
      'start_date': DateTime.now().toIso8601String(),
      'finished': 0,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کتاب جدید')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(
          child: GestureDetector(
            onTap: pick,
            child: Stack(alignment: Alignment.bottomLeft, children: [
              Cover({'title': titleC.text, 'cover': cover},
                  width: 150, height: 225),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_rounded,
                    color: Colors.white, size: 20),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('برای انتخاب عکس جلد بزنید')),
        const SizedBox(height: 20),
        TextField(
            controller: titleC,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'نام کتاب', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        TextField(
            controller: authorC,
            decoration: const InputDecoration(
                labelText: 'نویسنده', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.check),
            label: const Text('ذخیره')),
      ]),
    );
  }
}
