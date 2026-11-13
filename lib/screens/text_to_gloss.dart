import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/groq_asl_gloss_service.dart';
import '../services/database_service.dart';

import 'gloss_screen.dart';

class TypeToGlossScreen extends StatefulWidget {
  static const String routeName = '/text_to_gloss';

  const TypeToGlossScreen({super.key});

  @override
  State<TypeToGlossScreen> createState() => _TypeToGlossScreenState();
}

class _TypeToGlossScreenState extends State<TypeToGlossScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  final TextEditingController _controller = TextEditingController();
  final GroqAslGlossService _glossService = GroqAslGlossService();
  bool _isConverting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _convertToGloss() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an English sentence first.'),
        ),
      );
      return;
    }

    setState(() => _isConverting = true);
    final gloss = await _glossService.convert(input);

    if (gloss.isEmpty) {
      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create a gloss for this sentence.'),
          ),
        );
      }
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await DatabaseService.instance.addTranslation(
        userId: user.id,
        englishText: input,
        aslGloss: gloss,
      );
    }

    if (!mounted) return;
    setState(() => _isConverting = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlossScreen(englishInput: input, aslGloss: gloss),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TYPE → GLOSS → SIGN',
          style: TextStyle(
            color: accentPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepBadge('Type', Icons.keyboard_alt_outlined, true),
                _buildStepDivider(),
                _buildStepBadge('Gloss', Icons.text_snippet_outlined, false),
                _buildStepDivider(),
                _buildStepBadge(
                  'Sign',
                  Icons.accessibility_new_outlined,
                  false,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    color: accentPurple,
                    size: 54,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Type your message in English',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'ASL gloss conversion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
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
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _convertToGloss(),
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: darkButtonColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: accentPurple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isConverting ? null : _convertToGloss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isConverting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            children: [
                              Text(
                                'Convert',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
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

  Widget _buildStepBadge(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? accentPurple : darkButtonColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() => Container(
    width: 10,
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.white10,
  );
}
