import 'package:flutter/material.dart';
import 'get_started_screen.dart';

class SkipContinueScreen extends StatelessWidget {
  static const routeName = '/skip-continue';
  const SkipContinueScreen({super.key});

  // Shared Design System Colors
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Dark background with subtle glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.8,
                colors: [
                  accentPurple.withOpacity(0.15),
                  bgColor,
                ],
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo box with hand and sparkle icons
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: darkButtonColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentPurple.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: accentPurple,
                          size: 60,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.15), // Replaced harsh pink with soft purple backing
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Title
                const Text(
                  'Real-Time Translation',
                  style: TextStyle(
                    color: accentPurple,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Sign to Speak · Speak to Sign',
                  style: TextStyle(
                    color: Colors.white54, // Softened for premium hierarchy
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Swipe to continue button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                GetStartedScreen.routeName,
              ),
              icon: const Icon(Icons.arrow_forward, color: Colors.white54),
              label: const Text(
                'Swipe to continue',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}