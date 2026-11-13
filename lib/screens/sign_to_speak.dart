import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class SignToSpeakScreen extends StatefulWidget {
  static const routeName = '/sign_to_speak';
  const SignToSpeakScreen({super.key});

  @override
  State<SignToSpeakScreen> createState() => _SignToSpeakScreenState();
}

class _SignToSpeakScreenState extends State<SignToSpeakScreen> {
  static const bg = Color(0xFF0D0B14);
  static const card = Color(0xFF16121E);
  static const purple = Color(0xFF9D59FF);
  static const dark = Color(0xFF1D1925);

  final _ip = TextEditingController(text: '10.20.31.28');
  final FlutterTts _tts = FlutterTts();
  final http.Client _httpClient = http.Client();
  CameraController? _camera;
  CameraDescription? _cameraInfo;
  List<CameraDescription> _cameras = [];

  bool _ready = false;
  bool _switchingCamera = false;
  bool _detecting = false;
  bool _auto = false;
  bool _sending = false;
  bool _server = false;
  bool _voiceEnabled = true;

  double _confidence = 0;
  int _frames = 0;
  int _hands = 0;
  String _handedness = '';
  String _title = 'Preparing camera...';
  String _subtitle = 'Please wait';
  final List<String> _history = [];
  final List<String> _recentPredictions = [];

  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAccepted = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTelemetryUi = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastLabel = '';

  // Adaptive pacing: one request stays in flight at a time, while this value
  // follows the real backend processing time instead of forcing a fixed FPS.
  int _adaptiveIntervalMs = 90;
  double _smoothedProcessingMs = 0;

