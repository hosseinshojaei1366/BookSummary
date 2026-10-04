import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../db.dart';
import '../util.dart';

class SessionScreen extends StatefulWidget {
  final Map<String, Object?> s;
  const SessionScreen(this.s, {super.key});
  @override
  State<SessionScreen> createState() => _SessionState();
}

class _SessionState extends State<SessionScreen> {
  final player = AudioPlayer();
  late final titleC = TextEditingController(text: '${widget.s['title'] ?? ''}');
  late final textC =
      TextEditingController(text: '${widget.s['transcript'] ?? ''}');

  @override
  void initState() {
    super.initState();
    final n = widget.s['audio'] as String?;
    if (n != null) {
      player.setFilePath(AppDb.path('audio', n)).catchError((_) => null);
    }
  }

  @override
  void dispose() {
    player.dispose();
    titleC.dispose();
    textC.dispose();
    super.dispose();
  }

  Future<void> save() async {
    await AppDb.db.update(
        'sessions', {'title': titleC.text.trim(), 'transcript': textC.text.trim()},
        where: 'id = ?', whereArgs: [widget.s['id']]);
    if (mounted) Navigator.pop(context);
  }

  Future<void> remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف خلاصه'),
        content: const Text('صوت و متن این خلاصه حذف می‌شود.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    final n = widget.s['audio'] as String?;
    if (n != null) {
      final f = File(AppDb.path('audio', n));
      if (await f.exists()) await f.delete();
    }
    await AppDb.db
        .delete('sessions', where: 'id = ?', whereArgs: [widget.s['id']]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(jDateStr(widget.s['date'] as String?)),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: remove)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: titleC,
              decoration: const InputDecoration(
                  labelText: 'عنوان بخش', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(.5),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (c, snap) {
                  final playing = snap.data?.playing ?? false;
                  final completed =
                      snap.data?.processingState == ProcessingState.completed;
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(playing && !completed
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill),
                    onPressed: () async {
                      if (playing && !completed) {
                        await player.pause();
                      } else {
                        if (completed) await player.seek(Duration.zero);
                        player.play();
                      }
                    },
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (c, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final total = (player.duration ?? Duration.zero)
                                .inMilliseconds >
                            0
                        ? player.duration!.inMilliseconds
                        : 1;
                    return Directionality(
                      textDirection: TextDirection.ltr,
                      child: Slider(
                        value: pos.inMilliseconds.clamp(0, total).toDouble(),
                        max: total.toDouble(),
                        onChanged: (v) =>
                            player.seek(Duration(milliseconds: v.toInt())),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: textC,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                  labelText: 'متن خلاصه', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('ذخیره تغییرات')),
          ),
        ]),
      ),
    );
  }
}
