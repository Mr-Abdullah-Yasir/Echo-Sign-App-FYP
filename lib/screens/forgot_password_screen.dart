import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color bg = Color(0xFF0D0B14);
  static const Color card = Color(0xFF16121E);
  static const Color purple = Color(0xFF9D59FF);
  static const Color field = Color(0xFF1D1925);

  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _message('Enter the verified email used for your EchoSign account.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordResetEmail(email);

    if (!mounted) return;

    if (ok) {
      _message(
        'If that email is registered, Firebase will send password-reset instructions.',
      );
      Navigator.pop(context);
    } else {
      _message(auth.errorMessage ?? 'Password reset email could not be sent.');
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: purple),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_rounded,
                    color: purple,
                    size: 58,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reset with your verified email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Firebase will send a secure password-reset link to your account email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Email'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: busy ? null : _sendReset,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(busy ? 'SENDING...' : 'SEND RESET EMAIL'),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      minimumSize: const Size.fromHeight(54),
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
