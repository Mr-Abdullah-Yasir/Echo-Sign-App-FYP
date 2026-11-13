import 'dart:ui';
import 'package:flutter/material.dart';
import 'skip_continue_screen.dart';

class SecureScreen extends StatelessWidget {
  static const routeName = '/secure';
  const SecureScreen({super.key});

  // Shared Design System Colors
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);
  static const Color dangerRed = Color(0xFFFF4B4B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background with subtle purple glow
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Features row with icons
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FeatureItem(
                        icon: Icons.linked_camera,
                        iconColor: dangerRed, // Updated to premium red
                        label: "bidirectional \nsync",
                      ),
                      FeatureItem(
                        icon: Icons.battery_0_bar,
                        iconColor: accentPurple,
                        label: "Low power\nusage",
                      ),
                      FeatureItem(
                        icon: Icons.lock,
                        iconColor: accentPurple,
                        label: "100% Private",
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Main title with glow
                  const Text(
                    'Works Smoothly &\nAnywhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentPurple,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: accentPurple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  const Text(
                    'Runs on low-end phones.\nYour data stays private.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54, // Softened for better contrast hierarchy
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Swipe to continue
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, SkipContinueScreen.routeName),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Swipe to continue',
                    style: TextStyle(color: Colors.white54),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1925), // Replaced black with design system darkButtonColor
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}