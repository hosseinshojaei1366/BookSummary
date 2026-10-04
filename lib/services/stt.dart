import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// تبدیل صوت به متن فارسی
/// - اگر کلید OpenAI در تنظیمات وارد شده باشد: Whisper (دقت بالا، نیاز به اینترنت)
/// - در غیر این صورت: Vosk آفلاین (مدل فارسی؛ بار اول دانلود می‌شود)
class Stt {
  static Model? _model;

  static Future<String> transcribe(
      String wavPath, void Function(String) onStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final key = (prefs.getString('openai_key') ?? '').trim();
    if (key.isNotEmpty) {
      onStatus('در حال تبدیل صوت به متن (Whisper)...');
      return _whisper(wavPath, key);
    }
    return _vosk(wavPath, onStatus);
  }

  static Future<String> _whisper(String path, String key) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('https://api.openai.com/v1/audio/transcriptions'))
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'fa'
      ..files.add(await http.MultipartFile.fromPath('file', path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Whisper ${res.statusCode}');
    }
    return (jsonDecode(utf8.decode(res.bodyBytes))['text'] as String).trim();
  }

  static Future<String> _vosk(
      String path, void Function(String) onStatus) async {
    final vosk = VoskFlutterPlugin.instance();
    if (_model == null) {
      onStatus('در حال آماده‌سازی مدل فارسی (بار اول دانلود می‌شود، حدود ۵۰ مگابایت)...');
      final modelPath = await ModelLoader().loadFromNetwork(
          'https://alphacephei.com/vosk/models/vosk-model-small-fa-0.42.zip');
      _model = await vosk.createModel(modelPath);
    }
    onStatus('در حال تبدیل صوت به متن...');
    final rec = await vosk.createRecognizer(model: _model!, sampleRate: 16000);
    final bytes = await File(path).readAsBytes();
    final parts = <String>[];
    String textOf(String json) =>
        ((jsonDecode(json) as Map)['text'] ?? '').toString().trim();

    var pos = 44; // رد کردن هدر WAV
    while (pos < bytes.length) {
      final end = (pos + 8000 < bytes.length) ? pos + 8000 : bytes.length;
      final done = await rec.acceptWaveformBytes(
          Uint8List.fromList(bytes.sublist(pos, end)));
      if (done) {
        final t = textOf(await rec.getResult());
        if (t.isNotEmpty) parts.add(t);
      }
      pos = end;
    }
    final last = textOf(await rec.getFinalResult());
    if (last.isNotEmpty) parts.add(last);
    await rec.dispose();
    return parts.join(' ');
  }
}
