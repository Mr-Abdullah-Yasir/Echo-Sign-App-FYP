import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/app_settings_service.dart';

class SignAnimationScreen extends StatelessWidget {
  static const String routeName = '/sign_animation';

  const SignAnimationScreen({
    super.key,
    required this.originalText,
    required this.aslGloss,
  });

  final String originalText;
  final String aslGloss;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignVideoSequencePlayer.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(
          'SIGN PLAYBACK',
          style: TextStyle(
            color: SignVideoSequencePlayer.accentPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SignVideoSequencePlayer(
          originalText: originalText,
          aslGloss: aslGloss,
          showTextSummary: true,
          showNewTextButton: true,
        ),
      ),
    );
  }
}

/// Reusable local MP4 sign-sequence player.
///
/// It tries the longest available phrase first. For example:
///   HELLO HOW YOU
///
/// It first tries:
///   hello-how-you.mp4
///   hello-how.mp4
///   hello.mp4
///
/// After HELLO plays, it tries:
///   how-you.mp4
///   how.mp4
///
/// Missing clips do not have to end the whole sequence. The user can skip the
/// unavailable gloss and continue with the remaining signs.
class SignVideoSequencePlayer extends StatefulWidget {
  const SignVideoSequencePlayer({
    super.key,
    required this.originalText,
    required this.aslGloss,
    this.showTextSummary = true,
    this.showNewTextButton = false,
    this.autoPlay = true,
  });

  final String originalText;
  final String aslGloss;
  final bool showTextSummary;
  final bool showNewTextButton;
  final bool autoPlay;

  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  @override
  State<SignVideoSequencePlayer> createState() =>
      _SignVideoSequencePlayerState();
}

