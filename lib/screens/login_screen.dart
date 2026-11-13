import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/security_service.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  String? _quickLoginFirebaseUid;
  bool _quickLoginBusy = false;

  @override
  void initState() {
    super.initState();
    _loadQuickLogin();
  }

  Future<void> _loadQuickLogin() async {
    final uid = await SecurityService.instance.getQuickLoginFirebaseUid();

    if (!mounted) return;

    setState(() {
      _quickLoginFirebaseUid = uid;
    });
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.signIn(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainScreen.routeName,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Sign in failed.'),
        ),
      );
    }
  }

  Future<void> _quickLogin() async {
    final uid = _quickLoginFirebaseUid;
    if (uid == null) return;

    setState(() {
      _quickLoginBusy = true;
    });

    final verified = await SecurityService.instance.authenticate(
      reason: 'Unlock EchoSign Pro',
    );

    if (!mounted) return;

    if (!verified) {
      setState(() {
        _quickLoginBusy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device authentication failed or was cancelled.',
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.quickSignIn(uid);

    if (!mounted) return;

    setState(() {
      _quickLoginBusy = false;
    });

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainScreen.routeName,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Quick Login failed.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.8,
                colors: [accentPurple.withOpacity(0.15), bgColor],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentPurple.withOpacity(0.35),
                              blurRadius: 24,
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

                    // adding a fyp demo screen button to the login screen here
/*
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/demo_screen');
                      },
                      child: const Text('FYP Demo Screen'),
                    ),
                    */
                    const SizedBox(height: 20),
                    const Text(
                      'EchoSign Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentPurple,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'American Sign Language ↔ English',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _identifierController,
                                keyboardType: TextInputType.text,
                                autofillHints: const [AutofillHints.username],
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  final identifier = value?.trim() ?? '';
                                  if (identifier.isEmpty) {
                                    return 'Enter your username or email.';
                                  }
                                  if (identifier.contains('@') &&
                                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(identifier)) {
                                    return 'Enter a valid email.';
                                  }
                                  if (!identifier.contains('@') &&
                                      !RegExp(r'^[A-Za-z0-9_]{3,20}$')
                                          .hasMatch(identifier)) {
                                    return 'Enter a valid username.';
                                  }
                                  return null;
                                },
                                decoration:
                                    _inputDecoration('Username or Email'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                autofillHints: const [AutofillHints.password],
                                style: const TextStyle(color: Colors.white),
                                validator: (value) => (value ?? '').isEmpty
                                    ? 'Enter your password.'
                                    : null,
                                decoration: _inputDecoration('Password')
                                    .copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _hidePassword = !_hidePassword,
                                        ),
                                        icon: Icon(
                                          _hidePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: accentPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (context.watch<AuthProvider>().needsEmailVerification) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: accentPurple.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: accentPurple.withOpacity(0.30),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Your email is not verified.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        onPressed: () async {
                                          final auth = context.read<AuthProvider>();
                                          final ok =
                                              await auth.resendVerificationEmail();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Verification email sent.'
                                                    : auth.errorMessage ??
                                                        'Could not send verification email.',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'RESEND VERIFICATION EMAIL',
                                          style: TextStyle(
                                            color: accentPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_quickLoginFirebaseUid != null) ...[
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Colors.white12),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(color: Colors.white38),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Colors.white12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _quickLoginBusy
                                        ? null
                                        : _quickLogin,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: accentPurple,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.fingerprint_rounded),
                                    label: Text(
                                      _quickLoginBusy
                                          ? 'VERIFYING...'
                                          : 'QUICK LOGIN',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Fingerprint, face, PIN, pattern, or device password',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New here? ',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            SignupScreen.routeName,
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: accentPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      errorStyle: const TextStyle(color: Color(0xFFFF7070)),
      filled: true,
      fillColor: darkButtonColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentPurple),
      ),
    );
  }
}
