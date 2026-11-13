import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/cloud_backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  static const String routeName = '/backup-restore';

  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  bool _busy = false;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    try {
      final value = await CloudBackupService.instance.getLastBackupTime();
      if (!mounted) return;
      setState(() => _lastBackup = value);
    } catch (_) {}
  }

  Future<void> _backupToFirebase() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _busy) return;

    setState(() => _busy = true);

    try {
      final count = await CloudBackupService.instance.createCloudBackup(
        localUserId: user.id,
      );

      await _loadLastBackup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase backup completed: $count translation${count == 1 ? '' : 's'} saved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase backup failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromFirebase() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Restore Firebase backup?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This replaces this account’s local translation history and favorites with its latest Firebase backup.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final count = await CloudBackupService.instance.restoreCloudBackup(
        localUserId: user.id,
      );

      await context.read<AuthProvider>().refreshCurrentUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore completed: $count translation${count == 1 ? '' : 's'} restored.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase restore failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _timeText(DateTime? time) {
    if (time == null) return 'No cloud backup yet';
    final local = time.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Last backup: ${local.day}/${local.month}/${local.year} '
        '${local.hour}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Backup & Restore',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  color: accentPurple,
                  size: 38,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Firebase Cloud Backup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Save translation history and favorites to your Firebase account. Sign into the same EchoSign account on another device and restore the latest backup.',
                  style: TextStyle(
                    color: Colors.white60,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _timeText(_lastBackup),
                  style: const TextStyle(
                    color: accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _actionCard(
            icon: Icons.cloud_upload_rounded,
            title: 'Back Up to Firebase',
            subtitle: 'Replace this account’s previous cloud snapshot.',
            onTap: _busy ? null : _backupToFirebase,
          ),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.cloud_download_rounded,
            title: 'Restore from Firebase',
            subtitle: 'Bring your saved history and favorites onto this device.',
            onTap: _busy ? null : _restoreFromFirebase,
          ),
          if (_busy) ...[
            const SizedBox(height: 22),
            const Center(
              child: CircularProgressIndicator(color: accentPurple),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentPurple.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: accentPurple),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cloud backups are private to the currently signed-in Firebase account. They are not shared with other EchoSign accounts.',
                    style: TextStyle(
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accentPurple),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
