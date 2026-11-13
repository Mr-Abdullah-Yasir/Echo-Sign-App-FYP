import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/profile_image_service.dart';
import 'backup_restore_screen.dart';
import 'edit_profile.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color dangerRed = Color(0xFFFF4B4B);

  Uint8List? _profileImage;
  String _username = '';
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadUsername();
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
      setState(() => _username = username);
    } catch (_) {
      // Keep the profile usable if the username cannot be loaded.
    }
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await ProfileImageService.instance.loadProfileImage();
      if (!mounted) return;
      setState(() {
        _profileImage = bytes;
        _loadingImage = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;

    await context.read<AuthProvider>().refreshCurrentUser();
    await _loadUsername();
    await _loadImage();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'No user is signed in.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _open(const EditProfileScreen()),
                          child: Stack(
                            children: [
                              Container(
                                width: 86,
                                height: 86,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1D1925),
                                  border: Border.all(
                                    color: accentPurple,
                                    width: 2,
                                  ),
                                ),
                                child: _loadingImage
                                    ? const Padding(
                                        padding: EdgeInsets.all(28),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: accentPurple,
                                        ),
                                      )
                                    : _profileImage != null
                                        ? Image.memory(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Text(
                                              _initials(user.fullName),
                                              style: const TextStyle(
                                                color: accentPurple,
                                                fontSize: 27,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: accentPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (_username.isNotEmpty)
                                Text(
                                  '@$_username',
                                  style: const TextStyle(
                                    color: accentPurple,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (_username.isNotEmpty)
                                const SizedBox(height: 5),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Member since ${_monthYear(user.createdAt)}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit profile',
                          onPressed: () => _open(const EditProfileScreen()),
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Your Stats',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<int>(
                          future: DatabaseService.instance
                              .countTranslationsForUser(user.id),
                          builder: (_, snapshot) => _statCard(
                            snapshot.data?.toString() ?? '0',
                            'Translations',
                            Icons.history_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<int>(
                          future: DatabaseService.instance
                              .countFavoritesForUser(user.id),
                          builder: (_, snapshot) => _statCard(
                            snapshot.data?.toString() ?? '0',
                            'Favorites',
                            Icons.favorite_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Data',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    label: 'Translation History',
                    icon: Icons.history_rounded,
                    onTap: () => _open(const HistoryScreen()),
                  ),
                  const SizedBox(height: 10),
                  _actionButton(
                    label: 'Favorites',
                    icon: Icons.favorite_border_rounded,
                    onTap: () => _open(const FavoritesScreen()),
                  ),
                  const SizedBox(height: 10),
                  _actionButton(
                    label: 'Firebase Backup & Restore',
                    icon: Icons.cloud_sync_rounded,
                    onTap: () => _open(const BackupRestoreScreen()),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Account',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    label: 'Edit Profile',
                    icon: Icons.manage_accounts_rounded,
                    onTap: () => _open(const EditProfileScreen()),
                  ),
                  const SizedBox(height: 10),
                  _actionButton(
                    label: 'Sign Out',
                    icon: Icons.logout_rounded,
                    color: dangerRed,
                    onTap: () async {
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginScreen.routeName,
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentPurple),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = accentPurple,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10),
        ),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color == dangerRed ? dangerRed : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: color.withOpacity(0.75),
        ),
        onTap: onTap,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  static String _monthYear(DateTime date) {
    const months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
