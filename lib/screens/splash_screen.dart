import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_service.dart';
import 'login_screen.dart';
import 'secure_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Shared Design System Colors
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  @override
  void initState() {
    super.initState();
    _continueFromSplash();
  }

  Future<void> _continueFromSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final db = await DatabaseService.instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM users');
      final accountCount = Sqflite.firstIntValue(result) ?? 0;

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        accountCount > 0
            ? LoginScreen.routeName
            : SecureScreen.routeName,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        LoginScreen.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, 
      body: Stack(
        children: [
          // Background with subtle purple gradient and glow
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
                // Logo Icon with outer glow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkButtonColor,
                    border: Border.all(color: accentPurple.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                 child: ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                 
                ),
                const SizedBox(height: 32),
                // App name
                const Text(
                  'ECHOSIGN PRO',
                  style: TextStyle(
                    color: accentPurple,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  'American Sign Language ↔ English',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Features
                const Text(
                  'Two-Way · AI-Assisted · For Everyone',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 50),
                
                // --- Animated Filling Progress Bar ---
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2), // Matches your Future.delayed
                  builder: (context, value, child) {
                    return Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: darkButtonColor, // Background track
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 200 * value, // Fills up based on animation value
                            decoration: BoxDecoration(
                              color: accentPurple,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: accentPurple.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}