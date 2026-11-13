import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.signUp(
      fullName: _nameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result == SignUpResult.success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        EmailVerificationScreen.routeName,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Sign up failed.')),
      );
    }
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    const Text(
                      "Let's get started!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentPurple,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if ((value?.trim().length ?? 0) < 2) {
                                    return 'Enter your full name.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration('Full Name'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  final username = value?.trim() ?? '';
                                  if (username.length < 3 || username.length > 20) {
                                    return 'Use 3-20 characters.';
                                  }
                                  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
                                    return 'Use letters, numbers, and underscore only.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration('Unique Username'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return 'Enter your email.';
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                    return 'Enter a valid email.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration('Email'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.length < 8) {
                                    return 'Use at least 8 characters.';
                                  }
                                  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
                                      !RegExp(r'[0-9]').hasMatch(password)) {
                                    return 'Include letters and numbers.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration('Password').copyWith(
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _hideConfirmPassword,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration('Confirm Password').copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _hideConfirmPassword = !_hideConfirmPassword,
                                    ),
                                    icon: Icon(
                                      _hideConfirmPassword
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
                                  onPressed: isLoading ? null : _signUp,
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
                                          'SIGN UP',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
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
