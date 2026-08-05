import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAppLocked = false;
  bool _appLockEnabled = false;
  bool _useBiometric = false;
  String? _appPin;
  String? _hiddenSongsPin;
  bool _showLyrics = true;
  bool _equalizerEnabled = false;
  bool _crossfadeEnabled = false;
  double _crossfadeDuration = 3.0;
  bool _gaplessPlayback = true;
  String _audioQuality = 'high';
  bool _showAlbumArt = true;
  bool _darkModeAmoled = false;
  String _accentColor = 'purple';
  bool _notificationEnabled = true;
  bool _headsetControl = true;

  bool get isAppLocked => _isAppLocked;
  bool get appLockEnabled => _appLockEnabled;
  bool get useBiometric => _useBiometric;
  bool get showLyrics => _showLyrics;
  bool get equalizerEnabled => _equalizerEnabled;
  bool get crossfadeEnabled => _crossfadeEnabled;
  double get crossfadeDuration => _crossfadeDuration;
  bool get gaplessPlayback => _gaplessPlayback;
  String get audioQuality => _audioQuality;
  bool get showAlbumArt => _showAlbumArt;
  bool get darkModeAmoled => _darkModeAmoled;
  String get accentColor => _accentColor;
  bool get notificationEnabled => _notificationEnabled;
  bool get headsetControl => _headsetControl;
  bool get hasAppPin => _appPin != null && _appPin!.isNotEmpty;
  bool get hasHiddenSongsPin => _hiddenSongsPin != null && _hiddenSongsPin!.isNotEmpty;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    _useBiometric = prefs.getBool('use_biometric') ?? false;
    _showLyrics = prefs.getBool('show_lyrics') ?? true;
    _equalizerEnabled = prefs.getBool('equalizer_enabled') ?? false;
    _crossfadeEnabled = prefs.getBool('crossfade_enabled') ?? false;
    _crossfadeDuration = prefs.getDouble('crossfade_duration') ?? 3.0;
    _gaplessPlayback = prefs.getBool('gapless_playback') ?? true;
    _audioQuality = prefs.getString('audio_quality') ?? 'high';
    _showAlbumArt = prefs.getBool('show_album_art') ?? true;
    _darkModeAmoled = prefs.getBool('dark_mode_amoled') ?? false;
    _accentColor = prefs.getString('accent_color') ?? 'purple';
    _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
    _headsetControl = prefs.getBool('headset_control') ?? true;

    _appPin = await _secureStorage.read(key: 'app_pin');
    _hiddenSongsPin = await _secureStorage.read(key: 'hidden_songs_pin');

    if (_appLockEnabled) {
      _isAppLocked = true;
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', _appLockEnabled);
    await prefs.setBool('use_biometric', _useBiometric);
    await prefs.setBool('show_lyrics', _showLyrics);
    await prefs.setBool('equalizer_enabled', _equalizerEnabled);
    await prefs.setBool('crossfade_enabled', _crossfadeEnabled);
    await prefs.setDouble('crossfade_duration', _crossfadeDuration);
    await prefs.setBool('gapless_playback', _gaplessPlayback);
    await prefs.setString('audio_quality', _audioQuality);
    await prefs.setBool('show_album_art', _showAlbumArt);
    await prefs.setBool('dark_mode_amoled', _darkModeAmoled);
    await prefs.setString('accent_color', _accentColor);
    await prefs.setBool('notification_enabled', _notificationEnabled);
    await prefs.setBool('headset_control', _headsetControl);
  }

  Future<bool> verifyAppPin(String pin) async {
    if (_appPin == null) return false;
    final match = _appPin == pin;
    if (match) {
      _isAppLocked = false;
      notifyListeners();
    }
    return match;
  }

  Future<bool> verifyHiddenSongsPin(String pin) async {
    if (_hiddenSongsPin == null) return false;
    return _hiddenSongsPin == pin;
  }

  Future<void> setAppPin(String pin) async {
    _appPin = pin;
    _appLockEnabled = true;
    await _secureStorage.write(key: 'app_pin', value: pin);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setHiddenSongsPin(String pin) async {
    _hiddenSongsPin = pin;
    await _secureStorage.write(key: 'hidden_songs_pin', value: pin);
    notifyListeners();
  }

  Future<void> removeAppPin() async {
    _appPin = null;
    _appLockEnabled = false;
    await _secureStorage.delete(key: 'app_pin');
    await _saveSettings();
    notifyListeners();
  }

  Future<void> removeHiddenSongsPin() async {
    _hiddenSongsPin = null;
    await _secureStorage.delete(key: 'hidden_songs_pin');
    notifyListeners();
  }

  void lockApp() {
    if (_appLockEnabled) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isAppLocked = false;
    notifyListeners();
  }

  void setAppLockEnabled(bool value) {
    _appLockEnabled = value;
    if (!value) _isAppLocked = false;
    _saveSettings();
    notifyListeners();
  }

  void setUseBiometric(bool value) {
    _useBiometric = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowLyrics(bool value) {
    _showLyrics = value;
    _saveSettings();
    notifyListeners();
  }

  void setEqualizerEnabled(bool value) {
    _equalizerEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setCrossfadeEnabled(bool value) {
    _crossfadeEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setCrossfadeDuration(double value) {
    _crossfadeDuration = value;
    _saveSettings();
    notifyListeners();
  }

  void setGaplessPlayback(bool value) {
    _gaplessPlayback = value;
    _saveSettings();
    notifyListeners();
  }

  void setAudioQuality(String value) {
    _audioQuality = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowAlbumArt(bool value) {
    _showAlbumArt = value;
    _saveSettings();
    notifyListeners();
  }

  void setDarkModeAmoled(bool value) {
    _darkModeAmoled = value;
    _saveSettings();
    notifyListeners();
  }

  void setAccentColor(String value) {
    _accentColor = value;
    _saveSettings();
    notifyListeners();
  }

  void setNotificationEnabled(bool value) {
    _notificationEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setHeadsetControl(bool value) {
    _headsetControl = value;
    _saveSettings();
    notifyListeners();
  }
}
