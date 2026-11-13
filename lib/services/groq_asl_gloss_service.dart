import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'asl_gloss_service.dart';

class GroqAslGlossService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-120b';

  // Paste the same ACTIVE Groq key used by your speech service here.
  static const String _apiKey = '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';

  final AslGlossService _localFallback = AslGlossService();
  bool _lastUsedFallback = false;
  String? _lastError;

  bool get lastUsedFallback => _lastUsedFallback;
  String? get lastError => _lastError;

  Future<String> convert(String englishText) async {
    final input = englishText.trim();
    if (input.isEmpty) return '';

    _lastUsedFallback = false;
    _lastError = null;

    if (_apiKey.startsWith('gsk_REPLACE_') || _apiKey.trim().isEmpty) {
      return _fallback(input, 'Groq ASL gloss API key is not configured.');
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _model,
          'temperature': 0.1,
          'top_p': 1,
          'max_completion_tokens': 128,
          'messages': <Map<String, String>>[
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': input},
          ],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        return _fallback(input, 'Groq rejected the API key.');
      }
      if (response.statusCode == 429) {
        return _fallback(input, 'Groq Free rate limit reached.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'Groq gloss request failed (${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          final apiMessage = decoded['error']?['message'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage.trim();
          }
        } catch (_) {}
        return _fallback(input, message);
      }

      final decoded = jsonDecode(response.body);
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        return _fallback(input, 'Groq returned no ASL gloss.');
      }
      final message = choices.first['message'];
      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        return _fallback(input, 'Groq returned an empty ASL gloss.');
      }

      final cleaned = _cleanGloss(content);
      if (cleaned.isEmpty) {
        return _fallback(input, 'Groq returned an unusable ASL gloss.');
      }
      return cleaned;
    } on TimeoutException {
      return _fallback(input, 'Groq ASL gloss request timed out.');
    } on SocketException {
      return _fallback(input, 'No internet connection for AI ASL gloss.');
    } catch (error) {
      return _fallback(input, error.toString());
    }
  }

  String _fallback(String input, String reason) {
    _lastUsedFallback = true;
    _lastError = reason;
    return _localFallback.convert(input);
  }

  String _cleanGloss(String raw) {
    var text = raw.trim();
    text = text.replaceAll('```', '').trim();
    text = text.replaceFirst(
      RegExp(r'^\s*(ASL(?:-STYLE)?\s+GLOSS|GLOSS)\s*:\s*', caseSensitive: false),
      '',
    );
    return text
        .toUpperCase()
        .replaceAll(RegExp(r"[^A-Z0-9'\-\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const String _systemPrompt = '''
You convert English into concise ASL-style lexical gloss for a sign-video app.

Return ONLY the gloss. No explanation, labels, quotes, Markdown, or punctuation.
Use UPPERCASE lexical tokens separated by spaces.
Preserve meaning; do not invent information.
Prefer natural ASL-style order when appropriate:
- time/context early when natural
- topic-comment order when natural
- WH concepts WHAT WHERE WHO WHY WHEN near the end when natural
- omit A AN THE when they add no meaning
- omit AM IS ARE when ASL normally does not need a separate lexical sign
- omit DO DOES DID when they are only English question auxiliaries
- place NOT after the concept it negates when natural
Use simple pronouns I ME YOU HE SHE WE THEY.
Do NOT use specialist notation such as IX-1, PRO-1, FS-, CL:, TOPIC, RHQ, NMM.
Proper names may remain as uppercase words.
Keep output short and compatible with individual sign-video tokens.

Examples:
English: What is your name?
Gloss: YOUR NAME WHAT
English: Where do you live?
Gloss: YOU LIVE WHERE
English: I am going to school tomorrow.
Gloss: TOMORROW I GO SCHOOL
English: Do you want water?
Gloss: YOU WANT WATER
English: I do not understand.
Gloss: I UNDERSTAND NOT
English: She is happy today.
Gloss: TODAY SHE HAPPY
English: Why are you sad?
Gloss: YOU SAD WHY
''';
}