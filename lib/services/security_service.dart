import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  SecurityService._();

  static final SecurityService instance = SecurityService._();

  static const String _quickLoginFirebaseUidKey =
      'security_quick_login_firebase_uid';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isDeviceAuthenticationAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      if (!await isDeviceAuthenticationAvailable()) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getQuickLoginFirebaseUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quickLoginFirebaseUidKey);
  }

  Future<bool> isQuickLoginEnabledForFirebaseUser(String firebaseUid) async {
    return await getQuickLoginFirebaseUid() == firebaseUid;
  }

  Future<void> enableQuickLoginForFirebaseUser(String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quickLoginFirebaseUidKey, firebaseUid);
  }

  Future<void> disableQuickLoginForFirebaseUser(String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString(_quickLoginFirebaseUidKey) == firebaseUid) {
      await prefs.remove(_quickLoginFirebaseUidKey);
    }
  }

  Future<void> clearQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickLoginFirebaseUidKey);
  }
}
