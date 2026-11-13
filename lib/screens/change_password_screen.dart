import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color _bg = Color(0xFF0D0B14);
  static const Color _card = Color(0xFF16121E);
  static const Color _purple = Color(0xFF9D59FF);
  static const Color _field = Color(0xFF1D1925);

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _buildDecoration(
    String label,
    bool isObscured,
    VoidCallback onToggle,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: _field,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white54,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _save() async {
    final newPassword = _newController.text;

    if (_currentController.text.isEmpty) {
      _showMessage('Enter current password.');
      return;
    }

    if (newPassword.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(newPassword) ||
        !RegExp(r'[0-9]').hasMatch(newPassword)) {
      _showMessage('Use at least 8 characters with letters and numbers.');
      return;
    }

    if (newPassword != _confirmController.text) {
      _showMessage('New passwords do not match.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.pop(context);
    } else {
      _showMessage(auth.errorMessage ?? 'Change failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildDecoration(
                    'Current Password',
                    _obscureCurrent,
                    () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildDecoration(
                    'New Password',
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildDecoration(
                    'Confirm New Password',
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('CHANGE PASSWORD'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}