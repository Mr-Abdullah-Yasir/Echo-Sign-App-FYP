import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/profile_image_service.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';

  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _loadingImage = true;
  Uint8List? _existingImage;
  Uint8List? _newImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _nameController.text = user.fullName;
        _emailController.text = user.email;
      }

      _initialized = true;
      _loadUsername();
      _loadImage();
    }
  }

  Future<void> _loadUsername() async {
    try {
      final firebaseUser = context.read<AuthProvider>().firebaseUser;
      if (firebaseUser == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final username =
          (snapshot.data()?['username'] as String? ?? '').trim();

      if (!mounted) return;
      setState(() => _usernameController.text = username);
    } catch (_) {
      // Keep the rest of Edit Profile usable if username loading fails.
    }
  }

  Future<void> _loadImage() async {
    final bytes = await ProfileImageService.instance.loadProfileImage();
    if (!mounted) return;

    setState(() {
      _existingImage = bytes;
      _loadingImage = false;
    });
  }

  Future<void> _chooseImage() async {
    try {
      final bytes = await ProfileImageService.instance.pickImageBytes();
      if (!mounted || bytes == null) return;

      setState(() => _newImage = bytes);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() => _saving = true);

    try {
      await ProfileImageService.instance.removeProfileImage();
      if (!mounted) return;

      setState(() {
        _existingImage = null;
        _newImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove picture: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();

    try {
      // Firebase phase: full name is editable here. Email remains the verified
      // Firebase login address and is deliberately read-only.
      final ok = await auth.updateProfile(
        fullName: _nameController.text,
        email: _emailController.text,
      );

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Profile could not be updated.'),
          ),
        );
        return;
      }

      if (_newImage != null) {
        await ProfileImageService.instance.saveProfileImage(_newImage!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _newImage ?? _existingImage;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardColor,
                      border: Border.all(color: accentPurple, width: 2),
                    ),
                    child: _loadingImage
                        ? const Padding(
                            padding: EdgeInsets.all(38),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentPurple,
                            ),
                          )
                        : image != null
                            ? Image.memory(image, fit: BoxFit.cover)
                            : const Icon(
                                Icons.person_rounded,
                                color: accentPurple,
                                size: 54,
                              ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Choose picture',
                      onPressed: _saving ? null : _chooseImage,
                      style: IconButton.styleFrom(
                        backgroundColor: accentPurple,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: image == null || _saving ? null : _removeImage,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove picture'),
              ),
              const SizedBox(height: 18),
              _field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter your full name.';
                  if (text.length < 2) return 'Name is too short.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.alternate_email_rounded,
                enabled: false,
                validator: (_) => null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _emailController,
                label: 'Verified email',
                icon: Icons.verified_user_outlined,
                enabled: false,
                validator: (_) => null,
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username and email are tied to your Firebase account identity, so they are shown here as read-only. You can safely change your full name and profile picture.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving || user == null ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: accentPurple),
        filled: true,
        fillColor: cardColor,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: accentPurple),
        ),
      ),
    );
  }
}
