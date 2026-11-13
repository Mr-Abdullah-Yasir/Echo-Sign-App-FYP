import 'package:flutter/material.dart';

import 'sign_animation.dart';

class AvatarResultScreen extends StatelessWidget {
  static const String routeName = '/avatar_result';

  const AvatarResultScreen({
    super.key,
    required this.recognizedText,
    required this.aslGloss,
  });

  final String recognizedText;
  final String aslGloss;

  static const Color bgColor = Color(0xFF1A1A2E);
  static const Color cardColor = Color(0xFF232336);
  static const Color accentPurple = Color(0xFF9D59FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Speak → Sign Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recognized English',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recognizedText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ASL Gloss',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aslGloss,
                      style: const TextStyle(
                        color: accentPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SignVideoSequencePlayer(
                originalText: recognizedText,
                aslGloss: aslGloss,
                showTextSummary: false,
                showNewTextButton: false,
                autoPlay: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text(
                    'Speak Again',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
