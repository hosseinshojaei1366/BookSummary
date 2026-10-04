import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../db.dart';
import '../services/stt.dart';
import '../util.dart';

class RecordScreen extends StatefulWidget {
  final Map<String, Object?> book;
  const RecordScreen(this.book, {super.key});
  @override
  State<RecordScreen> createState() => _RecordState();
}

class _RecordState extends State<RecordScreen> {
  final rec = AudioRecorder();
  final sw = Stopwatch();
  Timer? timer;
  bool recording = false, busy = false;
  String? file;
  String status = 'برای شروع، دکمه میکروفون را بزنید';
  final titleC = TextEditingController();
  final textC = TextEditingController();

  @override
  void dispose() {
    timer?.cancel();
    rec.dispose();
    titleC.dispose();
    textC.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    if (!recording) {
      if (!await rec.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('اجازه دسترسی به میکروفون داده نشد')));
        }
        return;
      }
      file = '${DateTime.now().millisecondsSinceEpoch}.wav';
      await rec.start(
          const RecordConfig(
              encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
          path: AppDb.path('audio', file!));
      sw
        ..reset()
        ..start();
      timer = Timer.periodic(
          const Duration(seconds: 1), (_) => setState(() {}));
      setState(() {
        recording = true;
        status = 'در حال ضبط...';
      });
    } else {
      await rec.stop();
      sw.stop();
      timer?.cancel();
      setState(() {
        recording = false;
        busy = true;
        status = 'در حال تبدیل صوت به متن...';
      });
      try {
        final txt = await Stt.transcribe(AppDb.path('audio', file!), (s) {
          if (mounted) setState(() => status = s);
        });
        textC.text = txt;
        status = txt.isEmpty
            ? 'متنی تشخیص داده نشد؛ می‌توانید دستی بنویسید'
            : 'تبدیل شد. متن را بررسی و ذخیره کنید';
      } catch (e) {
        status = 'خطا در تبدیل: $e\nصوت ذخیره می‌شود و متن را می‌توانید دستی بنویسید';
      }
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (file == null) return;
    await AppDb.db.insert('sessions', {
      'book_id': widget.book['id'],
      'date': DateTime.now().toIso8601String(),
      'title': titleC.text.trim(),
      'audio': file,
      'transcript': textC.text.trim(),
      'duration': sw.elapsed.inSeconds,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final el = sw.elapsed;
    return Scaffold(
      appBar: AppBar(title: Text('ضبط خلاصه • ${widget.book['title']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: titleC,
              decoration: const InputDecoration(
                  labelText: 'عنوان بخش (مثلاً فصل ۳)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: recording ? 112 : 96,
              height: recording ? 112 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recording ? Colors.red : cs.primary,
                boxShadow: [
                  BoxShadow(
                      color: (recording ? Colors.red : cs.primary)
                          .withOpacity(.4),
                      blurRadius: recording ? 30 : 12,
                      spreadRadius: recording ? 8 : 0)
                ],
              ),
              child: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text('${two(el.inMinutes)}:${two(el.inSeconds % 60)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (busy) const LinearProgressIndicator(),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(status, textAlign: TextAlign.center)),
          Expanded(
            child: TextField(
              controller: textC,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                  hintText: 'متن خلاصه اینجا نمایش داده می‌شود (قابل ویرایش)',
                  border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (file != null && !recording && !busy) ? save : null,
              icon: const Icon(Icons.save_rounded),
              label: const Text('ذخیره خلاصه'),
            ),
          ),
        ]),
      ),
    );
  }
}
