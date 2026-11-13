import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const routeName = '/verify-email';

  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  bool _resending = false;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _checkVerification() async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerificationAndFinish();

    if (!mounted) return;

    if (verified) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
      _message('Email verified. Sign in to continue.');
    } else {
      _message(auth.errorMessage ?? 'Email is not verified yet.');
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerificationEmail();
    if (!mounted) return;
    setState(() => _resending = false);
    _message(
      ok
          ? 'Verification email sent again.'
          : auth.errorMessage ?? 'Could not resend verification email.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: accentPurple,
                    size: 68,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We sent a Firebase verification link to\n'
                    '${auth.firebaseUser?.email ?? 'your email address'}.\n\n'
                    'Open the link, then return here and press the button below.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: auth.isLoading ? null : _checkVerification,
                      style: FilledButton.styleFrom(
                        backgroundColor: accentPurple,
                      ),
                      icon: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: const Text("I'VE VERIFIED MY EMAIL"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(
                      _resending
                          ? 'SENDING...'
                          : 'RESEND VERIFICATION EMAIL',
                      style: const TextStyle(color: accentPurple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