  String get _baseUrl => 'http://${_ip.text.trim()}:8000';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // Recognition must continue even if a device has no TTS engine installed.
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled || text.trim().isEmpty) return;

    try {
      // Stop the previous utterance so rapid sign changes do not create
      // a queue of old words.
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Never interrupt sign recognition because of a TTS error.
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera found on this device');
      }

      _cameras = cameras;
      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      await _openCamera(selected);

      if (mounted) {
        _testServer(silent: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _title = 'Camera unavailable';
        _subtitle = '$e';
      });
    }
  }

  Future<void> _openCamera(CameraDescription selected) async {
    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      rethrow;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _camera = controller;
      _cameraInfo = selected;
      _ready = true;
      _title = 'Ready';
      _subtitle =
          '${selected.lensDirection == CameraLensDirection.front ? 'Front' : 'Back'} camera ready • Tap Start';
    });
  }

  Future<void> _switchCamera() async {
    if (_switchingCamera || _cameras.length < 2) return;

    final current = _cameraInfo;
    if (current == null) return;

    CameraDescription? target;
    final wanted = current.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    for (final camera in _cameras) {
      if (camera.lensDirection == wanted) {
        target = camera;
        break;
      }
    }

    if (target == null) {
      if (!mounted) return;
      setState(() {
        _title = 'Camera unavailable';
        _subtitle = wanted == CameraLensDirection.back
            ? 'No back camera was found'
            : 'No front camera was found';
      });
      return;
    }

    final wasDetecting = _detecting;
    _switchingCamera = true;

    if (mounted) {
      setState(() {
        _detecting = false;
        _ready = false;
        _title = 'Switching camera...';
        _subtitle = wanted == CameraLensDirection.back
            ? 'Opening back camera'
            : 'Opening front camera';
        _recentPredictions.clear();
        _lastLabel = '';
        _lastAccepted = DateTime.fromMillisecondsSinceEpoch(0);
        _confidence = 0;
        _frames = 0;
        _hands = 0;
        _handedness = '';
      });
    }

    final old = _camera;

    try {
      if (old != null && old.value.isStreamingImages) {
        try {
          await old.stopImageStream();
        } catch (_) {}
      }

      // Wait for an already-sent frame to finish before changing camera metadata.
      for (var i = 0; i < 30 && _sending; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await _resetServer();

      if (old != null) {
        try {
          await old.dispose();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _camera = null;
          _cameraInfo = null;
        });
      }

      await _openCamera(target);

      if (wasDetecting && mounted) {
        await _resetServer();
        final c = _camera;
        if (c != null && c.value.isInitialized) {
          final activeTarget = target;
          setState(() {
            _detecting = true;
            _title = 'Camera active';
            _subtitle =
                '${activeTarget.lensDirection == CameraLensDirection.front ? 'Front' : 'Back'} camera • Show a supported sign';
          });
          _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
          _lastTelemetryUi = DateTime.fromMillisecondsSinceEpoch(0);
          _adaptiveIntervalMs = 90;
          _smoothedProcessingMs = 0;
          if (!c.value.isStreamingImages) {
            await c.startImageStream(_onFrame);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _detecting = false;
        _title = 'Camera switch failed';
        _subtitle = '$e';
      });
    } finally {
      _switchingCamera = false;
      if (mounted) setState(() {});
    }
  }


  Future<bool> _testServer({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _title = 'Connecting...';
          _subtitle = _baseUrl;
        });
      }
      final r = await _httpClient.get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 4));
      final ok = r.statusCode == 200;
      if (mounted) {
        setState(() {
          _server = ok;
          if (!silent) {
            _title = ok ? 'Laptop connected' : 'Connection failed';
            _subtitle = ok ? 'Recognition server is ready' : 'HTTP ${r.statusCode}';
          }
        });
      }
      return ok;
    } catch (_) {
      if (mounted) {
        setState(() {
          _server = false;
          if (!silent) {
            _title = 'Laptop not connected';
            _subtitle = 'Check Wi-Fi, IP, and FastAPI';
          }
        });
      }
      return false;
    }
  }

  Future<void> _resetServer() async {
    try {
      await _httpClient.post(Uri.parse('$_baseUrl/reset'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_detecting) {
      await _stop();
      return;
    }
    final c = _camera;
    if (!_ready || c == null || !c.value.isInitialized) return;
    if (!await _testServer()) return;

    await _resetServer();
    if (!mounted) return;
    setState(() {
      _detecting = true;
      _confidence = 0;
      _frames = 0;
      _hands = 0;
      _handedness = '';
      _recentPredictions.clear();
      _lastLabel = '';
      _lastAccepted = DateTime.fromMillisecondsSinceEpoch(0);
      _title = 'Camera active';
      _subtitle =
          '${_cameraInfo?.lensDirection == CameraLensDirection.back ? 'Back' : 'Front'} camera • Show a supported sign';
    });
    _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
    _lastTelemetryUi = DateTime.fromMillisecondsSinceEpoch(0);
    _adaptiveIntervalMs = 90;
    _smoothedProcessingMs = 0;
    if (!c.value.isStreamingImages) {
      await c.startImageStream(_onFrame);
    }
  }

  Future<void> _stop() async {
    setState(() {
      _detecting = false;
      _title = 'Detection stopped';
      _subtitle = 'Tap Start when ready';
      _frames = 0;
      _recentPredictions.clear();
    });
    final c = _camera;
    if (c != null && c.value.isStreamingImages) {
      try { await c.stopImageStream(); } catch (_) {}
    }
    await _resetServer();
  }

  void _onFrame(CameraImage image) {
    if (!_detecting || _sending) return;

    final now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < _adaptiveIntervalMs) return;

    // This app/device is using the efficient single-plane NV21 CameraX path.
    // Do not concatenate planes here, because that creates another large
    // allocation for every frame.
    if (image.planes.length != 1) return;

    _lastSent = now;
    _sending = true;
    _sendFrame(image).whenComplete(() => _sending = false);
  }

  Future<void> _sendFrame(CameraImage image) async {
    final info = _cameraInfo;
    if (info == null || image.planes.length != 1) return;

    try {
      // Zero extra concatenation on the working CameraX NV21 path.
      final Uint8List rawBytes = image.planes[0].bytes;

      final r = await _httpClient.post(
        Uri.parse('$_baseUrl/predict_nv21'),
        headers: {
          'Content-Type': 'application/octet-stream',
          'X-Frame-Width': image.width.toString(),
          'X-Frame-Height': image.height.toString(),
          'X-Plane-Count': '1',
          'X-Row-Bytes': image.planes[0].bytesPerRow.toString(),
          'X-Pixel-Stride': (image.planes[0].bytesPerPixel ?? 1).toString(),
          'X-Sensor-Orientation': info.sensorOrientation.toString(),
          'X-Lens-Direction': info.lensDirection.name,
          'X-Reported-Format': image.format.group.name,
          'X-Transport-Format': 'nv21',
        },
        body: rawBytes,
      ).timeout(const Duration(seconds: 3));

      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (!mounted || !_detecting) return;

      // Let the phone pace itself from the real server cost.
      final processingMs =
          (data['processing_ms'] as num?)?.toDouble();
      if (processingMs != null && processingMs > 0) {
        if (_smoothedProcessingMs == 0) {
          _smoothedProcessingMs = processingMs;
        } else {
          _smoothedProcessingMs =
              (_smoothedProcessingMs * 0.80) + (processingMs * 0.20);
        }

        // Keep a little breathing room around MediaPipe/TFLite processing.
        // Clamp keeps interaction responsive while avoiding needless frame churn.
        _adaptiveIntervalMs =
            (_smoothedProcessingMs * 1.12).round().clamp(75, 180);
      }

      if (data['error'] != null) {
        setState(() {
          _server = true;
          _title = 'Frame decode problem';
          _subtitle = data['error'].toString();
        });
        return;
      }

      final frames = (data['frames_collected'] as num?)?.toInt() ?? 0;
      final hands = (data['hands_detected'] as num?)?.toInt() ?? 0;
      final handText = (data['handedness'] as List?)
              ?.map((e) => e.toString()).join(', ') ??
          '';

      // Ready predictions update the UI through _acceptPrediction().
      // Telemetry/warm-up text is intentionally limited to ~5 UI updates/sec.
      if (data['ready'] == true) {
        _frames = frames;
        _hands = hands;
        _handedness = handText;
        _server = true;
        _acceptPrediction(data);
        return;
      }

      final now = DateTime.now();
      final telemetryDue =
          now.difference(_lastTelemetryUi).inMilliseconds >= 200;

      if (telemetryDue) {
        _lastTelemetryUi = now;

        String newTitle;
        String newSubtitle;

        if (hands == 0) {
          newTitle = 'Looking for hands';
          newSubtitle = 'Keep your hand clearly in view';
        } else {
          final warmingUp = data['warming_up'] == true;
          newTitle =
              warmingUp ? 'Warming up live recognition' : 'Tracking live sign';
          newSubtitle = warmingUp
              ? 'Landmarks collected: $frames / 30'
              : 'Rolling window ready • updating prediction';
        }

        final changed = _server != true ||
            _frames != frames ||
            _hands != hands ||
            _handedness != handText ||
            _title != newTitle ||
            _subtitle != newSubtitle;

        if (changed) {
          setState(() {
            _server = true;
            _frames = frames;
            _hands = hands;
            _handedness = handText;
            _title = newTitle;
            _subtitle = newSubtitle;
          });
        }
      } else {
        // Keep internal telemetry current without rebuilding the widget tree.
        _server = true;
        _frames = frames;
        _hands = hands;
        _handedness = handText;
      }
    } catch (_) {
      if (!mounted) return;

      // Avoid rebuilding on every failed frame if the UI already shows the
      // same connection state.
      if (_server ||
          _title != 'Connection interrupted' ||
          _subtitle != 'Check laptop server') {
        setState(() {
          _server = false;
          _title = 'Connection interrupted';
          _subtitle = 'Check laptop server';
        });
      }
    }
  }

  void _acceptPrediction(Map<String, dynamic> data) {
    final label = data['label']?.toString() ?? 'Unknown';
    final conf =
        ((data['confidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);

    _recentPredictions.add(label);
    if (_recentPredictions.length > 3) {
      _recentPredictions.removeAt(0);
    }

    final counts = <String, int>{};
    for (final item in _recentPredictions) {
      counts[item] = (counts[item] ?? 0) + 1;
    }

    String stableLabel = label;
    int bestCount = 0;
    counts.forEach((key, value) {
      if (value > bestCount) {
        stableLabel = key;
        bestCount = value;
      }
    });

    final isStable = bestCount >= 2 && conf >= .55;
    final isNewHistoryEvent = isStable && stableLabel != _lastLabel;

    if (isNewHistoryEvent) {
      _lastLabel = stableLabel;
      _lastAccepted = DateTime.now();
    }

    final newTitle =
        isStable ? stableLabel.toUpperCase() : 'Recognizing...';
    final newSubtitle = isStable
        ? 'Live recognition • ${(conf * 100).toStringAsFixed(1)}% confidence'
        : 'Hold the sign briefly for a stable result';

    // One rebuild handles confidence, text, and History together.
    final confidenceChanged = (_confidence - conf).abs() >= 0.02;
    final textChanged = _title != newTitle || _subtitle != newSubtitle;

    if (confidenceChanged || textChanged || isNewHistoryEvent) {
      setState(() {
        _confidence = conf;
        _title = newTitle;
        _subtitle = newSubtitle;

        if (isNewHistoryEvent) {
          _history.insert(0, stableLabel);
          if (_history.length > 8) _history.removeLast();
        }
      });
    } else {
      _confidence = conf;
    }

    if (!isStable) return;

    if (isNewHistoryEvent) {
      _speak(stableLabel);
    }

    // Manual mode: stop after the first stable result.
    if (!_auto) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _detecting) _stop();
      });
    }
  }

  Future<void> _serverDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: const Text('Laptop Server'),
        content: TextField(
          controller: _ip,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'IPv4 address',
            hintText: '10.20.31.28',
            prefixIcon: Icon(Icons.laptop_mac),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _testServer();
            },
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detecting = false;
    _tts.stop();
    _httpClient.close();
    _ip.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text.rich(TextSpan(children: [
          TextSpan(text: 'Sign ', style: TextStyle(color: Colors.white)),
          TextSpan(text: '→ ', style: TextStyle(color: Colors.white38)),
          TextSpan(text: 'Speak', style: TextStyle(color: purple)),
        ])),
        actions: [
          Tooltip(
            message: _voiceEnabled ? 'Voice on' : 'Voice off',
            child: IconButton(
              onPressed: () {
                setState(() => _voiceEnabled = !_voiceEnabled);
                if (!_voiceEnabled) {
                  _tts.stop();
                } else if (_lastLabel.isNotEmpty) {
                  _speak(_lastLabel);
                }
              },
              icon: Icon(
                _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _voiceEnabled ? purple : Colors.white38,
              ),
            ),
          ),
          IconButton(
            onPressed: _detecting ? null : _serverDialog,
            icon: Icon(_server ? Icons.laptop_mac : Icons.cloud_off,
                color: _server ? purple : Colors.white38),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: const Text('Auto'),
              selected: _auto,
              onSelected: (v) {
                setState(() {
                  _auto = v;
                  _recentPredictions.clear();
                });
              },
              selectedColor: purple.withOpacity(.2),
            ),
          )
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recognition Confidence',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('${(_confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _confidence,
              minHeight: 4,
              backgroundColor: dark,
              valueColor: const AlwaysStoppedAnimation(purple),
            ),
          ]),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(fit: StackFit.expand, children: [
                _cameraView(),
                Container(color: Colors.black.withOpacity(.08)),
                Positioned(left: 12, top: 12, bottom: 12, width: 140,
                  child: _historyPanel()),
                Positioned(top: 12, right: 12, child: _cameraTools()),
                Positioned(right: 16, bottom: 16, child: _startButton()),
              ]),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            const CircleAvatar(
              backgroundColor: dark,
              child: Icon(Icons.translate_rounded, color: purple),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(_subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ])),
            if (_detecting)
              SizedBox(width: 42, height: 42, child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: (_frames / 30).clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(purple),
                ),
                Text('$_frames', style: const TextStyle(fontSize: 11)),
              ])),
          ]),
        ),
      ]),
    );
  }

  Widget _cameraView() {
    final c = _camera;
    if (!_ready || c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: purple));
    }
    return CameraPreview(c);
  }

  Widget _historyPanel() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg.withOpacity(.78),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('●  History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 12),
      Expanded(child: _history.isEmpty
        ? const Center(child: Text('No translations yet',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)))
        : ListView.builder(
            itemCount: _history.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_history[i],
                style: TextStyle(
                  color: i == 0 ? Colors.white : Colors.white70,
                  fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                )),
            ),
          )),
    ]),
  );

  Widget _cameraTools() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Tooltip(
        message: _cameraInfo?.lensDirection == CameraLensDirection.front
            ? 'Switch to back camera'
            : 'Switch to front camera',
        child: Material(
          color: bg.withOpacity(.82),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: (_switchingCamera || _cameras.length < 2)
                ? null
                : _switchCamera,
            child: SizedBox(
              width: 44,
              height: 44,
              child: _switchingCamera
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: purple,
                      ),
                    )
                  : const Icon(
                      Icons.cameraswitch_rounded,
                      color: purple,
                      size: 23,
                    ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _badge(
        _cameraInfo?.lensDirection == CameraLensDirection.back
            ? 'Back camera'
            : 'Front camera',
        _cameraInfo?.lensDirection == CameraLensDirection.back
            ? Icons.camera_alt_outlined
            : Icons.camera_front_outlined,
      ),
      const SizedBox(height: 6),
      _badges(),
    ],
  );

  Widget _badges() => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    _badge(_server ? 'Server online' : 'Server offline',
        _server ? Icons.cloud_done : Icons.cloud_off),
    if (_detecting) ...[
      const SizedBox(height: 6),
      _badge(_hands > 0 ? '$_hands hand${_hands == 1 ? '' : 's'}' : 'No hand',
          Icons.back_hand_outlined),
      if (_handedness.isNotEmpty) ...[
        const SizedBox(height: 6),
        _badge(_handedness, Icons.swap_horiz),
      ]
    ]
  ]);

  Widget _badge(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: bg.withOpacity(.8), borderRadius: BorderRadius.circular(14)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: purple, size: 14),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );

  Widget _startButton() => GestureDetector(
    onTap: _toggle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _detecting ? Colors.redAccent : purple),
      ),
      child: Row(children: [
        Icon(_detecting ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: _detecting ? Colors.redAccent : purple),
        const SizedBox(width: 8),
        Text(_detecting ? 'Stop' : 'Start',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}
