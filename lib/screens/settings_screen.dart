import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/app_settings_service.dart';
import '../services/security_service.dart';
import 'change_password_screen.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);
  static const Color darkButtonColor = Color(0xFF1D1925);

  final AppSettingsService _settings = AppSettingsService.instance;

  bool _loading = true;
  double _playbackSpeed = 1.0;
  bool _autoPlaySigns = true;
  bool _skipMissingSigns = false;
  bool _showGlossProgress = true;
  bool _deviceAuthAvailable = false;
  bool _quickLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final speed = await _settings.getPlaybackSpeed();
    final autoplay = await _settings.getAutoPlaySigns();
    final skipMissing = await _settings.getSkipMissingSigns();
    final showProgress = await _settings.getShowGlossProgress();
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final deviceAuth =
        await SecurityService.instance.isDeviceAuthenticationAvailable();
    final quickLogin = firebaseUid == null
        ? false
        : await SecurityService.instance
            .isQuickLoginEnabledForFirebaseUser(firebaseUid);

    if (!mounted) return;

    setState(() {
      _playbackSpeed = speed;
      _autoPlaySigns = autoplay;
      _skipMissingSigns = skipMissing;
      _showGlossProgress = showProgress;
      _deviceAuthAvailable = deviceAuth;
      _quickLoginEnabled = quickLogin;
      _loading = false;
    });
  }

  Future<void> _resetDefaults() async {
    await _settings.resetDefaults();
    await _load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults.')),
    );
  }

  Future<void> _toggleQuickLogin(bool value) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    if (firebaseUid == null) {
      _showMessage('No Firebase account is currently signed in.');
      return;
    }

    if (value) {
      if (!_deviceAuthAvailable) {
        _showMessage('Device authentication is not available on this device.');
        return;
      }

      final ok = await SecurityService.instance.authenticate(
        reason: 'Verify your identity to enable Quick Login',
      );

      if (!ok) {
        _showMessage('Device authentication failed or was cancelled.');
        return;
      }

      await SecurityService.instance
          .enableQuickLoginForFirebaseUser(firebaseUid);
    } else {
      await SecurityService.instance
          .disableQuickLoginForFirebaseUser(firebaseUid);
    }

    if (!mounted) return;

    setState(() => _quickLoginEnabled = value);
    _showMessage(value ? 'Quick Login enabled.' : 'Quick Login disabled.');
  }

  Future<void> _testDeviceAuth() async {final ok=await SecurityService.instance.authenticate(reason:'Test EchoSign device authentication');_showMessage(ok?'Device authentication is working.':'Device authentication failed or was cancelled.');}
  void _showMessage(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}

  String _speedLabel(double value) {
    if (value <= 0.75) return 'Slow';
    if (value >= 1.25) return 'Fast';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: accentPurple),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _sectionTitle('Sign Playback'),
                _card(
                  children: [
                    const Text(
                      'Default playback speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _speedLabel(_playbackSpeed),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _speedChoice('Slow', 0.75),
                        const SizedBox(width: 8),
                        _speedChoice('Normal', 1.0),
                        const SizedBox(width: 8),
                        _speedChoice('Fast', 1.25),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 28),
                    _switchTile(
                      title: 'Auto-play signs',
                      subtitle:
                          'Start sign videos automatically when a result opens.',
                      value: _autoPlaySigns,
                      onChanged: (value) async {
                        setState(() => _autoPlaySigns = value);
                        await _settings.setAutoPlaySigns(value);
                      },
                    ),
                    _switchTile(
                      title: 'Skip missing signs automatically',
                      subtitle:
                          'Continue the sequence instead of stopping at a missing MP4.',
                      value: _skipMissingSigns,
                      onChanged: (value) async {
                        setState(() => _skipMissingSigns = value);
                        await _settings.setSkipMissingSigns(value);
                      },
                    ),
                    _switchTile(
                      title: 'Show gloss progress',
                      subtitle:
                          'Display the current progress through the gloss sequence.',
                      value: _showGlossProgress,
                      onChanged: (value) async {
                        setState(() => _showGlossProgress = value);
                        await _settings.setShowGlossProgress(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('Security'),
                _card(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: accentPurple,
                      secondary: const Icon(
                        Icons.lock_person_rounded,
                        color: accentPurple,
                      ),
                      title: const Text(
                        'Quick Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _deviceAuthAvailable
                            ? 'Use fingerprint, face, PIN, pattern, or device password from the Login screen.'
                            : 'Device authentication is not available on this device.',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      value: _quickLoginEnabled,
                      onChanged:
                          _deviceAuthAvailable ? _toggleQuickLogin : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.fingerprint_rounded,
                        color: accentPurple,
                      ),
                      title: const Text(
                        'Test Device Authentication',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                      onTap:
                          _deviceAuthAvailable ? _testDeviceAuth : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.password_rounded,
                        color: accentPurple,
                      ),
                      title: const Text(
                        'Change EchoSign Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('Speech Recognition'),
                _card(
                  children: const [
                    _InfoRow(
                      icon: Icons.cloud_rounded,
                      title: 'Speech-to-text',
                      value: 'Groq Whisper Large V3 Turbo',
                    ),
                    _InfoRow(
                      icon: Icons.language_rounded,
                      title: 'Recognition language',
                      value: 'English',
                    ),
                    _InfoRow(
                      icon: Icons.auto_awesome_rounded,
                      title: 'ASL-style gloss',
                      value: 'Groq AI + local fallback',
                    ),
                    _InfoRow(
                      icon: Icons.back_hand_rounded,
                      title: 'Sign recognition',
                      value: 'Laptop AI server',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('App & Data'),
                _card(
                  children: [
                    _navTile(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Translation History',
                      route: '/history',
                    ),
                    _navTile(
                      context,
                      icon: Icons.favorite_outline_rounded,
                      title: 'Favorites',
                      route: '/favorites',
                    ),
                    _navTile(
                      context,
                      icon: Icons.backup_outlined,
                      title: 'Backup & Restore',
                      route: BackupRestoreScreen.routeName,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle('About'),
                _card(
                  children: const [
                    _InfoRow(
                      icon: Icons.apps_rounded,
                      title: 'Application',
                      value: 'EchoSign',
                    ),
                    _InfoRow(
                      icon: Icons.hub_rounded,
                      title: 'Processing',
                      value: 'Hybrid cloud + local',
                    ),
                    _InfoRow(
                      icon: Icons.storage_rounded,
                      title: 'Local database',
                      value: 'SQLite',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _resetDefaults,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset Settings'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: accentPurple,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _speedChoice(String label, double value) {
    final selected = _playbackSpeed == value;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _playbackSpeed = value);
          await _settings.setPlaybackSpeed(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accentPurple : darkButtonColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? accentPurple : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: accentPurple,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accentPurple),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white38,
      ),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.info_outline_rounded,
        color: _SettingsScreenState.accentPurple,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
