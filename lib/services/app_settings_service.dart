import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _keyPlaybackSpeed = 'settings_playback_speed';
  static const _keyAutoPlaySigns = 'settings_auto_play_signs';
  static const _keySkipMissingSigns = 'settings_skip_missing_signs';
  static const _keyShowGlossProgress = 'settings_show_gloss_progress';

  Future<double> getPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPlaybackSpeed) ?? 1.0;
  }

  Future<void> setPlaybackSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPlaybackSpeed, value);
  }

  Future<bool> getAutoPlaySigns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPlaySigns) ?? true;
  }

  Future<void> setAutoPlaySigns(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPlaySigns, value);
  }

  Future<bool> getSkipMissingSigns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySkipMissingSigns) ?? false;
  }

  Future<void> setSkipMissingSigns(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkipMissingSigns, value);
  }

  Future<bool> getShowGlossProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowGlossProgress) ?? true;
  }

  Future<void> setShowGlossProgress(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowGlossProgress, value);
  }

  Future<void> resetDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlaybackSpeed);
    await prefs.remove(_keyAutoPlaySigns);
    await prefs.remove(_keySkipMissingSigns);
    await prefs.remove(_keyShowGlossProgress);
  }
}
