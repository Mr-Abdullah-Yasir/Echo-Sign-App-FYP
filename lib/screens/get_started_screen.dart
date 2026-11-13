import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'login_screen.dart';

class GetStartedScreen extends StatefulWidget {
  static const routeName = '/get-started';

  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color accentPurple = Color(0xFF9D59FF);

  bool _requestingPermissions = false;

  Future<void> _getStarted() async {
    if (_requestingPermissions) return;
    setState(() => _requestingPermissions = true);

    try {
      final statuses = await <Permission>[
        Permission.camera,
        Permission.microphone,
      ].request();

      if (!mounted) return;

      final camera = statuses[Permission.camera];
      final mic = statuses[Permission.microphone];

      final cameraGranted = camera?.isGranted ?? false;
      final micGranted = mic?.isGranted ?? false;

      if (cameraGranted && micGranted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }

      final permanentlyDenied =
          (camera?.isPermanentlyDenied ?? false) ||
          (mic?.isPermanentlyDenied ?? false);

      if (permanentlyDenied) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF16121E),
            title: const Text(
              'Permission Required',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Camera or microphone access has been permanently denied. '
              'Open app settings and allow the required permissions.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'OPEN SETTINGS',
                  style: TextStyle(color: accentPurple),
                ),
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await openAppSettings();
        }
        return;
      }

      final missing = <String>[
        if (!cameraGranted) 'camera',
        if (!micGranted) 'microphone',
      ];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please allow ${missing.join(' and ')} access to continue.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not request camera and microphone permissions. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _requestingPermissions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PermissionIcon(icon: Icons.camera_alt),
                      SizedBox(width: 40),
                      PermissionIcon(icon: Icons.mic),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Start Translating',
                    style: TextStyle(
                      color: accentPurple,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: accentPurple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Allow camera and microphone access?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _requestingPermissions ? null : _getStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      disabledBackgroundColor: accentPurple.withOpacity(0.45),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: _requestingPermissions
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'GET STARTED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
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

class PermissionIcon extends StatelessWidget {
  final IconData icon;

  const PermissionIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1925),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9D59FF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D59FF).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xFF9D59FF),
        size: 36,
      ),
    );
  }
}
