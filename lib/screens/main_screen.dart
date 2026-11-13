import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  static const routeName = '/main';
  const MainScreen({super.key});

  // Design Colors
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ECHOSIGN PRO',
                      style: TextStyle(
                        color: accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/profile'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Central Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Practice Button
                      Positioned(
                        top: 20,
                        right: 20,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/practics_videos');
                          }, // Add logic if needed
                          icon: const Icon(Icons.menu_book, size: 16),
                          label: const Text(
                            "PRACTICE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentPurple,
                            side: const BorderSide(
                              color: accentPurple,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: accentPurple.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                      // Central Avatar and Text
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing Avatar Container
                            Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accentPurple.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentPurple.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 28,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/icon/icon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Your Sign Language Assistant',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select a mode below to start',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mode Selection Buttons (Bottom Grid)
              Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      context: context,
                      label: "SIGN → SPEAK",
                      icon: Icons.front_hand_outlined,
                      isActive: true,
                      onTap: () =>
                          Navigator.pushNamed(context, '/sign_to_speak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeButton(
                      context: context,
                      label: "SPEAK → SIGN",
                      icon: Icons.mic_none_outlined,
                      isActive: true,
                      onTap: () =>
                          Navigator.pushNamed(context, '/speak_to_sign'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildModeButton(
                context: context,
                label: "TYPE → GLOSS → SIGN",
                icon: Icons.keyboard_alt_outlined,
                isActive: false,
                fullWidth: true,
                onTap: () => Navigator.pushNamed(context, '/text_to_gloss'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: isActive ? accentPurple : darkButtonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