class _SignVideoSequencePlayerState
    extends State<SignVideoSequencePlayer> {
  VideoPlayerController? _controller;

  late final List<String> _words;

  int _currentWordIndex = 0;
  int _currentSegmentLength = 1;

  bool _isLoading = true;
  bool _sequenceFinished = false;
  bool _handlingCompletion = false;

  String _currentSegmentLabel = '';
  String? _errorMessage;

  double _playbackSpeed = 1.0;
  bool _autoPlaySigns = true;
  bool _skipMissingSigns = false;
  bool _showGlossProgress = true;

  @override
  void initState() {
    super.initState();

    _words = widget.aslGloss
        .trim()
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.replaceAll(
            RegExp(r'^[^\w-]+|[^\w-]+$'),
            '',
          ),
        )
        .where((word) => word.isNotEmpty)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettingsAndStart();
    });
  }


  Future<void> _loadSettingsAndStart() async {
    final settings = AppSettingsService.instance;

    final speed = await settings.getPlaybackSpeed();
    final autoPlay = await settings.getAutoPlaySigns();
    final skipMissing = await settings.getSkipMissingSigns();
    final showProgress = await settings.getShowGlossProgress();

    if (!mounted) return;

    setState(() {
      _playbackSpeed = speed;
      _autoPlaySigns = autoPlay;
      _skipMissingSigns = skipMissing;
      _showGlossProgress = showProgress;
    });

    await _startSequence();
  }

  Future<void> _startSequence() async {
    if (_words.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No gloss words were available for playback.';
      });
      return;
    }

    _currentWordIndex = 0;
    _currentSegmentLength = 1;
    _currentSegmentLabel = '';
    _sequenceFinished = false;
    _errorMessage = null;

    await _playBestMatchFromCurrentIndex();
  }

  Future<void> _playBestMatchFromCurrentIndex() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _disposeController();

    if (_currentWordIndex >= _words.length) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _sequenceFinished = true;
        _currentSegmentLabel = 'DONE';
      });
      return;
    }

    final remainingCount = _words.length - _currentWordIndex;

    for (int length = remainingCount; length >= 1; length--) {
      final segment = _words.sublist(
        _currentWordIndex,
        _currentWordIndex + length,
      );

      final fileName = segment
          .map((word) => word.toLowerCase())
          .join('-');

      final assetPath = 'assets/sign_videos/$fileName.mp4';
      final controller = VideoPlayerController.asset(assetPath);

      try {
        await controller.initialize();

        if (!mounted) {
          await controller.dispose();
          return;
        }

        _controller = controller;
        _currentSegmentLength = length;
        _currentSegmentLabel = segment.join(' ');

        await controller.setPlaybackSpeed(_playbackSpeed);
        controller.addListener(_videoListener);

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        if (widget.autoPlay && _autoPlaySigns) {
          await controller.play();
        }
        return;
      } catch (_) {
        await controller.dispose();
      }
    }

    final missingWord = _words[_currentWordIndex];

    if (_skipMissingSigns) {
      _currentWordIndex += 1;
      _currentSegmentLength = 1;

      if (_currentWordIndex >= _words.length) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _sequenceFinished = true;
          _currentSegmentLabel = 'DONE';
          _errorMessage = null;
        });
        return;
      }

      await _playBestMatchFromCurrentIndex();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _sequenceFinished = false;
      _currentSegmentLength = 1;
      _currentSegmentLabel = missingWord;
      _errorMessage = 'Video unavailable for: $missingWord';
    });
  }

  void _videoListener() {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isCompleted ||
        _handlingCompletion) {
      return;
    }

    _handlingCompletion = true;

    _advanceSequence().whenComplete(() {
      _handlingCompletion = false;
    });
  }

  Future<void> _advanceSequence() async {
    _currentWordIndex += _currentSegmentLength;

    if (_currentWordIndex >= _words.length) {
      await _disposeController();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _sequenceFinished = true;
        _currentSegmentLabel = 'DONE';
      });
      return;
    }

    await _playBestMatchFromCurrentIndex();
  }

  Future<void> _skipMissing() async {
    if (_errorMessage == null) return;

    _currentWordIndex += 1;
    _currentSegmentLength = 1;

    if (_currentWordIndex >= _words.length) {
      if (!mounted) return;

      setState(() {
        _errorMessage = null;
        _isLoading = false;
        _sequenceFinished = true;
        _currentSegmentLabel = 'DONE';
      });
      return;
    }

    await _playBestMatchFromCurrentIndex();
  }

  Future<void> _replay() async {
    await _disposeController();

    if (!mounted) return;

    setState(() {
      _currentWordIndex = 0;
      _currentSegmentLength = 1;
      _currentSegmentLabel = '';
      _sequenceFinished = false;
      _errorMessage = null;
    });

    await _playBestMatchFromCurrentIndex();
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.isCompleted) {
        await controller.seekTo(Duration.zero);
      }

      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setPlaybackSpeed(speed);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _disposeController() async {
    final oldController = _controller;
    _controller = null;

    if (oldController != null) {
      oldController.removeListener(_videoListener);
      await oldController.dispose();
    }
  }

  @override
  void dispose() {
    final controller = _controller;

    if (controller != null) {
      controller.removeListener(_videoListener);
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final canShowVideo =
        controller != null &&
        controller.value.isInitialized &&
        _errorMessage == null;

    final processedWords = _sequenceFinished
        ? _words.length
        : (_currentWordIndex + _currentSegmentLength).clamp(
            0,
            _words.length,
          );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SignVideoSequencePlayer.accentPurple
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: SignVideoSequencePlayer.accentPurple
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _sequenceFinished
                        ? 'DONE'
                        : (_currentSegmentLabel.isEmpty
                            ? 'LOADING'
                            : _currentSegmentLabel),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SignVideoSequencePlayer.accentPurple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: SignVideoSequencePlayer.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildPlayerArea(canShowVideo),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSpeedControls(),
                if (widget.showTextSummary) ...[
                  const SizedBox(height: 18),
                  Text(
                    widget.aslGloss,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.originalText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (_words.isNotEmpty && _showGlossProgress) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$processedWords / ${_words.length} gloss words',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Row(
            children: [
              if (widget.showNewTextButton) ...[
                Expanded(
                  child: _buildActionButton(
                    label: 'New Text',
                    icon: Icons.add_rounded,
                    isPrimary: false,
                    onTap: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildActionButton(
                  label: _errorMessage != null
                      ? 'Skip Missing'
                      : _sequenceFinished
                          ? 'Replay'
                          : 'Play / Pause',
                  icon: _errorMessage != null
                      ? Icons.skip_next_rounded
                      : _sequenceFinished
                          ? Icons.replay_rounded
                          : (controller?.value.isPlaying ?? false)
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                  isPrimary: true,
                  onTap: _errorMessage != null
                      ? _skipMissing
                      : _sequenceFinished
                          ? _replay
                          : _togglePlayPause,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControls() {
    Widget speedButton(String label, double value) {
      final selected = _playbackSpeed == value;

      return Expanded(
        child: GestureDetector(
          onTap: () => _setPlaybackSpeed(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? SignVideoSequencePlayer.accentPurple
                  : SignVideoSequencePlayer.darkButtonColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? SignVideoSequencePlayer.accentPurple
                    : Colors.white10,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        speedButton('SLOW 0.75×', 0.75),
        const SizedBox(width: 8),
        speedButton('NORMAL 1×', 1.0),
        const SizedBox(width: 8),
        speedButton('FAST 1.25×', 1.25),
      ],
    );
  }

  Widget _buildPlayerArea(bool canShowVideo) {
    if (_errorMessage != null) {
      return Container(
        color: SignVideoSequencePlayer.darkButtonColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_file_outlined,
              color: Colors.white38,
              size: 58,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can skip this missing sign and continue the sequence.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_sequenceFinished) {
      return Container(
        color: SignVideoSequencePlayer.darkButtonColor,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: SignVideoSequencePlayer.accentPurple,
              size: 72,
            ),
            SizedBox(height: 14),
            Text(
              'Sign sequence complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading || !canShowVideo) {
      return Container(
        color: SignVideoSequencePlayer.darkButtonColor,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: SignVideoSequencePlayer.accentPurple,
        ),
      );
    }

    final controller = _controller!;

    final videoAspectRatio = controller.value.aspectRatio == 0
        ? 4 / 3
        : controller.value.aspectRatio;

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: videoAspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary
              ? SignVideoSequencePlayer.accentPurple
              : SignVideoSequencePlayer.darkButtonColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: SignVideoSequencePlayer.accentPurple
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
