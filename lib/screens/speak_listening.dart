import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/groq_asl_gloss_service.dart';
import '../services/database_service.dart';
import '../services/groq_speech_service.dart';
import 'avatar_result.dart';

class SpeakListeningScreen extends StatefulWidget {
  static const String routeName = '/speak_listening';

  const SpeakListeningScreen({super.key});

  @override
  State<SpeakListeningScreen> createState() =>
      _SpeakListeningScreenState();
}

class _SpeakListeningScreenState extends State<SpeakListeningScreen> {
  static const Color bgColor = Color(0xFF1A1A2E);
  static const Color accentPurple = Color(0xFF9D59FF);

  final GroqSpeechService _speechService = GroqSpeechService.instance;
  final GroqAslGlossService _glossService = GroqAslGlossService();

  bool _isStarting = false;
  bool _isRecording = false;
  bool _isTranscribing = false;

  String _status = 'Ready to record.';
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  Future<void> _startRecording() async {
    if (_isStarting || _isRecording || _isTranscribing) return;

    setState(() {
      _isStarting = true;
      _recognizedText = '';
      _status = 'Starting microphone...';
    });

    try {
      await _speechService.startRecording(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _status = status;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isStarting = false;
        _isRecording = true;
        _status =
            'Recording... speak naturally, then tap Stop & Transcribe.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isStarting = false;
        _isRecording = false;
        _status = _friendlyError(error);
      });
    }
  }

  Future<void> _stopAndTranscribe() async {
    if (!_isRecording || _isTranscribing) return;

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
      _status = 'Stopping recording...';
    });

    try {
      final text = await _speechService.stopAndTranscribe(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _status = status;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _recognizedText = text;
        _status = 'Preparing sign result...';
      });

      setState(() {
        _status = 'Converting English to ASL-style gloss with AI...';
      });

      final gloss = await _glossService.convert(text);

      if (!mounted) return;

      setState(() {
        _status = _glossService.lastUsedFallback
            ? 'AI gloss unavailable — local grammar fallback used.'
            : 'AI ASL-style gloss ready.';
      });

      if (gloss.trim().isEmpty) {
        throw StateError(
          'Could not create an ASL gloss from the recognized speech.',
        );
      }

      final user = context.read<AuthProvider>().currentUser;

      if (user != null) {
        await DatabaseService.instance.addTranslation(
          userId: user.id,
          englishText: text,
          aslGloss: gloss,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AvatarResultScreen(
            recognizedText: text,
            aslGloss: gloss,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isTranscribing = false;
        _isRecording = false;
        _status = _friendlyError(error);
      });
    }
  }

  Future<void> _retry() async {
    await _speechService.cancel();

    if (!mounted) return;

    setState(() {
      _recognizedText = '';
      _status = 'Ready to record.';
      _isStarting = false;
      _isRecording = false;
      _isTranscribing = false;
    });

    await _startRecording();
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Bad state: ', '');

    if (text.toLowerCase().contains('permission')) {
      return 'Microphone permission is required for Speak → Sign.';
    }

    if (text.toLowerCase().contains('internet') ||
        text.toLowerCase().contains('socket')) {
      return 'No internet connection. Groq speech recognition requires internet.';
    }

    if (text.toLowerCase().contains('rate limit')) {
      return 'Groq Free rate limit reached. Wait a moment and try again.';
    }

    if (text.toLowerCase().contains('api key') ||
        text.toLowerCase().contains('unauthorized')) {
      return 'Groq API key problem. Check your key in groq_speech_service.dart.';
    }

    return 'Speech recognition failed: $text';
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canStop =
        !_isStarting && _isRecording && !_isTranscribing;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Speak → Sign',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            children: [
              const Spacer(),

              SizedBox(
                height: 70,
                child: _isRecording
                    ? const _AudioWaveform()
                    : const Center(
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white24,
                          size: 52,
                        ),
                      ),
              ),

              const SizedBox(height: 26),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? const Color(0xFFE53935)
                      : accentPurple,
                ),
                child: Icon(
                  _isTranscribing
                      ? Icons.cloud_upload_rounded
                      : _isStarting
                          ? Icons.hourglass_top_rounded
                          : _isRecording
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                _isTranscribing
                    ? 'Transcribing...'
                    : _isStarting
                        ? 'Starting...'
                        : _isRecording
                            ? 'Recording...'
                            : 'Stopped',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),

              if (_isTranscribing) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(
                  minHeight: 6,
                ),
              ],

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF232336),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recognized speech',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _recognizedText.isEmpty
                          ? (_isRecording
                              ? 'Your text will appear after transcription.'
                              : 'No transcript yet.')
                          : '"$_recognizedText"',
                      style: TextStyle(
                        color: _recognizedText.isEmpty
                            ? Colors.white24
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              if (!_isRecording &&
                  !_isStarting &&
                  !_isTranscribing) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: canStop ? _stopAndTranscribe : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _isTranscribing
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    _isTranscribing
                        ? 'TRANSCRIBING...'
                        : 'STOP & TRANSCRIBE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioWaveform extends StatefulWidget {
  const _AudioWaveform();

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(15, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final offset = index * 0.55;

            var waveHeight =
                12 + 28 * sin((progress * 2 * pi) + offset).abs();

            if (index > 4 && index < 10) {
              waveHeight += 11;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: waveHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        );
      }),
    );
  }
}
