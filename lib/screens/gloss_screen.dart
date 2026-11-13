import 'package:flutter/material.dart';
import 'sign_animation.dart';

class GlossScreen extends StatelessWidget {
  static const String routeName = '/gloss_screen';

  final String englishInput;
  final String aslGloss;

  const GlossScreen({
    super.key,
    required this.englishInput,
    required this.aslGloss,
  });

  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TYPE → GLOSS → SIGN',
          style: TextStyle(color: accentPurple, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepBadge('Type', Icons.keyboard_alt_outlined, false),
                _buildStepDivider(),
                _buildStepBadge('Gloss', Icons.text_snippet_outlined, true),
                _buildStepDivider(),
                _buildStepBadge('Sign', Icons.accessibility_new_outlined, false),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('ENGLISH INPUT', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(englishInput, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  const SizedBox(height: 24),
                  const Center(child: Icon(Icons.keyboard_double_arrow_down_rounded, color: accentPurple, size: 34)),
                  const SizedBox(height: 24),
                  const Text('ASL GLOSS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accentPurple, accentPurple.withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          aslGloss,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'verify complex sentences',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Edit Text', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignAnimationScreen(
                            originalText: englishInput,
                            aslGloss: aslGloss,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Watch Sign', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStepBadge(String label, IconData icon, bool isActive) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isActive ? accentPurple : darkButtonColor, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Icon(icon, color: Colors.white, size: 14), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]),
      );

  Widget _buildStepDivider() => Container(width: 10, height: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white10);
}
