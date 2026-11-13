import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

typedef SpeechStatusCallback = void Function(String status);

class GroqSpeechService {
  GroqSpeechService._();
  static final GroqSpeechService instance = GroqSpeechService._();

  static const String _endpoint =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  static const String _model = 'whisper-large-v3-turbo';


  static const String _apiKey =
      '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';

  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordingPath;

  bool get isRecording => _isRecording;

  Future<void> startRecording({SpeechStatusCallback? onStatus}) async {
    if (_isRecording) return;

    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission is required for Speak → Sign.');
    }

    final supported = await _recorder.isEncoderSupported(AudioEncoder.wav);

    if (!supported) {
      throw StateError('WAV recording is not supported on this device.');
    }

    final tempDir = await getTemporaryDirectory();
    await tempDir.create(recursive: true);

    final path =
        '${tempDir.path}/echosign_${DateTime.now().millisecondsSinceEpoch}.wav';

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );

    onStatus?.call('Recording... speak naturally.');

    await _recorder.start(config, path: path);

    _recordingPath = path;
    _isRecording = true;
  }

  Future<String> stopAndTranscribe({SpeechStatusCallback? onStatus}) async {
    if (!_isRecording) {
      throw StateError('No active recording.');
    }

    _isRecording = false;

    final stoppedPath = await _recorder.stop();
    final path = stoppedPath ?? _recordingPath;
    _recordingPath = null;

    if (path == null || path.trim().isEmpty) {
      throw StateError('No speech recording was created.');
    }

    final audioFile = File(path);

    if (!await audioFile.exists()) {
      throw StateError('Recorded audio file was not found.');
    }

    try {
      if (_apiKey == 'gsk_REPLACE_WITH_NEW_KEY' || _apiKey.trim().isEmpty) {
        throw StateError(
          'Groq API key is not configured. '
          'Open groq_speech_service.dart and paste your NEW key.',
        );
      }

      final size = await audioFile.length();

      if (size == 0) {
        throw StateError('The recorded audio file is empty.');
      }

      // Groq Free currently accepts direct audio uploads up to 25 MB.
      if (size > 25 * 1024 * 1024) {
        throw StateError(
          'Recording is too large. Keep each speech clip shorter.',
        );
      }

      onStatus?.call('Uploading speech to Groq...');

      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));

      request.headers['Authorization'] = 'Bearer $_apiKey';

      request.fields['model'] = _model;
      request.fields['language'] = 'en';
      request.fields['response_format'] = 'json';
      request.fields['temperature'] = '0';

      request.files.add(
        await http.MultipartFile.fromPath('file', path, filename: 'speech.wav'),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        throw StateError(
          'Groq rejected the API key. Create a new key and update the app.',
        );
      }

      if (response.statusCode == 413) {
        throw StateError('Audio file is too large for Groq Free.');
      }

      if (response.statusCode == 429) {
        throw StateError(
          'Groq Free rate limit reached. Wait a moment and try again.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Groq request failed (${response.statusCode}).';

        try {
          final body = jsonDecode(response.body);
          final apiMessage = body['error']?['message'];

          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage.trim();
          }
        } catch (_) {}

        throw StateError(message);
      }

      onStatus?.call('Groq transcription received.');

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        throw StateError('Unexpected Groq response.');
      }

      final text = body['text'];

      if (text is! String || text.trim().isEmpty) {
        throw StateError(
          'Groq did not recognize any speech. Try again and speak clearly.',
        );
      }

      return text.trim();
    } on SocketException {
      throw StateError(
        'No internet connection. Groq speech recognition requires internet.',
      );
    } finally {
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> cancel() async {
    if (_isRecording) {
      _isRecording = false;

      try {
        await _recorder.stop();
      } catch (_) {}
    }

    final path = _recordingPath;
    _recordingPath = null;

    if (path != null) {
      try {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await cancel();
  }
}
